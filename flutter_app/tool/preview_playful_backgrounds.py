"""Preview light, playful store-card backgrounds using the current app UI."""

from __future__ import annotations

from PIL import Image, ImageDraw, ImageFilter

from generate_cinematic_store_screenshots import BASE, CARDS, H, W, device, font, rgb


OPTIONS = (
    ("살구 크림 · 추천", "apricot_cream", "#FFF0E4", "#FFDACC", "#FFF9F0"),
    ("버터 옐로", "butter_yellow", "#FFF8DF", "#FFE9B8", "#FFFFF1"),
    ("소프트 민트", "soft_mint", "#E9F9F1", "#CFF0E6", "#F8FFFC"),
)
INK = "#221C42"
CORAL = "#FF746C"


def place_light(canvas: Image.Image) -> None:
    name, width, left, top, angle = CARDS[1].phones[0]
    phone = device(name, width, angle)
    x = left - (phone.width - width) // 2
    y = top - (phone.height - round((width - 34) * 1528 / 703) - 34) // 2
    silhouette = Image.new("RGBA", phone.size)
    silhouette.paste((37, 33, 55, 72), (0, 0, phone.width, phone.height), phone.getchannel("A"))
    canvas.alpha_composite(silhouette.filter(ImageFilter.GaussianBlur(48)), (x + 15, y + 24))
    canvas.alpha_composite(phone, (x, y))


def render_option(left: str, right: str, glow: str) -> Image.Image:
    canvas = Image.new("RGBA", (W, H))
    draw = ImageDraw.Draw(canvas)
    a, b = rgb(left), rgb(right)
    for x in range(W):
        t = x / (W - 1)
        shade = tuple(round(a[i] * (1 - t) + b[i] * t) for i in range(3))
        draw.line((x, 0, x, H), fill=(*shade, 255))
    soft = Image.new("RGBA", (W, H))
    sd = ImageDraw.Draw(soft)
    sd.ellipse((525, 385, 1395, 1255), fill=(*rgb(glow), 175))
    sd.ellipse((-410, 1180, 430, 2020), fill=(255, 255, 255, 95))
    canvas.alpha_composite(soft.filter(ImageFilter.GaussianBlur(95)))

    draw = ImageDraw.Draw(canvas)
    draw.rectangle((0, 0, 9, H), fill=CORAL)
    draw.text((80, 62), "LOOPET", font=font(30), fill=INK)
    draw.text((1000, 64), "02 / 08", font=font(25), fill="#59536D", anchor="ra")
    place_light(canvas)
    draw = ImageDraw.Draw(canvas)
    draw.text((80, 155), "지금 할 루틴을", font=font(82), fill=INK)
    draw.text((80, 258), "바로 확인", font=font(82), fill=INK)
    draw.rounded_rectangle((81, 383, 196, 394), radius=5, fill=CORAL)
    return canvas.convert("RGB")


def main() -> None:
    output = BASE / "light_color_options"
    output.mkdir(parents=True, exist_ok=True)
    contact = Image.new("RGB", (1224, 792), "#F8F6F2")
    draw = ImageDraw.Draw(contact)
    for i, (label, filename, left, right, glow) in enumerate(OPTIONS):
        result = render_option(left, right, glow)
        result.save(output / f"{i+1:02d}_{filename}.png", optimize=True)
        x = 24 + i * 400
        contact.paste(result.resize((360, 640), Image.Resampling.LANCZOS), (x, 24))
        draw.text((x, 680), label, font=font(31), fill=INK)
        draw.text((x, 726), f"{left}  →  {right}", font=font(22), fill="#666278")
    path = BASE / "light_color_options_preview_ko.png"
    contact.save(path, optimize=True)
    print(path)


if __name__ == "__main__":
    main()
