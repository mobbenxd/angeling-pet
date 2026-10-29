# การติดตั้ง

## วิธีที่ 1: คำสั่งเดียว (แนะนำ)

1. เปิดแอป **Terminal** (กด ⌘Space แล้วพิมพ์ `Terminal`)
2. วางคำสั่งนี้แล้วกด Enter:

```bash
curl -fsSL https://raw.githubusercontent.com/mobbenxd/angeling-pet/main/get.sh | bash
```

3. รอประมาณ 10 วินาที Angeling จะโผล่ที่มุมขวาล่างของจอ

ตัวติดตั้งจะดาวน์โหลดแอปที่ build ไว้แล้ว พร้อมภาพ Angeling, emote และเสียงเตือน ไม่ต้องลงโปรแกรมอื่นเพิ่ม

ถ้าไม่อยากให้เปิดเองตอน login ให้ใช้:

```bash
curl -fsSL https://raw.githubusercontent.com/mobbenxd/angeling-pet/main/get.sh | bash -s -- --no-login
```

### สิ่งที่ควรเห็น

```
==> Downloading Angeling
######################################################################## 100.0%
==> Artwork
==> App (/Users/<you>/Applications/Angeling.app)
    installed the prebuilt app
==> Files (/Users/<you>/.claude/angeling-pet)
==> Claude Code
    hook added to …            ← ถ้ามี Claude Code
    not installed, so …        ← ถ้าไม่มี (ไม่เป็นไร การเตือนกับ LINE ยังใช้ได้)
==> Start at login (…/local.angeling.pet.plist)
==> Launch

Done! Angeling is in the bottom-right corner of your screen.
```

## วิธีที่ 2: build จากซอร์สโค้ด

สำหรับคนที่อยากแก้โค้ด ต้องมี Xcode Command Line Tools ก่อน (`xcode-select --install`)

```bash
git clone https://github.com/mobbenxd/angeling-pet.git ~/apps/angeling-pet
cd ~/apps/angeling-pet
./install.sh
```

ภาพจะดาวน์โหลดจาก GitHub Release ให้เอง ถ้ามีเพ็ต `angeling` ใน Codex อยู่แล้ว จะใช้ไฟล์นั้นแทน (ดู [เปลี่ยนเป็นเพ็ตตัวอื่น](Custom-Pet.md))

## ตัวติดตั้งทำอะไรบ้าง

| ขั้น | ผลลัพธ์ |
|---|---|
| Artwork | เตรียมภาพ Angeling, emote 6 ตัว และเสียง Level Up |
| App | วาง `~/Applications/Angeling.app` |
| Files | คัดลอกภาพ เสียง hook และตัวถอนการติดตั้งไปที่ `~/.claude/angeling-pet/` |
| Claude Code | ถ้ามี Claude Code จะเพิ่ม hook ใน `~/.claude/settings.json` โดยไม่แตะ hook เดิม และสำรองไฟล์เดิมไว้ก่อน ถ้าไม่มีจะข้ามขั้นนี้ |
| Start at login | ให้ Angeling เปิดเองตอน login |
| Launch | เปิด Angeling |

ตัวติดตั้งรันซ้ำได้อย่างปลอดภัย

## เช็คว่าติดตั้งสำเร็จ

| เช็ค | ควรเห็น |
|---|---|
| มุมขวาล่างของจอ | Angeling ลอยอยู่ |
| แถบเมนูด้านบน | ไอคอนหน้า Angeling |
| กด ⌥⌘R | หน้าต่าง "ตั้งเตือนกับ Angeling" |

แล้วไปลองใช้งานจริงที่ **[เริ่มใช้งานครั้งแรก →](First-Run.md)**

## ติดตั้งไม่ผ่าน?

| ข้อความ error | วิธีแก้ |
|---|---|
| `Angeling needs macOS 13 or later.` | อัปเดต macOS |
| `curl: (22) … 404` | ยังไม่มี Release หรือเน็ตมีปัญหา ลองใหม่อีกครั้ง |
| `Could not download the Angeling sprite sheet` | เน็ตมีปัญหา ลองใหม่อีกครั้ง |
| `swiftc not found` (วิธีที่ 2) | `xcode-select --install` หรือใช้วิธีที่ 1 แทน |
| `jq not found, so the session hook was skipped` | macOS 13–14: `brew install jq` แล้วรันตัวติดตั้งซ้ำ |
| `"Angeling" can't be opened` / `Apple could not verify` | ดู [แก้ปัญหา](Troubleshooting.md#เปิดแอปไม่ได้-apple-could-not-verify) |

ปัญหาอื่นดูที่ [แก้ปัญหา](Troubleshooting.md)

---
[← สารบัญคู่มือ](README.md)
