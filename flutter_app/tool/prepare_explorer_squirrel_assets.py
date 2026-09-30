"""Extract the explorer squirrel sprite sheets into app-sized transparent PNGs."""

from pathlib import Path
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "design" / "explorer-squirrel"
CHARACTERS = ROOT / "assets" / "characters" / "squirrel_explorer" / "v1" / "approved"
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
    sheet = Image.open(SOURCE / "squirrel-poses-source.png")
    for index, pose in enumerate(poses):
        column, row = index % 3, index // 3
        sprite = clean_alpha(sheet.crop((
            column * 512, row * 512, (column + 1) * 512, (row + 1) * 512,
        )))
        sprite.resize((384, 384), Image.Resampling.NEAREST).save(
            CHARACTERS / f"{pose}.png"
        )

    icons = Image.open(SOURCE / "squirrel-decorations-source.png")
    names = ("squirrel-acorn", "squirrel-map", "squirrel-backpack")
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

    forest = Image.open(SOURCE / "squirrel-forest-source.png").convert("RGB")
    forest = forest.resize((768, 240), Image.Resampling.NEAREST)
    (ROOT / "assets" / "pack_backgrounds").mkdir(parents=True, exist_ok=True)
    forest.save(ROOT / "assets" / "pack_backgrounds" / "squirrel-forest.png")
    forest.save(ROOT / "android" / "app" / "src" / "main" /
                "res" / "drawable-nodpi" / "widget_forest.png")
    forest.save(ROOT / "ios" / "RoutineWidgetExtension" /
                "Artwork" / "widget_forest.png")


if __name__ == "__main__":
    main()
