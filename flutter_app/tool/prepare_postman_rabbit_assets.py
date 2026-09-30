"""Extract the approved rabbit concept sprites into app-sized transparent PNGs.

The source sheets live in design/postman-rabbit so the crops remain reproducible.
"""

from pathlib import Path
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "design" / "postman-rabbit"
CHARACTERS = ROOT / "assets" / "characters" / "rabbit_postman" / "v1" / "approved"
DECORATIONS = ROOT / "assets" / "decorations"


def clean_alpha(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            red, green, blue, alpha = pixels[x, y]
            pixels[x, y] = (red, green, blue, 255 if alpha >= 128 else 0)
    return image


def main() -> None:
    CHARACTERS.mkdir(parents=True, exist_ok=True)
    pose_sheet = Image.open(SOURCE / "rabbit-poses-source.png")
    poses = ("idle", "activity", "focus", "complete", "rest", "guide")
    for index, pose in enumerate(poses):
        column, row = index % 3, index // 3
        sprite = pose_sheet.crop((column * 512, row * 512, (column + 1) * 512, (row + 1) * 512))
        sprite = clean_alpha(sprite)
        sprite.resize((384, 384), Image.Resampling.NEAREST).save(CHARACTERS / f"{pose}.png")

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
