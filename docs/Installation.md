# การติดตั้ง

## วิธีที่ 1: คำสั่งเดียว (แนะนำ สำหรับทุกคน)

ใช้เวลาประมาณ 1 นาที ไม่ต้องลงโปรแกรมอื่นเพิ่ม ไม่ต้องใส่รหัสผ่าน

### ขั้นที่ 1: เช็คเวอร์ชัน macOS

คลิกเมนู  มุมซ้ายบน → **About This Mac** ต้องเป็น **macOS 13 (Ventura) ขึ้นไป** เช่น 13 Ventura, 14 Sonoma, 15 Sequoia หรือ 26 Tahoe

### ขั้นที่ 2: เปิดแอป Terminal

กด **⌘ + Space** พิมพ์ `Terminal` แล้วกด **Enter** จะได้หน้าต่างสีขาวหรือดำที่มีเคอร์เซอร์กะพริบ

### ขั้นที่ 3: วางคำสั่งแล้วกด Enter

ก็อปคำสั่งนี้ทั้งบรรทัด:

```bash
curl -fsSL https://raw.githubusercontent.com/mobbenxd/angeling-pet/main/get.sh | bash
```

กลับไปที่ Terminal กด **⌘ + V** เพื่อวาง แล้วกด **Enter**

### ขั้นที่ 4: รอจนขึ้น `Done!`

ใช้เวลาประมาณ 10 วินาที หน้าจอจะขึ้นแบบนี้:

```
==> Downloading Angeling
######################################################################## 100.0%
==> Artwork
==> App (/Users/<you>/Applications/Angeling.app)
    installed the prebuilt app
==> Files (/Users/<you>/.claude/angeling-pet)
==> Claude Code
    not installed, so …        ← ถ้าไม่มี Claude Code (ไม่เป็นไร)
==> Start at login (…/local.angeling.pet.plist)
==> Launch

Done! Angeling is in the bottom-right corner of your screen.
```

**Angeling จะโผล่ที่มุมขวาล่างของจอ** และมีไอคอนหน้า Angeling ในแถบเมนูด้านบน ปิด Terminal ได้เลย

### ขั้นที่ 5: ลองตั้งเตือนครั้งแรก

1. กด **⌥ + ⌘ + R** (Option + Command + R)
2. พิมพ์ว่าจะทำอะไร เลือกวันและเวลา แล้วกด **ตั้งเตือน**
3. macOS จะถามขอสิทธิ์เข้าถึงปฏิทิน (ข้อความประมาณ *"Angeling" would like full access to your Calendar*) ให้กด **Allow Full Access** เพื่อให้บันทึกลงปฏิทินได้
4. พอถึงเวลา Angeling จะส่งเสียง Level Up ของ Ragnarok และขึ้นแถวสีส้ม คลิกแถวเพื่อรับทราบ

**เสร็จแล้ว** 🎉 ตั้งแต่นี้ Angeling จะเปิดเองทุกครั้งที่เปิดเครื่อง

### ขั้นเพิ่มเติม (ทำเฉพาะที่ต้องการ)

| อยากได้ | ทำอะไร |
|---|---|
| เห็นข้อความ LINE ล่าสุด | ให้สิทธิ์ Full Disk Access ตาม[แจ้งเตือน LINE](LINE-Notifications.md) (ถ้าไม่ให้ จะเห็นแค่จำนวนที่ยังไม่อ่าน) |
| ให้รายงานงานของ Claude Code | ติดตั้ง Claude Code แล้วทำขั้นที่ 3 ซ้ำ |
| ไม่ให้เปิดเองตอนเปิดเครื่อง | ใช้คำสั่ง `curl -fsSL https://raw.githubusercontent.com/mobbenxd/angeling-pet/main/get.sh \| bash -s -- --no-login` แทนในขั้นที่ 3 |
| ซ่อน Angeling ชั่วคราว | กด **⌥ + ⌘ + A** |

อัปเดตเป็นเวอร์ชันใหม่: ทำขั้นที่ 2–3 ซ้ำ ส่วนการถอนการติดตั้ง ดูที่[อัปเดตและถอนการติดตั้ง](Updating-and-Uninstalling.md)

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
