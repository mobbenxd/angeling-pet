# ความต้องการของระบบ

## จำเป็น

| ต้องมี | เช็คด้วย |
|---|---|
| macOS 13 (Ventura) ขึ้นไป รองรับทั้ง Apple silicon (M1/M2/M3…) และ Intel | เมนู  → About This Mac หรือรัน `sw_vers -productVersion` |
| อินเทอร์เน็ตตอนติดตั้ง | ใช้ดาวน์โหลดตัวแอป ภาพ Angeling และเสียง |

แค่นี้ก็ติดตั้งได้แล้ว ไม่ต้องมี Xcode, git, Homebrew หรือ Claude Code ภาพ Angeling, emote และเสียง Level Up มาพร้อมตัวติดตั้งเลย

## ไม่บังคับ (ใช้กับฟีเจอร์บางส่วน)

| ถ้ามี | จะได้ | หมายเหตุ |
|---|---|---|
| [Claude Code](https://claude.com/claude-code) (แอป Claude desktop หรือ CLI `claude`) | รายงานสถานะงานของ Claude | ติดตั้ง Claude ก่อน Angeling หรือถ้าติดตั้งทีหลัง ให้รันตัวติดตั้ง Angeling ซ้ำ |
| `jq` | ใช้คู่กับ Claude Code | macOS 15 ขึ้นไปมีให้แล้ว ถ้าเป็น macOS 13–14 ต้องรัน `brew install jq` |
| แอป LINE for Mac | [แจ้งเตือน LINE](LINE-Notifications.md) | ถ้าอยากเห็นข้อความด้วย ต้องให้สิทธิ์ Full Disk Access |
| แอป Calendar ที่มีบัญชีอยู่ (iCloud, Google ฯลฯ) | การ[ตั้งเตือน](Reminders.md)จะบันทึกลงปฏิทินด้วย | ไม่มีก็เตือนได้ปกติ |

## สำหรับคนที่จะ build เอง

| ต้องมี | เช็คด้วย | ติดตั้ง |
|---|---|---|
| Xcode Command Line Tools | `swiftc --version` | `xcode-select --install` |
| git | `git --version` | มาพร้อม Command Line Tools |

ต่อไป: **[การติดตั้ง →](Installation.md)**

---
[← สารบัญคู่มือ](README.md)
