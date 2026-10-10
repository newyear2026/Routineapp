"""Encode actual Flutter screen captures as time-of-day GIF review boards."""
import argparse
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageChops

parser = argparse.ArgumentParser()
parser.add_argument('--frames', default='/private/tmp/loopet-motion-frames')
args = parser.parse_args()
source = Path(args.frames)
out = Path(__file__).resolve().parents[1] / 'design/pack-motion-previews'
out.mkdir(parents=True, exist_ok=True)
font = ImageFont.truetype('/System/Library/Fonts/Supplemental/AppleGothic.ttf', 24)
small = ImageFont.truetype('/System/Library/Fonts/Supplemental/AppleGothic.ttf', 19)
packs = {
 'cat_starlight': ('별빛 고양이', '하늘의 별빛 반짝임'),
 'poodle_garden': ('푸들 정원', '이슬 · 꽃가루와 나비 · 꽃잎 · 반딧불'),
 'squirrel_explorer': ('탐험가 다람쥐', '기존 숲 움직임 / 비교용'),
 'cat_stargazer': ('유성 관측 고양이', '빛 반짝임 · 밤의 짧은 유성'),
 'rabbit_postman': ('우편배달부 토끼', '꽃잎 · 낮의 나비 · 밤의 반딧불'),
 'sheep_mooncloud': ('달구름 양', '작은 구름 조각 · 밤의 별빛'),
 'redpanda_teashop': ('찻집 랫서팬더', '창가의 빗방울 · 찻잔 위의 김'),
 'otter_seaside': ('햇살 해달', '수면 반짝임 · 밤의 별빛'),
}
phases = [('morning','아침 05–11'),('day','낮 11–17'),('sunset','노을 17–20'),('night','밤 20–05')]
report = []
for pack,(name,description) in packs.items():
 frames=[]
 for i in range(30):
  board=Image.new('RGB',(1170,1092),'#FFF9EF')
  d=ImageDraw.Draw(board)
  d.text((18,10),f'{name} — {description}',font=font,fill='#251E44')
  for j,(phase,label) in enumerate(phases):
   x=(j%2)*585; y=52+(j//2)*520
   d.text((x+18,y+4),label,font=small,fill='#5E587C')
   capture=Image.open(source/pack/phase/f'{i:03d}.png').convert('RGB')
   # Show header and focus card at 1.5x, without changing any UI pixels.
   board.paste(capture.crop((0,0,585,480)),(x,y+34))
  frames.append(board)
 # Keep one palette for all frames so the fixed artwork does not flicker.
 palette=frames[0].quantize(colors=256,method=Image.Quantize.MEDIANCUT)
 encoded=[f.quantize(palette=palette,dither=Image.Dither.NONE) for f in frames]
 encoded[0].save(out/f'{pack}.gif',save_all=True,append_images=encoded[1:],
                 duration=200,loop=0,optimize=False,disposal=1)
 frames[0].save(out/f'{pack}-poster.png')
 delta=ImageChops.difference(frames[0],frames[10])
 assert delta.getbbox(), f'{pack}: no motion in captured frames'
 report.append(f'{pack}: 30 frames / 6 s / {(out / (pack + ".gif")).stat().st_size // 1024} KB')
print('\n'.join(report))
(out/'README.md').write_text('''# 캐릭터 팩 움직임 시안

실제 Flutter `HomeScreen`의 상단과 카드 영역을 캡처한 GIF입니다.
한 팩에 아침·낮·노을·밤을 2×2로 배치했습니다. 200ms 간격 30프레임,
6초 반복이며 GIF에서는 실제 앱보다 프레임 수가 적습니다.
배경 원화는 고정이고 작은 효과와 기존 캐릭터 동작만 움직입니다.
고정 팔레트를 사용하여 GIF 색 양자화로 생기는 배경 깜빡임을 줄였습니다.

재생성:
```
flutter test --no-pub tool/render_pack_time_scenes.dart \\
  --dart-define=PREVIEW_FONT=/System/Library/Fonts/Supplemental/AppleGothic.ttf \\
  --dart-define=RENDER_MOTION=true \\
  --dart-define=AUDIT_OUTPUT_DIR=/private/tmp/loopet-motion-frames
python3 tool/build_pack_motion_boards.py
```
''')
