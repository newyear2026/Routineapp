"""Four distinct LOOPET English campaigns. Existing artwork and actual Flutter UI.

python3 design/promo/loopet-style-collection-en/render_collection.py --preview
python3 design/promo/loopet-style-collection-en/render_collection.py --style arcade
Styles: arcade, minimal, scrapbook, night. No arguments renders all four.
Requires Pillow, ffmpeg, macOS system fonts, and the preceding promo's helpers.
"""
from __future__ import annotations

import argparse
import array
import functools
import importlib.util
import math
from pathlib import Path
import random
import subprocess
import wave

from PIL import Image, ImageDraw, ImageFilter, ImageFont

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[2]
ASSETS = ROOT / "flutter_app/assets"
spec = importlib.util.spec_from_file_location("promo_helpers", OUT.parent / "loopet-dynamic-en/render_dynamic.py")
helper = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helper)
put, ease, smooth, spring, clamp = helper.put, helper.ease, helper.smooth, helper.spring, helper.clamp
helper.SCREENS = OUT / "source/play/en"
W, H, SECONDS = 1080, 1920, 16

STYLES = {
    "arcade": {"folder":"01-pixel-arcade", "title":"Pixel Arcade", "fps":60, "cuts":[0,2.5,6,10,13,16], "bpm":128},
    "minimal": {"folder":"02-minimal-studio", "title":"Minimal Studio", "fps":30, "cuts":[0,4,8,12,16], "bpm":90},
    "scrapbook": {"folder":"03-daily-scrapbook", "title":"Daily Scrapbook", "fps":30, "cuts":[0,3,7,11.5,16], "bpm":96},
    "night": {"folder":"04-night-orbit", "title":"Night Orbit", "fps":30, "cuts":[0,4,8,12,16], "bpm":72},
}

FONTS = {
    "bold":"/System/Library/Fonts/Supplemental/Arial Bold.ttf",
    "sans":"/System/Library/Fonts/Supplemental/Arial.ttf",
    "serif":"/System/Library/Fonts/Supplemental/Georgia.ttf",
    "italic":"/System/Library/Fonts/Supplemental/Georgia Italic.ttf",
    "pixel":str(ASSETS / "fonts/PixelifySans.ttf"),
}


@functools.lru_cache(maxsize=150)
def font(kind, size):
    return ImageFont.truetype(FONTS[kind], size)


@functools.lru_cache(maxsize=400)
def letters(value, size, color, kind="bold"):
    f = font(kind,size)
    b = f.getbbox(value)
    im = Image.new("RGBA", (b[2]-b[0]+20,b[3]-b[1]+20))
    ImageDraw.Draw(im).text((10-b[0],10-b[1]),value,font=f,fill=color)
    return im


def txt(im,value,size,x,y,color,kind="bold",**kwargs):
    put(im,letters(value,size,color,kind),x,y,**kwargs)


@functools.lru_cache(maxsize=60)
def label(value,fill,color,size=34,kind="sans",square=False):
    inner=letters(value,size,color,kind)
    im=Image.new("RGBA",(inner.width+74,inner.height+40))
    ImageDraw.Draw(im).rounded_rectangle((1,1,im.width-2,im.height-2),0 if square else im.height//2,fill=fill)
    put(im,inner,im.width/2,im.height/2)
    return im


CAT = helper.sticker("cat_starlight",width=520)
CAT_WIN = helper.sticker("cat_starlight","complete",340)
PANDA = helper.PANDA
PANDA_WIN = helper.sticker("redpanda_teashop","complete",330)
RABBIT = helper.sticker("rabbit_postman",width=360)
STARCAT = helper.sticker("cat_stargazer",width=520)
STARCAT_SLEEP = helper.sticker("cat_stargazer","rest",390)
HOME = helper.phone("01_home",560)
PROGRESS = helper.phone("02_progress",395)
CALENDAR = helper.phone("06_calendar",395)
STAT = helper.screen_card("02_progress",(228,826,854,1060),790)
ROW1 = helper.screen_card("02_progress",(228,1147,854,1284),740)
ROW2 = helper.screen_card("02_progress",(228,1288,854,1423),740)
RP_HOME = helper.HOME
RP_STAT = helper.STAT
RP_ROW = helper.ROWS[0]
ICON = helper.ICON


def circle_clock():
    # The actual clock, enlarged without changing any UI or labels.
    im=Image.open(helper.SCREENS/"01_home.png").convert("RGBA").crop((346,815,738,1207))
    mask=Image.new("L",im.size)
    ImageDraw.Draw(mask).ellipse((2,2,389,389),fill=255)
    im.putalpha(mask)
    return im.resize((635,635),Image.Resampling.LANCZOS)


CLOCK=circle_clock()


def masthead(im,left,right,color,kind="sans"):
    txt(im,left,29,165,150,color,kind)
    txt(im,right,23,837,150,color,kind)


def pixel_star(im,x,y,size,color):
    d=ImageDraw.Draw(im)
    q=size/3
    d.rectangle((x-q,y-size,x+q,y+size),fill=color)
    d.rectangle((x-size,y-q,x+size,y+q),fill=color)


@functools.lru_cache(maxsize=12)
def solid_background(style):
    if style=="arcade":
        im=Image.new("RGBA",(W,H),"#15152D")
        d=ImageDraw.Draw(im)
        for y in range(0,H,8):
            d.line((0,y,W,y),fill="#191931",width=1)
        return im
    if style=="minimal":
        return Image.new("RGBA",(W,H),"#F7F6F0")
    if style=="scrapbook":
        im=Image.new("RGBA",(W,H),"#F0E3CE")
        d=ImageDraw.Draw(im)
        for x in range(0,W,54):
            d.line((x,0,x,H),fill="#E1D6C4")
        for y in range(0,H,54):
            d.line((0,y,W,y),fill="#E1D6C4")
        rng=random.Random(4)
        for _ in range(12500):
            x,y=rng.randrange(W),rng.randrange(H)
            d.point((x,y),fill=rng.choice(["#E9DDC8","#F7ECD8"]))
        return im
    im=Image.new("RGBA",(W,H))
    d=ImageDraw.Draw(im)
    for y in range(H):
        p=y/H
        d.line((0,y,W,y),fill=(round(12+17*p),round(19+7*p),round(45+23*p),255))
    glow=Image.new("RGBA",(W,H))
    ImageDraw.Draw(glow).ellipse((0,620,1080,1700),fill=(90,89,173,36))
    im.alpha_composite(glow.filter(ImageFilter.GaussianBlur(130)))
    return im


def arcade_grid(im,t):
    d=ImageDraw.Draw(im)
    for x in range(-500,1700,170):
        d.line((540+(x-540)*.32,1180,x,1920),fill="#2B2C56",width=3)
    for i in range(10):
        phase=(i/10+t*.13)%1
        y=1180+740*phase*phase
        d.line((0,y,W,y),fill="#2B2C56",width=2)
    for i in range(16):
        x=70+(i*197)%940
        y=230+((i*353+t*32)%1350)
        pixel_star(im,x,y,4 if i%3 else 8,"#7775A5")


def pixel_frame(im,box,color,width=7):
    x0,y0,x1,y1=box
    d=ImageDraw.Draw(im)
    cut=18
    d.line([(x0+cut,y0),(x1-cut,y0),(x1-cut,y0+cut),(x1,y0+cut),(x1,y1-cut),(x1-cut,y1-cut),(x1-cut,y1),(x0+cut,y1),(x0+cut,y1-cut),(x0,y1-cut),(x0,y0+cut),(x0+cut,y0+cut),(x0+cut,y0)],fill=color,width=width)


def arcade_scene(n,u,t):
    im=solid_background("arcade").copy()
    arcade_grid(im,t)
    white,cyan,lime,pink="#F4F1FF","#9AEBEB","#DFFF91","#FFA4D0"
    masthead(im,"LOOPET","DAILY ROUTINE",cyan,"pixel")
    # A stepped bob and pixel font make this feel different from smooth ads.
    bob=12*math.sin(math.floor(u*8)/8*math.pi*2)
    e=spring(u/.5)
    if n==0:
        txt(im,"READY, SET,",117,540,346,white,"pixel",scale=.94+.06*e)
        txt(im,"ROUTINE.",165,540,511,lime,"pixel",opacity=ease((u-.15)/.3))
        pixel_frame(im,(171,705,909,1415),pink)
        put(im,CAT,540,1060+bob,.92+.08*e)
        put(im,label("YOUR DAY STARTS HERE",cyan,"#15152D",38,"pixel",True),540,1600)
    elif n==1:
        txt(im,"PLAN YOUR",116,540,328,white,"pixel")
        txt(im,"NEXT MOVE.",127,540,460,cyan,"pixel")
        put(im,HOME,540+750*(1-e),1140,1,-4*(1-e))
        put(im,label("24 HOURS / ONE CIRCLE",lime,"#15152D",31,"pixel",True),540,1732)
    elif n==2:
        txt(im,"ONE ROUTINE",107,540,324,white,"pixel")
        txt(im,"AT A TIME.",126,540,458,lime,"pixel")
        put(im,STAT,540,804,1,opacity=ease(u/.4))
        put(im,ROW1,540-850*(1-spring((u-.2)/.4)),1160)
        put(im,ROW2,540+850*(1-spring((u-.4)/.4)),1395)
        put(im,CAT_WIN,880,1650+bob,.46)
        txt(im,"LITTLE WINS COUNT.",43,457,1655,cyan,"pixel")
    elif n==3:
        txt(im,"MAKE IT",124,540,342,white,"pixel")
        txt(im,"YOURS.",172,540,510,pink,"pixel")
        pets=[CAT,RABBIT,PANDA]
        for i,pet in enumerate(pets):
            a=spring((u-i*.16)/.5)
            x=230+i*310
            pixel_frame(im,(x-145,797,x+145,1267),[cyan,lime,pink][i],5)
            put(im,pet,x,1050+bob*((-1)**i)+90*(1-a),(.47 if i!=1 else .62)*max(.01,a))
        txt(im,"PICK A LITTLE COMPANION",42,540,1440,white,"pixel")
        txt(im,"Extra character packs available",29,540,1580,cyan,"sans")
    else:
        txt(im,"LET'S DO TODAY.",94,540,358,lime,"pixel")
        put(im,ICON,540,695,.98)
        txt(im,"LOOPET",183,540,983,white,"pixel")
        txt(im,"Your daily routine buddy.",37,540,1145,cyan,"sans")
        pixel_frame(im,(173,1360,907,1520),lime)
        txt(im,"START YOUR ROUTINE",48,540,1440,lime,"pixel",scale=1+.012*math.sin(u*3))
        put(im,CAT_WIN,540,1685+bob,.55)
    txt(im,"PLAN  /  DO  /  REPEAT",27,540,1831,"#8F8DB8","pixel")
    return im


def minimal_scene(n,u,t):
    im=solid_background("minimal").copy()
    d=ImageDraw.Draw(im)
    ink,muted,olive="#202E28","#6C7A70","#B5C4B2"
    masthead(im,"LOOPET","A DAILY PRACTICE",muted)
    d.line((100,216,980,216),fill="#D7DED4",width=2)
    a=ease(u/.9)
    if n==0:
        txt(im,"My day.",123,540,372,ink,"serif",opacity=a)
        txt(im,"In balance.",108,540,530,ink,"italic",opacity=ease((u-.16)/.9))
        # A slow, close view of the app's existing circular schedule.
        d.ellipse((177,744,903,1470),fill="#E8ECE2")
        put(im,CLOCK,540,1105+35*(1-a),.93+.055*min(u/4,1),opacity=a)
        txt(im,"Your routines. A clearer view.",38,540,1604,muted,"sans")
    elif n==1:
        txt(im,"See your day",83,540,345,ink,"serif")
        txt(im,"as one circle.",86,540,464,ink,"italic")
        put(im,HOME,540,1140+65*(1-a),.96+.02*min(u/4,1),opacity=a)
        txt(im,"A little clarity, from morning to night.",33,540,1737,muted,"sans")
    elif n==2:
        txt(im,"Little steps.",90,540,348,ink,"serif")
        txt(im,"Visible progress.",82,540,474,ink,"italic")
        put(im,PROGRESS,321-100*(1-a),1100,.98,-3,opacity=a)
        put(im,CALENDAR,759+100*(1-a),1132,.98,3,opacity=ease((u-.12)/.9))
        txt(im,"Track today. Look back on your month.",33,540,1655,muted,"sans")
    else:
        d.ellipse((264,476,816,1028),outline="#D1DCCE",width=2)
        put(im,ICON,540,751,.97+.025*math.sin(u*.6),opacity=a)
        txt(im,"LOOPET",127,540,1121,ink,"serif")
        txt(im,"Make room for what matters.",37,540,1292,muted,"sans")
        put(im,label("Find your rhythm",ink,"#FBFCF8",38,"sans"),540,1520,opacity=ease((u-.4)/.7))
    d.line((100,1795,980,1795),fill="#D7DED4",width=2)
    txt(im,f"0{n+1} / 04",22,540,1840,muted,"sans")
    return im


@functools.lru_cache(maxsize=24)
def tape(color="#EBC77B",width=250):
    im=Image.new("RGBA",(width,65))
    d=ImageDraw.Draw(im)
    d.polygon([(8,0),(width-5,2),(width,13),(width-5,28),(width,43),(width-7,64),(5,61),(10,48),(1,34),(6,20)],fill=color)
    return im


def paper_photo(image,width,caption=""):
    image=image.resize((width,round(width*image.height/image.width)),Image.Resampling.LANCZOS)
    h=image.height+90+(75 if caption else 0)
    im=Image.new("RGBA",(width+120,h+80))
    shade=Image.new("RGBA",im.size)
    ImageDraw.Draw(shade).rectangle((42,42,width+100,h+62),fill=(69,44,26,54))
    im.alpha_composite(shade.filter(ImageFilter.GaussianBlur(14)))
    ImageDraw.Draw(im).rectangle((25,20,width+95,h+35),fill="#FFFCF3")
    put(im,image,width/2+60,image.height/2+52)
    if caption:
        txt(im,caption,36,width/2+60,h-14,"#504A38","italic")
    return im


def raw_phone_screen(name):
    p=OUT.parent/"loopet-15s-en/source/play/en"/f"{name}.png"
    return Image.open(p).convert("RGBA").crop((189,264,892,1792))


SCRAP_HOME=paper_photo(raw_phone_screen("01_home"),445,"a plan for today")
PANDA_PHOTO_BASE=Image.new("RGBA",(570,590),"#F2D4BC")
put(PANDA_PHOTO_BASE,PANDA,285,304,.85)
PANDA_PHOTO=paper_photo(PANDA_PHOTO_BASE,570,"a little more me-time")
SCRAP_STAT=paper_photo(Image.open(OUT.parent/"loopet-15s-en/source/play/en/02_progress.png").convert("RGBA").crop((228,826,854,1060)),755,"little wins count")


def scribble(im,points,color="#657D66",width=4):
    ImageDraw.Draw(im).line(points,fill=color,width=width,joint="curve")


def scrapbook_scene(n,u,t):
    # Limited motion cadence resembles paper pieces being moved by hand.
    u=math.floor(u*12)/12
    im=solid_background("scrapbook").copy()
    d=ImageDraw.Draw(im)
    ink="#4D4537"
    masthead(im,"LOOPET","MY LITTLE EVERYDAY",ink,"sans")
    a=spring(u/.6)
    if n==0:
        txt(im,"Small plans.",95,540,340,ink,"italic",angle=-2)
        txt(im,"Lovely days.",94,540,469,ink,"serif",angle=-2)
        put(im,PANDA_PHOTO,540+200*(1-a),1060,1,-7+2*math.sin(u*.7),opacity=clamp(a))
        put(im,tape(),542,672,angle=-12)
        put(im,tape("#CCD4AF",190),262,1420,angle=12)
        txt(im,"Make a little space for you.",40,540,1660,ink,"italic",angle=-2)
    elif n==1:
        txt(im,"Dear today,",102,540,335,ink,"italic",angle=-3)
        # Shadowed paper and tape frame authentic app pixels.
        put(im,SCRAP_HOME,540+170*(1-a),1120,1,-4+math.sin(u),opacity=clamp(a))
        put(im,tape("#CBD7C7",230),571,546,angle=7)
        put(im,label("01 / make a plan","#F0C0B7",ink,32,"italic",True),304,1530,angle=7)
        scribble(im,[(839,696),(927,747),(941,872),(914,838),(941,872),(956,829)])
    elif n==2:
        txt(im,"Look at you go.",86,540,345,ink,"italic",angle=-2)
        put(im,SCRAP_STAT,540+200*(1-a),842,1,-5,opacity=clamp(a))
        put(im,tape(),499,552,angle=5)
        b=spring((u-.25)/.55)
        put(im,RP_ROW,512-330*(1-b),1274,.93,7,clamp(b))
        put(im,PANDA_WIN,800,1537,.66,12)
        put(im,label("one step at a time","#C7D9CE",ink,36,"italic",True),394,1563,angle=-6)
    else:
        txt(im,"My kind of",86,540,326,ink,"italic",angle=-2)
        txt(im,"everyday.",106,540,451,ink,"serif",angle=-2)
        card=Image.new("RGBA",(790,850),"#FFFBEF")
        cd=ImageDraw.Draw(card)
        for yy in range(610,820,52):
            cd.line((90,yy,700,yy),fill="#E6DDCC",width=2)
        put(card,ICON,395,230,1)
        txt(card,"LOOPET",106,395,462,ink,"serif")
        txt(card,"Your daily routine buddy.",33,395,576,ink,"italic")
        put(im,card,540,1050,1,-3,opacity=ease(u/.7))
        put(im,tape("#EBC77B",270),541,622,angle=4)
        put(im,label("Start a lovely little routine.","#536E5F","#FFFBEF",34,"sans"),540,1642,angle=-2)
    # A small hand-drawn corner flourish, different from pixel or orbit motifs.
    scribble(im,[(91,1741),(108,1717),(123,1727),(129,1751),(107,1775),(90,1743)],"#9F7765",4)
    txt(im,"a page from your day",25,751,1819,"#8C7963","italic")
    return im


STAR_POINTS=[(random.Random(i*17+8).randint(60,1020),random.Random(i*31+9).randint(225,1740),2+i%3,i*.71) for i in range(48)]


def sky(im,t):
    d=ImageDraw.Draw(im)
    for x,y,r,phase in STAR_POINTS:
        b=round(140+55*math.sin(t*.7+phase))
        d.ellipse((x-r,y-r,x+r,y+r),fill=(b,b, min(255,b+24)))
    # One slow shooting star per cycle, without flashes.
    p=(t*.13)%1
    if p < .28:
        x=130+1100*p
        y=600+280*p
        d.line((x-60,y-15,x,y),fill="#818CB3",width=2)


def orbit(im,t,cx=540,cy=1090,r=440):
    d=ImageDraw.Draw(im)
    d.ellipse((cx-r,cy-r*.64,cx+r,cy+r*.64),outline="#505A83",width=2)
    a=t*.19
    x,y=cx+r*math.cos(a),cy+r*.64*math.sin(a)
    d.ellipse((x-7,y-7,x+7,y+7),fill="#EBDCB6")


def night_scene(n,u,t):
    im=solid_background("night").copy()
    sky(im,t)
    gold,ivory,muted="#E5D3AC","#F8F0E1","#A9B7D4"
    masthead(im,"LOOPET","AT YOUR OWN PACE",muted)
    a=ease(u/1.2)
    if n==0:
        txt(im,"A softer",99,540,345,ivory,"serif",opacity=a)
        txt(im,"kind of rhythm.",81,540,483,ivory,"italic",opacity=ease((u-.12)/1.2))
        moon=Image.new("RGBA",(650,650))
        md=ImageDraw.Draw(moon)
        md.ellipse((25,25,625,625),fill=gold)
        # Transparent cut-out in a crescent, retaining the night background.
        md.ellipse((170,-15,720,535),fill=(0,0,0,0))
        put(im,moon,540,1000,.96)
        orbit(im,t,540,1050,440)
        put(im,STARCAT,565,1170+8*math.sin(t),.80,opacity=a)
        txt(im,"Make space for your everyday.",36,540,1610,muted,"sans")
    elif n==1:
        txt(im,"Find your focus.",87,540,359,ivory,"serif")
        txt(im,"One routine at a time.",39,540,488,gold,"italic")
        orbit(im,t,540,1160,479)
        put(im,HOME,540+10*math.sin(t*.7),1131+60*(1-a),.96,opacity=a)
        txt(im,"See what is now. Know what is next.",31,540,1733,muted,"sans")
    elif n==2:
        txt(im,"Every small step",74,540,353,ivory,"serif")
        txt(im,"leaves a little light.",69,540,474,gold,"italic")
        orbit(im,t,540,1120,480)
        put(im,STAT,540,914+40*(1-a),.96,opacity=a)
        put(im,ROW1,540,1226+40*(1-a),.91,opacity=ease((u-.2)/1.1))
        put(im,STARCAT_SLEEP,756,1510+6*math.sin(t),.69)
        txt(im,"Your progress, gently in view.",33,540,1700,muted,"sans")
    else:
        txt(im,"Begin again.",96,540,348,ivory,"serif")
        txt(im,"At your pace.",84,540,481,gold,"italic")
        orbit(im,t,540,965,427)
        put(im,ICON,540,762,.94,opacity=a)
        txt(im,"LOOPET",128,540,1044,ivory,"serif")
        put(im,STARCAT_SLEEP,540,1325,.91)
        put(im,label("Start with LOOPET","#E5D3AC","#16213F",38,"sans"),540,1583,opacity=ease((u-.3)/1))
        txt(im,"Your daily routine buddy.",30,540,1710,muted,"sans")
    return im


RENDERERS={"arcade":arcade_scene,"minimal":minimal_scene,"scrapbook":scrapbook_scene,"night":night_scene}


def frame(style,t):
    cuts=STYLES[style]["cuts"]
    i=max(n for n in range(len(cuts)-1) if cuts[n]<=t)
    elapsed=t-cuts[i]
    offset=.22 if style in ("arcade","scrapbook") else .32
    current=RENDERERS[style](i,elapsed+offset,t)
    if i:
        duration={"arcade":.18,"minimal":.55,"scrapbook":.24,"night":.8}[style]
        if elapsed<duration:
            prev=RENDERERS[style](i-1,cuts[i]-cuts[i-1]+elapsed+offset,t)
            p=smooth(elapsed/duration)
            if style=="arcade":
                mask=Image.new("L",(W,H))
                d=ImageDraw.Draw(mask)
                # Pixel columns appear in staggered blocks instead of a fade.
                for x in range(0,W,90):
                    h=clamp(p*1.5-(x//90)%3*.15)*H
                    d.rectangle((x,0,x+90,h),fill=255)
                current=Image.composite(current,prev,mask)
            elif style=="scrapbook":
                x=round(W*(1-p))
                prev.alpha_composite(current,(x,0))
                current=prev
            else:
                current=Image.blend(prev,current,p)
    return current.convert("RGB")


def music(style,destination):
    rate=32000
    count=rate*SECONDS
    l,r=array.array("f",[0])*count,array.array("f",[0])*count
    rng=random.Random(700+list(STYLES).index(style))
    beat=60/STYLES[style]["bpm"]

    def tone(midi,start,seconds,amp,kind="bell",pan=0):
        begin=int(start*rate)
        freq=440*2**((midi-69)/12)
        for j in range(min(int(seconds*rate),count-begin)):
            t=j/rate
            release=min(1,max(0,(seconds-t)/.15))
            if kind=="pad":
                env=min(1,t/.7)*release*.7
                signal=math.sin(math.tau*freq*t)+.16*math.sin(math.tau*freq*2.003*t)
            elif kind=="chip":
                env=min(1,t/.008)*math.exp(-7*t)*release
                signal=(math.sin(math.tau*freq*t)+.3*math.sin(math.tau*freq*3*t)+.14*math.sin(math.tau*freq*5*t))*.7
            elif kind=="pluck":
                env=min(1,t/.006)*math.exp(-4*t)*release
                signal=math.sin(math.tau*freq*t)+.32*math.sin(math.tau*freq*2*t)*math.exp(-5*t)+.12*math.sin(math.tau*freq*3*t)
            else:
                env=min(1,t/.014)*math.exp(-2.4*t)*release
                signal=math.sin(math.tau*freq*t)+.23*math.sin(math.tau*freq*2*t)*math.exp(-3*t)
            value=signal*env*amp
            l[begin+j]+=value*(1-pan*.3)
            r[begin+j]+=value*(1+pan*.3)

    def tap(start,kind,amp):
        begin=int(start*rate)
        sec=.26 if kind=="kick" else .1
        for j in range(min(int(sec*rate),count-begin)):
            t=j/rate
            if kind=="kick":
                val=math.sin(math.tau*(51*t+2.5*(1-math.exp(-29*t))))*math.exp(-18*t)
            else:
                val=rng.uniform(-1,1)*math.exp(-45*t)*min(1,t/.003)
            l[begin+j]+=val*amp
            r[begin+j]+=val*amp

    chords=[(48,60,64,67),(45,57,60,64),(53,60,65,69),(43,59,62,67)]
    if style=="arcade":
        for k in range(int(SECONDS/beat)):
            chord=chords[(k//8)%4]
            tone(chord[0],k*beat,.32,.16,"chip")
            tap(k*beat,"kick",.18)
            if k%2: tap(k*beat,"tick",.08)
            for s in range(2):
                tone(chord[1+(k+s)%3]+12,k*beat+s*beat/2,.4,.11,"chip",(-1)**k*.6)
        for start in STYLES[style]["cuts"][1:-1]:
            for j,n in enumerate((72,76,79)): tone(n,start+j*.07,.25,.055,"chip")
    elif style=="minimal":
        for k in range(4):
            for j,n in enumerate(chords[k][1:]):
                tone(n,k*4+j*.42,2.8,.105,"bell",(j-1)*.4)
                tone(n-12,k*4,3.8,.034,"pad")
        for start,n in [(2.8,79),(6.8,76),(10.8,81),(14.0,79)]: tone(n,start,1.8,.075)
    elif style=="scrapbook":
        for k in range(int(SECONDS/beat)):
            chord=chords[(k//6)%4]
            tone(chord[0],k*beat,.44,.10,"pluck")
            tone(chord[1+k%3],k*beat,.8,.12,"pluck",(-1)**k*.5)
            tone(chord[1+(k+1)%3]+12,k*beat+beat*.55,.65,.05,"pluck",-(-1)**k*.5)
            if k%2: tap(k*beat,"tick",.038)
    else:
        for k in range(4):
            for j,n in enumerate(chords[k][1:]):
                tone(n-12,k*4,5.3,.055,"pad",(j-1)*.55)
            tone(chords[k][-1]+12,k*4+.6,3.6,.085,"bell",.4)
            tone(chords[k][-2]+12,k*4+2.2,2.7,.06,"bell",-.4)
    # Every score resolves and gently fades, with no borrowed sound recording.
    for n in (72,76,79): tone(n,14.7,1.3,.047,"chip" if style=="arcade" else "bell")
    samples=array.array("h")
    for i in range(count):
        fade=min(1,i/(rate*.02),max(0,(SECONDS-i/rate)/.7))
        for ch in (l,r): samples.append(round(math.tanh(ch[i]*1.15)*fade*32767))
    with wave.open(str(destination),"wb") as wav:
        wav.setnchannels(2); wav.setsampwidth(2); wav.setframerate(rate)
        wav.writeframes(samples.tobytes())


def preview(style):
    directory=OUT/STYLES[style]["folder"]
    directory.mkdir(exist_ok=True)
    cuts=STYLES[style]["cuts"]
    times=[(cuts[i]+cuts[i+1])/2 for i in range(len(cuts)-1)]
    sheet=Image.new("RGB",(len(times)*270+(len(times)+1)*14,548),"#EAE9E2")
    for i,t in enumerate(times):
        im=frame(style,t)
        im.save(directory/f"scene-{i+1:02}.jpg",quality=92)
        sheet.paste(im.resize((270,480),Image.Resampling.LANCZOS),(14+i*284,14))
        ImageDraw.Draw(sheet).text((14+i*284,508),f"{t:.1f}s",font=font("sans",22),fill="#252533")
    sheet.save(directory/"storyboard.jpg",quality=94)
    frame(style,times[0]).save(directory/"poster.jpg",quality=94)
    return directory


def render(style):
    directory=preview(style)
    soundtrack=directory/"soundtrack.wav"
    music(style,soundtrack)
    fps=STYLES[style]["fps"]
    video=directory/f"loopet-{style}-en-16s.mp4"
    target_loudness="-16" if style=="arcade" else "-19" if style=="scrapbook" else "-21"
    cmd=["ffmpeg","-hide_banner","-loglevel","warning","-y","-f","rawvideo","-pixel_format","rgb24","-video_size",f"{W}x{H}","-framerate",str(fps),"-i","pipe:0","-i",str(soundtrack),"-c:v","libx264","-threads","4","-preset","fast","-crf","19","-pix_fmt","yuv420p","-c:a","aac","-b:a","192k","-ar","48000","-af",f"loudnorm=I={target_loudness}:TP=-2:LRA=7","-t",str(SECONDS),"-movflags","+faststart","-metadata",f"title=LOOPET - {STYLES[style]['title']}",str(video)]
    with subprocess.Popen(cmd,stdin=subprocess.PIPE) as process:
        for i in range(fps*SECONDS):
            process.stdin.write(frame(style,i/fps).tobytes())
            if i%(fps*4)==0: print(f"{style}: {i//fps}/{SECONDS} seconds rendered",flush=True)
        process.stdin.close()
        code=process.wait()
        if code: raise SystemExit(code)
    print(video,flush=True)


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--style",choices=list(STYLES))
    parser.add_argument("--preview",action="store_true")
    args=parser.parse_args()
    styles=[args.style] if args.style else list(STYLES)
    for style in styles:
        if args.preview:
            print(preview(style)/"storyboard.jpg")
        else:
            render(style)


if __name__=="__main__": main()
