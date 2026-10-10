"""Render three light background proposals around captured character-pack UI.

Run after ``generate_store_screenshots.dart`` captures the desired pack. For
the signature cat, set ``STORE_SCREENSHOT_CHARACTER=cat_starlight``.
"""

from __future__ import annotations

from dataclasses import dataclass
import os
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

from PIL import Image, ImageDraw, ImageFilter

from generate_cinematic_store_screenshots import BASE, CARDS, H, W, device, font, rgb


CHARACTER = os.environ.get("STORE_SCREENSHOT_CHARACTER", "redpanda")
ROOT = BASE / CHARACTER
SOURCE = ROOT / "source/play/ko"
OUTPUT = ROOT / "background_options"
APP_ROOT = Path(__file__).resolve().parents[1]


@dataclass(frozen=True)
class Palette:
    folder: str
    label: str
    left: str
    right: str
    ink: str
    accent: str


PALETTES = (
    Palette("01_powder_blue", "파우더 블루", "#EEF8FC", "#CCE9F1", "#203D4D", "#E78F6D"),
    Palette("02_soft_sage", "소프트 세이지", "#F0F8EE", "#D5EDDA", "#29463B", "#D98261"),
    Palette("03_lilac_cream", "라일락 크림", "#F5F0FC", "#DDD8F2", "#352B52", "#DE8A75"),
)


def background(palette: Palette, index: int) -> Image.Image:
    canvas = Image.new("RGBA", (W, H))
    draw = ImageDraw.Draw(canvas)
    a, b = rgb(palette.left), rgb(palette.right)
    for x in range(W):
        t = x / (W - 1)
        shade = tuple(round(a[i] * (1 - t) + b[i] * t) for i in range(3))
        draw.line((x, 0, x, H), fill=(*shade, 255))

    light = Image.new("RGBA", (W, H))
    ld = ImageDraw.Draw(light)
    ld.ellipse((570, 390, 1350, 1170), fill=(255, 255, 255, 110))
    ld.ellipse((-420, 1250, 340, 2010), fill=(255, 255, 255, 90))
    canvas.alpha_composite(light.filter(ImageFilter.GaussianBlur(120)))

    draw = ImageDraw.Draw(canvas)
    draw.rectangle((0, 0, 9, H), fill=palette.accent)
    draw.text((80, 62), "LOOPET", font=font(30), fill=palette.ink)
    draw.text((1000, 64), f"{index:02d} / 08", font=font(25), fill=palette.ink, anchor="ra")
    return canvas


def place_phone(canvas: Image.Image, item: tuple[str, int, int, int, float]) -> None:
    name, width, left, top, angle = item
    phone = device(name, width, angle, SOURCE)
    x = left - (phone.width - width) // 2
    y = top - (phone.height - round((width - 34) * 1528 / 703) - 34) // 2
    shadow = Image.new("RGBA", phone.size)
    shadow.paste((33, 44, 48, 42), (0, 0, phone.width, phone.height), phone.getchannel("A"))
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(60)), (x + 12, y + 18))
    canvas.alpha_composite(phone, (x, y))


def widget_callout(canvas: Image.Image, palette: Palette) -> None:
    source = Image.open(SOURCE / "03_widget.png").convert("RGBA")
    crop = source.crop((205, 545, 875, 920)).resize((850, 476), Image.Resampling.LANCZOS)
    panel = Image.new("RGBA", (910, 536))
    draw = ImageDraw.Draw(panel)
    draw.rounded_rectangle((0, 0, 909, 535), radius=43, fill=palette.ink,
                           outline="#817C83", width=4)
    mask = Image.new("L", crop.size)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, 849, 475), radius=25, fill=255)
    panel.paste(crop, (30, 30), mask)
    panel = panel.rotate(4, resample=Image.Resampling.BICUBIC, expand=True)
    x, y = 60, 1200
    shadow = Image.new("RGBA", panel.size)
    shadow.paste((33, 44, 48, 48), (0, 0, panel.width, panel.height), panel.getchannel("A"))
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(55)), (x + 12, y + 18))
    canvas.alpha_composite(panel, (x, y))


def signature_mascot(canvas: Image.Image, index: int) -> None:
    """Make the app's included mascot visible at store-thumbnail size."""
    if CHARACTER != "cat_starlight":
        return
    placements = {
        1: ("guide", 270, 770, 130),
        3: ("complete", 250, 790, 140),
        8: ("idle", 270, 770, 130),
    }
    if index not in placements:
        return
    pose, size, left, top = placements[index]
    path = APP_ROOT / f"assets/characters/cat_starlight/v1/approved/{pose}.png"
    character = Image.open(path).convert("RGBA").resize(
        (size, size), Image.Resampling.NEAREST
    )
    canvas.alpha_composite(character, (left, top))


def render(palette: Palette, index: int) -> Image.Image:
    card = CARDS[index - 1]
    canvas = background(palette, index)
    for item in card.phones:
        place_phone(canvas, item)
    if index == 4:
        widget_callout(canvas, palette)
    draw = ImageDraw.Draw(canvas)
    title_y = 155
    for line in card.title:
        draw.text((80, title_y), line, font=font(82), fill=palette.ink)
        title_y += 103
    draw.rounded_rectangle((81, 383, 196, 394), radius=5, fill=palette.accent)
    signature_mascot(canvas, index)
    return canvas.convert("RGB")


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    sheet = Image.new("RGB", (1224, 792), "#FAF9F6")
    labels = ImageDraw.Draw(sheet)
    for p_index, palette in enumerate(PALETTES):
        folder = OUTPUT / palette.folder
        folder.mkdir(parents=True, exist_ok=True)
        thumbs = []
        for index, card in enumerate(CARDS, 1):
            result = render(palette, index)
            result.save(folder / card.filename, optimize=True)
            thumbs.append(result.resize((270, 480), Image.Resampling.LANCZOS))
            if index == 2:
                x = 24 + p_index * 400
                sheet.paste(result.resize((360, 640), Image.Resampling.LANCZOS), (x, 24))

        strip = Image.new("RGB", (8 * 270 + 9 * 18, 516), "#FAF9F6")
        for index, thumb in enumerate(thumbs):
            strip.paste(thumb, (18 + index * 288, 18))
        strip.save(OUTPUT / f"{palette.folder}_preview_ko.png", optimize=True)
        with ZipFile(OUTPUT / f"{palette.folder}_play_ko.zip", "w", ZIP_DEFLATED) as archive:
            for card in CARDS:
                archive.write(folder / card.filename, card.filename)
        x = 24 + p_index * 400
        labels.text((x, 680), palette.label, font=font(31), fill=palette.ink)
        labels.text((x, 726), f"{palette.left}  →  {palette.right}",
                    font=font(22), fill="#666278")

    sheet.save(OUTPUT / "comparison_ko.png", optimize=True)
    print(OUTPUT / "comparison_ko.png")


if __name__ == "__main__":
    main()
