#!/usr/bin/env python3
"""Import the Bomber character pack into assets/characters/.

    python3 -I scripts/import-characters.py ~/Downloads/bomber-all-18-characters.zip

Writes the sheets each character uses plus characters.json, the frame table Angeling reads:
    [{"id", "name", "rows": [[[file, x, y, w, h] x4] x6], "flip": [row, ...]}]
Rows are walk down, walk left, walk right, walk up, place, hurt. Rows listed in "flip" are
drawn mirrored. Frame rects follow the pack's frame-reference/skins.ts and atlas.json.
Like the rest of the artwork this is not committed; it ships as the characters.zip release asset.
"""
import json
import os
import shutil
import sys
import tempfile
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "characters")

if len(sys.argv) != 2:
    sys.exit(__doc__)
src = sys.argv[1]
tmp = None
if zipfile.is_zipfile(src):
    tmp = tempfile.mkdtemp()
    zipfile.ZipFile(src).extractall(tmp)
    src = tmp

sheets = {}  # file name -> path in the pack
for dirpath, _, files in os.walk(src):
    for f in files:
        if f.endswith(".png"):
            sheets[f] = os.path.join(dirpath, f)
atlas = json.load(open(os.path.join(src, "frame-reference", "atlas.json")))


def rects(file, rs):
    return [[file, *r] for r in rs]


def grid(xs, y, w, h):
    return [[x, y, w, h] for x in xs]


chars = []


def add(name, down, left, right, up, place, hurt, flip=()):
    chars.append({"id": name.lower().replace(" ", "-"), "name": name,
                  "rows": [down, left, right, up, place, hurt], "flip": list(flip)})


# Thunder, Horse, Husky and Cat have hand-measured rects in skins.ts.
tw = "thunder-walker-v1.png"
ta = [[i * 543 + 45, 140, 455, 480] for i in range(4)]
add("Thunder", *(rects(tw, grid([30, 335, 635, 945], y, 300, 280)) for y in (55, 345, 630, 919)),
    rects("thunder-place-empty-v1.png", ta), rects("thunder-hurt-blink-v1.png", ta))

hw = "horse-walker-v1.png"
add("Bomber Horse",
    rects(hw, [[40, 26, 280, 280], [340, 29, 280, 280], [640, 28, 280, 280], [940, 28, 280, 280]]),
    rects(hw, [[40, 319, 280, 280], [340, 319, 280, 280], [640, 322, 280, 280], [940, 322, 280, 280]]),
    rects(hw, [[40, 614, 280, 280], [340, 614, 280, 280], [640, 612, 280, 280], [940, 615, 280, 280]]),
    rects(hw, grid([40, 340, 640, 940], 916, 280, 280)),
    rects("horse-place-v1.png", [[78, 141, 480, 500], [585, 141, 480, 500], [1116, 149, 480, 500], [1616, 141, 480, 500]]),
    rects("horse-hurt-v1.png", [[43, 96, 480, 500], [586, 96, 480, 500], [1117, 102, 480, 500], [1660, 103, 480, 500]]))

hk = "husky-actions-v1.png"
cols = [230, 430, 630, 830]
add("Bomber Husky",
    rects(hk, grid(cols, 15, 200, 200)),
    rects(hk, [[230, 210, 200, 185], [430, 210, 200, 185], [630, 395, 200, 185], [430, 210, 200, 185]]),
    rects(hk, [[630, 210, 200, 185], [830, 210, 200, 185], [230, 395, 200, 185], [430, 395, 200, 185]]),
    rects(hk, grid(cols, 580, 200, 200)),
    rects(hk, grid(cols, 785, 200, 200)),
    rects(hk, grid(cols, 995, 200, 210)))

ct = "cat-actions-v1.png"
cols = [45, 315, 580, 845]
add("Bomber Cat", *(rects(ct, grid(cols, y, 260, 220)) for y in (0, 220, 445, 667)),
    rects(ct, grid(cols, 897, 260, 205)), rects(ct, grid(cols, 1114, 260, 250)))


def row(file, i):
    return rects(file, atlas[file][i])


# The rest come from the atlas.
for name, prefix in [("Cool Pomeranian", "pom"), ("Pumpkin Raccoon", "raccoon"), ("Chubby Valkyrie", "valkyrie"),
                     ("Chubby Drake", "drake"), ("Chubby Mage", "mage"), ("Chubby Beerus", "beerus"),
                     ("Chubby Legend", "legend"), ("Carrot Engineer", "rabbit-engineer"), ("Sun Sage", "sun-sage")]:
    combined = prefix in ("mage", "rabbit-engineer", "sun-sage")
    actions = f"{prefix}-actions-{'v3' if prefix == 'rabbit-engineer' else 'v1'}.png"
    walker = actions if combined else f"{prefix}-walker-v1.png"
    left = row(walker, 1)
    if prefix == "beerus":
        left[3] = left[1]  # the last Beerus left pose faces right in the source
    add(name, row(walker, 0), left, row(walker, 2), row(walker, 3),
        row(actions, 4 if combined else 0), row(actions, 5 if combined else 1))

for name, file in [("Noid", "noid-actions-v1.png"), ("Chick Squad", "chick-squad-actions-v1.png"),
                   ("Chubby Cloudy", "cloudy-actions-v1.png"), ("Tommy Shelby", "shelby-actions-v1.png"),
                   ("Charles Leclerc", "leclerc-actions-v1.png")]:
    chick = name == "Chick Squad"
    hurt = row(file, 5)
    if name == "Chubby Cloudy":
        hurt = [hurt[0], hurt[1], hurt[3], hurt[2]]
    add(name, row(file, 0), row(file, 1), row(file, 1 if chick else 2), row(file, 3), row(file, 4), hurt,
        flip=[2] if chick else [])

shutil.rmtree(OUT, ignore_errors=True)
os.makedirs(OUT)
used = sorted({r[0] for c in chars for rs in c["rows"] for r in rs})
for f in used:
    shutil.copy(sheets[f], os.path.join(OUT, f))
with open(os.path.join(OUT, "characters.json"), "w") as fh:
    json.dump(chars, fh, separators=(",", ":"))
if tmp:
    shutil.rmtree(tmp)
print(f"{len(chars)} characters, {len(used)} sheets -> {OUT}")
