# เปลี่ยนเป็นเพ็ตตัวอื่น

Angeling ใช้ sprite sheet แบบเดียวกับเพ็ตของ Codex (รูปแบบ v2) จึงใช้เพ็ต Codex ตัวไหนก็ได้

## ใช้เพ็ตตัวอื่นจาก Codex

```bash
ls ~/.codex/pets/                  # ดูชื่อเพ็ตที่มี
cd ~/apps/angeling-pet
rm assets/spritesheet.webp
ANGELING_CODEX_PET=<ชื่อเพ็ต> ./install.sh
```

## ใช้ไฟล์ของคุณเอง

วางไฟล์ไว้ที่ `assets/spritesheet.webp` (หรือ PNG ที่เปลี่ยนชื่อเป็นนามสกุลนี้) แล้วรัน `./install.sh`

| สเปก | ค่า |
|---|---|
| ขนาดภาพ | 1536 × 2288 px |
| ตาราง | 8 คอลัมน์ × 11 แถว |
| ขนาดช่อง | 192 × 208 px |

| แถว | ท่า |
|---|---|
| 0 | idle |
| 1 | running-right |
| 2 | running-left |
| 3 | waving |
| 4 | jumping |
| 5 | failed |
| 6 | waiting |
| 7 | running |
| 8 | review |
| 9–10 | มองไปรอบๆ |

ชื่อแอปและไอคอนในแถบเมนูยังเป็น Angeling แต่ภาพตัวละครจะเปลี่ยนตามไฟล์ใหม่
