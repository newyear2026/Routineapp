"""Prepare the Postman Rabbit dawn scene for Flutter and native widgets."""

from pathlib import Path
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "design" / "postman-rabbit" / "rabbit-dawn-source.png"
DESTINATIONS = (
    ROOT / "assets" / "pack_backgrounds" / "rabbit-dawn.png",
    ROOT / "android" / "app" / "src" / "main" / "res" / "drawable-nodpi" / "widget_rabbit_dawn.png",
    ROOT / "ios" / "RoutineWidgetExtension" / "Artwork" / "widget_rabbit_dawn.png",
)


def main() -> None:
    scene = Image.open(SOURCE).convert("RGB")
    scene = scene.resize((768, 240), Image.Resampling.NEAREST)
    for destination in DESTINATIONS:
        destination.parent.mkdir(parents=True, exist_ok=True)
        scene.save(destination, optimize=True)


if __name__ == "__main__":
    main()
