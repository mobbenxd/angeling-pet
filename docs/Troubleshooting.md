# แก้ปัญหา

> ไม่เจอปัญหาของคุณ? [เปิด issue](https://github.com/mobbenxd/angeling-pet/issues) พร้อมแนบผลของ `sw_vers -productVersion` และสิ่งที่เห็น

## Angeling ไม่ขึ้น

1. เช็คว่าแอปรันอยู่ไหม: `pgrep -x Angeling` ถ้าไม่มีเลข ให้เปิดด้วย `open ~/Applications/Angeling.app`
2. ถูกซ่อนอยู่หรือเปล่า: กด **⌥⌘A** หรือคลิกไอคอนในแถบเมนู → "แสดง Angeling"
3. ตกขอบจอ (เช่น เคยวางไว้บนจอที่ถอดไปแล้ว): รีเซ็ตตำแหน่ง
   ```bash
   defaults delete local.angeling.pet x; defaults delete local.angeling.pet y
   pkill -x Angeling; open ~/Applications/Angeling.app
   ```
4. เปิดแล้วปิดทันที: รันตรงๆ เพื่อดู error
   ```bash
   ~/Applications/Angeling.app/Contents/MacOS/Angeling
   ```
   ถ้าขึ้น `Cannot load spritesheet.webp` ให้[รันคำสั่งติดตั้งซ้ำ](Installation.md)

## เปิดแอปไม่ได้ (Apple could not verify)

Angeling ไม่ได้เซ็นด้วยใบรับรองของ Apple ถ้าดาวน์โหลด zip ผ่าน browser แล้วเปิดเอง macOS จะบล็อก

- **ทางที่ง่ายที่สุด:** ติดตั้งด้วย[คำสั่งเดียว](Installation.md) ซึ่งไม่โดนบล็อก
- หรือเปิด System Settings → Privacy & Security เลื่อนลงไปจะเจอ "Angeling was blocked…" แล้วกด **Open Anyway**

## ไม่เปิดเองตอน login
```bash
launchctl print gui/$(id -u)/local.angeling.pet | head -3
```
ถ้าหาไม่เจอ ให้[รันคำสั่งติดตั้งซ้ำ](Installation.md) (อย่าใส่ `--no-login`) และเช็คว่า System Settings → General → Login Items ไม่ได้ปิด `local.angeling.pet` ไว้

## บับเบิลไม่มีงานขึ้นเลย

0. ต้องมี Claude Code ก่อนติดตั้ง Angeling ถ้าติดตั้ง Claude ทีหลัง ให้[รันคำสั่งติดตั้งซ้ำ](Installation.md)
1. เช็คว่ามี hook ครบ: `grep -c angeling-pet/hook.sh ~/.claude/settings.json` ต้องได้ `11`
2. เช็คว่า hook เขียนไฟล์ได้: สั่งงาน Claude แล้วดู `ls -lt ~/.claude/angeling-pet/state/` ต้องมีไฟล์ที่เพิ่งอัปเดต
3. เช็คว่ามี `jq`: `jq --version` (hook หาที่ `/opt/homebrew/bin/jq` ก่อน แล้วค่อยหาใน PATH)
4. บับเบิลถูกซ่อนอยู่หรือเปล่า: ชี้ที่ Angeling แล้วกดปุ่มทางซ้าย หรือเมนู → "แสดงกิจกรรม"

## งานค้างเป็น "กำลังทำ" ทั้งที่เสร็จแล้ว

ปกติจะเปลี่ยนเป็น "พร้อม" เองหลังเงียบ 10 นาที ถ้าอยากล้างทันที ให้คลิกขวาที่แถว → "ซ่อนแถวนี้" หรือลบไฟล์ของ session นั้น:
```bash
ls -lt ~/.claude/angeling-pet/state/
rm ~/.claude/angeling-pet/state/<session-id>.json
```

## มีแถว "เสร็จแล้ว" เต็มไปหมด
เมนู → "ล้าง session ที่เสร็จแล้ว" หรือคลิกแต่ละแถว (เปิดแล้วแถวจะหายไป)

## คลิกแล้วไม่ไปที่ session

| ใช้กับ | วิธีแก้ |
|---|---|
| Terminal / iTerm2 | System Settings → Privacy & Security → **Automation** → เปิดให้ Angeling ควบคุม Terminal หรือ iTerm |
| kitty | ไปถูกแอปแต่ผิดหน้าต่าง: ยังไม่ได้เปิด remote control ดู [Usage](Usage.md) แล้วปิดและเปิด kitty ใหม่ |
| herdr | ต้องเป็นเวอร์ชันที่มีคำสั่ง `herdr agent focus` ส่วน session ใน `herdr --remote` ยังกระโดดไปไม่ได้ |
| แอป Claude desktop | ต้องเป็นแอปเวอร์ชันที่รองรับ Code tab ถ้ายังไม่ไป Angeling จะแค่เรียกแอป Claude ขึ้นมา |
| session ที่เริ่มก่อนติดตั้ง | ยังไม่รู้ว่าอยู่หน้าต่างไหน จะรู้หลังจาก session นั้นมีความเคลื่อนไหวครั้งถัดไป |

## ไม่มี emote
[รันคำสั่งติดตั้งซ้ำ](Installation.md)เพื่อดาวน์โหลดใหม่ (ดู [Emote และท่าทาง](Emotes-and-Animations.md))

## LINE ไม่แสดง
ดูตารางแก้ปัญหาในหน้า [แจ้งเตือน LINE](LINE-Notifications.md#แก้ปัญหา)

## ทำ settings.json เสียหาย?
ตัวติดตั้งสำรองไฟล์ไว้ให้เสมอ:
```bash
cp ~/.claude/settings.json.angeling-backup ~/.claude/settings.json
```

## เริ่มใหม่หมด
```bash
~/.claude/angeling-pet/uninstall.sh --purge
curl -fsSL https://raw.githubusercontent.com/mobbenxd/angeling-pet/main/get.sh | bash
```

---
[← สารบัญคู่มือ](README.md)
