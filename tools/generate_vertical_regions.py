#!/usr/bin/env python3
"""Generate 17 portrait, transparent, fully-vector region vignettes for Nihongo Quest.

These are environmental illustrations, not flat map screenshots: the continuous terrain
and tappable route are painted by Flutter, while these 720x1280 assets provide original
chapter-specific landmarks, foliage, water, architecture and atmospheric detail.
"""
from pathlib import Path
from xml.etree import ElementTree as ET
import math

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets' / 'artwork' / 'regions'

PALETTES = [
    {'sky':'#9ac7d5','far':'#6e9aa4','mid':'#436e68','dark':'#254a4a','leaf':'#4d805b','light':'#a9c58b','wood':'#77513d','roof':'#35465c','red':'#c95f58','water':'#2b829d','foam':'#a9e5e4','gold':'#f7d89b','rock':'#778b8b'},
    {'sky':'#a6d8e4','far':'#70a9a4','mid':'#548463','dark':'#345b4e','leaf':'#69a65a','light':'#c4d78d','wood':'#8b6442','roof':'#416459','red':'#ce6f51','water':'#278caf','foam':'#b9f0ed','gold':'#ffe1a2','rock':'#82999a'},
    {'sky':'#add9e8','far':'#7ca8bc','mid':'#588174','dark':'#304f4d','leaf':'#6a9a60','light':'#c3d59b','wood':'#7b4d3d','roof':'#394e5b','red':'#d94f4a','water':'#2686ac','foam':'#b8f0eb','gold':'#ffd795','rock':'#788c8d'},
    {'sky':'#9ec5dc','far':'#6f96b1','mid':'#617b78','dark':'#304d4c','leaf':'#60866a','light':'#b4c89b','wood':'#785640','roof':'#38495d','red':'#bd5649','water':'#3987a6','foam':'#b9e6e8','gold':'#ffd995','rock':'#7b9095'},
    {'sky':'#bbe1ec','far':'#9cbca8','mid':'#8aa75d','dark':'#5b7947','leaf':'#6fa04d','light':'#e2d27c','wood':'#96633e','roof':'#68694c','red':'#ca6848','water':'#55a4ad','foam':'#d4f0d3','gold':'#fff0b0','rock':'#a7b29a'},
    {'sky':'#b6e0e7','far':'#9cc9ad','mid':'#77a65f','dark':'#456f4b','leaf':'#69a35a','light':'#c7d88b','wood':'#916247','roof':'#596a53','red':'#c94d44','water':'#579f9a','foam':'#d4f0ca','gold':'#f8e3a2','rock':'#8ea18b'},
    {'sky':'#756d9f','far':'#5a557b','mid':'#42425c','dark':'#272d48','leaf':'#4f665e','light':'#899a9b','wood':'#70473e','roof':'#2c3049','red':'#e35d53','water':'#3e6d8b','foam':'#8dc8dc','gold':'#ffd18b','rock':'#616b7c'},
    {'sky':'#a8dce9','far':'#83b4bf','mid':'#62a172','dark':'#3b7059','leaf':'#67a65c','light':'#bfda91','wood':'#835a40','roof':'#4a5c5f','red':'#d15c4d','water':'#2898b1','foam':'#c0f1eb','gold':'#ffe6a1','rock':'#7fa5a5'},
    {'sky':'#c4e2ef','far':'#9dbbce','mid':'#799f83','dark':'#4a7055','leaf':'#6b9a56','light':'#f0bdd0','wood':'#8b5a40','roof':'#59616d','red':'#d75e60','water':'#579eab','foam':'#d5f0ed','gold':'#ffe6bf','rock':'#9aaba7'},
    {'sky':'#a7c8de','far':'#849bad','mid':'#687983','dark':'#3d4f5c','leaf':'#647f65','light':'#d8bd6f','wood':'#78543e','roof':'#3b4858','red':'#c85241','water':'#4f8c9c','foam':'#c3e6e3','gold':'#ffe19a','rock':'#8c9aa0'},
    {'sky':'#557f84','far':'#3e6b6a','mid':'#315b50','dark':'#1e3b3b','leaf':'#4c8660','light':'#9cbd82','wood':'#60493b','roof':'#314c47','red':'#b94f48','water':'#23797d','foam':'#8bdfc7','gold':'#d5efb6','rock':'#526e69'},
    {'sky':'#d3a09a','far':'#b67c6b','mid':'#95684e','dark':'#594844','leaf':'#9c6543','light':'#dfab5a','wood':'#7e523b','roof':'#5b4446','red':'#d4553f','water':'#698a8f','foam':'#d3dfcf','gold':'#ffd18b','rock':'#8a7770'},
    {'sky':'#395d91','far':'#496f94','mid':'#2e5d62','dark':'#17394a','leaf':'#416d61','light':'#9bb4cf','wood':'#655040','roof':'#2a3d54','red':'#a84f58','water':'#225d8a','foam':'#9bd5e5','gold':'#e8d9ad','rock':'#617c98'},
    {'sky':'#a16e9b','far':'#806182','mid':'#575066','dark':'#333449','leaf':'#5b745e','light':'#e7a078','wood':'#7b5043','roof':'#45384d','red':'#e45d4c','water':'#4d7185','foam':'#b7dcdb','gold':'#ffd37e','rock':'#777282'},
    {'sky':'#b5e1ed','far':'#82b7c3','mid':'#498a86','dark':'#2a625f','leaf':'#5c9b75','light':'#bfdfae','wood':'#9a6b4d','roof':'#465d65','red':'#cd5b50','water':'#2187b7','foam':'#baf2ef','gold':'#ffe3ae','rock':'#829e9e'},
    {'sky':'#a8624d','far':'#79534e','mid':'#564044','dark':'#2e2d38','leaf':'#56604a','light':'#d8723c','wood':'#5d4239','roof':'#34343e','red':'#df4932','water':'#55565c','foam':'#f3a35a','gold':'#ffcb5f','rock':'#6d6265'},
    {'sky':'#b9d8ed','far':'#91b5c9','mid':'#6c918b','dark':'#425e61','leaf':'#6b8c61','light':'#d6d8bb','wood':'#80634b','roof':'#4d5962','red':'#bd594c','water':'#5799b1','foam':'#d7eff0','gold':'#f7d78e','rock':'#879ba5'},
]

class Scene:
    def __init__(self, i, p):
        self.i, self.p = i, p
        self.q = f'r{i:02d}_'
        self.parts = []
    def add(self, s): self.parts.append(s)
    def path(self,d,fill,stroke=None,sw=1,op=1,extra=''):
        self.add(f'<path d="{d}" fill="{fill}"' + (f' stroke="{stroke}" stroke-width="{sw}" stroke-linecap="round" stroke-linejoin="round"' if stroke else '') + ('' if op == 1 else f' opacity="{op}"') + f' {extra}/>' )
    def line(self,x1,y1,x2,y2,col,sw=2,op=1): self.path(f'M{x1:.1f} {y1:.1f} L{x2:.1f} {y2:.1f}','none',col,sw,op)
    def circle(self,x,y,r,col,stroke=None,sw=1,op=1):
        self.add(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r:.1f}" fill="{col}"' + (f' stroke="{stroke}" stroke-width="{sw}"' if stroke else '') + ('' if op == 1 else f' opacity="{op}"') + '/>')
    def ellipse(self,x,y,rx,ry,col,stroke=None,sw=1,op=1):
        self.add(f'<ellipse cx="{x:.1f}" cy="{y:.1f}" rx="{rx:.1f}" ry="{ry:.1f}" fill="{col}"' + (f' stroke="{stroke}" stroke-width="{sw}"' if stroke else '') + ('' if op == 1 else f' opacity="{op}"') + '/>')
    def rect(self,x,y,w,h,col,rx=0,stroke=None,sw=1,op=1):
        self.add(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{col}"' + (f' stroke="{stroke}" stroke-width="{sw}"' if stroke else '') + ('' if op == 1 else f' opacity="{op}"') + '/>')
    def defs(self):
        p,q=self.p,self.q
        self.add(f'''<defs>
 <linearGradient id="{q}far" x1="0" y1="0" x2="0.25" y2="1"><stop stop-color="{p['sky']}"/><stop offset="1" stop-color="{p['far']}"/></linearGradient>
 <linearGradient id="{q}green" x1="0" y1="0" x2="0.3" y2="1"><stop stop-color="{p['light']}"/><stop offset="0.48" stop-color="{p['leaf']}"/><stop offset="1" stop-color="{p['dark']}"/></linearGradient>
 <linearGradient id="{q}wood" x1="0" y1="0" x2="1" y2="0.3"><stop stop-color="{p['dark']}"/><stop offset="0.35" stop-color="{p['wood']}"/><stop offset="0.7" stop-color="{p['wood']}"/><stop offset="1" stop-color="{p['dark']}"/></linearGradient>
 <linearGradient id="{q}roof" x1="0" y1="0" x2="0.4" y2="1"><stop stop-color="{p['roof']}"/><stop offset="0.55" stop-color="{p['dark']}"/><stop offset="1" stop-color="{p['roof']}"/></linearGradient>
 <linearGradient id="{q}water" x1="0" y1="0" x2="0.15" y2="1"><stop stop-color="{p['foam']}"/><stop offset="0.35" stop-color="{p['water']}"/><stop offset="1" stop-color="{p['dark']}"/></linearGradient>
 <linearGradient id="{q}rock" x1="0" y1="0" x2="0.5" y2="1"><stop stop-color="#d0d1bd"/><stop offset="0.45" stop-color="{p['rock']}"/><stop offset="1" stop-color="{p['dark']}"/></linearGradient>
 <radialGradient id="{q}glow"><stop stop-color="{p['gold']}" stop-opacity=".8"/><stop offset="1" stop-color="{p['gold']}" stop-opacity="0"/></radialGradient>
 <linearGradient id="{q}red" x1="0" y1="0" x2="0.4" y2="1"><stop stop-color="{p['red']}"/><stop offset="1" stop-color="{p['dark']}"/></linearGradient>
</defs>''')
    def finish(self):
        body=''.join(self.parts)
        return f'''<svg xmlns="http://www.w3.org/2000/svg" width="720" height="1280" viewBox="0 0 720 1280" role="img" aria-label="Portrait vector environment illustration for Nihongo Quest chapter {self.i:02d}" preserveAspectRatio="xMidYMid meet"><title>Portrait chapter environment {self.i:02d}</title>{body}</svg>'''

# Common vector motifs. Paths deliberately leave the middle mostly open for the
# Flutter-painted route and level nodes; the map's terrain canvas supplies the ground.
def pine(s,x,y,k=1):
    p=s.p
    s.ellipse(x,y+5*k,28*k,9*k,'#142f35',op=.18)
    s.path(f'M{x} {y-104*k} L{x-28*k} {y-48*k} L{x-17*k} {y-48*k} L{x-39*k} {y-6*k} L{x+39*k} {y-6*k} L{x+17*k} {y-48*k} L{x+28*k} {y-48*k} Z',f'url(#{s.q}green)',p['dark'],1.2*k)
    s.path(f'M{x} {y-100*k} L{x-26*k} {y-50*k} L{x-12*k} {y-50*k} L{x-31*k} {y-12*k} L{x} {y-12*k} Z',p['leaf'],op=.56)
    s.rect(x-4*k,y-10*k,8*k,18*k,f'url(#{s.q}wood)',rx=2*k)
    for j in range(4):
        yy=y-(25+j*18)*k
        s.path(f'M{x-19*k} {yy} q10 {-5*k} 19 0','none','#c2d5a3',1.2*k,.42)

def broad_tree(s,x,y,k=1,canopy=None):
    p=s.p; c=canopy or p['leaf']
    s.ellipse(x,y+4*k,48*k,12*k,'#173b35',op=.18)
    s.path(f'M{x-7*k} {y+5*k} Q{x-13*k} {y-32*k} {x-5*k} {y-70*k} L{x+9*k} {y-70*k} Q{x+18*k} {y-26*k} {x+8*k} {y+5*k} Z',f'url(#{s.q}wood)',p['dark'],1.8*k)
    for dx,dy,rx,ry,col in [(-20,-72,34,31,c),(15,-86,36,34,p['light']), (39,-67,26,25,c),(-43,-60,23,24,p['dark']),(-2,-107,29,28,p['leaf'])]:
        s.ellipse(x+dx*k,y+dy*k,rx*k,ry*k,col,p['dark'],1.1*k,.98)
    # Veins and leaf clusters keep the canopy from becoming a flat blob.
    for dx,dy in [(-32,-70),(-13,-91),(12,-86),(30,-67),(-4,-58)]:
        s.path(f'M{x+dx*k} {y+(dy+12)*k} q{8*k} {-10*k} {17*k} {-14*k}','none',p['light'],1.5*k,.66)
    for dx,dy in [(-28,-82),(1,-107),(29,-76)]:
        s.ellipse(x+dx*k,y+dy*k,4*k,3*k,'#d7e3a9',op=.7)

def roof_house(s,x,y,k=1,festival=False):
    p=s.p; w=112*k; h=65*k
    s.ellipse(x+7*k,y+8*k,70*k,13*k,'#17323a',op=.2)
    s.path(f'M{x-w*.56} {y-h*.55} L{x-w*.34} {y-h*.92} L{x+w*.32} {y-h*.92} L{x+w*.58} {y-h*.52} Q{x} {y-h*.68} {x-w*.56} {y-h*.55} Z',f'url(#{s.q}roof)',p['dark'],2*k)
    s.path(f'M{x-w*.52} {y-h*.55} Q{x} {y-h*.73} {x+w*.53} {y-h*.52}','none','#e2bd84',2.2*k,.8)
    s.path(f'M{x-w*.42} {y-h*.50} L{x-w*.37} {y+h*.55} L{x+w*.36} {y+h*.55} L{x+w*.42} {y-h*.50} Z',f'url(#{s.q}wood)',p['dark'],1.8*k)
    for dx in (-.25,0,.25):
        s.line(x+dx*w,y-h*.44,x+dx*w,y+h*.48,'#dfb684',1.6*k,.75)
    s.rect(x-11*k,y+5*k,22*k,36*k,'#3a302c',rx=2*k,stroke='#e4c18c',sw=1.2*k)
    s.rect(x-31*k,y-7*k,16*k,17*k,'#f9d999',rx=2*k,stroke='#57473e',sw=1*k,op=.9)
    if festival:
        s.path(f'M{x-54*k} {y-h*.68} Q{x} {y-h*1.13} {x+54*k} {y-h*.68}','none',p['red'],3*k)
        for dx in (-35,0,35): lantern(s,x+dx*k,y-h*.64,k*.55)

def lantern(s,x,y,k=1):
    p=s.p
    s.ellipse(x,y+8*k,23*k,9*k,f'url(#{s.q}glow)',op=.65)
    s.line(x,y-28*k,x,y-20*k,p['wood'],2*k)
    s.path(f'M{x-12*k} {y-20*k} Q{x} {y-27*k} {x+12*k} {y-20*k} L{x+10*k} {y+13*k} Q{x} {y+19*k} {x-10*k} {y+13*k} Z',f'url(#{s.q}red)',p['dark'],1*k)
    s.rect(x-11*k,y-20*k,22*k,4*k,'#e6c68e',rx=1*k)
    s.rect(x-11*k,y+10*k,22*k,4*k,'#e6c68e',rx=1*k)
    s.line(x,y+15*k,x,y+24*k,'#e6c68e',1.4*k)

def boulder(s,x,y,k=1):
    p=s.p
    s.path(f'M{x-32*k} {y+8*k} Q{x-42*k} {y-12*k} {x-21*k} {y-29*k} L{x+2*k} {y-34*k} Q{x+26*k} {y-29*k} {x+35*k} {y-5*k} L{x+24*k} {y+12*k} Z',f'url(#{s.q}rock)',p['dark'],1.7*k)
    s.path(f'M{x-19*k} {y-20*k} Q{x-2*k} {y-32*k} {x+8*k} {y-25*k}','none','#f4e4c5',2*k,.72)
    s.path(f'M{x-7*k} {y-16*k} l-5 12 8 6','none',p['dark'],1.4*k,.8)

def leaf_cluster(s,x,y,k=1,color=None):
    p=s.p; c=color or p['leaf']
    for dx,dy,rx,ry,col in [(-19,0,22,13,c),(0,-13,27,19,p['light']),(22,2,21,14,c),(5,8,18,12,p['dark'])]:
        s.ellipse(x+dx*k,y+dy*k,rx*k,ry*k,col,p['dark'],1*k,.98)
    s.path(f'M{x-32*k} {y+8*k} Q{x} {y-5*k} {x+31*k} {y+4*k}','none',p['light'],1.3*k,.78)

def sakura_cluster(s,x,y,k=1):
    p=s.p
    for j in range(5):
        a=j*math.pi*2/5-math.pi/2
        cx=x+math.cos(a)*10*k; cy=y+math.sin(a)*10*k
        s.ellipse(cx,cy,7*k,9*k,'#f1b6ca', '#fbe0e7',.8*k)
    s.circle(x,y,3.5*k,p['gold'], '#b9835b',.7*k)

def rock_path(s, coords):
    for x,y,k in coords: boulder(s,x,y,k)

def grass(s,x,y,k=1,col=None):
    c=col or s.p['light']
    for j in range(5):
        dx=(j-2)*4*k
        s.path(f'M{x+dx} {y} Q{x+dx-9*k} {y-11*k} {x+dx-5*k} {y-22*k}','none',c,1.6*k,.92)

def water_ribbon(s,d,wide=34):
    p=s.p; q=s.q
    s.path(d,'none',p['dark'],wide+10, .26)
    s.path(d,'none',f'url(#{q}water)',wide)
    s.path(d,'none',p['foam'],2.2,.65)

def mountain(s,cx,base,w,h,col=None):
    p=s.p
    col=col or p['far']
    s.path(f'M{cx-w} {base} L{cx-w*.23} {base-h*.76} L{cx-w*.05} {base-h} L{cx+w*.2} {base-h*.55} L{cx+w*.42} {base-h*.68} L{cx+w} {base} Z',col,p['dark'],1.3,.85)
    s.path(f'M{cx-w*.23} {base-h*.76} L{cx-w*.05} {base-h} L{cx+w*.2} {base-h*.55} L{cx+w*.04} {base-h*.66} L{cx-w*.04} {base-h*.58} Z','#edf0df',None,1,.78)

# Chapter-specific vertical compositions. None uses a full-canvas background rectangle.
def scene_01(s):
    p=s.p
    mountain(s,175,245,160,205); mountain(s,525,275,155,170,p['sky'])
    for x,y,k in [(65,385,1.15),(105,610,.92),(651,460,1.1),(622,720,.9),(86,1000,1.18),(642,1080,1.1)]: pine(s,x,y,k)
    broad_tree(s,90,820,1.05,'#d0a0ba'); roof_house(s,540,605,.94); roof_house(s,170,1044,.8)
    # The stream meanders vertically down the margin and over a vermilion bridge.
    water_ribbon(s,'M610 0 C540 130 655 230 572 345 S645 515 550 650 S633 830 564 970 S634 1134 596 1280',40)
    s.path('M520 665 Q565 600 612 665 L604 683 Q566 632 529 683 Z','url(#r01_red)','#6f3f38',2)
    s.path('M518 660 Q566 587 615 660','none','#f1c28a',5)
    for x in [535,553,571,589,607]: s.line(x,652,x,681,'#edc48f',2,.9)
    for x,y in [(140,280),(190,300),(232,320),(485,390),(455,408),(422,422)]: sakura_cluster(s,x,y,.85)
    for x,y in [(500,460),(505,490),(510,520)]: s.circle(x,y,34,'none','#d8efe5',1.8,.42)
    for x,y in [(550,450),(600,510),(505,885),(612,920)]: lantern(s,x,y,.8)

def scene_02(s):
    p=s.p
    mountain(s,160,230,150,145); mountain(s,545,240,170,162)
    water_ribbon(s,'M100 0 C205 145 110 245 250 350 S405 490 315 625 S175 810 320 935 S515 1088 420 1280',52)
    for x,y,k in [(110,270,1.15),(590,300,1.1),(145,560,.9),(600,760,1.0),(110,1000,1.1),(570,1120,.95)]:
        boulder(s,x,y,k); grass(s,x+25,y+22,k*.9)
    # Stepping stones continue as a vertical sequence, not a horizontal scene.
    for x,y,k in [(170,160,.9),(190,242,.82),(233,323,.9),(289,408,.82),(338,496,.9),(356,593,.78),(320,699,.88),(291,805,.78),(346,901,.9),(400,1010,.82),(439,1125,.9),(430,1216,.76)]:
        s.ellipse(x,y,27*k,15*k,'url(#r02_rock)','#4b6f71',1.4)
        s.path(f'M{x-12*k} {y-3*k} Q{x} {y-10*k} {x+12*k} {y-4*k}','none','#e3e6cf',1.4,.7)
    for x,y in [(74,390),(648,540),(105,860),(635,1005)]:
        s.path(f'M{x} {y} q-17 -29 -6 -55 q18 30 6 55 M{x+14} {y+2} q20 -23 12 -47 q-21 24 -12 47','none',p['leaf'],3)
    # An abacus-like creek gate placed vertically along a bank.
    s.path('M500 800 L610 800 L610 1040 L500 1040 Z','none',p['wood'],7)
    for yy in [835,880,925,970,1015]:
        s.line(515,yy,595,yy,'#d5b57b',3)
        for xx in [535,555,575]: s.ellipse(xx,yy,7,11,'#c68b4c','#5e4538',1.2)

def scene_03(s):
    p=s.p
    for x,y,k in [(70,300,.85),(650,385,1.0),(85,950,1.15),(635,1080,.95)]: pine(s,x,y,k)
    water_ribbon(s,'M0 420 C140 365 250 480 360 430 S560 390 720 450',42)
    # Bridge is a horizontal landmark inside an otherwise vertical scene.
    s.path('M100 535 Q360 400 620 535 L604 560 Q360 455 116 560 Z','url(#r03_red)','#6f3439',3)
    s.path('M95 530 Q360 390 625 530','none','#f2c994',5)
    for i in range(13):
        x=120+i*40; y=520-100*math.sin(i/12*math.pi)
        s.line(x,y,x,y+28,'#f1d3a3',2.1)
    # Torii gate and lanterns anchor the lower bank.
    s.path('M120 820 L143 820 L143 1010 L120 1010 Z','url(#r03_red)','#683e39',2)
    s.path('M575 820 L598 820 L598 1010 L575 1010 Z','url(#r03_red)','#683e39',2)
    s.path('M92 817 Q360 770 626 817 L616 842 Q360 803 102 842 Z','url(#r03_red)','#683e39',2)
    s.path('M108 807 Q360 752 610 807','none','#f3cb92',4)
    for x,y in [(75,620),(648,635),(100,1120),(610,1150)]: lantern(s,x,y,1)
    for x,y in [(225,665),(480,685),(300,1090),(415,1110)]: s.ellipse(x,y,42,7,'#9fe5e3',op=.42)
    for x,y in [(165,250),(195,278),(228,264),(515,295),(548,319)]: sakura_cluster(s,x,y,.9)

def scene_04(s):
    p=s.p
    mountain(s,190,230,180,180); mountain(s,550,270,155,150)
    for x,y,k in [(80,450,1.05),(650,530,.85),(110,915,.95),(630,1090,1.0)]: pine(s,x,y,k)
    # Perspective tracks recede up the center-left and widen toward the foreground.
    s.path('M285 0 Q340 270 285 500 T310 850 T235 1280','none','#5f5147',7,.65)
    s.path('M350 0 Q400 290 350 500 T380 850 T312 1280','none','#5f5147',7,.65)
    for i in range(19):
        y=70+i*62; x1=300+math.sin(i*.4)*16-(i*1.0); x2=x1+45+i*1.2
        s.line(x1,y,x2,y,'#b79b79',2.4,.75)
    roof_house(s,520,670,1.15)
    s.path('M430 590 L610 590 L610 602 L430 602 Z',p['wood'],p['dark'],1)
    s.path('M428 588 Q520 552 612 588 L621 608 Q520 574 420 608 Z',f'url(#{s.q}roof)',p['dark'],2)
    for x,y in [(435,635),(605,635),(448,670),(590,670)]: lantern(s,x,y,.55)
    s.rect(68,705,56,90,'#6b4640',rx=4,stroke='#d6b47d',sw=2)
    s.circle(96,735,9,'#e7bf61'); s.rect(86,752,20,22,'#d4b77e',rx=2)

def scene_05(s):
    p=s.p
    mountain(s,140,270,160,120); mountain(s,575,260,145,105)
    # Golden grasses sweep upward along both sides, leaving the center open.
    for side in [0,1]:
        for i in range(25):
            x=(12+i*14) if side==0 else (440+i*11)
            y=(i*47+30)%1240
            h=24+(i%5)*10
            s.path(f'M{x} {y+28} Q{x-12} {y+3} {x-4} {y-h} M{x} {y+18} Q{x+12} {y} {x+15} {y-h*.7}','none',['#9ab05b','#d8c66f','#e8d891'][i%3],1.7,.85)
    # Windmill with visible spokes and cloth sail panels.
    s.path('M180 620 L205 620 L214 806 L174 806 Z','#896648','#634a39',2)
    s.circle(194,603,16,'#d6b77a','#71543f',3)
    for a in [0,math.pi/2,math.pi,math.pi*1.5]:
        x1=194+math.cos(a)*14; y1=603+math.sin(a)*14; x2=194+math.cos(a)*100; y2=603+math.sin(a)*100
        s.path(f'M{x1} {y1} L{x2-12*math.sin(a)} {y2+12*math.cos(a)} L{x2+12*math.sin(a)} {y2-12*math.cos(a)} Z','#e6d9ae','#8a7658',2,.9)
    for x,y in [(540,420),(590,870),(125,1030),(600,1175)]:
        s.path(f'M{x} {y} q-20 -25 0 -42 q18 24 0 42','none',p['leaf'],3)
    for x,y in [(255,980),(290,1010),(330,990),(475,1080)]: s.ellipse(x,y,35,11,'#a6bd65',op=.7)
    roof_house(s,530,730,.78)

def scene_06(s):
    p=s.p
    # Terraced fields are built as vertical contour bands, not stacked rectangular panels.
    for i in range(10):
        y=65+i*124
        left=70+25*math.sin(i*.7); right=655-20*math.cos(i*.58)
        s.path(f'M{left} {y+40} C{left+100} {y-8} {right-110} {y+62} {right} {y+8} L{right-6} {y+59} C{right-150} {y+110} {left+140} {y+30} {left} {y+95} Z',['#8bb56c','#719c5b','#5e8954'][i%3],p['dark'],1.6,.78)
        s.path(f'M{left+18} {y+58} Q360 {y+35} {right-20} {y+35}','none','#c3d991',2,.75)
        for x in range(int(left+25),int(right-25),34):
            yy=y+47+math.sin(x*.04+i)*8
            s.path(f'M{x} {yy} q-5 -7 -3 -13 M{x+2} {yy} q8 -8 8 -13','none','#c4d58c',1.4,.85)
    for x,y,k in [(80,450,.8),(640,520,.9),(92,960,.85),(632,1125,.8)]: broad_tree(s,x,y,k)
    roof_house(s,530,300,.72); roof_house(s,180,860,.68)
    for x,y in [(118,700),(600,800),(138,1095),(590,1155)]: boulder(s,x,y,.7)

def scene_07(s):
    p=s.p
    # Tall old-town buildings frame a rainy alley; the middle remains navigable.
    for x,y,k,side in [(78,170,.9,0),(638,230,.88,1),(92,500,.95,0),(632,640,1.0,1),(72,900,.82,0),(652,1060,.9,1)]:
        w=80*k; h=150*k
        s.path(f'M{x-w/2} {y-h} L{x-w/2+18*k} {y-h-32*k} L{x+w/2+14*k} {y-h-32*k} L{x+w/2} {y-h} Z',f'url(#{s.q}roof)',p['dark'],2)
        s.path(f'M{x-w/2} {y-h} L{x-w/2} {y} L{x+w/2} {y} L{x+w/2} {y-h} Z',f'url(#{s.q}wood)',p['dark'],1.6)
        for row in range(3):
            for col in range(2):
                xx=x-w*.28+col*36*k; yy=y-h+row*40*k
                s.rect(xx,yy,17*k,24*k,'#f4c779',rx=2,stroke='#66463b',sw=1.2,op=.9)
                s.rect(xx+4*k,yy+5*k,9*k,14*k,'#e45f4e',rx=1)
        for yy in [y-h*.7,y-h*.35]: s.line(x-w*.52,yy,x+w*.52,yy,'#d1a66f',2,.8)
    # Rain streaks and lantern strings follow the vertical alley perspective.
    for i in range(42):
        x=(i*71+17)%700; y=(i*113+53)%1240
        s.line(x,y,x-5,y+18,'#b6cce5',1,.45)
    for j in range(4):
        y=270+j*175
        s.path(f'M80 {y} Q360 {y+66} 650 {y-7}','none','#57434c',3)
        for x in [130,230,335,440,545,620]: lantern(s,x,y+20+20*math.sin(x),.62)
    for x,y in [(240,610),(475,820),(290,1040)]:
        s.path(f'M{x-43} {y} Q{x} {y-38} {x+43} {y} L{x+34} {y+9} L{x-34} {y+9} Z',f'url(#{s.q}red)',p['dark'],2)
        s.line(x,y+4,x,y+32,p['wood'],2)
        s.circle(x,y,5,'#f8d6a0')

def scene_08(s):
    p=s.p
    for x,y,k in [(85,240,1.0),(645,365,.95),(72,930,1.1),(650,1100,.95)]: pine(s,x,y,k)
    water_ribbon(s,'M90 0 C140 170 530 170 560 330 S230 490 300 650 S600 830 510 995 S210 1140 265 1280',62)
    # Round pond coves, lily pads, and koi that orient along the vertical current.
    for x,y,rx,ry in [(485,285,115,52),(215,560,108,54),(440,830,118,65),(300,1085,120,55)]:
        s.ellipse(x,y,rx,ry,'#4ba7b5','#8ad9d8',4,.7)
        s.ellipse(x,y,rx*.78,ry*.72,'#1c718d','#97e0da',2,.9)
        for j in range(5): s.ellipse(x-rx*.45+j*rx*.2,y+math.sin(j)*ry*.18,8,4,'#8ec66b',op=.9)
    for x,y,ang in [(450,285,-15),(225,559,12),(445,830,-18),(304,1088,21)]:
        s.path(f'M{x-34} {y} Q{x-12} {y-26} {x+20} {y-5} Q{x+35} {y+2} {x+43} {y-10} Q{x+34} {y+12} {x+8} {y+8} Q{x-20} {y+28} {x-34} {y} Z','#e7a6a1','#315a70',1.5,.9)
        s.circle(x+3,y-4,3,'#fff5d4'); s.circle(x+4,y-4,1.5,'#28313a')
        for j in range(4): s.line(x-10+j*8,y-9,x-4+j*8,y+3,'#f2d6b2',1,.85)
    for x,y in [(120,430),(603,700),(98,820),(617,990)]: boulder(s,x,y,.7)

def scene_09(s):
    p=s.p
    # Main sakura canopy leans inward as a tall vertical branch structure.
    s.path('M610 125 Q520 230 580 350 T492 590 T560 800 T478 1020','none','#60483b',22)
    s.path('M580 315 Q480 290 435 230 M540 510 Q650 480 670 430 M535 730 Q420 708 390 640 M518 920 Q630 884 648 825','none','#73513e',11)
    for x,y,k in [(520,210,1.1),(620,315,1.0),(450,355,.9),(635,470,1.0),(430,635,1.1),(585,735,1.0),(438,860,.92),(570,1000,1.08),(625,1130,.9)]:
        for dx,dy,rx,ry in [(-25,0,38,28),(10,-18,42,30),(43,5,34,26),(-1,20,39,28)]:
            s.ellipse(x+dx*k,y+dy*k,rx*k,ry*k,'#efb7cb','#f8d7e0',1,.93)
        for j in range(7): sakura_cluster(s,x+(j%3-1)*25*k,y+(j//3-1)*20*k,.58*k)
    for i in range(45):
        x=(i*103+27)%690; y=(i*79+60)%1250
        s.path(f'M{x} {y} q8 -8 13 1 q-8 9 -13 -1 Z',['#f3b8cc','#e990b1','#fbe1dc'][i%3],op=.84)
    mountain(s,155,310,135,145)
    roof_house(s,165,1005,.62)

def scene_10(s):
    p=s.p
    # A towering peak is built from separate crags and mineral veins.
    mountain(s,340,500,340,430,'#879da9'); mountain(s,525,565,220,350,'#6b7f90'); mountain(s,185,600,190,290,'#9aadb6')
    s.path('M335 150 L285 283 L320 306 L265 430 L308 458 L255 565','none','#e6d49b',6,.82)
    s.path('M430 260 L392 360 L424 388 L378 485','none','#e0b965',5,.75)
    for x,y,k in [(82,790,.85),(635,830,.85),(115,1110,1.0),(622,1140,.9)]: boulder(s,x,y,k)
    # Small shrine above the clouds, joined to the cliff by a winding stair.
    s.path('M280 690 Q355 665 430 690 L416 708 Q355 689 294 708 Z','url(#r10_red)','#64463d',2)
    s.path('M302 706 L315 760 L395 760 L408 706 Z','url(#r10_wood)','#493d3d',2)
    s.path('M270 692 Q355 649 440 692 L426 701 Q355 673 284 701 Z','url(#r10_roof)','#433d43',2)
    for i in range(8):
        y=760+i*19; x=312+math.sin(i*.35)*20
        s.path(f'M{x} {y} l42 -3 l-5 8 l-42 3 Z','#b8a18b','#5f5651',1,.86)
    for i in range(13):
        x=160+i*35; y=900+(i%3)*19
        s.circle(x,y,3.5,'#f6d37a',op=.9)

def scene_11(s):
    p=s.p
    # Twin ancient trunks and roots form a natural vertical arch without boxing the scene.
    for x,sgn in [(90,1),(635,-1)]:
        s.path(f'M{x-25} 0 Q{x-5} 170 {x-30} 350 T{x+10} 650 Q{x+30} 800 {x-15} 980 T{x} 1280 L{x+75} 1280 Q{x+35} 1070 {x+65} 930 T{x+32} 625 Q{x+15} 450 {x+60} 300 T{x+50} 0 Z','url(#r11_wood)',p['dark'],2,.95)
        for j in range(8):
            x0=x+(-12 if j%2 else 17); y=j*164+20
            s.path(f'M{x0} {y} Q{x0+sgn*20} {y+40} {x0-sgn*4} {y+90}','none','#9ab38b',3,.52)
        for y in [170,465,780,1080]: leaf_cluster(s,x+sgn*25,y,1.2,p['leaf'])
        for y in [350,635,920,1160]:
            s.path(f'M{x+20} {y} Q{360} {y-70} {360-sgn*90} {y+12} L{360-sgn*55} {y+35} Q{360} {y-10} {x+10} {y+48} Z','url(#r11_wood)',p['dark'],1.6,.88)
    for x,y in [(210,360),(470,520),(280,780),(500,970),(360,1120)]:
        s.ellipse(x,y,13,21,'#6cc8aa',op=.22); s.ellipse(x,y,5,9,'#c6f5d2',op=.65)
        s.path(f'M{x-14} {y+16} q-14 10 -8 22 M{x+14} {y+16} q14 10 8 22','none','#8bdcb8',2,.7)
    for x,y,k in [(180,600,.6),(525,700,.65),(220,1030,.7),(480,1160,.6)]:
        s.path(f'M{x-20*k} {y} Q{x} {y-35*k} {x+20*k} {y} Q{x+14*k} {y+15*k} {x} {y+13*k} Q{x-14*k} {y+15*k} {x-20*k} {y} Z','#bcbd8a','#455948',1.2)
        s.rect(x-3*k,y-10*k,6*k,11*k,'#f0dca4',rx=2)

def scene_12(s):
    p=s.p
    for x,y,k in [(75,320,1.05),(650,410,.98),(86,750,.9),(630,980,1.15),(110,1150,.95)]: broad_tree(s,x,y,k,['#c85c3d','#d77b3e','#a94c37'][int(y)%3])
    for side in [0,1]:
        for i in range(19):
            x=(20+i*16) if side==0 else (430+i*13)
            y=(i*67+35)%1240
            s.path(f'M{x} {y} q-12 -14 -2 -27 q17 4 16 19 q-2 12 -14 8 Z',['#c84731','#e07e37','#e6aa52'][i%3], '#8c4535',.9,.9)
            s.path(f'M{x} {y-3} l11 -13','none','#f0c67e',1,.7)
    for x,y in [(165,475),(530,655),(210,875),(505,1090)]:
        s.ellipse(x,y,31,11,'#8a9a91',op=.7); s.ellipse(x,y,20,7,'#d1c3a6',op=.6)
    s.path('M620 0 Q500 160 610 320 T530 620 T610 890 T485 1280','none','#785542',18,.8)
    for x,y in [(220,250),(270,270),(485,390),(460,415),(235,700),(270,730),(510,880),(490,910)]: sakura_cluster(s,x,y,.55)

def scene_13(s):
    p=s.p
    # Moon and a quiet vertical garden with stone lanterns and reflected light.
    s.circle(515,145,62,'#f1e6ba',op=.92); s.circle(540,128,57,p['sky'],op=.96)
    for x,y,k in [(80,300,.9),(650,380,.8),(84,850,1.05),(640,1080,.95)]: pine(s,x,y,k)
    water_ribbon(s,'M90 0 C250 130 565 170 560 330 S250 475 305 640 S545 805 475 970 S250 1125 315 1280',42)
    for x,y,rx,ry in [(450,300,90,30),(275,575,76,28),(410,850,92,32),(315,1090,82,27)]:
        s.ellipse(x,y,rx,ry,'#265a7a','#87c5d7',2,.85)
        s.ellipse(x,y,rx*.72,ry*.55,'#1b496a',op=.9)
        for j in range(3):
            s.path(f'M{x-rx*.4+j*rx*.35} {y} q9 -8 18 0 q-9 8 -18 0 Z','#a8c5ba',op=.72)
    for x,y in [(145,550),(590,660),(140,960),(585,1110)]:
        s.path(f'M{x-24} {y+18} L{x-19} {y-14} L{x-7} {y-24} L{x+7} {y-24} L{x+19} {y-14} L{x+24} {y+18} Z','#687d8d','#243b56',2)
        s.rect(x-28,y-1,56,7,'#9eabb4',rx=2); s.rect(x-20,y-28,40,6,'#b8c6c9',rx=2)
        s.ellipse(x,y-7,12,7,'#f2d69b',op=.75)
    for x,y in [(250,370),(500,515),(225,800),(485,1010)]:
        s.path(f'M{x} {y-10} q16 12 0 25 q-15 -13 0 -25 Z','#f8e8b6',op=.75)

def scene_14(s):
    p=s.p
    # Wooden shop fronts and awnings march up the sides; lantern strings connect them.
    for x,y,k,flip in [(88,260,.9,0),(630,355,.92,1),(80,610,1.0,0),(635,805,.88,1),(85,1055,.92,0),(632,1165,.85,1)]:
        roof_house(s,x,y,k,True)
        s.path(f'M{x-65*k} {y+20*k} L{x+65*k} {y+20*k} L{x+57*k} {y+49*k} L{x-58*k} {y+49*k} Z',['#e9b46d','#b84b43','#d6a65a'][int(y)%3],p['dark'],1.3,.9)
        for xx in [x-38*k,x,x+38*k]: s.rect(xx-8*k,y+25*k,16*k,19*k,'#f8d28a',rx=2,stroke='#8c513d',sw=1)
    for j in range(5):
        y=170+j*210
        s.path(f'M75 {y} Q360 {y+88} 650 {y-12}','none','#514047',3)
        for x in range(115,635,66):
            yy=y+35+60*math.sin(x/720*math.pi)
            lantern(s,x,yy,.66)
    for x,y in [(175,440),(540,700),(180,930),(520,1130)]:
        s.rect(x-18,y-25,36,48,'#e4c79a',rx=3,stroke='#56453f',sw=1.4)
        s.path(f'M{x-10} {y-15} q10 -8 20 0 q-10 8 -20 0 M{x-10} {y} q10 -8 20 0 q-10 8 -20 0','none','#9d5045',2)

def scene_15(s):
    p=s.p
    # Vertical tide pools and surf bands curve around exposed coastal rock.
    water_ribbon(s,'M690 0 C560 130 675 260 565 375 S665 610 540 730 S650 930 520 1065 S620 1190 590 1280',58)
    for x,y,k in [(90,220,1.2),(630,300,.9),(115,570,1.0),(635,790,1.15),(95,1040,.9),(625,1150,1.05)]: boulder(s,x,y,k)
    for x,y,rx,ry in [(495,195,76,36),(550,465,58,27),(470,730,88,34),(520,945,62,29),(450,1145,90,38)]:
        s.ellipse(x,y,rx,ry,'#318fa7','#b3e6df',3,.77)
        s.ellipse(x,y,rx*.7,ry*.55,'#4db4bd','#d0f0dc',2,.83)
        for j in range(5):
            xx=x-rx*.5+j*rx*.25; yy=y+math.sin(j)*ry*.3
            s.circle(xx,yy,3.5,['#e58f74','#e9d7a1','#74bfaa'][j%3],op=.88)
    # A tiny fishing skiff in portrait perspective.
    s.path('M170 810 Q245 842 328 810 L307 837 Q247 852 191 837 Z','#956b50','#493e3a',2)
    s.line(247,740,247,814,'#694d3e',3); s.path('M252 746 L303 800 L252 800 Z','#e8dcc0','#8b7764',1.2)
    for x,y in [(160,410),(330,465),(245,1040),(400,1110)]:
        s.path(f'M{x-13} {y} q13 -18 26 0 q-13 18 -26 0 Z','#da6e60','#693f53',1.2)
        s.circle(x,y,3,'#f7dec2')

def scene_16(s):
    p=s.p
    # A single tall volcanic cone with broken basalt fingers and molten fissures.
    s.path('M40 620 L115 480 L168 520 L242 320 L300 380 L360 90 L430 325 L488 275 L552 490 L628 455 L690 630 Q672 711 604 746 T454 778 T294 756 T115 772 Q37 751 0 720 Z','url(#r16_rock)','#292d39',3,.95)
    s.path('M260 350 L315 392 L360 90 L400 370 L450 330 L495 490 L550 510 L510 590 L465 555 L422 635 L373 600 L330 672 L286 590 L245 620 L221 535 Z','#393742','#252b35',2,.95)
    for d,sw in [('M358 155 Q320 260 365 330 T318 495 T355 620 T302 730',13),('M430 360 Q478 418 431 465 T470 610',8),('M265 540 Q300 574 275 630 T294 750',6),('M524 505 Q500 552 545 604 T518 710',6)]:
        s.path(d,'none','#f29a42',sw,.9); s.path(d,'none','#ffdb65',sw*.35,.95)
    for x,y,k in [(85,820,1.0),(620,875,.9),(120,1100,1.1),(630,1150,.85)]: boulder(s,x,y,k)
    for i in range(22):
        x=(i*97+23)%690; y=(i*151+80)%760
        s.path(f'M{x} {y} q-8 -14 2 -24 q12 12 2 24 Z','#fa8f45',op=.75)

def scene_17(s):
    p=s.p
    # Tall temple towers and suspended bronze mechanisms establish a vertical finale.
    mountain(s,170,270,160,190); mountain(s,560,270,160,160)
    roof_house(s,360,590,1.45)
    s.path('M265 550 L278 390 L300 340 L420 340 L442 390 L455 550 Z','url(#r17_wood)','#50463f',2.2)
    s.path('M282 398 Q360 360 438 398 L430 418 Q360 390 290 418 Z','url(#r17_roof)','#49434b',2)
    for y in [440,480,520]:
        s.line(300,y,420,y,'#d7b77d',2.2)
        for x in [322,360,398]: s.rect(x-8,y-8,16,16,'#b68c52',rx=3,stroke='#65513f',sw=1)
    for cx,cy,r in [(125,520,58),(585,700,74),(135,900,47),(590,1070,61)]:
        s.circle(cx,cy,r,'none','#a77b45',9,.86); s.circle(cx,cy,r*.7,'none','#e1c07b',3,.9)
        s.circle(cx,cy,5,'#f2d99b')
        for j in range(12):
            a=j*math.pi/6
            x=cx+math.cos(a)*r*.82; y=cy+math.sin(a)*r*.82
            s.path(f'M{x-2} {y-3} l4 6','none','#f2d99b',1.7,.9)
    for x,y,k in [(80,340,.75),(650,405,.8),(82,1090,.8),(644,1175,.78)]: pine(s,x,y,k)

SCENES=[scene_01,scene_02,scene_03,scene_04,scene_05,scene_06,scene_07,scene_08,scene_09,scene_10,scene_11,scene_12,scene_13,scene_14,scene_15,scene_16,scene_17]

def draw_common_edges(s, i):
    p=s.p; q=s.q
    # Organic side hills create a connected, illustrated terrain under the
    # chapter landmark. They do not form a rectangular panel or map background;
    # the center stays open for Flutter's connected trail and level markers.
    phase=(i%5)*27
    s.path(f'M0 0 C115 {120+phase} 55 260 122 380 S74 610 128 760 S48 1030 122 1175 Q138 1230 92 1280 L0 1280 Z',f'url(#{q}green)',None,1,.23)
    s.path(f'M720 0 C610 {95+phase} 671 250 598 385 S664 620 590 770 S680 1040 593 1180 Q580 1230 632 1280 L720 1280 Z',f'url(#{q}green)',None,1,.21)
    s.path(f'M0 155 C75 200 87 230 127 283 S91 400 120 454 S80 590 130 650 S75 785 115 849 S86 1024 131 1088', 'none',p['light'],2,.3)
    s.path(f'M720 205 C650 244 633 282 597 333 S633 452 590 521 S639 669 586 728 S647 884 596 952 S639 1102 591 1170', 'none',p['light'],2,.28)
    # Long soft contour lines and drifting foliage make the composition genuinely portrait.
    # All edge strokes are clipped naturally by the viewport and will be feathered in Flutter.
    for j in range(7):
        y=115+j*175
        phase=(i%4)*19
        s.path(f'M0 {y+phase} C120 {y-55} 145 {y+70} 225 {y+18} S315 {y-8} 360 {y+16}', 'none',p['far'],2.1,.18)
        s.path(f'M720 {y+45-phase} C610 {y-10} 575 {y+82} 505 {y+22} S425 {y-6} 360 {y+20}', 'none',p['far'],2.1,.18)
    # Small foliage on outer edges. Keep central 220–500 mostly clear for route/nodes.
    for j in range(18):
        y=(j*73+i*31)%1230+25
        lx=18+(j*29+i*11)%112
        rx=590+(j*23+i*17)%112
        leaf_cluster(s,lx,y,.35+(j%3)*.11,p['leaf'] if j%2 else p['light'])
    for j in range(12):
        x=170+(j*43+i*19)%380; y=(j*97+i*23)%1240+20
        s.circle(x,y,1.6+(j%3)*.5,p['gold'],op=.4+(j%2)*.18)

def generate():
    OUT.mkdir(parents=True,exist_ok=True)
    for i,(p,scene) in enumerate(zip(PALETTES,SCENES),1):
        s=Scene(i,p); s.defs(); draw_common_edges(s,i); scene(s)
        file=OUT/f'{i:02d}.svg'; file.write_text(s.finish(),encoding='utf-8')
        root=ET.fromstring(file.read_text(encoding='utf-8'))
        assert root.attrib['viewBox']=='0 0 720 1280', file
        assert not any(e.tag.endswith('image') for e in root.iter()), f'raster asset in {file}'
        assert len(file.read_text(encoding='utf-8')) > 5000, (file, file.stat().st_size)
    assert len(list(OUT.glob('*.svg')))==17
    print('Generated 17 portrait SVG region vignettes (720x1280).')

if __name__=='__main__': generate()
