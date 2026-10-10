"""Compare exact background colors around the same current LOOPET screen."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

from generate_cinematic_store_screenshots import BASE, CARDS, H, W, font, place, rgb


OPTIONS = (
    ("딥 틸 · 추천", "deep_teal", "#0E2B34", "#145158", (32, 145, 145)),
    ("미드나이트 블루", "midnight_blue", "#0D1B31", "#21425D", (44, 116, 179)),
    ("웜 코코아", "warm_cocoa", "#2D2424", "#57413B", (171, 103, 78)),
)


def render_option(left: str, right: str, glow_color: tuple[int, int, int]) -> Image.Image:
    canvas = Image.new("RGBA", (W, H))
    draw = ImageDraw.Draw(canvas)
    a, b = rgb(left), rgb(right)
    for x in range(W):
        t = x / (W - 1)
        shade = tuple(round(a[i] * (1 - t) + b[i] * t) for i in range(3))
        draw.line((x, 0, x, H), fill=(*shade, 255))

    glow = Image.new("RGBA", (W, H))
    gd = ImageDraw.Draw(glow)
    gd.ellipse((-330, 410, 570, 1290), fill=(*glow_color, 65))
    gd.ellipse((540, 800, 1370, 1630), fill=(*glow_color, 55))
    canvas.alpha_composite(glow.filter(ImageFilter.GaussianBlur(180)))

    draw = ImageDraw.Draw(canvas)
    draw.rectangle((0, 0, 9, H), fill="#FF6C75")
    draw.text((80, 62), "LOOPET", font=font(30), fill="#EDE9E6")
    draw.text((1000, 64), "02 / 08", font=font(25), fill="#D1CDCE", anchor="ra")
    place(canvas, CARDS[1].phones[0])
    draw = ImageDraw.Draw(canvas)
    draw.text((80, 155), "지금 할 루틴을", font=font(82), fill="white")
    draw.text((80, 258), "바로 확인", font=font(82), fill="white")
    draw.rounded_rectangle((81, 383, 196, 394), radius=5, fill="#FF6C75")
    return canvas.convert("RGB")


def main() -> None:
    output = BASE / "color_options"
    output.mkdir(parents=True, exist_ok=True)
    contact = Image.new("RGB", (1224, 792), "#F4F1ED")
    draw = ImageDraw.Draw(contact)
    for i, (label, filename, left, right, glow_color) in enumerate(OPTIONS):
        result = render_option(left, right, glow_color)
        result.save(output / f"{i+1:02d}_{filename}.png", optimize=True)
        x = 24 + i * 400
        contact.paste(result.resize((360, 640), Image.Resampling.LANCZOS), (x, 24))
        draw.text((x, 680), label, font=font(31), fill="#202A31")
        draw.text((x, 726), f"{left}  →  {right}", font=font(22), fill="#55616A")
    contact.save(BASE / "color_options_preview_ko.png", optimize=True)
    print(BASE / "color_options_preview_ko.png")


if __name__ == "__main__":
    main()
