#!/bin/bash
# Checks how Angeling reads and shows Claude's usage limits. Needs the artwork in ~/.claude/angeling-pet.
# Usage: scripts/check-limits.sh [path/to/Angeling.app]   (default build/Angeling.app; touches nothing real)
set -u
APP="${1:-build/Angeling.app}/Contents/MacOS/Angeling"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
B="$T/.claude/angeling-pet"; mkdir -p "$B/state"
for f in characters emotes pets sounds spritesheet.webp; do ln -s "$HOME/.claude/angeling-pet/$f" "$B/$f"; done
fails=0

run() { CFFIXED_USER_HOME="$T" ANGELING_LIMIT_WINDOWS="${ANGELING_LIMIT_WINDOWS:-both}" ANGELING_STATE_DIR="$B/state" ANGELING_LIMIT_SHOW="${SHOW:-auto}" ANGELING_LIMIT_PLACE=both \
        ANGELING_PRINT_LIMITS=1 ANGELING_SNAPSHOT="$T/out.png" ANGELING_LIMITS="$1" "$APP" 2>/dev/null; }

# check <name> <ANGELING_LIMITS> <text the output must have>
check() {
  local out; out=$(run "$2")
  if printf '%s' "$out" | grep -qF -- "$3"; then echo "ok    $1"; else echo "FAIL  $1: wanted '$3', got:"; printf '%s\n' "$out"; fails=$((fails + 1)); fi
}
# reply <file> <rows as kind:percent[:name]...>: a usage API reply resetting in `HOURS` hours
reply() { /usr/bin/python3 - "$@" <<'P'
import datetime, json, os, sys
at = (datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(hours=float(os.environ.get("HOURS", 2)))).isoformat()
def row(a):
    k, p, *n = a.split(":")
    return {"kind": k, "percent": float(p), "resets_at": at, "scope": {"model": {"display_name": n[0]}, "surface": None} if n else None}
json.dump({"five_hour": None, "seven_day": None, "limits": [row(a) for a in sys.argv[2:]]}, open(sys.argv[1], "w"))
P
}

reply "$T/max.json" session:40 weekly_all:62 weekly_scoped:30:Fable
check "5 hours and week by default"  "@$T/max.json" "bar: 5hrs. 40%  ·  weekly 62%"
check "scoped limit in the list"     "@$T/max.json" "weekly (Fable) ใช้ไป 30%"

reply "$T/ultra.json" weekly_all:62 weekly_scoped:30:Fable weekly_scoped:10:Sonnet
check "no session: busiest scoped"   "@$T/ultra.json" "bar: Fable 30%  ·  weekly 62%"

reply "$T/unknown.json" monthly_spend:44
check "unknown meter still shows"    "@$T/unknown.json" "bar: monthly spend 44%"

printf '{"five_hour":{"utilization":40},"seven_day":{"utilization":62}}' > "$T/legacy.json"
check "reply without rows"           "@$T/legacy.json" "bar: 5hrs. 40%  ·  weekly 62%"

printf '{"limits":[],"five_hour":null,"seven_day":null}' > "$T/empty.json"
check "no numbers"                   "@$T/empty.json" "ยังไม่มีข้อมูล limit"

HOURS=2 reply "$T/full.json" session:92 weekly_all:20
check "near full shows the reset"    "@$T/full.json" "5hrs. 92%▲ ("
HOURS=160 reply "$T/pace.json" weekly_all:40
check "ahead of time gets a ▲"       "@$T/pace.json" "weekly 40%▲"
HOURS=20 reply "$T/calm.json" weekly_all:40
check "behind time has no ▲"         "@$T/calm.json" "bar: weekly 40%  ·  รีเซ็ต"

reply "$T/dup.json" weekly_all:62 weekly_scoped:30:Fable other_meter:40:Fable
check "same name, first row"         "@$T/dup.json" "weekly (Fable) ใช้ไป 30%"
check "same name, second row"        "@$T/dup.json" "Fable ใช้ไป 40%"

printf '{"five_hour":{"utilization":40},"seven_day":{"utilization":62},"limits":[{"kind":"weekly_scoped","percent":5,"scope":{"model":{"display_name":"Fable"}}}]}' > "$T/partial.json"
check "rows without main ones"       "@$T/partial.json" "bar: 5hrs. 40%  ·  weekly 62%"

printf '{"limits":[{"kind":"session","percent":null}]}' > "$T/nulls.json"
check "rows without numbers"         "@$T/nulls.json" "ยังไม่มีข้อมูล limit"

reply "$T/pill.json" weekly_all:20 weekly_scoped:5:Fable weekly_scoped:95:Sonnet
SHOW="week,Fable,Sonnet" check "pill takes the fullest"  "@$T/pill.json" "pill: Sonnet"

reply "$T/many.json" session:40 weekly_all:62 weekly_scoped:30:Fable weekly_scoped:20:Sonnet weekly_scoped:10:Claude-Design-Long-Name weekly_scoped:5:Another-Long-Surface-Name
SHOW="week,five,Fable,Sonnet,Claude-Design-Long-Name,Another-Long-Surface-Name" check "narrow label keeps both"  "@$T/many.json" "5hrs. 40%"
SHOW="week,five,Fable,Sonnet,Claude-Design-Long-Name,Another-Long-Surface-Name" check "...and the week"          "@$T/many.json" "weekly 62%"

same() { local out; out=$(SHOW="$2" run "@$T/$1.json"); if [ "$(printf '%s\n' "$out" | sed -n 's/^bar: //p')" = "$(printf '%s\n' "$out" | sed -n 's/^bubble: //p')" ]; then echo "ok    bubble matches label: $1"; else echo "FAIL  bubble and label differ: $out"; fails=$((fails + 1)); fi; }
same max auto
same full auto
same many "week,five,Fable,Sonnet,Claude-Design-Long-Name,Another-Long-Surface-Name"
reply "$T/single.json" weekly_all:71
same single auto
check "starts with 5hrs."            "@$T/max.json" "bubble: 5hrs. 40%  ·  weekly 62%"

# 1.11's one setting still counts, and can't leave a plan with nothing.
ANGELING_LIMIT_WINDOWS=five check "1.11 setting: 5 hours only"  "@$T/max.json" "bar: 5hrs. 40%  ·  รีเซ็ต"
ANGELING_LIMIT_WINDOWS=week check "1.11 setting: week only"     "@$T/max.json" "bar: weekly 62%  ·  รีเซ็ต"
ANGELING_LIMIT_WINDOWS=five check "1.11 setting without 5hrs."  "@$T/ultra.json" "weekly 62%"

# Two saved files: the newer numbers win, and old ones say so.
save() { printf '{"rate_limits":{"seven_day":{"used_percentage":%s}}}' "$2" > "$B/$1"; touch -t "$(date -v-"$3" +%Y%m%d%H%M)" "$B/$1"; }
save limits-api.json 88 1H; save limits.json 11 5d
check "API newer than status line"   files "bar: weekly 88%"
check "old numbers say so"           files "อัปเดต 1 ชม. ก่อน (ตัวเลขอาจไม่ล่าสุด"
save limits-api.json 88 5d; save limits.json 11 1H
check "status line newer than API"   files "bar: weekly 11%"
printf '{"rate_limits":{"seven_day":{"used_percentage":88},"limits":[{"kind":"weekly_all","percent":88},{"kind":"weekly_scoped","percent":30,"scope":{"model":{"display_name":"Fable"}}}]}}' > "$B/limits-api.json"; touch -t "$(date -v-5d +%Y%m%d%H%M)" "$B/limits-api.json"
check "status line keeps the API's Fable" files "weekly (Fable) ใช้ไป 30%"
save limits-api.json 88 5M; save limits.json 11 1M
check "fresh API beats status line"  files "bar: weekly 88%"

[ "$fails" = 0 ] && echo "All limit checks passed" || { echo "$fails failed"; exit 1; }
