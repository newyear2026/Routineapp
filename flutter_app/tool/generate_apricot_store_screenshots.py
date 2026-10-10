"""Render the eight LOOPET Google Play cards in the apricot cream palette.

Run from flutter_app with ``python3 tool/generate_apricot_store_screenshots.py``.
The phone interiors come from current Flutter captures under cinematic/source.
"""

from __future__ import annotations

from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

from PIL import Image, ImageDraw, ImageFilter

from generate_cinematic_store_screenshots import CARDS, BASE, H, W, device, font, rgb, SOURCE


OUTPUT_BASE = BASE / "apricot_cream"
OUTPUT = OUTPUT_BASE / "play_console_ko"
INK = "#221C42"
CORAL = "#FF746C"
LEFT = "#FFF0E4"
RIGHT = "#FFDACC"


def background(index: int) -> Image.Image:
    canvas = Image.new("RGBA", (W, H))
    draw = ImageDraw.Draw(canvas)
    a, b = rgb(LEFT), rgb(RIGHT)
    for x in range(W):
        t = x / (W - 1)
        shade = tuple(round(a[i] * (1 - t) + b[i] * t) for i in range(3))
        draw.line((x, 0, x, H), fill=(*shade, 255))

    soft = Image.new("RGBA", (W, H))
    sd = ImageDraw.Draw(soft)
    sd.ellipse((525, 385, 1395, 1255), fill=(*rgb("#FFF9F0"), 175))
    sd.ellipse((-410, 1180, 430, 2020), fill=(255, 255, 255, 95))
    canvas.alpha_composite(soft.filter(ImageFilter.GaussianBlur(95)))

    draw = ImageDraw.Draw(canvas)
    draw.rectangle((0, 0, 9, H), fill=CORAL)
    draw.text((80, 62), "LOOPET", font=font(30), fill=INK)
    draw.text((1000, 64), f"{index:02d} / 08", font=font(25), fill="#59536D", anchor="ra")
    return canvas


def place_phone(canvas: Image.Image, item: tuple[str, int, int, int, float]) -> None:
    name, width, left, top, angle = item
    phone = device(name, width, angle)
    x = left - (phone.width - width) // 2
    y = top - (phone.height - round((width - 34) * 1528 / 703) - 34) // 2
    shadow = Image.new("RGBA", phone.size)
    shadow.paste((37, 33, 55, 42), (0, 0, phone.width, phone.height), phone.getchannel("A"))
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(60)), (x + 12, y + 18))
    canvas.alpha_composite(phone, (x, y))


def widget_callout(canvas: Image.Image) -> None:
    source = Image.open(SOURCE / "03_widget.png").convert("RGBA")
    crop = source.crop((205, 545, 875, 920)).resize((850, 476), Image.Resampling.LANCZOS)
    panel = Image.new("RGBA", (910, 536))
    draw = ImageDraw.Draw(panel)
    draw.rounded_rectangle((0, 0, 909, 535), radius=43, fill="#221C42", outline="#6A6174", width=4)
    mask = Image.new("L", crop.size)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, 849, 475), radius=25, fill=255)
    panel.paste(crop, (30, 30), mask)
    panel = panel.rotate(4, resample=Image.Resampling.BICUBIC, expand=True)
    x, y = 60, 1200
    shadow = Image.new("RGBA", panel.size)
    shadow.paste((37, 33, 55, 48), (0, 0, panel.width, panel.height), panel.getchannel("A"))
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(55)), (x + 12, y + 18))
    canvas.alpha_composite(panel, (x, y))


def render(index: int) -> Image.Image:
    card = CARDS[index - 1]
    canvas = background(index)
    for item in card.phones:
        place_phone(canvas, item)
    if index == 4:
        widget_callout(canvas)
    draw = ImageDraw.Draw(canvas)
    title_y = 155
    for line in card.title:
        draw.text((80, title_y), line, font=font(82), fill=INK)
        title_y += 103
    draw.rounded_rectangle((81, 383, 196, 394), radius=5, fill=CORAL)
    return canvas.convert("RGB")


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    thumbs = []
    for index, card in enumerate(CARDS, 1):
        result = render(index)
        result.save(OUTPUT / card.filename, optimize=True)
        thumbs.append(result.resize((270, 480), Image.Resampling.LANCZOS))

    preview = Image.new("RGB", (8 * 270 + 9 * 18, 480 + 36), "#F8F6F2")
    for index, thumb in enumerate(thumbs):
        preview.paste(thumb, (18 + index * 288, 18))
    preview.save(OUTPUT_BASE / "preview_ko.png", optimize=True)

    with ZipFile(OUTPUT_BASE / "loopet_apricot_cream_play_ko.zip", "w", ZIP_DEFLATED) as archive:
        for card in CARDS:
            archive.write(OUTPUT / card.filename, card.filename)
    print(OUTPUT_BASE)


if __name__ == "__main__":
    main()
