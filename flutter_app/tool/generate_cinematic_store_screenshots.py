"""Render a dark, layered LOOPET Google Play screenshot set.

Inspired by the supplied AppScreens streaming template. All phone interiors are
Flutter-rendered LOOPET screens from ``marketing/play/ko``; no streaming-app
graphics or copy are included. Run from ``flutter_app``:

    python3 tool/generate_cinematic_store_screenshots.py
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/store/screenshots/marketing/cinematic/source/play/ko"
OUTPUT = ROOT / "assets/store/screenshots/marketing/cinematic/play_console_ko"
BASE = OUTPUT.parent
FONT = "/System/Library/Fonts/AppleSDGothicNeo.ttc"
W, H = 1080, 1920


@dataclass(frozen=True)
class Card:
    filename: str
    title: tuple[str, str]
    left: str
    right: str
    phones: tuple[tuple[str, int, int, int, float], ...]


# Phone entries: source file, width, left, top, counterclockwise rotation.
# Back-to-front order is intentional. Every card contains actual app UI.
CARDS = (
    Card("01_overview.png", ("하루의 루틴을", "한눈에"), "#160B27", "#680B2B",
         (("02_progress", 570, 438, 465, -11), ("01_home", 685, -37, 638, 10))),
    Card("02_home.png", ("지금 할 루틴을", "바로 확인"), "#260A29", "#670B2B",
         (("01_home", 790, 155, 425, -5),)),
    Card("03_progress.png", ("작은 완료가", "쌓이는 하루"), "#100D2B", "#4D1037",
         (("02_progress", 790, 145, 430, 5),)),
    Card("04_widget.png", ("앱을 열지 않아도", "지금이 보여요"), "#1C0B2D", "#72112C",
         (("03_widget", 790, 150, 430, -4),)),
    Card("05_routines.png", ("나만의 루틴을", "한 곳에"), "#140B28", "#5C0D37",
         (("04_routines", 790, 148, 430, 5),)),
    Card("06_add.png", ("원하는 시간에", "루틴을 만들고"), "#210927", "#741027",
         (("05_add", 790, 155, 435, -5),)),
    Card("07_calendar.png", ("한 달의 리듬을", "달력으로 확인"), "#110B28", "#5E0D33",
         (("06_calendar", 790, 145, 430, 4),)),
    Card("08_everyday.png", ("하루의 흐름이", "선명해져요"), "#1B0B29", "#72102A",
         (("06_calendar", 580, 470, 505, -11), ("01_home", 680, -15, 615, 9))),
)


def font(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT, size, index=14)


def rgb(hex_color: str) -> tuple[int, int, int]:
    return tuple(bytes.fromhex(hex_color.lstrip("#")))


def background(card: Card, index: int) -> Image.Image:
    canvas = Image.new("RGBA", (W, H))
    draw = ImageDraw.Draw(canvas)
    left, right = rgb(card.left), rgb(card.right)
    for x in range(W):
        t = x / (W - 1)
        shade = tuple(round(left[i] * (1 - t) + right[i] * t) for i in range(3))
        draw.line((x, 0, x, H), fill=(*shade, 255))

    # Diffuse color pools give depth without competing with the app UI.
    glow = Image.new("RGBA", (W, H))
    gd = ImageDraw.Draw(glow)
    gd.ellipse((-340, 390, 570, 1310), fill=(135, 32, 91, 105))
    gd.ellipse((510, 690, 1360, 1600), fill=(103, 36, 224, 66))
    gd.ellipse((40, 1350, 980, 2290), fill=(229, 43, 61, 37))
    canvas.alpha_composite(glow.filter(ImageFilter.GaussianBlur(170)))
    # Slim luminous edge, echoing the reference's editorial panels.
    draw = ImageDraw.Draw(canvas)
    draw.rectangle((0, 0, 9, H), fill=(243, 91, 108, 205))
    draw.text((80, 62), "LOOPET", font=font(30), fill="#E6DDE9")
    draw.text((1000, 64), f"{index:02d} / 08", font=font(25), fill="#CBB8CD", anchor="ra")
    return canvas


def screenshot(name: str) -> Image.Image:
    source = Image.open(SOURCE / f"{name}.png").convert("RGBA")
    return source.crop((189, 264, 892, 1792))


def device(name: str, width: int, angle: float) -> Image.Image:
    inside_w = width - 34
    inside_h = round(inside_w * 1528 / 703)
    body_h = inside_h + 34
    inset = 54
    stage = Image.new("RGBA", (width + inset * 2, body_h + inset * 2))
    draw = ImageDraw.Draw(stage)
    outline = (inset, inset, inset + width, inset + body_h)
    draw.rounded_rectangle(outline, radius=93, fill="#050507", outline="#68636D", width=5)
    draw.rounded_rectangle((inset + 8, inset + 8, inset + width - 8, inset + body_h - 8),
                           radius=86, outline="#222027", width=7)
    screen = screenshot(name).resize((inside_w, inside_h), Image.Resampling.LANCZOS)
    mask = Image.new("L", (inside_w, inside_h))
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, inside_w - 1, inside_h - 1), radius=72, fill=255)
    stage.paste(screen, (inset + 17, inset + 17), mask)
    draw.rounded_rectangle(outline, radius=93, outline="#77717C", width=3)
    if angle:
        stage = stage.rotate(angle, resample=Image.Resampling.BICUBIC, expand=True)
    return stage


def place(canvas: Image.Image, item: tuple[str, int, int, int, float]) -> None:
    name, width, left, top, angle = item
    phone = device(name, width, angle)
    x = left - (phone.width - width) // 2
    y = top - (phone.height - round((width - 34) * 1528 / 703) - 34) // 2

    alpha = phone.getchannel("A")
    silhouette = Image.new("RGBA", phone.size, (0, 0, 0, 0))
    silhouette.paste((0, 0, 0, 165), (0, 0, phone.width, phone.height), alpha)
    canvas.alpha_composite(silhouette.filter(ImageFilter.GaussianBlur(45)), (x + 25, y + 35))
    canvas.alpha_composite(phone, (x, y))


def widget_callout(canvas: Image.Image) -> None:
    """Enlarge the real widget card so its content remains readable."""
    source = Image.open(SOURCE / "03_widget.png").convert("RGBA")
    crop = source.crop((205, 545, 875, 920)).resize((850, 476), Image.Resampling.LANCZOS)
    panel = Image.new("RGBA", (910, 536))
    draw = ImageDraw.Draw(panel)
    draw.rounded_rectangle((0, 0, 909, 535), radius=43, fill="#08070D", outline="#77717C", width=4)
    mask = Image.new("L", crop.size)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, 849, 475), radius=25, fill=255)
    panel.paste(crop, (30, 30), mask)
    panel = panel.rotate(4, resample=Image.Resampling.BICUBIC, expand=True)
    x, y = 60, 1200
    silhouette = Image.new("RGBA", panel.size, (0, 0, 0, 0))
    silhouette.paste((0, 0, 0, 160), (0, 0, panel.width, panel.height), panel.getchannel("A"))
    canvas.alpha_composite(silhouette.filter(ImageFilter.GaussianBlur(42)), (x + 18, y + 30))
    canvas.alpha_composite(panel, (x, y))


def render(card: Card, index: int) -> Image.Image:
    canvas = background(card, index)
    for item in card.phones:
        place(canvas, item)
    if index == 4:
        widget_callout(canvas)
    draw = ImageDraw.Draw(canvas)
    title_y = 155
    for line in card.title:
        draw.text((80, title_y), line, font=font(82), fill="white", stroke_width=1,
                  stroke_fill="#FFFFFF")
        title_y += 103
    draw.rounded_rectangle((81, 383, 196, 394), radius=5, fill="#FF6C75")
    return canvas.convert("RGB")


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    thumbs: list[Image.Image] = []
    for index, card in enumerate(CARDS, 1):
        result = render(card, index)
        path = OUTPUT / card.filename
        result.save(path, optimize=True)
        thumbs.append(result.resize((270, 480), Image.Resampling.LANCZOS))
        print(path)

    preview = Image.new("RGB", (8 * 270 + 9 * 18, 480 + 36), "#14101A")
    for index, thumb in enumerate(thumbs):
        preview.paste(thumb, (18 + index * 288, 18))
    preview.save(BASE / "preview_ko.png", optimize=True)

    with ZipFile(BASE / "loopet_cinematic_play_ko.zip", "w", ZIP_DEFLATED) as archive:
        for card in CARDS:
            archive.write(OUTPUT / card.filename, card.filename)
    print(BASE / "preview_ko.png")
    print(BASE / "loopet_cinematic_play_ko.zip")


if __name__ == "__main__":
    main()
