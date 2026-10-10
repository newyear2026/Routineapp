"""Render a 15-second Korean LOOPET promo from existing project assets.

Requires Python 3, Pillow, ffmpeg, and the macOS Apple SD Gothic Neo font.
Run with --preview for a contact sheet, or without arguments for H.264 MP4.
The soundtrack is synthesized here; no downloaded music or voice is used.
"""

from __future__ import annotations

import argparse
import array
import functools
import math
from pathlib import Path
import subprocess
import wave

from PIL import Image, ImageDraw, ImageFilter, ImageFont

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[2]
ASSETS = ROOT / "flutter_app/assets"
SOURCE = ASSETS / "store/screenshots/marketing/cinematic/redpanda/source/play/ko"
W, H, FPS, DURATION = 1080, 1920, 30, 15
CREAM = "#FFF8ED"
INK = "#234F45"
ORANGE = "#DD794C"
MUTED = "#69827A"
FONT = "/System/Library/Fonts/AppleSDGothicNeo.ttc"


def ease(t):
    t = max(0.0, min(1.0, t))
    return 1 - (1 - t) ** 3


@functools.lru_cache(maxsize=64)
def font(size, bold=True):
    return ImageFont.truetype(FONT, size, index=14 if bold else 0)


@functools.lru_cache(maxsize=128)
def lettering(value, size, fill=INK, bold=True):
    f = font(size, bold)
    box = f.getbbox(value)
    layer = Image.new("RGBA", (box[2] - box[0] + 12, box[3] - box[1] + 12))
    ImageDraw.Draw(layer).text((6 - box[0], 6 - box[1]), value, font=f, fill=fill)
    return layer


def place(canvas, layer, x, y, opacity=1.0, scale=1.0, centered=True):
    if scale != 1:
        layer = layer.resize((max(1, round(layer.width * scale)), max(1, round(layer.height * scale))), Image.Resampling.LANCZOS)
    if opacity < 1:
        layer = layer.copy()
        layer.putalpha(layer.getchannel("A").point(lambda a: round(a * max(0, opacity))))
    if centered:
        x -= layer.width / 2
        y -= layer.height / 2
    canvas.alpha_composite(layer, (round(x), round(y)))


def text(canvas, value, size, x, y, fill=INK, alpha=1.0, centered=True, bold=True):
    place(canvas, lettering(value, size, fill, bold), x, y, opacity=alpha, centered=centered)


@functools.lru_cache(maxsize=32)
def pill(value, size=36, color=INK, fill="#FFFFFF", border=None):
    label = lettering(value, size, color)
    panel = Image.new("RGBA", (label.width + 70, label.height + 40))
    ImageDraw.Draw(panel).rounded_rectangle((1, 1, panel.width - 2, panel.height - 2), panel.height // 2, fill=fill, outline=border, width=2)
    place(panel, label, panel.width / 2, panel.height / 2 - 1)
    return panel


def cutout(name, width):
    img = Image.open(ASSETS / f"characters/redpanda_teashop/v1/approved/{name}.png").convert("RGBA")
    img = img.crop(img.getchannel("A").getbbox())
    return img.resize((width, round(width * img.height / img.width)), Image.Resampling.NEAREST)


def phone(name, width=530):
    original = Image.open(SOURCE / f"{name}.png").convert("RGBA")
    # Bounds of the full device in the existing Flutter marketing capture.
    original = original.crop((172, 248, 910, 1810))
    mask = Image.new("L", original.size)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, original.width - 1, original.height - 1), 111, fill=255)
    original.putalpha(mask)
    body = original.resize((width, round(width * original.height / original.width)), Image.Resampling.LANCZOS)
    stage = Image.new("RGBA", (body.width + 150, body.height + 160))
    shadow = Image.new("RGBA", stage.size)
    shadow.paste((27, 62, 48, 65), (75, 85), body.getchannel("A"))
    stage.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(26)))
    stage.alpha_composite(body, (75, 45))
    return stage


GUIDE = cutout("guide", 455)
COMPLETE = cutout("complete", 285)
PHONES = [phone("01_home"), phone("02_progress")]
ICON = Image.open(ASSETS / "icon/app_icon.png").convert("RGBA").resize((216, 216), Image.Resampling.LANCZOS)
icon_mask = Image.new("L", ICON.size)
ImageDraw.Draw(icon_mask).rounded_rectangle((0, 0, 215, 215), 48, fill=255)
ICON.putalpha(icon_mask)


@functools.lru_cache(maxsize=4)
def background(scene):
    colors = [CREAM, "#F7F4EA", "#EDF3EC", INK]
    im = Image.new("RGBA", (W, H), colors[scene])
    d = ImageDraw.Draw(im)
    if scene < 3:
        d.ellipse((-390, 1130, 470, 2020), fill="#E1EAE0")
        d.ellipse((760, -160, 1490, 570), fill="#F7E6D6")
        d.arc((-600, 980, 880, 2390), 196, 325, fill="#CFDED3", width=2)
        d.arc((665, -320, 1395, 640), 80, 245, fill="#E9CDB9", width=2)
    else:
        d.ellipse((-450, 1170, 450, 2100), fill="#2C5B4F")
        d.ellipse((785, -320, 1560, 610), fill="#2B594E")
        d.arc((-290, 1130, 930, 2350), 190, 335, fill="#547265", width=2)
        d.arc((560, -450, 1600, 650), 40, 220, fill="#547265", width=2)
    return im


def sparkle(canvas, x, y, r, color):
    d = ImageDraw.Draw(canvas)
    d.polygon([(x, y-r), (x+r*.24, y-r*.24), (x+r, y), (x+r*.24, y+r*.24), (x, y+r), (x-r*.24, y+r*.24), (x-r, y), (x-r*.24, y-r*.24)], fill=color)


def heading(canvas, first, second, t, second_color=ORANGE):
    a = ease(t / .5)
    b = ease((t - .12) / .55)
    text(canvas, first, 87, 540, 300 + 30 * (1-a), alpha=a)
    text(canvas, second, 101, 540, 415 + 30 * (1-b), fill=second_color, alpha=b)


def render_scene(scene, t):
    canvas = background(scene).copy()
    brand_color = INK if scene < 3 else "#E2EADF"
    text(canvas, "LOOPET", 35, 100, 143, brand_color, centered=False)
    if scene < 3:
        d = ImageDraw.Draw(canvas)
        for i in range(3):
            cx = 891 + 25 * i
            d.ellipse((cx, 157, cx+8, 165), fill=ORANGE if scene == i else "#CFD7CC")

    if scene == 0:
        heading(canvas, "하루가,", "조금 더 귀엽게.", t)
        d = ImageDraw.Draw(canvas)
        radius = 352
        box = (540-radius, 1010-radius, 540+radius, 1010+radius)
        d.ellipse(box, fill="#E5EBDE", outline="#D2DFD1", width=3)
        d.ellipse((239, 709, 841, 1311), outline="#FAF9EF", width=12)
        d.arc((239, 709, 841, 1311), -90, -90 + 270*ease(t/2.2), fill=ORANGE, width=12)
        for i in range(12):
            angle = i * math.tau / 12 - math.pi/2
            x, y = 540+328*math.cos(angle), 1010+328*math.sin(angle)
            d.ellipse((x-3, y-3, x+3, y+3), fill="#87A698")
        reveal = ease((t-.15)/.65)
        place(canvas, GUIDE, 540, 1022+14*math.sin(t*2.4)+50*(1-reveal), opacity=reveal, scale=.95+.05*reveal)
        for i, (label, x, y) in enumerate([("기상", 240, 790), ("휴식", 845, 1045), ("독서", 280, 1280)]):
            alpha = ease((t-.45-i*.18)/.4)
            place(canvas, pill(label, 32), x, y+12*(1-alpha), opacity=alpha)
        sparkle(canvas, 835, 743, 23+3*math.sin(t*3), ORANGE)
        sparkle(canvas, 180, 1105, 16, "#9CB5A0")
        text(canvas, "작은 루틴, 포근한 하루", 43, 540, 1530, alpha=ease((t-.65)/.6), bold=False)
    elif scene in (1, 2):
        if scene == 1:
            heading(canvas, "오늘의 루틴을", "한눈에.", t)
        else:
            heading(canvas, "작은 완료가", "쌓이는 하루.", t, INK)
        enter = ease(t/.7)
        obj = PHONES[scene-1]
        # Gentle camera movement keeps the authentic app capture readable.
        scale = .95 + .025*enter + .025*min(t/4, 1)
        place(canvas, obj, 540, 1100+100*(1-enter)-8*math.sin(t*.8), opacity=enter, scale=scale)
        if scene == 1:
            label = "24시간 원형 시간표"
        else:
            label = "오늘의 진행 상황을 차곡차곡"
        text(canvas, label, 34, 540, 1738, MUTED, alpha=ease((t-.4)/.55), bold=False)
        if scene == 2 and t > 1.0:
            a = ease((t-1)/.45)
            sparkle(canvas, 180, 800, 19*a, ORANGE)
            sparkle(canvas, 890, 1420, 23*a, "#83A894")
    else:
        a = ease(t/.65)
        text(canvas, "나만의 리듬으로,", 76, 540, 320+25*(1-a), CREAM, alpha=a)
        text(canvas, "오늘도 함께.", 85, 540, 425+25*(1-a), "#F1BC8C", alpha=a)
        place(canvas, ICON, 540, 668+30*(1-a), opacity=a)
        text(canvas, "LOOPET", 133, 540, 875, CREAM, alpha=ease((t-.12)/.6))
        text(canvas, "귀여운 하루 루틴 메이트", 38, 540, 1005, "#CBDACB", alpha=ease((t-.28)/.6), bold=False)
        b = ease((t-.35)/.7)
        place(canvas, COMPLETE, 540, 1260+35*(1-b)+7*math.sin(t*2.6), opacity=b)
        sparkle(canvas, 312, 1232, 19+3*math.sin(t*3), "#F0BE89")
        sparkle(canvas, 765, 1185, 23, "#F0BE89")
        c = ease((t-.7)/.55)
        place(canvas, pill("오늘의 루틴을 시작해요", 43, INK, "#F5C595"), 540, 1525+20*(1-c), opacity=c)
        text(canvas, "루틴 · 원형 시간표 · 진행 기록", 31, 540, 1705, "#BFD1C1", alpha=c, bold=False)
    return canvas.convert("RGB")


def frame(t):
    boundaries = [(0, 0), (3, 1), (7, 2), (11, 3)]
    start, scene = max((p for p in boundaries if p[0] <= t), key=lambda p: p[0])
    current = render_scene(scene, t-start + (.75 if scene > 0 else 0))
    # 0.3-second dissolves before the next scene, with static outgoing copy.
    if scene < 3:
        next_start = boundaries[scene+1][0]
        if t >= next_start-.3:
            incoming = render_scene(scene+1, .45 + t - (next_start-.3))
            current = Image.blend(current, incoming, (t-(next_start-.3))/.3)
    # Skip repeating the entrance after a dissolve has introduced a new scene.
    return current


def music():
    rate = 32000
    total = int(rate*DURATION)
    left, right = array.array("f", [0])*total, array.array("f", [0])*total

    def add_note(midi, start, seconds, volume, pan=0, pad=False):
        hz = 440 * 2 ** ((midi-69)/12)
        begin = int(start*rate)
        count = min(int(seconds*rate), total-begin)
        for i in range(count):
            tm = i/rate
            if pad:
                env = min(1, tm/.3) * min(1, (seconds-tm)/.5) * .5
                sig = math.sin(math.tau*hz*tm) + .18*math.sin(math.tau*hz*2*tm)
            else:
                env = min(1, tm/.012) * math.exp(-3.2*tm) * min(1, (seconds-tm)/.08)
                sig = math.sin(math.tau*hz*tm) + .27*math.sin(math.tau*hz*2*tm)*math.exp(-4*tm) + .1*math.sin(math.tau*hz*3*tm)*math.exp(-6*tm)
            val = sig*env*volume
            left[begin+i] += val*(1-pan*.3)
            right[begin+i] += val*(1+pan*.3)

    for bar, chord in enumerate([(48,55,64), (53,60,69), (45,52,60), (43,55,62), (48,55,64), (48,55,60)]):
        for j, note in enumerate(chord):
            add_note(note, bar*2.5, 2.9, .038, (j-1)*.65, True)
    melody = [(0.12,72),(.745,76),(1.37,79),(2.0,76),(3.12,77),(4.37,76),(5.62,72),(6.245,76),(7.12,74),(8.37,71),(9.62,67),(11.12,72),(11.745,76),(12.37,79),(13.62,84)]
    for i, (when, note) in enumerate(melody):
        add_note(note, when, 1.25, .13, (-1 if i%2 else 1)*.45)
        add_note(note, when+.16, 1.1, .023, (-1 if i%2 else 1)*-.5)
    samples = array.array("h")
    for i in range(total):
        tm = i/rate
        fade = min(1, tm/.08, max(0, (DURATION-tm)/1.0))
        samples.append(round(max(-1,min(1,left[i]*fade))*32767))
        samples.append(round(max(-1,min(1,right[i]*fade))*32767))
    with wave.open(str(OUT/"soundtrack.wav"), "wb") as audio:
        audio.setnchannels(2)
        audio.setsampwidth(2)
        audio.setframerate(rate)
        audio.writeframes(samples.tobytes())


def previews():
    times = [.9, 2.4, 4.7, 8.8, 12.8, 14.3]
    sheet = Image.new("RGB", (6*270+7*16, 480+80), "#E9E8DD")
    for i, tm in enumerate(times):
        shot = frame(tm)
        shot.save(OUT/f"preview-{i+1:02}.jpg", quality=93)
        sheet.paste(shot.resize((270,480), Image.Resampling.LANCZOS), (16+i*286, 16))
        ImageDraw.Draw(sheet).text((16+i*286, 510), f"{tm:04.1f}s", font=font(22), fill=INK)
    sheet.save(OUT/"storyboard.jpg", quality=92)
    frame(1.8).save(OUT/"poster.jpg", quality=95)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--preview", action="store_true")
    args = parser.parse_args()
    previews()
    if args.preview:
        print(OUT/"storyboard.jpg")
        return
    music()
    output = OUT/"loopet-promo-ko-15s.mp4"
    cmd = ["ffmpeg", "-hide_banner", "-loglevel", "warning", "-y", "-f", "rawvideo", "-pixel_format", "rgb24", "-video_size", f"{W}x{H}", "-framerate", str(FPS), "-i", "pipe:0", "-i", str(OUT/"soundtrack.wav"), "-c:v", "libx264", "-preset", "fast", "-crf", "19", "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-af", "loudnorm=I=-19:TP=-2:LRA=7", "-t", str(DURATION), "-movflags", "+faststart", "-metadata", "title=LOOPET — 귀여운 하루 루틴 메이트", str(output)]
    with subprocess.Popen(cmd, stdin=subprocess.PIPE) as process:
        for index in range(FPS*DURATION):
            process.stdin.write(frame(index/FPS).tobytes())
            if index%90 == 0:
                print(f"Rendered {index}/{FPS*DURATION} frames", flush=True)
        process.stdin.close()
        code = process.wait()
        if code:
            raise SystemExit(code)
    print(output, flush=True)


if __name__ == "__main__":
    main()
