#!/bin/bash
# Angeling pet: answer Claude Code's permission prompts from the pet (PermissionRequest hook).
# Claude Code shows its own prompt while this runs, so whichever is answered first wins.
# Answering in Claude Code usually sends this script SIGTERM, but not always, so the wait loop
# also watches the transcript and gives up once the tool has a result there.
# Protocol, in ~/.claude/angeling-pet/permits/:
#   enabled        exists while the pet's buttons are on (the app keeps it in sync)
#   no-questions   exists while the pet should leave AskUserQuestion to Claude Code alone
#   <id>.json      the request, written here; the app shows it with buttons
#   <id>.answer    written by the app: allow | always | deny, or for AskUserQuestion a JSON
#                  object mapping each question to the chosen label(s)
DIR="$HOME/.claude/angeling-pet/permits"
INPUT=$(cat)
# Nothing to wait for unless the pet is running with its buttons on.
[ -f "$DIR/enabled" ] || exit 0
pgrep -xq Angeling || exit 0
JQ=/opt/homebrew/bin/jq
[ -x "$JQ" ] || JQ=jq
command -v "$JQ" >/dev/null || exit 0
TOOL=$(echo "$INPUT" | $JQ -r '.tool_name // empty')
[ "$TOOL" = "AskUserQuestion" ] && [ -f "$DIR/no-questions" ] && exit 0

ID="$(date +%s)-$$-$RANDOM"
REQ="$DIR/$ID.json"
ANS="$DIR/$ID.answer"
REQIN="$DIR/.$ID.in"
cleanup() { rm -f "$REQ" "$ANS" "$REQIN"; }
trap 'cleanup; exit 0' TERM INT HUP
trap cleanup EXIT

TMP=$(mktemp "$DIR/.tmp.XXXXXX") || exit 0
echo "$INPUT" | $JQ -c --arg id "$ID" --argjson pid $$ --arg now "$(date +%s)" '
  def short(n): tostring | gsub("[\\r\\t]+"; " ") | if length > n then .[0:n] + "…" else . end;
  def base: tostring | split("/") | last;
  def cap: if . == null then null else tostring | if length > 6000 then .[0:6000] else . end end;
  (.tool_input // {}) as $i
  | {
      id: $id,
      pid: $pid,
      created: ($now | tonumber),
      session: .session_id,
      project: ((.cwd // "") | base),
      tool: (.tool_name // "" | sub("^mcp__[^_]+__"; "")),
      title: (if .tool_name == "AskUserQuestion" then "ถามคุณ"
              elif .tool_name == "Bash" then "รันคำสั่ง"
              elif (.tool_name // "" | test("^(Edit|MultiEdit|NotebookEdit)$")) then "แก้ไฟล์"
              elif .tool_name == "Write" then "เขียนไฟล์"
              elif (.tool_name // "" | test("^(WebFetch|WebSearch)$")) then "เข้าเว็บ"
              elif (.tool_name // "" | test("^mcp__")) then "ใช้ MCP"
              else "ใช้ " + (.tool_name // "tool") end),
      detail: (if .tool_name == "Bash" then ($i.command // "")
               elif ($i.file_path // $i.notebook_path) != null then (($i.file_path // $i.notebook_path) | base)
               elif $i.url != null then $i.url
               elif $i.query != null then $i.query
               elif $i.pattern != null then $i.pattern
               else ($i | tostring) end | short(240)),
      note: ($i.description // "" | short(80)),
      canAlways: ((.permission_suggestions // []) | length > 0),
      questions: (if .tool_name == "AskUserQuestion" then [($i.questions // [])[]
                    | {question, header, multiSelect: (.multiSelect // false),
                       options: [(.options // [])[] | {label, description}]}] else null end),
      # For the diff preview: the text an edit replaces and the text it puts in. Write leaves
      # "old" out, and the app reads the current file instead.
      path: ($i.file_path // $i.notebook_path),
      old: (if .tool_name == "Edit" then $i.old_string
            elif .tool_name == "MultiEdit" then ([($i.edits // [])[] | .old_string] | join("\n"))
            else null end | cap),
      new: (if .tool_name == "Edit" then $i.new_string
            elif .tool_name == "MultiEdit" then ([($i.edits // [])[] | .new_string] | join("\n"))
            elif .tool_name == "Write" then $i.content
            elif .tool_name == "NotebookEdit" then $i.new_source
            else null end | cap)
    }' > "$TMP" 2>/dev/null && mv "$TMP" "$REQ" || { rm -f "$TMP"; exit 0; }

# The transcript gets the tool's result once the prompt is answered in Claude Code (or the turn
# is interrupted). Find this request's tool_use id: the newest call with the same tool and input.
TRANSCRIPT=$(echo "$INPUT" | $JQ -r '.transcript_path // empty')
[ -f "$TRANSCRIPT" ] || TRANSCRIPT=""
START=0
[ -n "$TRANSCRIPT" ] && START=$(stat -f %z "$TRANSCRIPT" 2>/dev/null || echo 0)
TOOL_ID=""
[ -n "$TRANSCRIPT" ] && { echo "$INPUT" > "$REQIN" || TRANSCRIPT=""; }
find_tool_id() {
  # Exact tool and input first; otherwise the newest call of that tool.
  TOOL_ID=$(tail -c 2000000 "$TRANSCRIPT" 2>/dev/null | grep -F '"tool_use"' | $JQ -rR --slurpfile req "$REQIN" '
    fromjson? | select(.type == "assistant") | (.message.content // [])[]?
    | select(.type == "tool_use" and .name == $req[0].tool_name)
    | "\(if .input == $req[0].tool_input then 1 else 0 end) \(.id)"' 2>/dev/null | sort -s -k1,1 | tail -1 | cut -d' ' -f2)
}
answered_elsewhere() {
  [ -n "$TRANSCRIPT" ] || return 1
  [ -n "$TOOL_ID" ] || find_tool_id
  [ -n "$TOOL_ID" ] || return 1
  # Only text written after this hook started can hold the result.
  tail -c +$((START + 1)) "$TRANSCRIPT" 2>/dev/null | grep -qF "\"tool_use_id\":\"$TOOL_ID\""
}

# Wait for the pet. Claude Code stops this hook when its timeout passes or (usually) when the
# prompt is answered there; the transcript check covers the times it does not.
N=0
while [ ! -s "$ANS" ]; do
  [ -f "$DIR/enabled" ] || exit 0
  if [ $((N % 4)) -eq 0 ]; then
    answered_elsewhere && exit 0
    [ "$TOOL" = "AskUserQuestion" ] && [ -f "$DIR/no-questions" ] && exit 0
  fi
  N=$((N + 1))
  sleep 0.25
done

ANSWER=$(cat "$ANS")
if [ "${ANSWER:0:1}" = "{" ]; then
  # AskUserQuestion: Claude Code takes the answers inside the tool's own input.
  echo "$INPUT" | $JQ -c --argjson answers "$ANSWER" '{hookSpecificOutput: {hookEventName: "PermissionRequest",
    decision: {behavior: "allow", updatedInput: ((.tool_input // {}) + {answers: $answers})}}}'
  exit 0
fi
case "$(echo "$ANSWER" | tr -d '[:space:]')" in
  allow)
    echo '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"allow"}}}' ;;
  always)
    # Claude Code's own "don't ask again" rules for this request.
    echo "$INPUT" | $JQ -c '{hookSpecificOutput: {hookEventName: "PermissionRequest",
      decision: {behavior: "allow", updatedPermissions: (.permission_suggestions // [])}}}' ;;
  deny)
    echo '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"deny","message":"The user denied this from the Angeling pet."}}}' ;;
esac
exit 0
