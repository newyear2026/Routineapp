"""Arrange actual Flutter captures for review; does not generate artwork."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

root = Path(__file__).resolve().parents[1] / 'design/remaining-pack-scenes'
font = ImageFont.truetype('/System/Library/Fonts/Supplemental/AppleGothic.ttf', 22)
packs = {
    'cat_stargazer': '유성 관측 고양이',
    'rabbit_postman': '우편배달부 토끼',
    'sheep_mooncloud': '달구름 양',
    'redpanda_teashop': '찻집 랫서팬더',
    'otter_seaside': '햇살 해달',
}
phases = [('morning', '아침 05–11'), ('day', '낮 11–17'),
          ('sunset', '노을 17–20'), ('night', '밤 20–05')]

def capture(pack, phase):
    return Image.open(root / 'previews' / pack / f'{phase}.png').convert('RGB').resize(
        (390, 844), Image.Resampling.LANCZOS)

for pack, name in packs.items():
    board = Image.new('RGB', (1560, 884), '#FFF9EF')
    draw = ImageDraw.Draw(board)
    for i, (phase, label) in enumerate(phases):
        board.paste(capture(pack, phase), (i * 390, 40))
        draw.text((i * 390 + 12, 10), label, fill='#251E44', font=font)
    board.save(root / f'{pack}-four-phases.png')

for phase in ['day', 'night']:
    board = Image.new('RGB', (1950, 884), '#FFF9EF')
    draw = ImageDraw.Draw(board)
    for i, (pack, name) in enumerate(packs.items()):
        board.paste(capture(pack, phase), (i * 390, 40))
        draw.text((i * 390 + 12, 10), name, fill='#251E44', font=font)
    board.save(root / f'all-packs-{phase}.png')
