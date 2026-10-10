"""Spanish localization of the approved Pixel Arcade promotional video.

Reuses the English video's motion and original music; all visible copy and
the actual Flutter app captures are Spanish. Does not modify earlier videos.
"""
from __future__ import annotations

import argparse
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent
EN = OUT.parent / "loopet-style-collection-en"
spec = importlib.util.spec_from_file_location("collection", EN / "render_collection.py")
base = importlib.util.module_from_spec(spec)
spec.loader.exec_module(base)

COPY = {
    "LOOPET": "LOOPET",
    "DAILY ROUTINE": "TU RUTINA DIARIA",
    "READY, SET,": "¡TODO LISTO!",
    "ROUTINE.": "¡A EMPEZAR!",
    "YOUR DAY STARTS HERE": "TU DÍA EMPIEZA AQUÍ",
    "PLAN YOUR": "PLANEA TU",
    "NEXT MOVE.": "PRÓXIMO PASO.",
    "24 HOURS / ONE CIRCLE": "24 HORAS / UN CÍRCULO",
    "ONE ROUTINE": "UNA RUTINA",
    "AT A TIME.": "A LA VEZ.",
    "LITTLE WINS COUNT.": "CADA LOGRO CUENTA.",
    "MAKE IT": "A TU",
    "YOURS.": "ESTILO.",
    "PICK A LITTLE COMPANION": "ELIGE TU COMPAÑERO",
    "Extra character packs available": "Hay packs de personajes adicionales",
    "LET'S DO TODAY.": "¡VAMOS POR HOY!",
    "Your daily routine buddy.": "Tu compañero de rutinas.",
    "START YOUR ROUTINE": "EMPIEZA TU RUTINA",
    "PLAN  /  DO  /  REPEAT": "PLANEA  /  HAZ  /  REPITE",
}

original_txt, original_label = base.txt, base.label


def fitted_size(value, size, kind, width):
    while base.letters(value, size, "#FFFFFF", kind).width > width:
        size -= 1
        if size < 18:
            raise ValueError(f"Spanish copy cannot fit: {value}")
    return size


def translated_txt(im, value, size, x, y, color, kind="bold", **kwargs):
    translated = COPY[value]  # Fail visibly if any new English copy is missed.
    width = 880
    if value == "DAILY ROUTINE":
        width = 285
    elif value == "LITTLE WINS COUNT.":
        width = 610
    elif value == "START YOUR ROUTINE":
        width = 660
    size = fitted_size(translated, size, kind, width)
    return original_txt(im, translated, size, x, y, color, kind, **kwargs)


def translated_label(value, fill, color, size=34, kind="sans", square=False):
    translated = COPY[value]
    size = fitted_size(translated, size, kind, 790)
    return original_label(translated, fill, color, size, kind, square)


base.txt, base.label = translated_txt, translated_label
base.helper.SCREENS = OUT / "source/play/es"
base.HOME = base.helper.phone("01_home", 560)
base.STAT = base.helper.screen_card("02_progress", (228,826,854,1060), 790)
base.ROW1 = base.helper.screen_card("02_progress", (228,1147,854,1284), 740)
base.ROW2 = base.helper.screen_card("02_progress", (228,1288,854,1423), 740)


def preview():
    cuts = base.STYLES["arcade"]["cuts"]
    times = [(cuts[i] + cuts[i+1])/2 for i in range(len(cuts)-1)]
    sheet = Image.new("RGB", (1434,548), "#EAE9E2")
    for i,t in enumerate(times):
        frame = base.frame("arcade", t)
        frame.save(OUT / f"scene-{i+1:02}.jpg", quality=94)
        sheet.paste(frame.resize((270,480), Image.Resampling.LANCZOS), (14+i*284,14))
        ImageDraw.Draw(sheet).text((14+i*284,508), f"{t:.1f}s", font=base.font("sans",22), fill="#252533")
    sheet.save(OUT / "storyboard.jpg", quality=94)
    base.frame("arcade",1.25).save(OUT / "poster.jpg", quality=94)
    (OUT / "spanish-copy.json").write_text(json.dumps(COPY, ensure_ascii=False, indent=2), encoding="utf-8")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--preview", action="store_true")
    args = parser.parse_args()
    preview()
    if args.preview:
        print(OUT / "storyboard.jpg")
        return
    soundtrack = OUT / "soundtrack.wav"
    shutil.copyfile(EN / "01-pixel-arcade/soundtrack.wav", soundtrack)
    output = OUT / "loopet-pixel-arcade-es-16s.mp4"
    cmd = [
        "ffmpeg", "-hide_banner", "-loglevel", "warning", "-y",
        "-f", "rawvideo", "-pixel_format", "rgb24", "-video_size", "1080x1920",
        "-framerate", "60", "-i", "pipe:0", "-i", str(soundtrack),
        "-c:v", "libx264", "-threads", "4", "-preset", "fast", "-crf", "19",
        "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "192k", "-ar", "48000",
        "-af", "loudnorm=I=-16:TP=-2:LRA=7", "-t", "16", "-movflags", "+faststart",
        "-metadata", "title=LOOPET - Arcade pixel art - Español",
        "-metadata:s:v:0", "language=spa", str(output),
    ]
    with subprocess.Popen(cmd, stdin=subprocess.PIPE) as process:
        for i in range(960):
            process.stdin.write(base.frame("arcade",i/60).tobytes())
            if i % 240 == 0:
                print(f"Spanish arcade: {i}/960 frames rendered", flush=True)
        process.stdin.close()
        code = process.wait()
        if code:
            raise SystemExit(code)
    print(output, flush=True)


if __name__ == "__main__":
    main()
