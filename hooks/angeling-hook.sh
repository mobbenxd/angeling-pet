#!/bin/bash
# Angeling pet: Claude Code hook -> writes per-session state for the floating widget.
# Usage (from settings.json hooks): hook.sh   (reads hook JSON on stdin)
DIR="$HOME/.claude/angeling-pet/state"
mkdir -p "$DIR"
INPUT=$(cat)
JQ=/opt/homebrew/bin/jq
[ -x "$JQ" ] || JQ=jq

EVENT=$(echo "$INPUT" | $JQ -r '.hook_event_name // empty')
SID=$(echo "$INPUT" | $JQ -r '.session_id // "unknown"')
FILE="$DIR/$SID.json"

if [ "$EVENT" = "SessionEnd" ]; then
  rm -f "$FILE"
  exit 0
fi

# Background helpers (away summaries, late subagents) and idle reminders fire after the
# turn ended; they must not reopen a finished session.
# One writer per session at a time: parallel tool calls fire hooks concurrently.
LOCK="$FILE.lock"
for _ in $(seq 1 100); do
  mkdir "$LOCK" 2>/dev/null && break
  # break a lock left behind by a killed hook (older than 5s)
  if [ -d "$LOCK" ] && [ $(( $(date +%s) - $(stat -f %m "$LOCK" 2>/dev/null || echo 0) )) -gt 5 ]; then rmdir "$LOCK" 2>/dev/null; fi
  sleep 0.02
done
trap 'rmdir "$LOCK" 2>/dev/null' EXIT

# Previous state; a damaged file counts as empty so it gets rewritten instead of sticking.
PREV_JSON=$($JQ -c . "$FILE" 2>/dev/null) || PREV_JSON='{}'
[ -n "$PREV_JSON" ] || PREV_JSON='{}'
PREV_STATE=$(echo "$PREV_JSON" | $JQ -r '.state // empty' 2>/dev/null)
case "$PREV_STATE" in done|idle|"") FINISHED=1 ;; *) FINISHED=0 ;; esac
if [ "$EVENT" = "SubagentStop" ] && [ "$FINISHED" = 1 ]; then exit 0; fi
# SessionStart also fires on resume / clear / compact: never wipe what the session was doing.
if [ "$EVENT" = "SessionStart" ] && [ "$PREV_JSON" != "{}" ]; then exit 0; fi
if [ "$EVENT" = "Notification" ]; then
  NTYPE=$(echo "$INPUT" | $JQ -r '.notification_type // empty')
  NMSG=$(echo "$INPUT" | $JQ -r '.message // empty')
  if [ "$NTYPE" = "idle_prompt" ] || echo "$NMSG" | grep -qi "waiting for your input"; then
    exit 0   # just "Claude is idle" — the Stop event already reported the result
  fi
fi

TMP=$(mktemp "$DIR/.tmp.XXXXXX") || exit 0
TTY_NAME=$(ps -o tty= -p "${CLAUDE_PID:-$PPID}" 2>/dev/null | tr -d ' ')
[ "$TTY_NAME" = "??" ] && TTY_NAME=""
echo "$INPUT" | $JQ -c --arg now "$(date +%s)" \
  --arg host "${CLAUDE_CODE_HOST_SESSION_ID:-}" --arg app "${__CFBundleIdentifier:-}" \
  --arg term "${TERM_PROGRAM:-}" --arg tty "$TTY_NAME" --arg iterm "${ITERM_SESSION_ID:-}" --argjson prevobj "$PREV_JSON" '
  def short(n): tostring | gsub("\\[(?<t>[^\\]]*)\\]\\([^)]*\\)"; "\(.t)") | gsub("\\*\\*|`|^#+ "; "") | gsub("[\\n\\r\\t]+"; " ") | if length > n then .[0:n] + "…" else . end;
  def base: tostring | split("/") | last;
  def tooltext:
    (.tool_input // {}) as $i
    | if .tool_name == "Bash" then "รัน: " + (($i.description // $i.command // "") | short(60))
      elif (.tool_name | test("^(Edit|Write|MultiEdit|NotebookEdit)$")) then "แก้ไฟล์ " + (($i.file_path // $i.notebook_path // "") | base)
      elif .tool_name == "Read" then "อ่าน " + (($i.file_path // "") | base)
      elif (.tool_name | test("^(Grep|Glob)$")) then "ค้นหา " + (($i.pattern // "") | short(40))
      elif (.tool_name | test("^(WebFetch|WebSearch)$")) then "ค้นเว็บ " + (($i.query // $i.url // "") | short(40))
      elif (.tool_name | test("^(Agent|Task)$")) then "ส่ง agent: " + (($i.description // "") | short(40))
      elif (.tool_name | test("update_plan$")) then "อัปเดต task list"
      else "ใช้ " + (.tool_name | sub("^mcp__[^_]+__"; "") | short(40))
      end;
  def reviewtool: (.tool_name // "") | test("^(Read|Grep|Glob|WebFetch|WebSearch)$");
  $prevobj as $p
  | {
      session: .session_id,
      cwd: (.cwd // $p.cwd // ""),
      project: ((.cwd // $p.cwd // "") | base),
      task: $p.task,
      updated: ($now | tonumber),
      host: (if $host != "" then $host else $p.host end),
      app: (if $app != "" then $app else $p.app end),
      term: (if $term != "" then $term else $p.term end),
      tty: (if $tty != "" then "/dev/" + $tty else $p.tty end),
      iterm: (if $iterm != "" then $iterm else $p.iterm end)
    }
  + ( if .hook_event_name == "SessionStart" then {state: "idle", text: "พร้อมแล้ว~"}
      elif .hook_event_name == "UserPromptSubmit" then {state: "running", text: "รับงานแล้ว!", task: (.prompt // "" | short(80)), plan: []}
      elif .hook_event_name == "PreToolUse" then
        (if (.tool_name // "") | test("wrap_up$") then
           {state: "running", text: "สรุปงาน", plan: ($p.plan // [] | map(. + {s: "completed"}))}
         elif (.tool_name // "") | test("update_plan$") then
           (.tool_input.items // null) as $items
           | if $items then
               ($items | map(select(.status == "in_progress")) | first | .content // null) as $cur
               | {state: "running", text: ("กำลังทำ: " + ($cur // "วางแผน")),
                  plan: ($items | map({c: .content, s: .status}))}
             elif .tool_input.advance == true and ($p.plan // [] | length) > 0 then
               ($p.plan | map(.s) | index("in_progress")) as $ip
               | ($p.plan | to_entries | map(
                   if .key == $ip then .value + {s: "completed"}
                   elif $ip != null and .key == ($ip + 1) then .value + {s: "in_progress"}
                   else .value end)) as $np
               | ($np | map(select(.s == "in_progress")) | first | .c // null) as $cur
               | {state: "running", text: (if $cur then "กำลังทำ: " + $cur else "เกือบเสร็จแล้ว" end), plan: $np}
             elif ((.tool_input.done // []) | length) > 0 or .tool_input.start != null then
               ((.tool_input.done // []) | map(. - 1)) as $done
               | ((.tool_input.start // 0) - 1) as $st
               | ($p.plan // [] | to_entries | map(
                   if (.key as $k | $done | index($k)) != null then .value + {s: "completed"}
                   elif .key == $st then .value + {s: "in_progress"}
                   else .value end)) as $np
               | ($np | map(select(.s == "in_progress")) | last | .c // null) as $cur
               | {state: "running", text: (if $cur then "กำลังทำ: " + $cur else "อัปเดต task list" end), plan: $np}
             else {state: "running", text: "อัปเดต task list"} end
         else {state: (if reviewtool then "review" else "running" end), text: tooltext} end)
      elif .hook_event_name == "PostToolUseFailure" then {state: "failed", text: ("พลาด: " + tooltext)}
      elif .hook_event_name == "PostToolUse" then {state: "running", text: $p.text}
      elif .hook_event_name == "Notification" then {state: "waiting", text: (.message // "รอคุณอยู่นะ" | short(80))}
      elif .hook_event_name == "PermissionRequest" then {state: "waiting", text: ("ขออนุญาต: " + tooltext)}
      elif .hook_event_name == "Stop" then {state: "done", text: ((.last_assistant_message // "เสร็จแล้ว ✨") | short(90))}
      elif .hook_event_name == "StopFailure" then {state: "failed", text: "เจอปัญหา ทำต่อไม่ได้"}
      elif .hook_event_name == "SubagentStop" then {state: "running", text: "agent ทำเสร็จหนึ่งตัว"}
      else {state: ($p.state // "idle"), text: $p.text} end )
  | . + {plan: (.plan // $p.plan)}
' > "$TMP" 2>/dev/null && [ -s "$TMP" ] && mv -f "$TMP" "$FILE"
rm -f "$TMP"
exit 0
