"""Build the offline gallery, comparison cover, and video download bundle."""
from pathlib import Path
from zipfile import ZipFile, ZIP_STORED
from PIL import Image, ImageDraw, ImageFont

BASE = Path(__file__).resolve().parent
STYLES = [
    ("01-pixel-arcade", "arcade", "Pixel Arcade", "Pixel type, playful motion, and chip-style music.", "60fps"),
    ("02-minimal-studio", "minimal", "Minimal Studio", "Quiet space, slow camera moves, and soft piano tones.", "30fps"),
    ("03-daily-scrapbook", "scrapbook", "Daily Scrapbook", "Paper, stickers, little moments, and warm plucked strings.", "30fps"),
    ("04-night-orbit", "night", "Night Orbit", "Moonlight, gentle orbits, and an ambient soundtrack.", "30fps"),
]

canvas = Image.new("RGB", (1180, 630), "#EEECE5")
draw = ImageDraw.Draw(canvas)
font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 23)
small = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 17)
cards = []
for i, (folder, key, title, description, fps) in enumerate(STYLES):
    x = 20+i*290
    draw.text((x, 25), title, font=font, fill="#252535")
    poster = Image.open(BASE/folder/"poster.jpg").resize((270,480), Image.Resampling.LANCZOS)
    canvas.paste(poster, (x,75))
    draw.text((x,582), f"16s / EN / {fps}", font=small, fill="#625F68")
    video = f"{folder}/loopet-{key}-en-16s.mp4"
    cards.append(f'''<article><div class="card-head"><span class="number">0{i+1}</span><h2>{title}</h2></div><video controls playsinline preload="metadata" poster="{folder}/poster.jpg" aria-label="{title} promotional video"><source src="{video}" type="video/mp4"></video><p class="description">{description}</p><div class="card-foot"><span>16s / {fps} / EN</span><a href="{video}" download>Download MP4</a></div></article>''')
canvas.save(BASE/"four-styles-overview.jpg", quality=94)

page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>LOOPET / Four Film Styles</title><style>*{box-sizing:border-box}body{margin:0;background:#f1efe7;color:#252334;font-family:system-ui,-apple-system,sans-serif}main{max-width:1380px;margin:auto;padding:50px 32px}header{display:flex;justify-content:space-between;gap:24px;align-items:end;margin-bottom:38px}.eyebrow{font-size:13px;letter-spacing:.2em;font-weight:750;color:#71607d}h1{font-size:clamp(28px,4vw,48px);letter-spacing:-.04em;margin:12px 0}header p{line-height:1.65;color:#686273;margin:0}.grid{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:22px}article{background:#fffdf7;border:1px solid #ded9ce;border-radius:16px;overflow:hidden}.card-head{display:flex;gap:12px;align-items:center;padding:18px}.number{font-size:27px;color:#a397ae}.card-head h2{font-size:17px;margin:0}video{display:block;width:100%;aspect-ratio:9/16;background:#111;border-top:1px solid #e5ded4;border-bottom:1px solid #e5ded4}.description{font-size:12px;line-height:1.6;padding:0 16px;color:#736c76;min-height:38px}.card-foot{padding:0 16px 20px;display:flex;justify-content:space-between;gap:12px;flex-wrap:wrap;font-size:11px}.card-foot span{color:#87808a}a{color:#5f3bad;font-weight:700;text-decoration:none}a:hover{text-decoration:underline}a:focus-visible{outline:3px solid #947dd0;outline-offset:5px}footer{font-size:12px;line-height:1.8;color:#827a86;margin-top:30px}@media(max-width:1000px){.grid{grid-template-columns:repeat(2,minmax(0,1fr))}}@media(max-width:560px){main{padding:28px 18px}header{display:block}.grid{grid-template-columns:1fr}header p{margin-top:18px}}</style><main><header><div><p class="eyebrow">LOOPET / FILM COLLECTION</p><h1>One day. Four different moods.</h1><p>Explore four new looks, each with its own motion and music.</p></div><p>16 seconds / vertical 1080 x 1920 / English<br>Playing a film pauses the others.</p></header><section class="grid">'''+"".join(cards)+'''</section><footer>Created with actual English app screenshots and approved character artwork.<br>Each film includes an original synthesized soundtrack. No voiceover.</footer></main><script>const videos=[...document.querySelectorAll('video')];videos.forEach(v=>v.addEventListener('play',()=>videos.filter(x=>x!==v).forEach(x=>x.pause())));</script></html>'''
(BASE/"index.html").write_text(page, encoding="utf-8")

notes = '''LOOPET / Four new English video styles

All videos: 16 seconds, vertical 1080 x 1920, H.264/yuv420p MP4,
stereo AAC at 48 kHz, embedded English copy, no narration.

01 Pixel Arcade - 60 fps. Pixelify typography, neon pixel borders, perspective
grid, stepped character motion, block reveals, and 128 BPM chip-style music.
02 Minimal Studio - 30 fps. Ivory and sage, serif typography, a close view of
the actual circular schedule, subtle camera movement, soft dissolves, and
sparse piano/bell tones. Includes actual progress and calendar screens.
03 Daily Scrapbook - 30 fps. Paper grid and grain, taped photo frames,
collage arrangement, 12-step-per-second paper motion, slide transitions,
and 96 BPM warm plucked music with light percussion.
04 Night Orbit - 30 fps. Navy and gold, crescent moon, slow orbiting light,
quiet stars, long dissolves, and ambient pads with sparse bells. The night
visuals are campaign artwork, not a claim that the app has a dark UI mode.

App imagery is captured from actual English Flutter widgets using example
routine data. Original full device and extracted card pixels are preserved;
this is screenshot-based motion design, not a live screen recording.
The cat theme was freshly captured for this collection. The scrapbook uses
the red panda English captures from the previous promo. Additional characters
use approved project assets. No free-purchase claim, store badge, or store URL
has been added. No external music or recorded voice was downloaded.

The four soundtracks are separately synthesized by render_collection.py.
Earlier Korean, English, and dynamic videos are retained unchanged.

Preview: open index.html. Only one video plays at a time.
Rebuild from the repository root:
python3 design/promo/loopet-style-collection-en/render_collection.py

To rebuild one video, add --style arcade, minimal, scrapbook, or night.
To render storyboards only, add --preview.
'''
(BASE/"production-notes.txt").write_text(notes, encoding="utf-8")

videos = [BASE/folder/f"loopet-{key}-en-16s.mp4" for folder,key,*_ in STYLES]
if all(p.exists() for p in videos):
    files = [BASE/"index.html", BASE/"production-notes.txt", BASE/"four-styles-overview.jpg"]
    for (folder,*_),video in zip(STYLES,videos):
        files += [video,BASE/folder/"poster.jpg",BASE/folder/"storyboard.jpg"]
    with ZipFile(BASE/"loopet-four-styles-en.zip", "w", ZIP_STORED) as archive:
        for p in files: archive.write(p, p.relative_to(BASE))
    print(BASE/"loopet-four-styles-en.zip")
print(BASE/"index.html")
