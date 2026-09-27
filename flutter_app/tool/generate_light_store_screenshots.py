"""Compose a light Korean store screenshot set from the captured app screens.

Run from flutter_app: python3 tool/generate_light_store_screenshots.py
The source screens come from generate_store_screenshots.dart. This script only
changes the marketing frame and copy; it keeps the real app UI intact.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/store/screenshots/marketing/play/ko"
DEST = ROOT / "assets/store/screenshots/marketing/light/play/ko"
PREVIEW = ROOT / "assets/store/screenshots/marketing/light/preview_ko.png"
FONT = "/System/Library/Fonts/AppleSDGothicNeo.ttc"
SIZE = (1080, 1920)

INK = "#242438"
MUTED = "#666477"
CORAL = "#ED7869"
PEACH = "#F6BBA6"
PURPLE = "#6853E8"

SLIDES = [
    ("01_home", "하루를", "한눈에 보다", "24시간 원형 시간표"),
    ("02_progress", "작은 완료가", "쌓이는 하루", "오늘의 진행 상황"),
    ("03_widget", "열지 않아도", "지금 루틴이", "홈 화면 위젯"),
    ("04_routines", "하루가", "색으로 채워져요", "나만의 루틴 목록"),
    ("05_add", "내 루틴을", "쉽게 만들어요", "간단한 루틴 만들기"),
    ("06_calendar", "한 달의 리듬을", "한눈에", "달력으로 돌아보기"),
    ("07_start", "나만의 하루,", "지금 시작해요", "계정 없이 바로 시작"),
]


def font(size: int, *, bold: bool = False) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT, size, index=14 if bold else 0)


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius, fill=255)
    return mask


def add_shadow(canvas: Image.Image, box: tuple[int, int, int, int], radius: int) -> None:
    layer = Image.new("RGBA", SIZE)
    ImageDraw.Draw(layer).rounded_rectangle(box, radius, fill=(49, 38, 62, 45))
    layer = layer.filter(ImageFilter.GaussianBlur(35))
    canvas.alpha_composite(layer)


def header(canvas: Image.Image, index: int, title: str, accent: str, caption: str) -> None:
    draw = ImageDraw.Draw(canvas)
    draw.text((82, 76), "LOOPET", font=font(31, bold=True), fill=INK)
    draw.rounded_rectangle((82, 137, 186, 145), radius=4, fill=CORAL)
    draw.text((82, 207), title, font=font(78, bold=True), fill=INK)
    draw.text((82, 301), accent, font=font(78, bold=True), fill=CORAL)
    draw.text((85, 415), caption, font=font(36), fill=MUTED)
    draw.text((947, 92), f"{index:02d} / 07", font=font(23, bold=True), fill="#A39BA0", anchor="ra")


def background(index: int) -> Image.Image:
    canvas = Image.new("RGBA", SIZE, "#FFFCF9")
    draw = ImageDraw.Draw(canvas)
    # Restrained peach decoration, kept behind the phone and away from copy.
    draw.ellipse((523, 642, 1161, 1280), fill="#FFF1EA")
    draw.ellipse((-226, 1365, 423, 2014), fill="#FFF4EE")
    draw.arc((630, 580, 1130, 1080), 203, 342, fill="#F7D3C6", width=5)
    for x, y, r in [(138, 636, 5), (895, 565, 4), (938, 1343, 6), (128, 1257, 4)]:
        draw.ellipse((x-r, y-r, x+r, y+r), fill=PEACH)
    return canvas


def phone(canvas: Image.Image, source: Path) -> None:
    raw = Image.open(source).convert("RGBA")
    # The source generator's phone interior: real rendered Flutter screen.
    screen = raw.crop((189, 264, 892, 1792)).resize((650, 1412), Image.Resampling.LANCZOS)
    x, y, w, h = 191, 520, 698, 1460
    add_shadow(canvas, (x + 5, y + 20, x + w + 5, y + h + 20), 98)
    draw = ImageDraw.Draw(canvas)
    draw.rounded_rectangle((x, y, x + w, y + h), radius=98, fill=PEACH)
    draw.rounded_rectangle((x + 10, y + 10, x + w - 10, y + h - 10), radius=89, fill="#FFF8F1")
    canvas.paste(screen, (x + 24, y + 24), rounded_mask(screen.size, 69))
    draw.rounded_rectangle((x, y, x + w, y + h), radius=98, outline="#E6A88F", width=4)


def cta(canvas: Image.Image) -> None:
    draw = ImageDraw.Draw(canvas)
    x, y, w, h = 137, 588, 806, 1040
    add_shadow(canvas, (x, y, x+w, y+h), 76)
    draw.rounded_rectangle((x, y, x+w, y+h), radius=76, fill="#FFF3E9", outline="#F5D6C9", width=4)
    draw.ellipse((255, 705, 825, 1275), fill="#FFE5D7")
    cat = Image.open(ROOT / "assets/characters/cat_starlight/v1/approved/guide.png").convert("RGBA")
    cat.thumbnail((580, 580), Image.Resampling.LANCZOS)
    canvas.alpha_composite(cat, ((1080-cat.width)//2, 788))
    icon = Image.open(ROOT / "assets/icon/app_icon.png").convert("RGBA").resize((150, 150), Image.Resampling.LANCZOS)
    canvas.paste(icon, (465, 650), rounded_mask(icon.size, 34))
    draw.rounded_rectangle((292, 1420, 788, 1510), radius=45, fill=CORAL)
    draw.text((540, 1467), "오늘부터 함께해요", font=font(36, bold=True), fill="white", anchor="mm")
    draw.text((540, 1720), "작은 루틴으로 만드는 나다운 하루", font=font(29), fill=MUTED, anchor="mm")


def generate() -> None:
    DEST.mkdir(parents=True, exist_ok=True)
    thumbs = []
    for i, (name, title, accent, caption) in enumerate(SLIDES, 1):
        canvas = background(i)
        header(canvas, i, title, accent, caption)
        if i == 7:
            cta(canvas)
        else:
            phone(canvas, SOURCE / f"{name}.png")
        out = DEST / f"{name}.png"
        canvas.convert("RGB").save(out, optimize=True)
        thumbs.append(canvas.convert("RGB").resize((270, 480), Image.Resampling.LANCZOS))
        print(out)

    strip = Image.new("RGB", (7 * 270 + 8 * 18, 480 + 36), "#F7F3EE")
    for i, thumb in enumerate(thumbs):
        strip.paste(thumb, (18 + i * (270 + 18), 18))
    PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    strip.save(PREVIEW, optimize=True)
    print(PREVIEW)


if __name__ == "__main__":
    generate()
