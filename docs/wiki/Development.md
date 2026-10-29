# การพัฒนาและร่วมพัฒนา

## โครงสร้าง repo

| Path | คืออะไร |
|---|---|
| `src/main.swift` | ตัวแอปทั้งหมด |
| `hooks/angeling-hook.sh` | hook ของ Claude Code |
| `scripts/build.sh` | build `.app` |
| `scripts/fetch-assets.sh` | ดึง sprite และ emote |
| `scripts/publish-wiki.sh` | เผยแพร่ `docs/wiki/` ขึ้น GitHub Wiki |
| `install.sh`, `uninstall.sh` | ติดตั้งและถอนการติดตั้ง |
| `docs/wiki/` | ต้นฉบับของ Wiki นี้ |

## Build และรัน

```bash
./scripts/build.sh                   # → ~/Applications/Angeling.app
pkill -x Angeling; open ~/Applications/Angeling.app
```

แก้ hook แล้วต้องคัดลอกไปวางที่เดิม:

```bash
cp hooks/angeling-hook.sh ~/.claude/angeling-pet/hook.sh
```

## ทดสอบหน้าตาโดยไม่ต้องจับภาพจอ

```bash
ANGELING_SNAPSHOT=/tmp/a.png ~/Applications/Angeling.app/Contents/MacOS/Angeling
```

| ตัวแปร | ผล |
|---|---|
| `ANGELING_EXPANDED=1` | แบบขยาย |
| `ANGELING_HIDE_ACTIVITY=1` | ซ่อนบับเบิล (เห็นป้ายตัวเลข) |
| `ANGELING_HOVER=1` | แสดงปุ่มซ่อนหรือแสดง |
| `ANGELING_EMOTE=lv` | บังคับให้แสดง emote |
| `ANGELING_LINE_UNREAD=5` | จำลองจำนวน LINE ที่ยังไม่อ่าน |
| `ANGELING_NOTIF_DB=/path/db` | ใช้ฐานข้อมูลแจ้งเตือนจำลอง |

## ทดสอบ hook

```bash
printf '%s' '{"hook_event_name":"UserPromptSubmit","session_id":"test","cwd":"/tmp/demo","prompt":"ลองดู"}' \
  | bash hooks/angeling-hook.sh
cat ~/.claude/angeling-pet/state/test.json
rm ~/.claude/angeling-pet/state/test.json
```

## ร่วมพัฒนา

`main` ถูกป้องกันไว้ ต้องแก้ผ่าน Pull Request เท่านั้น

1. Fork repo (หรือสร้าง branch ถ้ามีสิทธิ์)
2. `git switch -c feat/<ชื่อ>`
3. แก้โค้ด แล้วทดสอบด้วย snapshot
4. เปิด PR เข้า `main` พร้อมบอกว่าทดสอบอะไรไปแล้ว

## แก้ Wiki

Wiki นี้สร้างจากไฟล์ใน `docs/wiki/` ให้แก้ที่นั่นแล้วเปิด PR เมื่อ merge แล้ว ผู้ดูแลจะรัน:

```bash
./scripts/publish-wiki.sh
```

ลิงก์ระหว่างหน้าให้ใช้ชื่อไฟล์โดยไม่ต้องมี `.md` เช่น `[การติดตั้ง](Installation)`
