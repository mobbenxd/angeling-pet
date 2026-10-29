# อัปเดตและถอนการติดตั้ง

## อัปเดตเป็นเวอร์ชันล่าสุด

รันคำสั่งเดิมที่ใช้ติดตั้งอีกครั้ง:

```bash
curl -fsSL https://raw.githubusercontent.com/mobbenxd/angeling-pet/main/get.sh | bash
```

ถ้าติดตั้งแบบ build จากซอร์ส ให้ใช้:

```bash
cd ~/apps/angeling-pet && git pull && ./install.sh
```

ตัวติดตั้งรันซ้ำได้อย่างปลอดภัย: ไม่เพิ่ม hook ซ้ำ และเก็บตำแหน่ง การตั้งค่า กับการเตือนที่ตั้งไว้ไว้ครบ

ดูว่าตอนนี้ใช้เวอร์ชันไหน: `defaults read ~/Applications/Angeling.app/Contents/Info CFBundleShortVersionString`

> หลังอัปเดต ต้องให้สิทธิ์ **Full Disk Access** สำหรับ[แจ้งเตือน LINE](LINE-Notifications.md)ใหม่ และ macOS อาจถามสิทธิ์ปฏิทินสำหรับ[การเตือน](Reminders.md)ซ้ำ เพราะแอปเวอร์ชันใหม่ถือเป็นแอปใหม่

## ถอนการติดตั้ง

```bash
~/.claude/angeling-pet/uninstall.sh
```

| ลบ | เก็บไว้ |
|---|---|
| `~/Applications/Angeling.app` | `~/.claude/angeling-pet/` (ภาพ, การเตือน, state) |
| LaunchAgent (เปิดเองตอน login) | การตั้งค่า (ตำแหน่ง, ตัวเลือกที่ซ่อนไว้) |
| hook ของ Angeling ใน `~/.claude/settings.json` (hook อื่นไม่ถูกแตะ) | event ที่เพิ่มลงปฏิทินไว้แล้ว |

ถ้าจะลบทุกอย่าง รวมถึงไฟล์ การเตือน และการตั้งค่า:

```bash
~/.claude/angeling-pet/uninstall.sh --purge
```

ถ้าเคยให้ Full Disk Access หรือสิทธิ์ปฏิทิน ให้ลบ Angeling ออกจากรายการใน System Settings → Privacy & Security ด้วย

---
[← สารบัญคู่มือ](README.md)
