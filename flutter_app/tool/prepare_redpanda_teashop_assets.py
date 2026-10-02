"""Prepare the approved red panda sprites and matching widget artwork."""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "design" / "red-panda-concept"
CHARACTERS = ROOT / "assets" / "characters" / "redpanda_teashop" / "v1" / "approved"
DECORATIONS = ROOT / "assets" / "decorations"
BACKGROUNDS = ROOT / "assets" / "pack_backgrounds"
ANDROID = ROOT / "android" / "app" / "src" / "main" / "res" / "drawable-nodpi"
IOS = ROOT / "ios" / "RoutineWidgetExtension" / "Artwork"


def clean_alpha(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            red, green, blue, alpha = pixels[x, y]
            pixels[x, y] = (red, green, blue, 255) if alpha >= 128 else (0, 0, 0, 0)
    return image


def save_rgba(image: Image.Image, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    image.save(destination, optimize=True)


def main() -> None:
    for pose in ("idle", "activity", "focus", "complete", "rest", "guide"):
        source = clean_alpha(Image.open(SOURCE / f"{pose}-source.png"))
        sprite = source.resize((384, 384), Image.Resampling.NEAREST)
        save_rgba(sprite, CHARACTERS / f"{pose}.png")

    sheet = Image.open(SOURCE / "decorations-source.png")
    for index, name in enumerate(("redpanda-teapot", "redpanda-window", "redpanda-teacup")):
        sprite = clean_alpha(sheet.crop((index * 724, 0, (index + 1) * 724, 724)))
        bounds = sprite.getchannel("A").getbbox()
        if bounds is None:
            raise ValueError(f"Empty decoration: {name}")
        cutout = sprite.crop(bounds)
        side = max(cutout.size)
        canvas = Image.new("RGBA", (side, side))
        canvas.alpha_composite(cutout, ((side - cutout.width) // 2, (side - cutout.height) // 2))
        save_rgba(canvas.resize((128, 128), Image.Resampling.NEAREST),
                  DECORATIONS / f"{name}.png")

    background = Image.open(SOURCE / "teashop-background-source.png").convert("RGB")
    background = background.resize((768, 240), Image.Resampling.NEAREST)
    for destination in (
        BACKGROUNDS / "redpanda-teashop.png",
        ANDROID / "widget_redpanda_teashop.png",
        IOS / "widget_redpanda_teashop.png",
    ):
        destination.parent.mkdir(parents=True, exist_ok=True)
        background.save(destination, optimize=True)

    idle = Image.open(CHARACTERS / "idle.png")
    for destination in (
        ANDROID / "widget_redpanda.png",
        ANDROID / "widget_variant_redpanda.png",
        IOS / "widget_redpanda.png",
    ):
        save_rgba(idle, destination)


if __name__ == "__main__":
    main()
