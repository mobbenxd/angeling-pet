# เปลี่ยนเป็นเพ็ตตัวอื่น

## เลือกตัวละคร Bomber

คลิกขวาที่ Angeling หรือไอคอนแถบเมนู แล้วเลือก **ตัวละคร ▸** มี Angeling และตัวละครจากเกม Bomber 18 ตัว:
Thunder, Bomber Horse, Bomber Husky, Bomber Cat, Cool Pomeranian, Pumpkin Raccoon, Chubby Valkyrie, Chubby Drake, Chubby Mage, Chubby Beerus, Chubby Legend, Carrot Engineer, Sun Sage, Noid, Chick Squad, Chubby Cloudy, Tommy Shelby, Charles Leclerc

ตัวละครเปลี่ยนทันทีและจำไว้หลังเปิดแอปใหม่ ท่าทางของตัวละคร Bomber:

| สถานะ | ท่า |
|---|---|
| ว่าง / กำลังทำงาน | เดินหันหน้าเข้าหาเรา |
| รอคำตอบ / โบกมือ / กระโดด | ท่าวางระเบิด |
| ผิดพลาด | ท่าโดนระเบิด กะพริบ |
| ลากไปมา | เดินซ้ายหรือขวา |

ถ้าไม่เห็นเมนูนี้ แปลว่ายังไม่มีไฟล์ตัวละคร ให้[อัปเดต](Updating-and-Uninstalling.md)เป็นเวอร์ชันล่าสุด

Angeling ใช้ sprite sheet แบบเดียวกับเพ็ตของ Codex (รูปแบบ v2) จึงใช้เพ็ต Codex ตัวไหนก็ได้

## ใช้เพ็ตตัวอื่นจาก Codex

```bash
ls ~/.codex/pets/                  # ดูชื่อเพ็ตที่มี
cd ~/apps/angeling-pet
rm assets/spritesheet.webp
ANGELING_CODEX_PET=<ชื่อเพ็ต> ./install.sh   # ต้องใช้วิธี build จากซอร์ส (git clone)
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

---
[← สารบัญคู่มือ](README.md)
