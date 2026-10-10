"""LOOPET: Your day. Your pace. A 16s / 60fps kinetic English promo.

Uses the existing English Flutter captures and approved character art.
Run with --preview for a storyboard; otherwise renders the complete MP4.
Dependencies: Pillow, ffmpeg, macOS Arial fonts. Audio synthesized locally.
"""
from __future__ import annotations

import argparse
import array
import functools
import math
from pathlib import Path
import random
import subprocess
import wave

from PIL import Image, ImageDraw, ImageFilter, ImageFont

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[2]
ASSETS = ROOT / "flutter_app/assets"
SCREENS = OUT.parent / "loopet-15s-en/source/play/en"
W, H, FPS, LENGTH = 1080, 1920, 60, 16
INK, CREAM = "#251C43", "#FFF8EA"
PURPLE, MINT, LIME, PEACH = "#7147E8", "#CDF2E5", "#E1FA9B", "#FFB486"
STARTS = [0, 2, 5, 8, 10, 12, 16]


def clamp(x):
    return max(0.0, min(1.0, x))


def ease(x):
    return 1 - (1-clamp(x))**3


def smooth(x):
    x = clamp(x)
    return x*x*(3-2*x)


def spring(x):
    x = clamp(x)
    return 1 + 2.4*(x-1)**3 + 1.4*(x-1)**2


@functools.lru_cache(maxsize=100)
def font(size, bold=True):
    name = "Arial Bold.ttf" if bold else "Arial.ttf"
    return ImageFont.truetype(f"/System/Library/Fonts/Supplemental/{name}", size)


@functools.lru_cache(maxsize=250)
def type_layer(value, size, color=INK, bold=True):
    f = font(size, bold)
    b = f.getbbox(value)
    result = Image.new("RGBA", (b[2]-b[0]+16, b[3]-b[1]+16))
    ImageDraw.Draw(result).text((8-b[0], 8-b[1]), value, font=f, fill=color)
    return result


def put(canvas, layer, x, y, scale=1.0, angle=0.0, opacity=1.0):
    if opacity <= 0 or scale <= 0:
        return
    if abs(scale-1) > .002:
        layer = layer.resize((max(1, round(layer.width*scale)), max(1, round(layer.height*scale))), Image.Resampling.BICUBIC)
    if abs(angle) > .02:
        layer = layer.rotate(angle, Image.Resampling.BICUBIC, expand=True)
    if opacity < .999:
        layer = layer.copy()
        layer.putalpha(layer.getchannel("A").point(lambda a: round(a*clamp(opacity))))
    canvas.alpha_composite(layer, (round(x-layer.width/2), round(y-layer.height/2)))


def text(canvas, value, size, x, y, color=INK, scale=1.0, angle=0, opacity=1, bold=True):
    put(canvas, type_layer(value, size, color, bold), x, y, scale, angle, opacity)


@functools.lru_cache(maxsize=32)
def chip(value, size=34, fill=INK, color=CREAM):
    label = type_layer(value, size, color)
    im = Image.new("RGBA", (label.width+70, label.height+42))
    ImageDraw.Draw(im).rounded_rectangle((0,0,im.width-1,im.height-1), im.height/2, fill=fill)
    put(im, label, im.width/2, im.height/2)
    return im


def sticker(pack, pose="guide", width=520):
    im = Image.open(ASSETS/f"characters/{pack}/v1/approved/{pose}.png").convert("RGBA")
    im = im.crop(im.getchannel("A").getbbox())
    return im.resize((width, round(width*im.height/im.width)), Image.Resampling.NEAREST)


def phone(name, width=660):
    im = Image.open(SCREENS/f"{name}.png").convert("RGBA").crop((172,248,910,1810))
    mask = Image.new("L", im.size)
    ImageDraw.Draw(mask).rounded_rectangle((0,0,im.width-1,im.height-1), 111, fill=255)
    im.putalpha(mask)
    im = im.resize((width, round(width*im.height/im.width)), Image.Resampling.LANCZOS)
    layer = Image.new("RGBA", (im.width+140, im.height+140))
    shadow = Image.new("RGBA", layer.size)
    shadow.paste((18,10,30,82), (70,85), im.getchannel("A"))
    layer.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(24)))
    layer.alpha_composite(im, (70,55))
    return layer


def screen_card(name, box, width, border=CREAM):
    im = Image.open(SCREENS/f"{name}.png").convert("RGBA").crop(box)
    im = im.resize((width, round(width*im.height/im.width)), Image.Resampling.LANCZOS)
    layer = Image.new("RGBA", (im.width+80, im.height+90))
    shadow = Image.new("RGBA", layer.size)
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((28,36,im.width+56,im.height+66), 28, fill=(15,12,27,60))
    layer.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(12)))
    ImageDraw.Draw(layer).rounded_rectangle((20,20,im.width+60,im.height+60), 26, fill=border)
    layer.alpha_composite(im, (40,40))
    return layer


PANDA = sticker("redpanda_teashop")
PANDA_WIN = sticker("redpanda_teashop", "complete", 255)
CAT = sticker("cat_starlight")
OTTER = sticker("otter_seaside")
HOME = phone("01_home")
WIDGET_PHONE = phone("03_widget", 510)
STAT = screen_card("02_progress", (228,826,854,1060), 825)
ROWS = [screen_card("02_progress", b, 730) for b in [(228,1147,854,1284), (228,1288,854,1423), (228,1426,854,1559)]]
WIDGET = screen_card("03_widget", (218,568,863,858), 855)
ICON = Image.open(ASSETS/"icon/app_icon.png").convert("RGBA").resize((228,228), Image.Resampling.LANCZOS)
mask = Image.new("L", ICON.size)
ImageDraw.Draw(mask).rounded_rectangle((0,0,227,227), 51, fill=255)
ICON.putalpha(mask)


def star(canvas, x, y, radius, color, rotation=0):
    points = []
    for i in range(16):
        a = math.pi*i/8+rotation
        r = radius if i%2 == 0 else radius*.60
        points.append((x+r*math.cos(a), y+r*math.sin(a)))
    ImageDraw.Draw(canvas).polygon(points, fill=color)


def ring(canvas, cx, cy, r, t, color, width=5):
    d = ImageDraw.Draw(canvas)
    for i in range(4):
        d.arc((cx-r,cy-r,cx+r,cy+r), i*90+t*18, i*90+63+t*18, fill=color, width=width)


def header(canvas, scene, dark=False):
    color = CREAM if dark else INK
    text(canvas, "LOOPET", 33, 161, 159, color)
    text(canvas, "YOUR DAY / YOUR PACE", 22, 824, 159, color)


def ticker(canvas, t, fill=INK, color=CREAM):
    layer = Image.new("RGBA", (W,94), fill)
    phrase = type_layer("PLAN  /  DO  /  CELEBRATE  /  REPEAT  /  ", 28, color)
    x = -(t*90)%phrase.width - phrase.width
    while x < W:
        put(layer, phrase, x+phrase.width/2, 47)
        x += phrase.width
    canvas.alpha_composite(layer, (0,1808))


def scene(index, u):
    palettes = [PEACH, CREAM, INK, MINT, "#E8DEFF", PURPLE]
    im = Image.new("RGBA", (W,H), palettes[index])
    d = ImageDraw.Draw(im)
    header(im, index, index in (2,5))
    enter = spring(u/.48)
    if index == 0:
        d.ellipse((-160,710,1240,2110), fill="#F6A270")
        ring(im, 540,1090,402,u,CREAM,8)
        ring(im, 540,1090,360,-u*.8,"#F3CBA9",2)
        text(im, "YOUR DAY.", 148, 540-110*(1-ease((u+.18)/.42)), 375, scale=1+.10*math.exp(-8*u))
        reveal = spring((u-.2)/.5)
        text(im, "YOUR PACE.", 133, 540+260*(1-reveal), 535, opacity=clamp(reveal))
        # The mascot lands on the beat, then keeps a gentle rhythmic bounce.
        put(im, PANDA, 540,1090+70*(1-enter)-12*abs(math.sin(math.pi*u*2)), .80+.25*enter, -10*(1-enter)+3*math.sin(u*2.5))
        star(im, 894,812,55,LIME,u*.5)
        star(im, 179,1337,35,CREAM,-u)
        for word, x,y,delay in [("PLAN",205,875,.35),("DO",855,1190,.60),("REPEAT",256,1400,.85)]:
            a = spring((u-delay)/.35)
            put(im, chip(word,30), x,y+45*(1-a), max(.01,a), (-8 if x<500 else 9), clamp(a))
        text(im, "A LITTLE ROUTINE. A LOT OF YOU.", 33,540,1655)
        ticker(im,u)
    elif index == 1:
        d.ellipse((-290,790,1370,2450), fill="#E7E1F6")
        for i in range(3):
            ring(im,540,1320,510+i*70,u+i,PURPLE,2)
        text(im, "PLAN IT.", 154,540,346, scale=.92+.08*enter)
        text(im, "Your routine, at a glance.", 42,540,483,bold=False)
        # Whip into place, then push closer to the real app screen.
        cam = .91 + .12*smooth((u-.45)/2.4)
        put(im, HOME, 540+610*(1-enter),1257+125*(1-enter), cam, -5-10*(1-enter)+2.5*math.sin(u*.9))
        put(im, chip("24 HOURS. ONE CIRCLE.",31,LIME,INK),540,1729,angle=-3)
        ticker(im,u+2,PURPLE,CREAM)
    elif index == 2:
        ring(im,1000,1170,650,u,"#3A2B61",30)
        ring(im,90,1050,430,-u,"#3A2B61",2)
        text(im,"CHECK IT.",144,540,350,CREAM,scale=.93+.07*enter)
        text(im,"Small wins. Every day.",44,540,489,LIME,bold=False)
        a = spring((u-.08)/.45)
        put(im,STAT,540+600*(1-a),818,.95+.05*a,-3+2*math.sin(u*.8),clamp(a))
        for i,row in enumerate(ROWS):
            a = spring((u-.32-i*.20)/.4)
            direction = -1 if i%2 == 0 else 1
            put(im,row,540+direction*900*(1-a),1135+i*235, .98+.02*a, direction*(1.2+4*(1-a)),clamp(a))
        # Decorative confetti celebrates the existing completed rows.
        if u > 1.30:
            for i in range(15):
                phase = clamp((u-1.30)/1.4)
                angle = i*2.399
                radius = 140+phase*450
                x = 540+math.cos(angle)*radius
                y = 1030+math.sin(angle)*radius+phase*270
                if x<200 or x>890:
                    star(im,x,y,8+(i%3)*3,[PEACH,LIME,MINT][i%3],u+i)
        ticker(im,u+5,LIME,INK)
    elif index == 3:
        d.ellipse((-190,605,1300,2095), fill="#B6DFD3")
        text(im,"GLANCE. GO.",119,540,352,scale=.92+.08*enter)
        text(im,"Your routine, on your home screen.",36,540,479,bold=False)
        put(im,WIDGET_PHONE,540-380*(1-enter),1160,.90,-8+3*math.sin(u))
        a = spring((u-.22)/.5)
        put(im,WIDGET,540+550*(1-a),1110+30*math.sin(u*2), .80+.20*a,5*(1-a)+3,clamp(a))
        put(im,chip("HOME SCREEN WIDGET",30,INK,CREAM),540,1680,angle=-3)
        star(im,907,733,43,CREAM,u)
        ticker(im,u+8)
    elif index == 4:
        text(im,"PICK YOUR",116,540,345)
        text(im,"SIDEKICK.",139,540,503,PURPLE)
        d.ellipse((138,717,942,1521),fill=CREAM)
        ring(im,540,1119,432,u,PURPLE,4)
        pets = [CAT,PANDA,OTTER]
        names = ["STARLIGHT CAT","RED PANDA","SEA OTTER"]
        # Three full-size characters slide across on musical half-bars.
        p = min(2,int(u/.65))
        local = u-p*.65
        shift = 0 if p==0 else 1080*(1-ease(local/.24))
        if p>0 and local<.24:
            put(im,pets[p-1],540-1080*ease(local/.24),1120,.98, -4)
        put(im,pets[p],540+shift,1110-18*math.sin(local*5),1+.025*math.sin(local*4),3*math.sin(local*3))
        put(im,chip(names[p],32,PURPLE,CREAM),540,1540)
        text(im,"Extra character packs available",29,540,1670,bold=False)
        star(im,175,788,35,LIME,u)
        star(im,906,1390,40,PEACH,-u)
        ticker(im,u+10,PURPLE,CREAM)
    else:
        d.ellipse((-270,660,1350,2280),fill="#6540D2")
        ring(im,540,1060,485,u,"#9472F1",4)
        ring(im,540,1060,576,-u*.4,"#9472F1",2)
        text(im,"MAKE TODAY",107,540-450*(1-enter),336,CREAM)
        text(im,"YOURS.",171,540+450*(1-enter),514,LIME)
        put(im,ICON,540,819+80*(1-enter), .8+.2*enter, -14*(1-enter))
        text(im,"LOOPET",156,540,1066,CREAM,scale=.94+.06*enter)
        text(im,"Your daily routine buddy.",39,540,1195,CREAM,bold=False)
        # Small character accents keep the CTA readable during the final hold.
        put(im,PANDA_WIN,168,1345-8*math.sin(u*3),.68,9)
        put(im,OTTER,927,911+9*math.sin(u*2),.30,-12)
        c = spring((u-.35)/.5)
        put(im,chip("Start your routine  →",45,LIME,INK),540,1448+75*(1-c),.98+.02*math.sin(u*3),opacity=clamp(c))
        text(im,"Plan. Do. Celebrate. Repeat.",34,540,1642,CREAM,bold=False)
        ticker(im,u+12,LIME,INK)
    return im


def render_frame(t):
    idx = max(i for i in range(6) if STARTS[i]<=t)
    u = t-STARTS[idx]
    current = scene(idx,u+.18)
    # Short diagonal reveals preserve crisp UI while speeding up each cut.
    if idx and u < .22:
        previous = scene(idx-1,STARTS[idx]-STARTS[idx-1]+u+.18)
        progress = smooth(u/.22)
        mask = Image.new("L",(W,H))
        x = -500+(W+1000)*progress
        ImageDraw.Draw(mask).polygon([(-600,0),(x+240,0),(x-240,H),(-600,H)],fill=255)
        current = Image.composite(current,previous,mask)
    return current.convert("RGB")


def soundtrack():
    rate=32000
    count=rate*LENGTH
    left,right = array.array("f",[0])*count,array.array("f",[0])*count
    rng=random.Random(804)

    def note(midi,start,duration,amp,pan=0,kind="pluck"):
        freq=440*2**((midi-69)/12)
        begin=int(start*rate)
        for i in range(min(int(duration*rate),count-begin)):
            t=i/rate
            if kind=="bass":
                env=min(1,t/.009)*math.exp(-6*t)*min(1,(duration-t)/.07)
                value=math.sin(math.tau*freq*t)+.22*math.sin(math.tau*freq*2*t)
            else:
                env=min(1,t/.008)*math.exp(-5.6*t)*min(1,(duration-t)/.05)
                value=math.sin(math.tau*freq*t)+.22*math.sin(math.tau*freq*2*t)*math.exp(-8*t)+.09*math.sin(math.tau*freq*3*t)
            v=value*env*amp
            left[begin+i]+=v*(1-pan*.3)
            right[begin+i]+=v*(1+pan*.3)

    def drum(start,kind,amp=.2):
        seconds={"kick":.28,"clap":.12,"hat":.06,"whoosh":.23}[kind]
        begin=int(start*rate)
        prev=0
        for i in range(min(int(seconds*rate),count-begin)):
            t=i/rate
            noise=rng.uniform(-1,1)
            if kind=="kick":
                value=math.sin(math.tau*(49*t+3.2*(1-math.exp(-27*t))))*math.exp(-15*t)
            elif kind=="clap":
                value=(noise-prev*.65)*math.exp(-34*t)*min(1,t/.002)
            elif kind=="hat":
                value=(noise-prev)*math.exp(-80*t)
            else:
                envelope=math.sin(math.pi*t/seconds)**2
                value=(noise+prev)*.45*envelope
            prev=noise
            left[begin+i]+=value*amp
            right[begin+i]+=value*amp

    chords=[(48,60,64,67),(45,60,64,69),(41,60,65,69),(43,59,62,67),(48,60,64,67),(45,60,64,69),(41,60,65,69),(48,60,64,67)]
    for bar,chord in enumerate(chords):
        start=bar*2
        for beat in range(4):
            when=start+beat*.5
            note(chord[0],when,.36,.14,kind="bass")
            drum(when,"kick",.26 if beat%2==0 else .19)
            if beat%2:
                drum(when,"clap",.105)
            drum(when+.25,"hat",.038)
        for step in range(8):
            midi=chord[1+step%3]+(12 if step in (3,7) else 0)
            note(midi,start+step*.25,.58,.10 if step%2==0 else .064,(-1 if step%2 else 1)*.65)
    for cut in STARTS[1:-1]:
        drum(cut-.12,"whoosh",.055)
        note(84,cut,.5,.065)
    # Resolve the ending with a soft C-major chord.
    for n in (72,76,79):
        note(n,15.0,.98,.09)
    samples=array.array("h")
    peak=0
    for i in range(count):
        fade=min(1,i/(rate*.008),max(0,(LENGTH-i/rate)/.55))
        for signal in (left,right):
            value=math.tanh(signal[i]*1.2)*fade
            peak=max(peak,abs(value))
            samples.append(round(value*32767))
    with wave.open(str(OUT/"soundtrack-120bpm.wav"),"wb") as f:
        f.setnchannels(2); f.setsampwidth(2); f.setframerate(rate)
        f.writeframes(samples.tobytes())
    print(f"Generated original 120 BPM soundtrack; sample peak {peak:.3f}",flush=True)


def preview():
    times=[.8,2.8,5.9,8.8,11.0,11.5,13.0,15.2]
    canvas=Image.new("RGB",(4*270+5*16,2*480+3*60),"#EEECE5")
    for i,t in enumerate(times):
        im=render_frame(t)
        im.save(OUT/f"preview-{i+1:02}.jpg",quality=93)
        x=16+(i%4)*286
        y=16+(i//4)*540
        canvas.paste(im.resize((270,480),Image.Resampling.LANCZOS),(x,y))
        ImageDraw.Draw(canvas).text((x,y+489),f"{t:04.1f}s",font=font(21),fill=INK)
    canvas.save(OUT/"storyboard.jpg",quality=94)
    render_frame(.85).save(OUT/"poster.jpg",quality=95)


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--preview",action="store_true")
    args=parser.parse_args()
    preview()
    if args.preview:
        print(OUT/"storyboard.jpg")
        return
    soundtrack()
    output=OUT/"loopet-dynamic-en-16s.mp4"
    cmd=["ffmpeg","-hide_banner","-loglevel","warning","-y","-f","rawvideo","-pixel_format","rgb24","-video_size",f"{W}x{H}","-framerate",str(FPS),"-i","pipe:0","-i",str(OUT/"soundtrack-120bpm.wav"),"-c:v","libx264","-preset","fast","-crf","19","-pix_fmt","yuv420p","-c:a","aac","-b:a","192k","-ar","48000","-af","loudnorm=I=-16:TP=-1.5:LRA=7","-t",str(LENGTH),"-movflags","+faststart","-metadata","title=LOOPET - Your day. Your pace.",str(output)]
    with subprocess.Popen(cmd,stdin=subprocess.PIPE) as proc:
        for i in range(FPS*LENGTH):
            proc.stdin.write(render_frame(i/FPS).tobytes())
            if i%120==0:
                print(f"Rendered {i}/{FPS*LENGTH} frames",flush=True)
        proc.stdin.close()
        result=proc.wait()
        if result:
            raise SystemExit(result)
    print(output,flush=True)


if __name__=="__main__":
    main()
