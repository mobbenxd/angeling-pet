# อัปเดตและถอนการติดตั้ง

## อัปเดตเป็นเวอร์ชันล่าสุด

```bash
cd ~/apps/angeling-pet     # โฟลเดอร์ที่ clone ไว้
git pull
./install.sh
```

ตัวติดตั้งรันซ้ำได้อย่างปลอดภัย: ไม่เพิ่ม hook ซ้ำ ไม่ดาวน์โหลดภาพที่มีอยู่แล้ว และเก็บตำแหน่งกับการตั้งค่าเดิมไว้

> ถ้าเคยให้ **Full Disk Access** สำหรับ [แจ้งเตือน LINE](LINE-Notifications.md) ต้องให้ใหม่หลังอัปเดต

## ถอนการติดตั้ง

```bash
cd ~/apps/angeling-pet
./uninstall.sh
```

| ลบ | เก็บไว้ |
|---|---|
| `~/Applications/Angeling.app` | `~/.claude/angeling-pet/` (hook, ภาพ, state) |
| LaunchAgent (เปิดเองตอน login) | การตั้งค่า (ตำแหน่ง, ตัวเลือกที่ซ่อนไว้) |
| hook ของ Angeling ใน `~/.claude/settings.json` (hook อื่นไม่ถูกแตะ) | |

ถ้าจะลบทุกอย่างรวมถึงไฟล์และการตั้งค่า:

```bash
./uninstall.sh --purge
```

หลังจากนั้นลบโฟลเดอร์ที่ clone ไว้ได้เลย และถ้าเคยให้ Full Disk Access ให้ลบ Angeling ออกจากรายการใน System Settings ด้วย

---
[← สารบัญคู่มือ](README.md)
