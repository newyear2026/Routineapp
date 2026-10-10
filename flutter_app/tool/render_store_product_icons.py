"""Play Console 일회성 제품 아이콘(512×512 PNG)을 앱의 승인 그림으로 만든다.

배경은 각 팩의 `PackSkin` 배경 그라데이션과 마스코트 후광 색을 쓴다.
python3 tool/render_store_product_icons.py → design/store-product-icons/
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'design' / 'store-product-icons'
SIZE = 512

# 제품 ID, 캐릭터 폴더, 배경 그라데이션(위→아래), 후광 색 — pack_skin_catalog.dart와 같다.
PACKS = [
    ('loopet.pack.rabbit_postman', 'rabbit_postman', '#FFD1C2', '#FFEFC9', '#FFF6E6'),
    ('loopet.pack.squirrel_explorer', 'squirrel_explorer', '#F5E9D4', '#D8E8C9', '#FFF2C8'),
    ('loopet.pack.sheep_mooncloud', 'sheep_mooncloud', '#DCE9FF', '#E9DDFF', '#FFF0C2'),
    ('loopet.pack.redpanda_teashop', 'redpanda_teashop', '#F9EBD7', '#D9ECE8', '#FFF0CF'),
    ('loopet.pack.otter_seaside', 'otter_seaside', '#FFF1D7', '#D7F5F2', '#FFF0D8'),
]
POODLE = 'poodle_garden'
BUNDLE_BG = ('#FFF4DC', '#E6D8FF', '#FFF8EC')


def rgb(hex_color):
    h = hex_color.lstrip('#')
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def backdrop(top, bottom, halo, halo_radius=200, halo_center=(256, 270)):
    a, b = rgb(top), rgb(bottom)
    img = Image.new('RGB', (SIZE, SIZE))
    px = img.load()
    for y in range(SIZE):
        for x in range(SIZE):
            t = (x * 0.35 + y * 0.65) / SIZE
            px[x, y] = tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))
    glow = Image.new('L', (SIZE, SIZE), 0)
    cx, cy = halo_center
    ImageDraw.Draw(glow).ellipse(
        (cx - halo_radius, cy - halo_radius, cx + halo_radius, cy + halo_radius),
        fill=210)
    glow = glow.filter(ImageFilter.GaussianBlur(40))
    img.paste(Image.new('RGB', (SIZE, SIZE), rgb(halo)), (0, 0), glow)
    return img.convert('RGBA')


def character(folder, box):
    art = Image.open(
        ROOT / 'assets' / 'characters' / folder / 'v1' / 'approved' / 'idle.png'
    ).convert('RGBA')
    art = art.crop(art.getchannel('A').getbbox())
    scale = box / max(art.size)
    return art.resize(
        (round(art.width * scale), round(art.height * scale)), Image.LANCZOS)


def shadow(img, width, cx, bottom):
    layer = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    h = max(10, width // 7)
    ImageDraw.Draw(layer).ellipse(
        (cx - width // 2, bottom - h // 2, cx + width // 2, bottom + h // 2),
        fill=(60, 40, 30, 46))
    img.alpha_composite(layer.filter(ImageFilter.GaussianBlur(8)))


def place(img, art, cx, bottom):
    shadow(img, int(art.width * 0.7), cx, bottom - 4)
    img.alpha_composite(art, (cx - art.width // 2, bottom - art.height))


def pack_icon(product_id, folder, top, bottom, halo):
    img = backdrop(top, bottom, halo)
    place(img, character(folder, 392), SIZE // 2, 462)
    return product_id, img


def bundle_icon():
    img = backdrop(*BUNDLE_BG, halo_radius=230, halo_center=(256, 256))
    back = [('sheep_mooncloud', 178), ('rabbit_postman', 178), ('otter_seaside', 178)]
    front = [('squirrel_explorer', 188), ('redpanda_teashop', 188), (POODLE, 188)]
    for (folder, box), cx in zip(back, (104, 256, 408)):
        place(img, character(folder, box), cx, 252)
    for (folder, box), cx in zip(front, (104, 256, 408)):
        place(img, character(folder, box), cx, 494)
    return 'loopet.supporter.bundle', img


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    icons = [pack_icon(*p) for p in PACKS] + [bundle_icon()]
    for product_id, img in icons:
        path = OUT / f'{product_id}.png'
        img.save(path, optimize=True)
        print(path.relative_to(ROOT), f'{path.stat().st_size // 1024}KB')


if __name__ == '__main__':
    main()
