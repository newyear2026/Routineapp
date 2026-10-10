"""Slice and size the generated penguin art for Flutter and native widgets."""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "design" / "penguin-snow-walk"
CHARACTERS = ROOT / "assets" / "characters" / "penguin_snow_walk" / "v1" / "approved"
DECORATIONS = ROOT / "assets" / "decorations"
BACKGROUNDS = ROOT / "assets" / "pack_backgrounds"
ANDROID = ROOT / "android" / "app" / "src" / "main" / "res" / "drawable-nodpi"
IOS = ROOT / "ios" / "RoutineWidgetExtension" / "Artwork"


def clear_soft_alpha(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    alpha = image.getchannel("A").point(lambda value: 255 if value >= 128 else 0)
    image.putalpha(alpha)
    return image


def save(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, optimize=True)


def fit_sprite(image: Image.Image, *, width: int, height: int, bottom: int) -> Image.Image:
    image = clear_soft_alpha(image)
    bounds = image.getchannel("A").getbbox()
    if bounds is None:
        raise ValueError("Empty sprite")
    cropped = image.crop(bounds)
    scale = min(width / cropped.width, height / cropped.height)
    cropped = cropped.resize(
        (round(cropped.width * scale), round(cropped.height * scale)),
        Image.Resampling.NEAREST,
    )
    canvas = Image.new("RGBA", (384, 384), (0, 0, 0, 0))
    canvas.alpha_composite(cropped, ((384 - cropped.width) // 2, bottom - cropped.height))
    return canvas


def main() -> None:
    save(fit_sprite(Image.open(SOURCE / "idle-source.png"), width=312, height=320, bottom=352),
         CHARACTERS / "idle.png")

    sheet = Image.open(SOURCE / "pose-sheet-source.png")
    cells = {
        "activity": (0, 0, 512, 512),
        "focus": (512, 0, 1024, 512),
        "complete": (1024, 0, 1536, 512),
        "rest": (0, 512, 512, 1024),
        "guide": (512, 512, 1024, 1024),
    }
    for pose, cell in cells.items():
        resting = pose == "rest"
        sprite = fit_sprite(sheet.crop(cell), width=320 if resting else 308,
                            height=248 if resting else 315,
                            bottom=335 if resting else 352)
        save(sprite, CHARACTERS / f"{pose}.png")

    decorations = Image.open(SOURCE / "decorations-source.png")
    names = ("penguin-snowflake", "penguin-mitten", "penguin-thermos")
    for index, name in enumerate(names):
        left = round(index * decorations.width / 3)
        right = round((index + 1) * decorations.width / 3)
        image = clear_soft_alpha(decorations.crop((left, 0, right, decorations.height)))
        bounds = image.getchannel("A").getbbox()
        if bounds is None:
            raise ValueError(f"Empty decoration: {name}")
        cropped = image.crop(bounds)
        scale = 118 / max(cropped.size)
        cropped = cropped.resize(
            (round(cropped.width * scale), round(cropped.height * scale)),
            Image.Resampling.NEAREST,
        )
        canvas = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
        canvas.alpha_composite(cropped, ((128 - cropped.width) // 2, (128 - cropped.height) // 2))
        save(canvas, DECORATIONS / f"{name}.png")

    header = Image.open(SOURCE / "header-source.png").convert("RGB")
    card = Image.open(SOURCE / "card-source.png").convert("RGB")
    save(header.resize((1024, 683), Image.Resampling.NEAREST),
         BACKGROUNDS / "penguin-scene-header.png")
    save(card.resize((1200, 400), Image.Resampling.NEAREST),
         BACKGROUNDS / "penguin-scene-card.png")
    widget_background = card.resize((768, 240), Image.Resampling.NEAREST)
    for path in (BACKGROUNDS / "penguin-snowpath.png",
                 ANDROID / "widget_penguin_snowpath.png",
                 IOS / "widget_penguin_snowpath.png"):
        save(widget_background, path)

    mascot = Image.open(CHARACTERS / "idle.png")
    for path in (ANDROID / "widget_penguin.png",
                 ANDROID / "widget_variant_penguin.png",
                 IOS / "widget_penguin.png"):
        save(mascot, path)


if __name__ == "__main__":
    main()
