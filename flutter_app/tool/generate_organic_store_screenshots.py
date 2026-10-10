"""Create LOOPET store cards inspired by the supplied mint app-screens layout.

The phones use the Flutter-rendered Korean screens from
``tool/generate_store_screenshots.dart``. Run from ``flutter_app`` with:

    python3 tool/generate_organic_store_screenshots.py

Outputs are kept separate from the existing marketing sets.
"""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/store/screenshots/marketing/play/ko"
DEST = ROOT / "assets/store/screenshots/marketing/organic"
FONT = "/System/Library/Fonts/AppleSDGothicNeo.ttc"

MINT = "#D1F4EB"
GREEN = "#185E57"
DEEP_GREEN = "#087969"
PALE = "#E8FBF5"
PURPLE = "#6842E8"

CARDS = [
    ("01_intro", "하루를 한눈에", "24시간을 원 하나로", None),
    ("02_home", "지금 할 루틴", "현재와 다음 루틴을 한눈에", "01_home"),
    ("03_progress", "작은 완료가 쌓여요", "오늘의 진행 상황", "02_progress"),
    ("04_widget", "앱을 열지 않아도", "홈 화면 위젯으로 확인", "03_widget"),
    ("05_routines", "하루를 색으로 채워요", "나만의 루틴 목록", "04_routines"),
    ("06_add", "내 루틴을 쉽게", "시간과 요일을 간단하게", "05_add"),
    ("07_calendar", "한 달의 리듬을", "달력으로 돌아보기", "06_calendar"),
    ("08_start", "계정 없이 바로 시작", "인터넷 없이 내 기기에 저장", None),
]


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT, size, index=14 if bold else 0)


def leaf_spray(canvas: Image.Image, base: tuple[int, int], size: float, angle: float, color: str) -> None:
    """Draw a restrained botanical branch like the reference card decoration."""
    draw = ImageDraw.Draw(canvas)
    bx, by = base
    ux, uy = math.cos(angle), math.sin(angle)
    nx, ny = -uy, ux
    length = 290 * size
    tip = (bx + ux * length, by + uy * length)
    draw.line((base, tip), fill=color, width=max(3, round(8 * size)), joint="curve")
    for i in range(1, 7):
        t = i / 7
        px, py = bx + ux * length * t, by + uy * length * t
        for side in (-1, 1):
            reach = (70 - 18 * t) * size
            qx = px + nx * side * reach + ux * reach * 0.45
            qy = py + ny * side * reach + uy * reach * 0.45
            width = 20 * size
            polygon = [
                (px, py),
                (px + nx * side * width + ux * 11 * size, py + ny * side * width + uy * 11 * size),
                (qx, qy),
                (px - nx * side * width + ux * 11 * size, py - ny * side * width + uy * 11 * size),
            ]
            draw.polygon(polygon, fill=color)


def flower(canvas: Image.Image, center: tuple[int, int], radius: int, color: str) -> None:
    draw = ImageDraw.Draw(canvas)
    x, y = center
    for i in range(8):
        a = 2 * math.pi * i / 8
        cx, cy = x + math.cos(a) * radius * 0.72, y + math.sin(a) * radius * 0.72
        r = radius * 0.37
        draw.ellipse((cx-r, cy-r, cx+r, cy+r), fill=color)
    draw.ellipse((x-radius*.27, y-radius*.27, x+radius*.27, y+radius*.27), fill=MINT)


def base(height: int, index: int) -> Image.Image:
    canvas = Image.new("RGBA", (1080, height), MINT)
    draw = ImageDraw.Draw(canvas)
    draw.ellipse((735, 465, 1190, 920), fill="#DCF8F0")
    draw.ellipse((-255, height-460, 315, height+110), fill="#BCEBDE")
    if index % 2:
        leaf_spray(canvas, (36, height-25), .75, -1.09, DEEP_GREEN)
        flower(canvas, (988, 800), 33, GREEN)
    else:
        leaf_spray(canvas, (1052, height-28), .72, -2.05, DEEP_GREEN)
        flower(canvas, (81, 823), 28, GREEN)
    return canvas


def header(canvas: Image.Image, title: str, caption: str, index: int) -> None:
    draw = ImageDraw.Draw(canvas)
    draw.text((540, 118), title, font=font(83, bold=True), fill=GREEN, anchor="mt")
    draw.text((540, 245), caption, font=font(42, bold=True), fill=GREEN, anchor="mt")
    draw.rounded_rectangle((475, 325, 605, 333), radius=4, fill=DEEP_GREEN)
    draw.text((540, 368), f"LOOPET  ·  {index:02d} / 08", font=font(26, bold=True), fill=GREEN, anchor="mt")


def shadow(canvas: Image.Image, box: tuple[int, int, int, int], radius: int) -> None:
    layer = Image.new("RGBA", canvas.size)
    ImageDraw.Draw(layer).rounded_rectangle(box, radius, fill=(21, 80, 72, 51))
    canvas.alpha_composite(layer.filter(ImageFilter.GaussianBlur(32)))


def screen_image(name: str) -> Image.Image:
    source = Image.open(SOURCE / f"{name}.png").convert("RGBA")
    # Crop the app pixels within the phone of the existing Flutter capture.
    return source.crop((189, 264, 892, 1792))


def cat_image(max_size: tuple[int, int]) -> Image.Image:
    cat = Image.open(ROOT / "assets/characters/cat_starlight/v1/approved/guide.png").convert("RGBA")
    bounds = cat.getchannel("A").getbbox()
    if bounds:
        cat = cat.crop(bounds)
    scale = min(max_size[0] / cat.width, max_size[1] / cat.height)
    return cat.resize((round(cat.width * scale), round(cat.height * scale)), Image.Resampling.NEAREST)


def phone(canvas: Image.Image, name: str, index: int, height: int) -> None:
    width = 738 if height == 1920 else 770
    screen_width = width - 44
    screen_height = round(screen_width * 1528 / 703)
    phone_height = screen_height + 44
    stage = Image.new("RGBA", (width + 120, phone_height + 130))
    px, py = 60, 25
    stage_draw = ImageDraw.Draw(stage)
    stage_draw.rounded_rectangle((px+5, py+15, px+width+5, py+phone_height+15), 100, fill=(26, 80, 70, 28))
    stage_draw.rounded_rectangle((px, py, px+width, py+phone_height), 94, fill="#F8FFFC", outline="#B9DDD3", width=5)
    inner = screen_image(name).resize((screen_width, screen_height), Image.Resampling.LANCZOS)
    mask = Image.new("L", inner.size)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, inner.width-1, inner.height-1), 73, fill=255)
    stage.paste(inner, (px+22, py+22), mask)
    stage_draw.rounded_rectangle((px, py, px+width, py+phone_height), 94, outline="#A6CDC2", width=4)
    angle = 8 if index == 2 else (-7 if index == 3 else 0)
    if angle:
        stage = stage.rotate(angle, resample=Image.Resampling.BICUBIC, expand=True)
    x = (1080 - stage.width) // 2
    y = 478 if height == 1920 else 585
    if index == 2:
        x += 45
    if index == 3:
        x -= 42
    glow = Image.new("RGBA", canvas.size)
    glow.alpha_composite(stage, (x+8, y+20))
    canvas.alpha_composite(glow.filter(ImageFilter.GaussianBlur(25)), (0, 0))
    canvas.alpha_composite(stage, (x, y))


def intro(canvas: Image.Image, height: int) -> None:
    draw = ImageDraw.Draw(canvas)
    cy = 1090 if height == 1920 else 1250
    draw.ellipse((145, cy-390, 935, cy+400), fill="#BCEBE0")
    draw.ellipse((197, cy-340, 883, cy+347), fill=PALE)
    draw.ellipse((245, cy-294, 835, cy+296), outline=GREEN, width=14)
    draw.arc((259, cy-280, 821, cy+282), 220, 316, fill=PURPLE, width=30)
    cat = cat_image((570, 570))
    canvas.alpha_composite(cat, ((1080-cat.width)//2, cy-cat.height//2+20))
    flower(canvas, (903, cy-300), 54, DEEP_GREEN)
    leaf_spray(canvas, (121, cy+330), .75, -1.1, GREEN)
    draw.rounded_rectangle((314, cy+455, 766, cy+543), radius=44, fill="#FFFFFF")
    draw.text((540, cy+499), "오늘의 리듬, LOOPET", font=font(35, bold=True), fill=GREEN, anchor="mm")


def finish(canvas: Image.Image, height: int) -> None:
    draw = ImageDraw.Draw(canvas)
    cy = 1150 if height == 1920 else 1330
    shadow(canvas, (190, cy-465, 890, cy+430), 85)
    draw.rounded_rectangle((190, cy-465, 890, cy+430), radius=85, fill="#F7FFFC", outline="#A8DBCE", width=4)
    draw.ellipse((291, cy-364, 789, cy+134), fill="#DFF7EC")
    cat = cat_image((455, 455))
    canvas.alpha_composite(cat, ((1080-cat.width)//2, cy-cat.height//2-115))
    draw.rounded_rectangle((300, cy+215, 780, cy+315), radius=50, fill=PURPLE)
    draw.text((540, cy+264), "오늘부터 함께해요", font=font(38, bold=True), fill="white", anchor="mm")
    flower(canvas, (915, cy-380), 41, DEEP_GREEN)


def build(height: int, folder: str) -> list[Image.Image]:
    output = DEST / folder / "ko"
    output.mkdir(parents=True, exist_ok=True)
    images: list[Image.Image] = []
    for index, (filename, title, caption, source_name) in enumerate(CARDS, 1):
        canvas = base(height, index)
        header(canvas, title, caption, index)
        if index == 1:
            intro(canvas, height)
        elif index == 8:
            finish(canvas, height)
        else:
            phone(canvas, source_name, index, height)
        if folder == "ios":
            canvas = canvas.resize((1290, 2796), Image.Resampling.LANCZOS)
        result = canvas.convert("RGB")
        result.save(output / f"{filename}.png", optimize=True)
        images.append(result)
        print(output / f"{filename}.png")
    return images


def main() -> None:
    play = build(1920, "play")
    build(2340, "ios")
    thumb_w, thumb_h, gap = 270, 480, 18
    preview = Image.new("RGB", (8 * thumb_w + 9 * gap, thumb_h + 2 * gap), "#F5F6F2")
    for i, frame in enumerate(play):
        preview.paste(frame.resize((thumb_w, thumb_h), Image.Resampling.LANCZOS), (gap + i * (thumb_w + gap), gap))
    preview.save(DEST / "preview_ko.png", optimize=True)
    print(DEST / "preview_ko.png")


if __name__ == "__main__":
    main()
