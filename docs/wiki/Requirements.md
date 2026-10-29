# ความต้องการของระบบ

เช็คให้ครบทุกข้อก่อน [ติดตั้ง](Installation) ทุกข้อมีคำสั่งให้ลองรันใน Terminal

| ต้องมี | เช็คด้วยคำสั่ง | ถ้ายังไม่มี |
|---|---|---|
| macOS 13 (Ventura) ขึ้นไป | `sw_vers -productVersion` | อัปเดต macOS |
| Xcode Command Line Tools (`swiftc`) | `swiftc --version` | `xcode-select --install` |
| `jq` | `jq --version` | `brew install jq` (ต้องมี [Homebrew](https://brew.sh) ก่อน) |
| `git` | `git --version` | มาพร้อม Command Line Tools |
| Claude Code (แอป Claude desktop หรือ CLI `claude`) | `ls ~/.claude` | ติดตั้งจาก <https://claude.com/claude-code> |
| ภาพ sprite ของเพ็ต Angeling จาก Codex | `ls ~/.codex/pets/angeling/spritesheet.webp` | ดูด้านล่าง |

## ภาพ sprite ของ Angeling

ภาพตัวละครไม่ได้รวมอยู่ใน repo เพราะเป็นลิขสิทธิ์ของ Gravity ตัวติดตั้งจะคัดลอกจากเพ็ตที่คุณติดตั้งไว้ในแอป Codex

1. เปิดแอป **Codex** (ChatGPT desktop) แล้วติดตั้งเพ็ต **Angeling**
2. เช็คว่ามีไฟล์ `~/.codex/pets/angeling/spritesheet.webp`

ถ้าไม่มี Codex ก็ใช้ sprite sheet ของเพ็ต Codex ตัวอื่น หรือไฟล์ที่ทำเองในรูปแบบเดียวกันได้ ดู [เปลี่ยนเป็นเพ็ตตัวอื่น](Custom-Pet)

## ไม่บังคับ

| สิ่งที่ต้องมี | ใช้ทำอะไร |
|---|---|
| อินเทอร์เน็ตตอนติดตั้ง | ดาวน์โหลด emote จาก irowiki.org (ถ้าโหลดไม่ได้ Angeling ก็ยังใช้งานได้ แค่ไม่มี emote) |
| แอป LINE สำหรับ Mac | [แจ้งเตือน LINE](LINE-Notifications) |
| สิทธิ์ Full Disk Access | แสดงข้อความ LINE ล่าสุด (ถ้าไม่ให้ จะเห็นแค่จำนวนที่ยังไม่อ่าน) |

ต่อไป: **[การติดตั้ง →](Installation)**
