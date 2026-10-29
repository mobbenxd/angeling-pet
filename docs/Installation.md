# การติดตั้ง

> ก่อนเริ่ม ตรวจ [ความต้องการของระบบ](Requirements.md) ให้ครบ

## 1. ดาวน์โหลด

```bash
git clone https://github.com/mobbenxd/angeling-pet.git ~/apps/angeling-pet
cd ~/apps/angeling-pet
```

จะเก็บไว้โฟลเดอร์ไหนก็ได้ แต่อย่าลบทิ้งหลังติดตั้ง เพราะต้องใช้ตอน [อัปเดต](Updating-and-Uninstalling.md)

## 2. ติดตั้ง

```bash
./install.sh
```

ถ้าไม่อยากให้ Angeling เปิดเองตอน login ให้ใช้ `./install.sh --no-login`

สิ่งที่ควรเห็น:

```
==> Assets
Sprite sheet: copied from /Users/<you>/.codex/pets/angeling/spritesheet.webp
Emote: lv
...
==> Build
Built /Users/<you>/Applications/Angeling.app
==> Runtime files (/Users/<you>/.claude/angeling-pet)
==> Claude Code hooks (/Users/<you>/.claude/settings.json)
    (backup: /Users/<you>/.claude/settings.json.angeling-backup)
==> Start at login (/Users/<you>/Library/LaunchAgents/local.angeling.pet.plist)
==> Launch
Done. Angeling is in the bottom-right corner; ⌥⌘A shows/hides it.
```

### `install.sh` ทำอะไรบ้าง

| ขั้น | ผลลัพธ์ |
|---|---|
| Assets | คัดลอก sprite sheet ไปที่ `assets/` และดาวน์โหลด emote 6 ตัว กับเสียง Level Up |
| Build | คอมไพล์ `~/Applications/Angeling.app` |
| Runtime files | คัดลอก hook และภาพไปที่ `~/.claude/angeling-pet/` |
| Claude Code hooks | เพิ่ม hook 11 event ใน `~/.claude/settings.json` โดยไม่แตะ hook เดิม และสำรองไฟล์เดิมไว้ก่อน รันซ้ำได้ ไม่เพิ่มซ้ำ |
| Start at login | สร้าง LaunchAgent `local.angeling.pet` |
| Launch | เปิด Angeling |

## 3. เช็คว่าติดตั้งสำเร็จ

| เช็ค | ควรเห็น |
|---|---|
| มุมขวาล่างของจอ | Angeling ลอยอยู่ |
| แถบเมนูด้านบน | ไอคอนหน้า Angeling |
| `pgrep -x Angeling` | มีเลข process |
| `grep -c angeling-pet/hook.sh ~/.claude/settings.json` | `11` |

แล้วไปลองใช้งานจริงที่ **[เริ่มใช้งานครั้งแรก →](First-Run.md)**

## ติดตั้งไม่ผ่าน?

| ข้อความ error | วิธีแก้ |
|---|---|
| `Angeling runs on macOS only.` | ใช้ได้เฉพาะ macOS |
| `swiftc not found` | `xcode-select --install` |
| `jq not found` | `brew install jq` |
| `Missing sprite sheet` | ติดตั้งเพ็ต Angeling ใน Codex หรือดู [เปลี่ยนเป็นเพ็ตตัวอื่น](Custom-Pet.md) |
| `Could not download the level-up sound` | ไม่เป็นไร การเตือนจะใช้เสียง Glass แทน รัน `./install.sh` ซ้ำภายหลังเพื่อลองโหลดใหม่ |
| `Could not download emote` | ไม่เป็นไร ใช้งานได้ปกติ แค่ไม่มี emote รัน `./install.sh` ซ้ำภายหลังเพื่อลองโหลดใหม่ |

ปัญหาอื่นดูที่ [แก้ปัญหา](Troubleshooting.md)

---
[← สารบัญคู่มือ](README.md)
