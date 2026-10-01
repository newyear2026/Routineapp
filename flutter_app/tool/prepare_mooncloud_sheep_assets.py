"""Extract the mooncloud sheep sprite sheets into app-sized transparent PNGs."""

from pathlib import Path
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "design" / "mooncloud-sheep"
CHARACTERS = ROOT / "assets" / "characters" / "sheep_mooncloud" / "v1" / "approved"
DECORATIONS = ROOT / "assets" / "decorations"


def clean_alpha(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            red, green, blue, alpha = pixels[x, y]
            pixels[x, y] = (red, green, blue, 255) if alpha >= 128 else (0, 0, 0, 0)
    return image


def main() -> None:
    CHARACTERS.mkdir(parents=True, exist_ok=True)
    poses = ("idle", "activity", "focus", "complete", "rest", "guide")
    sheet = Image.open(SOURCE / "sheep-poses-source.png")
    for index, pose in enumerate(poses):
        column, row = index % 3, index // 3
        sprite = clean_alpha(sheet.crop((
            column * 512, row * 512, (column + 1) * 512, (row + 1) * 512,
        )))
        sprite.resize((384, 384), Image.Resampling.NEAREST).save(
            CHARACTERS / f"{pose}.png"
        )

    icons = Image.open(SOURCE / "sheep-decorations-source.png")
    names = ("sheep-cloud", "sheep-moon", "sheep-book")
    for index, name in enumerate(names):
        sprite = clean_alpha(icons.crop((index * 724, 0, (index + 1) * 724, 724)))
        bounds = sprite.getchannel("A").getbbox()
        if bounds is None:
            raise ValueError(f"Empty icon: {name}")
        cutout = sprite.crop(bounds)
        side = max(cutout.size)
        canvas = Image.new("RGBA", (side, side))
        canvas.alpha_composite(cutout, ((side - cutout.width) // 2, (side - cutout.height) // 2))
        canvas.resize((128, 128), Image.Resampling.NEAREST).save(
            DECORATIONS / f"{name}.png"
        )

    sky = Image.open(SOURCE / "sheep-sky-source.png").convert("RGB")
    sky = sky.resize((768, 240), Image.Resampling.NEAREST)
    (ROOT / "assets" / "pack_backgrounds").mkdir(parents=True, exist_ok=True)
    sky.save(ROOT / "assets" / "pack_backgrounds" / "sheep-sky.png")
    sky.save(ROOT / "android" / "app" / "src" / "main" /
                "res" / "drawable-nodpi" / "widget_sheep_sky.png")
    sky.save(ROOT / "ios" / "RoutineWidgetExtension" /
                "Artwork" / "widget_sheep_sky.png")


if __name__ == "__main__":
    main()
