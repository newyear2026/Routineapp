#!/usr/bin/env python3
"""홈 캐릭터 모션 시안을 GIF로 그린다.

그림은 앱이 쓰는 다람쥐 포즈 PNG 6장을 그대로 쓰고, 움직임은 앱에서도
Transform·작은 픽셀 스프라이트만으로 낼 수 있는 것으로 한정한다.

    python3 design/home-character-motion-concepts/render-motion-board.py
"""
import os
import subprocess
import tempfile

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, '..', '..'))
CHAR_DIR = os.path.join(ROOT, 'assets/characters/squirrel_explorer/v1/approved')
CARD_BG = os.path.join(ROOT, 'assets/pack_backgrounds/squirrel-home-card.png')
HOME_SHOT = os.path.join(ROOT, 'design/squirrel-menu-flow-concepts/01-home-forest-card.png')
FONT = '/System/Library/Fonts/AppleSDGothicNeo.ttc'

FPS = 12
N = 72  # 6초 한 바퀴

# CharacterArtwork.byCharacter['squirrel_explorer'] 와 같은 값.
BOUNDS = {
    'idle': (36, 46, 332, 368),
    'activity': (23, 48, 334, 370),
    'focus': (35, 74, 348, 372),
    'complete': (36, 32, 377, 340),
    'rest': (34, 56, 357, 337),
    'guide': (11, 28, 356, 340),
}
POSES = {p: Image.open(os.path.join(CHAR_DIR, f'{p}.png')).convert('RGBA') for p in BOUNDS}

SP = 4  # 효과 스프라이트 한 칸 크기(px)
INK = (38, 33, 74)
PAPER = (247, 242, 230)
MUTED = (107, 100, 136)
PURPLE = (122, 111, 184)

# 앱의 홈 카드 고양이 자리(88×96dp)를 스크린샷 배율(약 2.16px/dp)로 옮긴 크기.
BOX_W, BOX_H = 190, 207


def font(size, weight=0):
    return ImageFont.truetype(FONT, size, index={0: 0, 1: 4, 2: 6}[weight])


# ---------------------------------------------------------------- 스프라이트
PALETTE = {
    'k': (43, 35, 30), 'R': (240, 110, 135), 'W': (255, 236, 240),
    'Y': (247, 201, 72), 'w': (255, 250, 222), 'Z': PURPLE, 'z': (196, 189, 236),
    'D': (240, 231, 208), 'O': (196, 176, 138), 'I': (74, 63, 107),
}
HEART = ['.kk...kk.', 'kRRk.kRRk', 'kRWRkRRRk', 'kRRRRRRRk',
         '.kRRRRRk.', '..kRRRk..', '...kRk...', '....k....']
SPARK_S = ['..Y..', '..Y..', 'YYwYY', '..Y..', '..Y..']
SPARK_L = ['...Y...', '...Y...', '..YwY..', 'YYwwwYY', '..YwY..', '...Y...', '...Y...']
ZED = ['ZZZZZ', '...Zz', '..Zz.', '.Zz..', 'ZZZZZ']
DUST_S = ['.D.', 'DDD', '.D.']
DUST_L = ['.OOO.', 'ODDDO', 'ODDDO', '.OOO.']


def sprite(img, grid, cx, cy, p):
    """grid 를 (cx, cy) 가운데에 칸 하나 p 픽셀로 찍는다."""
    d = ImageDraw.Draw(img)
    h, w = len(grid), len(grid[0])
    x0, y0 = round(cx - w * p / 2), round(cy - h * p / 2)
    for j, row in enumerate(grid):
        for i, ch in enumerate(row):
            if ch != '.':
                d.rectangle([x0 + i * p, y0 + j * p, x0 + (i + 1) * p - 1,
                             y0 + (j + 1) * p - 1], fill=PALETTE[ch])


def ring(img, cx, cy, r, color, p=3):
    """픽셀 칸에 맞춘 원 테두리."""
    d = ImageDraw.Draw(img)
    seen = set()
    for a in range(0, 360, 4):
        import math
        x = round((cx + r * math.cos(math.radians(a))) / p) * p
        y = round((cy + r * math.sin(math.radians(a))) / p) * p
        if (x, y) not in seen:
            seen.add((x, y))
            d.rectangle([x, y, x + p - 1, y + p - 1], fill=color)


# ---------------------------------------------------------------- 캐릭터
_cache = {}


def placed(pose, dw=0, dh=0):
    """포즈를 앱과 같은 배율로 줄이고, 보이는 그림 폭·높이를 dw·dh 픽셀만큼 늘인다."""
    key = (pose, dw, dh)
    if key not in _cache:
        l, t, r, b = BOUNDS[pose]
        bw, bh = r - l, b - t
        s = min(BOX_W / bw, BOX_H / bh) * .94
        sx = 1 + dw / (bw * s)
        sy = 1 + dh / (bh * s)
        size = (round(384 * s * sx), round(384 * s * sy))
        im = POSES[pose].resize(size, Image.BOX)
        anchor = ((l + r) / 2 * s * sx, b * s * sy)
        _cache[key] = (im, anchor, s)
    return _cache[key]


def src_point(pose, sx, sy, ax, ay, state):
    """원본 384 좌표의 한 점이 무대에서 어디 놓이는지."""
    l, t, r, b = BOUNDS[pose]
    _, _, s = placed(pose)
    return (ax + (sx - (l + r) / 2) * s + state.get('dx', 0),
            ay + (sy - b) * s + state.get('dy', 0))


def draw_character(stage, state, ax, ay):
    pose = state['pose']
    im, (cx, cy), s = placed(pose, state.get('dw', 0), state.get('dh', 0))
    dx, dy = state.get('dx', 0), state.get('dy', 0)
    # 그림자: 뛰어오르면 작아진다.
    l, _, r, _ = BOUNDS[pose]
    w = (r - l) * s * .62 * (1 - min(-dy, 24) / 48)
    shadow = Image.new('RGBA', stage.size)
    sd = ImageDraw.Draw(shadow)
    sd.ellipse([ax - w / 2, ay - 6, ax + w / 2, ay + 6], fill=(70, 86, 40, 70))
    stage.alpha_composite(shadow)
    stage.alpha_composite(im, (round(ax - cx + dx), round(ay - cy + dy)))


def breathe(t, period=24, amp=3):
    steps = [0, 0, 0, 1, 2, 3, 3, 3, 2, 1, 0, 0]
    return round(steps[int((t % period) / period * 12)] * amp / 3)


HOP = {  # 프레임: (dy, dw, dh)
    0: (0, 3, -4), 1: (0, 3, -4), 2: (-8, -2, 3), 3: (-14, -1, 2), 4: (-16, 0, 0),
    5: (-16, 0, 0), 6: (-14, 0, 0), 7: (-8, -1, 2), 8: (0, 3, -4), 9: (0, 2, -2),
}


def hop_state(k):
    dy, dw, dh = HOP[k]
    return {'dy': dy, 'dw': dw, 'dh': dh}


# ---------------------------------------------------------------- 모션 8가지
# 각 함수는 (상태, 그 위에 그릴 효과 함수 목록)을 낸다.

def m_idle(t):
    return {'pose': 'idle', 'dh': breathe(t)}, []


def m_activity(t):
    # 2초 동안 총총 네 걸음, 4초 쉰다.
    if t < 24:
        k = t % 6
        dy = [0, -2, -4, -4, -2, 0][k]
        st = {'pose': 'activity', 'dy': dy, 'dw': 2 if k == 0 else 0, 'dh': -2 if k == 0 else 0}
    else:
        st = {'pose': 'activity', 'dh': breathe(t - 24)}
    fx = []
    for land in range(0, 30, 6):
        age = t - land
        if 0 <= age < 5 and land < 24:
            def f(img, ax, ay, age=age):
                x, y = src_point('activity', 90, 362, ax, ay, {})
                sprite(img, DUST_L if age < 2 else DUST_S, x - 6 - age * 4, y - 4 - age, SP)
            fx.append(f)
    return st, fx


def m_focus(t):
    st = {'pose': 'focus', 'dh': breathe(t, 36, 2)}
    if 30 <= t < 34:
        st['dy'] = 2  # 고개 끄덕
    fx = []
    dots = sum(t >= f for f in (6, 14, 22)) if t < 46 else 0

    def f_dots(img, ax, ay):
        x, y = src_point('focus', 320, 80, ax, ay, st)
        for i in range(dots):
            sprite(img, ['II', 'II'], x + 10 + i * 16, y - 4, SP)
    fx.append(f_dots)
    if 50 <= t < 58:
        def f_glint(img, ax, ay):
            x, y = src_point('focus', 318, 250, ax, ay, st)
            sprite(img, SPARK_L if 52 <= t < 56 else SPARK_S, x, y, SP)
        fx.append(f_glint)
    return st, fx


def m_rest(t):
    st = {'pose': 'rest', 'dh': breathe(t, 36, 3)}
    fx = []
    for born in (0, 24, 48):
        age = (t - born) % N
        if age < 30:
            def f(img, ax, ay, age=age):
                x, y = src_point('rest', 340, 70, ax, ay, st)
                p = 3 if age < 8 else SP
                sprite(img, ZED, x + (age // 4) * 3, y - (age // 3) * 4, p)
            fx.append(f)
    return st, fx


def m_guide(t):
    st = {'pose': 'guide', 'dh': breathe(t)}
    if 12 <= t < 20:
        st = {'pose': 'guide', 'dx': [2, 4, 2, 0, 2, 4, 2, 0][t - 12]}
    fx = []
    if 13 <= t < 24 and (t // 2) % 2 == 0:
        def f(img, ax, ay):
            x, y = src_point('guide', 356, 205, ax, ay, st)
            sprite(img, SPARK_L if t < 18 else SPARK_S, x + 16, y - 6, SP)
        fx.append(f)
    return st, fx


def m_hop(t):
    st = {'pose': 'idle', 'dh': breathe(t)}
    if 30 <= t < 40:
        st = {'pose': 'idle', **hop_state(t - 30)}
    fx = []
    if 38 <= t < 44:
        age = t - 38

        def f(img, ax, ay):
            for side in (-1, 1):
                sprite(img, DUST_L if age < 3 else DUST_S, ax + side * (58 + age * 5), ay - 4 - age, SP)
        fx.append(f)
    return st, fx


def m_tap(t):
    st = {'pose': 'idle', 'dh': breathe(t)}
    if 14 <= t < 24:
        st = {'pose': 'idle', **hop_state(t - 14)}
    fx = []
    if 14 <= t < 20:
        r = 10 + (t - 14) * 7

        def f_ring(img, ax, ay):
            x, y = src_point('idle', 184, 260, ax, ay, {})
            ring(img, x, y, r, (255, 255, 255))
            ring(img, x, y, r + 4, PURPLE)
        fx.append(f_ring)
    if 17 <= t < 42 and not (36 <= t and t % 2):
        def f_heart(img, ax, ay):
            x, y = src_point('idle', 300, 40, ax, ay, {})
            p = {17: 3, 18: 6}.get(t, SP)
            sprite(img, HEART, x + 6, y - 6 - (t - 17) // 2 * 2, p)
        fx.append(f_heart)
    return st, fx


def m_complete(t):
    if t < 18 or t >= 61:
        st = {'pose': 'idle', 'dh': breathe(t)}
    elif t < 20:
        st = {'pose': 'idle', 'dw': 3, 'dh': -4}
    elif t < 28:
        dy, dw, dh = [(-10, -2, 3), (-16, -1, 2), (-18, 0, 0), (-18, 0, 0),
                      (-14, 0, 0), (-8, -1, 2), (0, 3, -4), (0, 2, -2)][t - 20]
        st = {'pose': 'complete', 'dy': dy, 'dw': dw, 'dh': dh}
    elif t < 58:
        st = {'pose': 'complete', 'dh': breathe(t, 24, 2)}
    else:
        st = {'pose': 'complete', 'dw': 3, 'dh': -4}
    fx = []
    if 20 <= t < 33:
        age = t - 20

        def f_burst(img, ax, ay):
            import math
            x, y = src_point('idle', 184, 200, ax, ay, {})
            r = 40 + age * 9
            for i in range(8):
                a = math.radians(i * 45 + 22)
                if age > 9 and (age + i) % 2:
                    continue
                sprite(img, SPARK_L if age < 6 else SPARK_S,
                       x + r * math.cos(a), y + r * math.sin(a) * .8, SP)
        fx.append(f_burst)
    if 36 <= t < 44 and t % 4 < 2:
        def f_acorn(img, ax, ay):
            x, y = src_point('complete', 350, 110, ax, ay, st)
            sprite(img, SPARK_S, x + 10, y - 16, SP)
        fx.append(f_acorn)
    return st, fx


CONCEPTS = [
    # (함수, 제목, 칩, 설명 두 줄)
    (m_idle, '숨쉬기', '상시 · 2초 주기', ['기본 대기. 몸이 1px씩 계단처럼', '오르내려 살아 있는 느낌만 준다.']),
    (m_activity, '총총 걷기', '활동 중 · 2초 걷고 4초 쉼', ['운동·외출 루틴. 네 걸음 뛰고', '흙먼지를 남긴 뒤 숨쉬기로.']),
    (m_focus, '생각 점 · 반짝', '집중 중 · 6초 주기', ['공부·일 루틴. 몸은 거의 멈추고', '점 세 개와 돋보기 반짝만.']),
    (m_rest, 'Zzz', '쉬는 중 · 3초 깊은 숨', ['미룸·커피·밤 루틴. 느린 숨에', 'Z가 하나씩 떠오른다.']),
    (m_guide, '콕콕 가리키기', '루틴 없음 · 6초에 한 번', ['빈 홈 안내. 가리키는 쪽으로', '두 번 찌르고 손끝이 반짝.']),
    (m_hop, '가끔 깡총', '상시 · 10초 이상 간격', ['오래 보고 있을 때만. 웅크렸다', '뛰고 착지 먼지. 그림자도 줄어든다.']),
    (m_tap, '탭하면 하트', '캐릭터 탭 · 1회', ['누른 자리에 물결, 작은 깡총,', '하트가 떠올라 사라진다.']),
    (m_complete, '완료 축하', '루틴 완료 · 1회', ['웅크림 → 완료 포즈로 바뀌며 점프,', '별 8개가 퍼진다. 다음 루틴에 복귀.']),
]


# ---------------------------------------------------------------- 보드
CELL_W, STAGE_H, LABEL_H = 340, 290, 122
GAP, MARGIN = 24, 40
BOARD_W = MARGIN * 2 + CELL_W * 4 + GAP * 3
ROW_TOP = (204, 204 + STAGE_H + LABEL_H + 66)
BOARD_H = ROW_TOP[1] + STAGE_H + LABEL_H + 28

_bg = Image.open(CARD_BG).convert('RGBA')
STAGE_BG = _bg.crop((1260, 0, 2080, 702)).resize((CELL_W, STAGE_H), Image.BOX)
GROUND_Y = 262
CENTER_X = 150


def notch_frame(img, x, y, w, h, base):
    d = ImageDraw.Draw(img)
    d.rectangle([x, y, x + w - 1, y + h - 1], outline=INK, width=3)
    for cx, cy in ((x, y), (x + w - 3, y), (x, y + h - 3), (x + w - 3, y + h - 3)):
        d.rectangle([cx, cy, cx + 2, cy + 2], fill=base)
    # 모서리 안쪽 한 칸으로 픽셀 둥근 모서리를 만든다.
    for cx, cy in ((x + 3, y + 3), (x + w - 6, y + 3), (x + 3, y + h - 6), (x + w - 6, y + h - 6)):
        d.rectangle([cx, cy, cx + 2, cy + 2], fill=INK)


def draw_static(board):
    d = ImageDraw.Draw(board)
    d.text((MARGIN, 36), '홈 캐릭터 모션 시안', font=font(34, 2), fill=INK)
    d.text((MARGIN, 84), '지금 있는 포즈 그림 6장만으로 만드는 움직임 · 12fps 계단식 · 홈 첫 카드에서만 재생',
           font=font(17, 1), fill=MUTED)
    d.text((MARGIN, 110), '움직임은 1~2px 단위로 끊어 픽셀 그림의 결을 지키고, 쉬는 시간을 길게 둬 아래 루틴 정보를 방해하지 않는다.',
           font=font(15), fill=MUTED)
    heads = [('상시 — 지금 루틴에 따라 포즈마다 다른 숨', '루틴 아이콘이 고르는 포즈(homeCatPose)마다 한 가지씩'),
             ('가끔 · 이벤트 — 짧게 한 번', '반복하지 않고, 끝나면 위의 상시 모션으로 돌아간다')]
    for (head, sub), top in zip(heads, ROW_TOP):
        d.text((MARGIN, top - 38), head, font=font(19, 2), fill=INK)
        hw = d.textlength(head, font=font(19, 2))
        d.text((MARGIN + hw + 14, top - 34), sub, font=font(14), fill=MUTED)
    for i, (_, title, chip, desc) in enumerate(CONCEPTS):
        x = MARGIN + (i % 4) * (CELL_W + GAP)
        y = ROW_TOP[i // 4] + STAGE_H + 16
        num = f'{i + 1:02d}'
        d.rectangle([x, y, x + 33, y + 25], fill=INK)
        d.text((x + 17, y + 13), num, font=font(15, 2), fill=PAPER, anchor='mm')
        d.text((x + 44, y + 13), title, font=font(21, 2), fill=INK, anchor='lm')
        cw = d.textlength(chip, font=font(13, 1)) + 18
        d.rectangle([x, y + 36, x + cw, y + 58], fill=(255, 241, 201), outline=(232, 199, 122), width=2)
        d.text((x + 9, y + 47), chip, font=font(13, 1), fill=(154, 106, 18), anchor='lm')
        for j, line in enumerate(desc):
            d.text((x, y + 68 + j * 21), line, font=font(15), fill=MUTED)


def render_board():
    base = Image.new('RGBA', (BOARD_W, BOARD_H), PAPER + (255,))
    draw_static(base)
    frames = []
    for t in range(N):
        board = base.copy()
        for i, (fn, *_rest) in enumerate(CONCEPTS):
            stage = STAGE_BG.copy()
            st, fx = fn(t)
            draw_character(stage, st, CENTER_X, GROUND_Y)
            for f in fx:
                f(stage, CENTER_X, GROUND_Y)
            x = MARGIN + (i % 4) * (CELL_W + GAP)
            y = ROW_TOP[i // 4]
            board.alpha_composite(stage, (x, y))
            notch_frame(board, x, y, CELL_W, STAGE_H, PAPER + (255,))
        frames.append(board.convert('RGB'))
    save_gif(frames, os.path.join(HERE, '00-motion-board.gif'))


# ---------------------------------------------------------------- 홈 화면 안에서
def render_in_context():
    shot = Image.open(HOME_SHOT).convert('RGBA').crop((0, 0, 887, 760))
    # 스크린샷의 카드는 예전 배경이라, 지금 카드 배경(BoxFit.cover)을 깔고
    # 왼쪽 글자 영역만 스크린샷에서 가져와 부드럽게 잇는다.
    card = (61, 322, 825, 691)
    cw, ch = card[2] - card[0], card[3] - card[1]
    cover = _bg.resize((round(_bg.width * ch / _bg.height), ch), Image.BOX)
    ox = (cover.width - cw) // 2
    fresh = cover.crop((ox, 0, ox + cw, ch))
    old = shot.crop(card)
    # 스크린샷 다람쥐 꼬리(카드 x≈505~)에 닿기 전에 새 배경으로 넘어간다.
    keep = Image.linear_gradient('L').rotate(90, expand=True).transpose(
        Image.Transpose.FLIP_LEFT_RIGHT).resize((140, ch))  # 왼쪽 255 → 오른쪽 0
    mask = Image.new('L', (cw, ch), 0)
    mask.paste(255, (0, 0, 360, ch))
    mask.paste(keep, (360, 0))
    fresh.paste(old, (0, 0), mask)
    for y0 in (0, ch - 6):  # 오른쪽 픽셀 모서리는 스크린샷 것을 그대로 쓴다
        fresh.paste(old.crop((cw - 6, y0, cw, y0 + 6)), (cw - 6, y0))
    # 블렌드 구간에 걸친 '23:00' 은 글자 픽셀만 다시 얹는다.
    time_box = (448, 300, 535, 342)
    glyphs = old.crop(time_box)
    gm = glyphs.convert('L').point(lambda v: 255 if v < 150 else 0)
    fresh.paste(glyphs, time_box[:2], gm)
    shot.paste(fresh, card[:2])
    ax, ay = 690, 686
    script = [(0, '상시 · 숨쉬기'), (30, '캐릭터 탭 → 깡총 + 하트'), (60, '루틴 완료 → 축하 점프'),
              (110, '쉬는 시간 → 다시 숨쉬기')]
    frames = []
    for t in range(132):
        img = shot.copy()
        layer = Image.new('RGBA', img.size)
        if t < 30:
            st, fx = m_idle(t)
        elif t < 60:
            st, fx = m_tap(t - 30 + 10)
        elif t < 120:
            st, fx = m_complete(t - 60 + 16)
            if st['pose'] == 'idle' and t > 100:
                st, fx = {'pose': 'complete', 'dh': breathe(t, 24, 2)}, []
        else:
            st, fx = {'pose': 'complete', 'dh': breathe(t, 24, 2)}, []
        draw_character(layer, st, ax, ay)
        for f in fx:
            f(layer, ax, ay)
        # 카드 밖으로 넘친 효과는 카드 안쪽으로 자른다(앱의 ClipRect 대신 카드 모양).
        mask = Image.new('L', img.size, 0)
        ImageDraw.Draw(mask).rectangle([card[0], card[1], card[2] - 1, card[3] - 1], fill=255)
        img.paste(layer, (0, 0), Image.composite(layer, Image.new('RGBA', img.size), mask).split()[3])
        label = [s for start, s in script if t >= start][-1]
        d = ImageDraw.Draw(img)
        lw = d.textlength(label, font=font(22, 2)) + 36
        d.rectangle([887 - lw - 40, 730 - 24, 887 - 40, 730 + 18], fill=INK)
        d.text((887 - 40 - lw / 2, 727), label, font=font(22, 2), fill=PAPER, anchor='mm')
        frames.append(img.convert('RGB'))
    save_gif(frames, os.path.join(HERE, '01-home-in-context.gif'))


def save_gif(frames, path):
    """ffmpeg 로 바뀐 칸만 담아 저장한다(전체 프레임을 다 담으면 10MB 가까이 된다)."""
    with tempfile.TemporaryDirectory() as tmp:
        for k, f in enumerate(frames):
            f.save(os.path.join(tmp, f'{k:03d}.png'))
        subprocess.run([
            'ffmpeg', '-loglevel', 'error', '-y', '-framerate', str(FPS),
            '-i', os.path.join(tmp, '%03d.png'), '-filter_complex',
            '[0:v]split[a][b];[a]palettegen=max_colors=192:stats_mode=full[p];'
            '[b][p]paletteuse=dither=none:diff_mode=rectangle',
            '-loop', '0', path], check=True)
    print(path, os.path.getsize(path) // 1024, 'KB')


if __name__ == '__main__':
    render_board()
    render_in_context()
