# หลักการทำงาน

```
Claude Code ──hook──► ~/.claude/angeling-pet/hook.sh ──► state/<session>.json
                                                              │ อ่านทุก 0.5 วินาที
LINE (Dock badge + Notification Center) ── ทุก 3 วินาที ──►    ▼
                                                     Angeling.app (src/main.swift)
```

## ไฟล์ในเครื่อง

| ที่อยู่ | คืออะไร |
|---|---|
| `~/Applications/Angeling.app` | ตัวแอป |
| `~/.claude/angeling-pet/hook.sh` | hook ที่ Claude Code เรียก |
| `~/.claude/angeling-pet/state/*.json` | สถานะของแต่ละ session |
| `~/.claude/angeling-pet/reminders.json` | การเตือนที่ตั้งไว้ |
| `~/.claude/angeling-pet/spritesheet.webp`, `emotes/` | ภาพ |
| `~/.claude/settings.json` | ลงทะเบียน hook |
| `~/Library/LaunchAgents/local.angeling.pet.plist` | เปิดเองตอน login |
| `defaults read local.angeling.pet` | การตั้งค่า (ตำแหน่ง, ตัวเลือก) |

## Hook

ลงทะเบียนไว้ 11 event: `SessionStart`, `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `Notification`, `PermissionRequest`, `Stop`, `StopFailure`, `SubagentStop`, `SessionEnd`

| Event | สถานะที่เขียน |
|---|---|
| `UserPromptSubmit` | กำลังทำ, บันทึก prompt |
| `PreToolUse` | กำลังทำ หรือตรวจดู (Read/Grep/Glob/Web) พร้อมบอกว่าทำอะไร; อ่าน task list จากเครื่องมือของ Claude desktop |
| `PermissionRequest`, `Notification` | รอคุณ |
| `PostToolUseFailure`, `StopFailure` | ติดปัญหา |
| `Stop` | เสร็จแล้ว พร้อมข้อความสุดท้ายของ Claude |
| `SessionEnd` | ลบไฟล์ |

กติกาสำคัญ:
- ล็อกต่อ session (`mkdir` lock + เขียนไฟล์ชั่วคราวแล้ว `mv`) เพราะ tool ที่รันพร้อมกันเรียก hook พร้อมกัน
- ไม่ให้ `SubagentStop` หรือแจ้งเตือน idle ที่มาทีหลังเปิด session ที่เสร็จแล้วขึ้นมาใหม่
- `SessionStart` ตอน resume หรือ compact ไม่ล้างสถานะเดิม
- ใช้เวลาประมาณ 50–80 ms ต่อ event

## ไฟล์ state

```json
{
  "session": "2c86…",            "cwd": "/path/to/project",  "project": "project",
  "state": "running",            "text": "รัน: npm test",      "task": "prompt ที่สั่ง",
  "plan": [{"c": "ขั้นที่ 1", "s": "completed"}],
  "updated": 1793259079,
  "host": "local_…",  "app": "com.apple.Terminal",  "term": "Apple_Terminal",
  "tty": "/dev/ttys022",  "iterm": null
}
```

`host`, `app`, `term`, `tty` และ `iterm` ใช้หาหน้าต่างตอนคลิก (ดู [วิธีใช้งาน](Usage.md#เปิด-session-ไปที่ไหน))

## ตัวแอป

- เขียนด้วย Swift + AppKit ในไฟล์เดียว ไม่มี dependency และไม่ใช้เน็ต
- เป็นหน้าต่างลอยที่ไม่แย่งโฟกัส อยู่ทุก Space และไม่มีไอคอนใน Dock
- คีย์ลัด ⌥⌘A ใช้ Carbon hotkey จึงไม่ต้องขอสิทธิ์ Accessibility

## การเตือน

- เก็บใน `reminders.json` (ชื่อ, เวลา, `eventId` ของ event ในปฏิทิน, เวลาเลื่อน, เวลาที่เริ่มเตือน)
- สร้าง event ผ่าน EventKit ต้องได้สิทธิ์ Full Access เพื่ออ่าน event กลับมาได้
- ซิงก์กับปฏิทินเมื่อ EventKit แจ้งว่ามีการเปลี่ยนแปลง และทุก 60 วินาที: ถ้า event ถูกย้าย เวลาเตือนจะย้ายตาม ถ้าถูกลบ การเตือนจะถูกยกเลิก (เฉพาะการเตือนที่ยังไม่ดัง)
- ตรวจทุก 0.5 วินาทีพร้อมกับ state ของ session

## LINE

- จำนวนที่ยังไม่อ่าน: `lsappinfo info -only StatusLabel -app jp.naver.line.mac`
- ข้อความล่าสุด: อ่าน record ล่าสุดของ `jp.naver.line.mac` จาก `~/Library/Group Containers/group.com.apple.usernoted/db2/db` (SQLite แบบอ่านอย่างเดียว ข้อมูลเป็น binary plist ใช้คีย์ `req.titl` / `req.subt` / `req.body`)

---
[← สารบัญคู่มือ](README.md)
