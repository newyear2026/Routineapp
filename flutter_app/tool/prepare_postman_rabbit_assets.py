"""Extract the approved rabbit concept sprites into app-sized transparent PNGs.

The source sheets live in design/postman-rabbit so the crops remain reproducible.
"""

import shutil
from pathlib import Path
from PIL import Image, ImageOps


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "design" / "postman-rabbit"
CHARACTERS = ROOT / "assets" / "characters" / "rabbit_postman" / "v1" / "approved"
DECORATIONS = ROOT / "assets" / "decorations"
# The ring widget and the timeline/cards widgets draw the idle pose as-is.
WIDGET_COPIES = (
    ROOT / "android" / "app" / "src" / "main" / "res" / "drawable-nodpi" / "widget_rabbit.png",
    ROOT / "android" / "app" / "src" / "main" / "res" / "drawable-nodpi" / "widget_variant_rabbit.png",
    ROOT / "ios" / "RoutineWidgetExtension" / "Artwork" / "widget_rabbit.png",
)


def clean_alpha(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            red, green, blue, alpha = pixels[x, y]
            pixels[x, y] = (red, green, blue, 255 if alpha >= 128 else 0)
    return image


def save_within_budget(image: Image.Image, path: Path) -> None:
    """Keeps a pose under the 130KB bundle budget (docs/CHARACTER_PACK_SPEC.md).

    The rabbit art is detailed enough that lossless PNG lands at 150-175KB.
    Dropping the lowest bit of each colour channel moves no value by more
    than 1/255 and brings every pose to 100-120KB. Alpha is left alone.
    """
    red, green, blue, alpha = image.split()
    rgb = ImageOps.posterize(Image.merge("RGB", (red, green, blue)), 7)
    Image.merge("RGBA", (*rgb.split(), alpha)).save(path, optimize=True, compress_level=9)


def main() -> None:
    CHARACTERS.mkdir(parents=True, exist_ok=True)
    pose_sheet = Image.open(SOURCE / "rabbit-poses-source.png")
    poses = ("idle", "activity", "focus", "complete", "rest", "guide")
    for index, pose in enumerate(poses):
        column, row = index % 3, index // 3
        sprite = pose_sheet.crop((column * 512, row * 512, (column + 1) * 512, (row + 1) * 512))
        sprite = clean_alpha(sprite)
        save_within_budget(sprite.resize((384, 384), Image.Resampling.NEAREST),
                           CHARACTERS / f"{pose}.png")
    for copy in WIDGET_COPIES:
        shutil.copyfile(CHARACTERS / "idle.png", copy)

    icon_sheet = Image.open(SOURCE / "rabbit-decorations-source.png")
    for index, name in enumerate(("rabbit-letter", "rabbit-satchel", "rabbit-carrot-stamp")):
        sprite = clean_alpha(icon_sheet.crop((index * 724, 0, (index + 1) * 724, 724)))
        bounds = sprite.getchannel("A").getbbox()
        if bounds is None:
            raise ValueError(f"Empty icon: {name}")
        cutout = sprite.crop(bounds)
        side = max(cutout.size)
        canvas = Image.new("RGBA", (side, side))
        canvas.alpha_composite(cutout, ((side - cutout.width) // 2, (side - cutout.height) // 2))
        canvas.resize((128, 128), Image.Resampling.NEAREST).save(DECORATIONS / f"{name}.png")


if __name__ == "__main__":
    main()
