#!/usr/bin/env python3
"""Generate Nihongo Quest's original, editable SVG illustration assets.

The 17 environment compositions and 17 boss silhouettes are art-directed per subject.
Helpers only shorten common vector construction (gradients, foliage and surface marks);
no raster artwork, external files, filters, or bitmap textures are used.
"""
from pathlib import Path
from xml.etree import ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
REGIONS = ROOT / 'assets' / 'artwork' / 'regions'
ARENAS = ROOT / 'assets' / 'artwork' / 'arenas'
BOSSES = ROOT / 'assets' / 'artwork' / 'bosses'

PALETTES = [
    dict(sky1='#182f59', sky2='#77b6d9', sky3='#e9ddb9', far='#7898ac', mid='#486c76', ground='#294c4b', water='#287c9a', water2='#7dd4df', wood='#805642', roof='#35455c', red='#cb5c54', green='#426e59', glow='#f5d6a1', shade='#172c45'),
    dict(sky1='#1b4265', sky2='#75c8de', sky3='#e8e6ba', far='#76a8a0', mid='#507f65', ground='#36644f', water='#227ca1', water2='#98edf0', wood='#8b6442', roof='#3c5551', red='#ca6a4e', green='#4c965e', glow='#fbe0a5', shade='#19384b'),
    dict(sky1='#25466f', sky2='#91cee2', sky3='#ffe2b2', far='#7998ae', mid='#567e70', ground='#3b6657', water='#217fa9', water2='#9be8e5', wood='#845339', roof='#3a4e5b', red='#db524b', green='#4f895b', glow='#ffdca0', shade='#1a314b'),
    dict(sky1='#19385b', sky2='#80b9db', sky3='#f2d8ad', far='#779ab6', mid='#657e7c', ground='#4d6358', water='#397e9c', water2='#9edce4', wood='#72513d', roof='#35465e', red='#c75549', green='#487d5a', glow='#f9d99b', shade='#182b45'),
    dict(sky1='#3477a6', sky2='#9bd5e5', sky3='#fff0b8', far='#8fb4c1', mid='#86a96a', ground='#71944d', water='#3e93a5', water2='#c1e8b1', wood='#8b5e42', roof='#5f614c', red='#c95d44', green='#4e8146', glow='#fff0ba', shade='#2d4d50'),
    dict(sky1='#366da1', sky2='#9fd9e5', sky3='#fff0c2', far='#91bcb2', mid='#8cad65', ground='#61854f', water='#4b9b9e', water2='#c5e9b8', wood='#865c43', roof='#53624f', red='#c9473e', green='#4d8a50', glow='#ffe5a2', shade='#2d4d4b'),
    dict(sky1='#1f2a54', sky2='#654b78', sky3='#d38e7d', far='#615471', mid='#373f5d', ground='#252d4b', water='#315a78', water2='#80b9ca', wood='#6c453c', roof='#292c48', red='#ec564c', green='#47665d', glow='#ffd28a', shade='#11182f'),
    dict(sky1='#2b6695', sky2='#9bdaeb', sky3='#fff0bb', far='#7aa7b9', mid='#649b6b', ground='#477a58', water='#278eaa', water2='#95e4e3', wood='#805b3e', roof='#40545b', red='#c84e45', green='#42895b', glow='#ffedb0', shade='#204b55'),
    dict(sky1='#4c79ab', sky2='#b6dfed', sky3='#ffe5bc', far='#a2bbc8', mid='#7b9c83', ground='#52755c', water='#5c9daa', water2='#c5ebe2', wood='#87573b', roof='#4a5961', red='#c85249', green='#4e895b', glow='#ffe5ad', shade='#354c5e'),
    dict(sky1='#2a4a78', sky2='#7bb2d4', sky3='#f5d3a2', far='#667f98', mid='#5d6870', ground='#3e4c58', water='#37788f', water2='#b5d9d8', wood='#72513f', roof='#3a4554', red='#bd5140', green='#526958', glow='#ffcf79', shade='#1c2a41'),
    dict(sky1='#132e4d', sky2='#27677b', sky3='#80a48d', far='#456f70', mid='#315c50', ground='#203d3f', water='#1b696f', water2='#75c5ad', wood='#56473d', roof='#2c4b45', red='#a94d43', green='#46845d', glow='#c1f0c3', shade='#0b1d32'),
    dict(sky1='#5c405d', sky2='#c47a72', sky3='#f5c88d', far='#9e807b', mid='#8a624e', ground='#5d4a46', water='#657b84', water2='#c1d4c7', wood='#775041', roof='#58404a', red='#d45b3d', green='#8d623f', glow='#ffd28a', shade='#342b3c'),
    dict(sky1='#071d4c', sky2='#244c83', sky3='#466c9a', far='#395a78', mid='#2f5f61', ground='#1b3c4c', water='#164a78', water2='#83bfd6', wood='#5d493d', roof='#24364e', red='#a64f51', green='#3e6b5b', glow='#e7d1a2', shade='#07152f'),
    dict(sky1='#30244f', sky2='#875378', sky3='#f2a37d', far='#786078', mid='#4e4a59', ground='#323346', water='#465f7c', water2='#a9d7d5', wood='#795044', roof='#423448', red='#e55d48', green='#4e6959', glow='#ffd17b', shade='#20192e'),
    dict(sky1='#347bb0', sky2='#94d5e8', sky3='#fce9bd', far='#82b4c3', mid='#4c8e87', ground='#326a68', water='#2485b3', water2='#9eeced', wood='#94684b', roof='#435968', red='#ce594b', green='#4a936b', glow='#fff0bc', shade='#214c60'),
    dict(sky1='#3a253a', sky2='#9b5344', sky3='#ffd18a', far='#65515a', mid='#4a4145', ground='#292e36', water='#4e5155', water2='#ed8a55', wood='#59423c', roof='#33343e', red='#dd4930', green='#4f5748', glow='#ffe16f', shade='#1c202b'),
    dict(sky1='#334d89', sky2='#a2cfe7', sky3='#ffe6b0', far='#8aa9ba', mid='#678b85', ground='#465e61', water='#5b99b4', water2='#d4e8df', wood='#80624b', roof='#4b5160', red='#bb4f47', green='#66845d', glow='#f7d987', shade='#253b5c'),
]

class SVG:
    def __init__(self, prefix, width=1280, height=720):
        self.prefix, self.width, self.height = prefix, width, height
        self.parts = []
    def add(self, s): self.parts.append(s)
    def path(self, d, fill, stroke=None, sw=1, opacity=1, extra=''):
        stroke_attr = f' stroke="{stroke}" stroke-width="{sw}" stroke-linejoin="round" stroke-linecap="round"' if stroke else ''
        op = '' if opacity == 1 else f' opacity="{opacity:.3f}"'
        self.add(f'<path d="{d}" fill="{fill}"{stroke_attr}{op} {extra}/>')
    def poly(self, points, fill, stroke=None, sw=1, opacity=1):
        pts = ' '.join(f'{x:.1f},{y:.1f}' for x,y in points)
        self.add(f'<polygon points="{pts}" fill="{fill}"' + (f' stroke="{stroke}" stroke-width="{sw}" stroke-linejoin="round"' if stroke else '') + ('' if opacity == 1 else f' opacity="{opacity:.3f}"') + '/>')
    def rect(self,x,y,w,h,fill,rx=0,stroke=None,sw=1,opacity=1):
        self.add(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{fill}"' + (f' stroke="{stroke}" stroke-width="{sw}"' if stroke else '') + ('' if opacity == 1 else f' opacity="{opacity:.3f}"') + '/>')
    def circle(self,cx,cy,r,fill,stroke=None,sw=1,opacity=1):
        self.add(f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{fill}"' + (f' stroke="{stroke}" stroke-width="{sw}"' if stroke else '') + ('' if opacity == 1 else f' opacity="{opacity:.3f}"') + '/>')
    def ellipse(self,cx,cy,rx,ry,fill,stroke=None,sw=1,opacity=1):
        self.add(f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="{fill}"' + (f' stroke="{stroke}" stroke-width="{sw}"' if stroke else '') + ('' if opacity == 1 else f' opacity="{opacity:.3f}"') + '/>')
    def line(self,x1,y1,x2,y2,stroke,sw=1,opacity=1):
        self.add(f'<path d="M{x1},{y1} L{x2},{y2}" fill="none" stroke="{stroke}" stroke-width="{sw}" stroke-linecap="round"' + ('' if opacity == 1 else f' opacity="{opacity:.3f}"') + '/>')
    def group(self, content, transform=''):
        self.add(f'<g transform="{transform}">{content}</g>')
    def defs(self, p):
        q=self.prefix
        self.add(f'''<defs>
 <linearGradient id="{q}sky" x1="0" y1="0" x2="0" y2="1"><stop stop-color="{p['sky1']}"/><stop offset="0.57" stop-color="{p['sky2']}"/><stop offset="1" stop-color="{p['sky3']}"/></linearGradient>
 <linearGradient id="{q}far" x1="0" y1="0" x2="0.2" y2="1"><stop stop-color="{p['far']}"/><stop offset="1" stop-color="{p['mid']}"/></linearGradient>
 <linearGradient id="{q}ground" x1="0" y1="0" x2="0" y2="1"><stop stop-color="{p['mid']}"/><stop offset="1" stop-color="{p['ground']}"/></linearGradient>
 <linearGradient id="{q}water" x1="0" y1="0" x2="0.2" y2="1"><stop stop-color="{p['water2']}"/><stop offset="0.38" stop-color="{p['water']}"/><stop offset="1" stop-color="{p['shade']}"/></linearGradient>
 <linearGradient id="{q}wood" x1="0" y1="0" x2="1" y2="0.3"><stop stop-color="{p['shade']}"/><stop offset="0.34" stop-color="{p['wood']}"/><stop offset="0.72" stop-color="{p['wood']}"/><stop offset="1" stop-color="{p['shade']}"/></linearGradient>
 <linearGradient id="{q}roof" x1="0" y1="0" x2="0.4" y2="1"><stop stop-color="{p['roof']}"/><stop offset="0.5" stop-color="{p['shade']}"/><stop offset="1" stop-color="{p['roof']}"/></linearGradient>
 <linearGradient id="{q}green" x1="0" y1="0" x2="0.4" y2="1"><stop stop-color="{p['green']}"/><stop offset="1" stop-color="{p['ground']}"/></linearGradient>
 <linearGradient id="{q}red" x1="0" y1="0" x2="0.4" y2="1"><stop stop-color="{p['red']}"/><stop offset="1" stop-color="{p['shade']}"/></linearGradient>
 <radialGradient id="{q}glow"><stop stop-color="{p['glow']}" stop-opacity=".85"/><stop offset="1" stop-color="{p['glow']}" stop-opacity="0"/></radialGradient>
 <linearGradient id="{q}gold" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#fff2bd"/><stop offset=".28" stop-color="#d9aa55"/><stop offset=".55" stop-color="#fff0aa"/><stop offset="1" stop-color="#9d6533"/></linearGradient>
 <linearGradient id="{q}stone" x1="0" y1="0" x2="0.5" y2="1"><stop stop-color="#d2d0bb"/><stop offset=".45" stop-color="#858f91"/><stop offset="1" stop-color="#4d606a"/></linearGradient>
 <clipPath id="{q}frame"><rect width="1280" height="720"/></clipPath>
 </defs>''')
    def finish_region(self, bg='#22394f'):
        return f'''<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="720" viewBox="0 0 1280 720" role="img" aria-label="Original Nihongo Quest Japanese fantasy environment" preserveAspectRatio="xMidYMid meet"><title>Original Japanese fantasy region illustration</title>{''.join(self.parts)}</svg>'''
    def finish_boss(self):
        return f'''<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024" role="img" aria-label="Original Nihongo Quest boss character" preserveAspectRatio="xMidYMid meet"><title>Original fantasy boss character</title>{''.join(self.parts)}</svg>'''

# Small environmental motifs are hand-positioned by each art-directed composition.
def cloud(s,x,y,k=1, col='#fff7e4',op=.28):
    s.path(f'M{x-70*k},{y+5*k} C{x-82*k},{y-15*k} {x-57*k},{y-30*k} {x-36*k},{y-23*k} C{x-24*k},{y-52*k} {x+14*k},{y-43*k} {x+20*k},{y-20*k} C{x+48*k},{y-34*k} {x+72*k},{y-12*k} {x+61*k},{y+5*k} Z', col, opacity=op)
    s.path(f'M{x-53*k},{y+1*k} Q{x-23*k},{y-7*k} {x+4*k},{y+1*k} T{x+47*k},{y+1*k}', 'none', stroke='#fff8df', sw=2*k, opacity=op*.65)

def pine(s,x,y,k,green='#315d55',shade='#1c3e48'):
    s.path(f'M{x},{y-170*k} L{x-50*k},{y-88*k} L{x-30*k},{y-89*k} L{x-68*k},{y-32*k} L{x-37*k},{y-38*k} L{x-75*k},{y+9*k} L{x-15*k},{y+5*k} L{x-15*k},{y+45*k} L{x+16*k},{y+45*k} L{x+16*k},{y+3*k} L{x+71*k},{y+12*k} L{x+35*k},{y-39*k} L{x+59*k},{y-32*k} L{x+26*k},{y-88*k} L{x+43*k},{y-84*k} Z', green, shade, max(1,1.3*k))
    s.path(f'M{x},{y-165*k} L{x-31*k},{y-87*k} L{x-8*k},{y-94*k} L{x-38*k},{y-36*k} L{x-13*k},{y-44*k} L{x-49*k},{y+1*k} L{x-5*k},{y-4*k} L{x-2*k},{y+4*k}', '#79a28a', opacity=.5)
    s.path(f'M{x+3*k},{y-137*k} Q{x+24*k},{y-73*k} {x+6*k},{y-24*k}', 'none', stroke='#a0b49b', sw=1.8*k, opacity=.6)
    s.rect(x-5*k,y+4*k,10*k,42*k, '#78533e', rx=3*k)

def broadleaf(s,x,y,k,colors):
    dark,mid,light=colors
    s.path(f'M{x-10*k},{y} C{x-26*k},{y-49*k} {x-14*k},{y-87*k} {x+2*k},{y-111*k} C{x+26*k},{y-79*k} {x+42*k},{y-43*k} {x+24*k},{y} Z', '#76513d', opacity=.98)
    for dx,dy,rx,ry,c in [(-28,-84,30,28,dark),(8,-105,38,30,mid),(38,-77,29,26,light),(-38,-50,28,23,mid),(2,-57,37,27,dark),(32,-40,23,20,light),(-5,-132,20,18,light)]:
        s.ellipse(x+dx*k,y+dy*k,rx*k,ry*k,c,opacity=.92)
    s.path(f'M{x-5*k},{y-8*k} Q{x+4*k},{y-53*k} {x+4*k},{y-98*k}', 'none', stroke='#b7c493', sw=1.8*k, opacity=.6)
    for dx,dy in [(-31,-88),(19,-102),(47,-72),(-45,-52),(9,-65),(32,-43),(-4,-136)]:
        s.ellipse(x+dx*k,y+dy*k,4*k,2*k,'#d2d9a1',opacity=.55)

def house(s,x,y,k,p,style='farm',flip=False):
    # Each build uses the same architectural logic but distinct proportions/details and materials.
    w=190*k; h=120*k; x0=x-w/2
    if style=='stilt':
        s.path(f'M{x0+15*k},{y-35*k} L{x0+w-15*k},{y-35*k} L{x0+w-25*k},{y+68*k} L{x0+25*k},{y+68*k} Z',f'url(#{s.prefix}wood)',p['shade'],1.8*k)
        for xx in (x0+35*k,x0+80*k,x0+125*k,x0+160*k): s.line(xx,y+47*k,xx,y+105*k,'#684832',4*k)
        s.path(f'M{x0-12*k},{y-36*k} L{x},{y-90*k} L{x0+w+18*k},{y-36*k} L{x0+w-6*k},{y-46*k} L{x0+5*k},{y-46*k} Z',f'url(#{s.prefix}roof)',p['shade'],1.6*k)
    elif style=='station':
        s.path(f'M{x0+10*k},{y-44*k} L{x0+w-10*k},{y-44*k} L{x0+w-10*k},{y+60*k} L{x0+10*k},{y+60*k} Z',f'url(#{s.prefix}wood)',p['shade'],1.6*k)
        s.path(f'M{x0-25*k},{y-44*k} L{x0+30*k},{y-94*k} L{x0+w-20*k},{y-94*k} L{x0+w+27*k},{y-44*k} L{x0+w+5*k},{y-53*k} L{x0-4*k},{y-53*k} Z',f'url(#{s.prefix}roof)',p['shade'],2*k)
        s.rect(x0+70*k,y-23*k,46*k,83*k,'#24394c',rx=2*k,stroke='#c8a476',sw=1.3*k)
        s.rect(x0+19*k,y-21*k,37*k,39*k,'#ddbd83',rx=1*k,stroke=p['shade'],sw=1*k)
        s.rect(x0+137*k,y-21*k,34*k,39*k,'#ddbd83',rx=1*k,stroke=p['shade'],sw=1*k)
    else:
        s.path(f'M{x0+15*k},{y-34*k} L{x0+w-12*k},{y-34*k} L{x0+w-15*k},{y+59*k} L{x0+15*k},{y+59*k} Z',f'url(#{s.prefix}wood)',p['shade'],1.6*k)
        roof_d=(f'M{x0-25*k},{y-34*k} Q{x0+10*k},{y-42*k} {x0+35*k},{y-82*k} Q{x0+w/2},{y-60*k} {x0+w-35*k},{y-82*k} Q{x0+w-8*k},{y-42*k} {x0+w+25*k},{y-34*k} L{x0+w-5*k},{y-44*k} L{x0+5*k},{y-44*k} Z')
        s.path(roof_d,f'url(#{s.prefix}roof)',p['shade'],1.8*k)
        s.path(f'M{x0+20*k},{y-36*k} Q{x0+w/2},{y-67*k} {x0+w-20*k},{y-36*k}', 'none', stroke='#91a1a0', sw=2*k, opacity=.65)
        s.rect(x0+24*k,y-18*k,33*k,35*k,'#263d4c',rx=1*k,stroke='#c9a878',sw=1*k)
        s.rect(x0+w-58*k,y-18*k,31*k,35*k,'#263d4c',rx=1*k,stroke='#c9a878',sw=1*k)
        s.rect(x0+w*.43,y-28*k,34*k,87*k,'#5c382e',rx=2*k,stroke='#d2a66e',sw=1*k)
    # Fine roof courses: short, staggered marks follow each roof silhouette rather
    # than a generic texture fill. Their quiet contrast keeps the architecture legible.
    if style == 'station':
        roof_rows = [(-50, 37, w-23), (-59, 40, w-27), (-68, 43, w-31), (-77, 46, w-35), (-86, 49, w-39)]
    elif style == 'stilt':
        roof_rows = [(-48, 53, w-43), (-56, 61, w-51), (-64, 69, w-59), (-72, 77, w-67)]
    else:
        roof_rows = [(-47, 45, w-43), (-52, 48, w-46), (-57, 52, w-50)]
    for row, (dy, left_inset, right_edge) in enumerate(roof_rows):
        xx = x0 + left_inset*k
        end_x = x0 + right_edge*k
        while xx + 10*k < end_x:
            yy = y + dy*k + ((xx//max(1, 13*k)) % 2) * 1.1*k
            s.path(f'M{xx:.2f},{yy:.2f} q{4*k:.2f},{-1.1*k:.2f} {10*k:.2f},0',
                   'none', stroke='#b9b7a4' if row%2==0 else '#8c9690',
                   sw=max(.65,1.15*k), opacity=.58)
            xx += 14*k

    # Window lattice, warm pane glints, and the woodwork around each doorway.
    if style == 'station':
        window_specs = [(x0+19*k,y-21*k,37*k,39*k),(x0+137*k,y-21*k,34*k,39*k)]
        door_spec = (x0+70*k,y-23*k,46*k,83*k)
    elif style == 'stilt':
        window_specs = []
        door_spec = None
    else:
        window_specs = [(x0+24*k,y-18*k,33*k,35*k),(x0+w-58*k,y-18*k,31*k,35*k)]
        door_spec = (x0+w*.43,y-28*k,34*k,87*k)
    for wx,wy,ww,wh in window_specs:
        s.line(wx+ww*.5,wy+3*k,wx+ww*.5,wy+wh-3*k,'#d8b77e',max(.8,1.15*k),opacity=.9)
        s.line(wx+3*k,wy+wh*.52,wx+ww-3*k,wy+wh*.52,'#d8b77e',max(.8,1.15*k),opacity=.9)
        s.path(f'M{wx+3*k:.2f},{wy+4*k:.2f} l{ww*.25:.2f},{wh*.12:.2f}',
               'none',stroke='#fff0c1',sw=max(.65,1.1*k),opacity=.65)
    if door_spec:
        dx,dy,dw,dh = door_spec
        for frac in (.24,.48,.72):
            s.path(f'M{dx+dw*frac:.2f},{dy+5*k:.2f} q{-1.2*k:.2f},{dh*.42:.2f} 0,{dh-10*k:.2f}',
                   'none',stroke='#d9a977',sw=max(.7,1.25*k),opacity=.52)
        s.line(dx+3*k,dy+dh*.56,dx+dw-3*k,dy+dh*.56,'#b77c54',max(.7,1.2*k),opacity=.7)
        s.circle(dx+dw*.78,dy+dh*.57,2.1*k,'#e9cf83',stroke='#644735',sw=max(.5,.8*k))
    # Small foundation stones break up the hard wall/ground seam.
    for i in range(7):
        sx=x0+(12+i*26)*k
        s.path(f'M{sx:.2f},{y+59*k:.2f} l{4*k:.2f},{-3*k:.2f} {7*k:.2f},{1*k:.2f} {2*k:.2f},{4*k:.2f} {-9*k:.2f},{1*k:.2f} Z',
               '#a7a28e',stroke='#56605b',sw=max(.5,.8*k),opacity=.82)
    # Beams, roof seams, warm interior glows, and shaded footing.
    s.line(x0+12*k,y+2*k,x0+w-12*k,y+2*k,'#d4a573',2*k,opacity=.75)
    for t in range(6):
        xx=x0+(18+t*29)*k
        s.line(xx,y-36*k,xx+(t%2)*2*k,y-20*k,'#d8ae7c',1*k,opacity=.55)
    s.ellipse(x,y+64*k,112*k,12*k,'#132d3a',opacity=.30)
    for dx in (-47,47):
        s.rect(x+dx*k-8*k,y+47*k,16*k,13*k,'#827b69',rx=2*k,opacity=.95)

def lantern(s,x,y,k,p):
    s.line(x,y-44*k,x,y-30*k,'#3b3037',2*k)
    s.path(f'M{x-14*k},{y-30*k} Q{x},{y-40*k} {x+14*k},{y-30*k} L{x+11*k},{y+13*k} Q{x},{y+24*k} {x-11*k},{y+13*k} Z',f'url(#{s.prefix}red)','#4a3035',1.1*k)
    s.rect(x-12*k,y-29*k,24*k,5*k,'#d7ae69',rx=2*k)
    s.rect(x-12*k,y+11*k,24*k,5*k,'#d7ae69',rx=2*k)
    s.ellipse(x,y-5*k,17*k,29*k,f'url(#{s.prefix}glow)',opacity=.6)
    s.line(x,y+17*k,x,y+29*k,'#d0a467',1.6*k)

def bridge(s,x1,x2,y,k,p,red=True):
    mid=(x1+x2)/2
    color=f'url(#{s.prefix}red)' if red else f'url(#{s.prefix}wood)'
    s.path(f'M{x1},{y} Q{mid},{y-83*k} {x2},{y} L{x2-8*k},{y+14*k} Q{mid},{y-53*k} {x1+8*k},{y+14*k} Z',color,p['shade'],2*k)
    s.path(f'M{x1-7*k},{y-9*k} Q{mid},{y-96*k} {x2+7*k},{y-9*k}', 'none', stroke='#e9c493', sw=5*k)
    s.path(f'M{x1},{y+6*k} Q{mid},{y-56*k} {x2},{y+6*k}', 'none', stroke='#6e4841' if red else '#d6ad76', sw=2.3*k)
    for i in range(11):
        t=i/10
        xx=x1+(x2-x1)*t
        yy=y-9*k-83*k*4*t*(1-t)
        s.line(xx,yy,xx,yy+18*k,'#eacb98',2*k)
    s.path(f'M{x1-12*k},{y+13*k} Q{mid},{y-43*k} {x2+12*k},{y+13*k}', 'none', stroke=p['shade'], sw=3*k)

def rocks(s, coords, fill='url(#stone)', stroke='#4c6672'):
    for i,(x,y,rx,ry) in enumerate(coords):
        s.path(f'M{x-rx},{y} Q{x-rx*.8},{y-ry*1.2} {x-rx*.15},{y-ry} Q{x+rx*.8},{y-ry*1.15} {x+rx},{y-ry*.15} L{x+rx*.75},{y+ry*.6} Q{x},{y+ry} {x-rx*.8},{y+ry*.5} Z',fill,stroke,1.3)
        s.path(f'M{x-rx*.35},{y-ry*.55} Q{x},{y-ry*.8} {x+rx*.45},{y-ry*.4}', 'none', stroke='#e4ddc6', sw=1.4, opacity=.55)

def leaves(s, clusters, colors):
    dark,mid,light=colors
    for x,y,k in clusters:
        s.path(f'M{x-24*k},{y+17*k} C{x-42*k},{y-7*k} {x-20*k},{y-27*k} {x+1*k},{y-15*k} C{x+19*k},{y-43*k} {x+44*k},{y-19*k} {x+29*k},{y+3*k} C{x+43*k},{y+17*k} {x+18*k},{y+28*k} {x-24*k},{y+17*k} Z',mid,opacity=.97)
        s.path(f'M{x-23*k},{y+13*k} Q{x+1*k},{y-1*k} {x+27*k},{y-19*k}', 'none', stroke=light, sw=1.8*k, opacity=.65)
        s.ellipse(x-8*k,y-3*k,7*k,5*k,dark,opacity=.78)
        s.ellipse(x+17*k,y+7*k,6*k,4*k,light,opacity=.7)

def blossom(s,x,y,k,color='#f4b8c9',gold='#ffe5ae'):
    for i in range(5):
        import math
        a=i*math.pi*2/5 - math.pi/2
        cx=x+math.cos(a)*10*k; cy=y+math.sin(a)*10*k
        s.ellipse(cx,cy,7*k,10*k,color,stroke='#f8d9e1',sw=.7*k)
    s.circle(x,y,4*k,gold,stroke='#b98258',sw=.7*k)

def grass(s,x,y,k,color='#c5d58c'):
    for i in range(5):
        dx=(i-2)*4*k
        s.path(f'M{x+dx},{y} Q{x+dx-8*k},{y-10*k} {x+dx-5*k},{y-21*k}', 'none', stroke=color, sw=1.7*k, opacity=.9)

# Scene 01 — a fog-layered cedar settlement with a stepping river and old roofs.
def region_01(s,p):
    s.rect(0,0,1280,720,f'url(#{s.prefix}sky)')
    s.ellipse(940,160,210,160,'url(#s01glow)',opacity=.85); cloud(s,250,130,1.1); cloud(s,685,97,.72)
    s.path('M0 395 L95 265 180 344 305 207 415 341 546 221 671 354 811 238 930 330 1050 195 1172 324 1280 252 V500 H0Z','url(#s01far)')
    s.path('M0 343 L82 276 137 322 191 259 256 330 316 281 402 366 492 289 575 358 670 285 744 360 832 306 920 372 1015 285 1098 347 1184 277 1280 356 V525 H0Z','#567f88',opacity=.65)
    # Cedar wall frames the village
    pine(s,70,487,.94,'#264d4f','#153445'); pine(s,190,479,.70,'#35665d','#1b4248'); pine(s,1180,466,1.12,'#1e4949','#102d3c'); pine(s,1080,482,.76,'#427365','#193e43')
    s.path('M0 491 Q210 437 370 488 T726 475 T1015 483 T1280 438 V720 H0Z','url(#s01ground)')
    s.path('M0 540 C210 495 305 540 437 557 C590 576 664 620 820 595 C1004 568 1110 610 1280 578 V720 H0Z','#294f4e')
    house(s,300,442,.78,p); house(s,560,402,.65,p,'stilt'); house(s,930,431,.9,p)
    # River has its own winding reflective planes
    s.path('M0 655 C173 604 284 680 440 646 C614 607 700 561 853 598 C1015 636 1111 591 1280 625 L1280 720 H0Z','url(#s01water)')
    s.path('M0 670 C190 624 260 699 448 664 S708 580 856 617 S1098 613 1280 642', 'none', stroke='#a5ebef', sw=5, opacity=.62)
    for i in range(12):
        x=60+i*97; y=676+(i%3)*11
        s.path(f'M{x},{y} q23,-7 45,0', 'none', stroke='#b7e8e6', sw=2, opacity=.55)
    bridge(s,390,725,621,.85,p,True)
    # Stone path and echo rings drift through the fog
    rocks(s,[(168,578,31,17),(220,596,25,14),(271,610,22,12),(319,623,24,12)],'url(#s01stone)')
    for cx,cy,r in [(790,334,30),(790,334,47),(790,334,64)]: s.circle(cx,cy,r,'none',stroke='#ddf4ec',sw=2,opacity=.26)
    for x in (810,880,950): lantern(s,x,493+(x%2)*13,.75,p)
    # blossom branches with individually placed flowers
    s.path('M18 370 Q110 314 160 362 T288 352','none',stroke='#4c5b53',sw=11)
    for x,y,k in [(48,345,.95),(104,322,.8),(145,348,.8),(192,336,.9),(246,354,.76),(290,341,.75)]:
        for dx,dy in [(-9,0),(0,-5),(10,1)]: blossom(s,x+dx*k,y+dy*k,k*.72,'#f4bbd1')
    for x,y,k in [(410,710,.7),(760,704,.6),(1020,700,.5)]: blossom(s,x,y,k)

# Scene 02 — a serpentine counting creek, polished stepping stones, bamboo and abacus gate.
def region_02(s,p):
    s.rect(0,0,1280,720,'url(#s02sky)'); s.ellipse(1060,125,160,140,'url(#s02glow)',opacity=.8); cloud(s,360,115,.7); cloud(s,780,176,.9)
    s.path('M0 420 L110 310 215 370 340 250 475 380 580 270 710 390 845 256 955 365 1085 245 1190 346 1280 294 V530 H0Z','url(#s02far)')
    s.path('M0 476 Q150 398 290 462 T580 438 T865 455 T1110 421 T1280 455 V720 H0Z','url(#s02ground)')
    # Creek curls into broad bends with bright rapids and layered banks
    s.path('M930 245 C1050 324 832 387 897 465 C960 544 783 546 703 590 C608 646 768 686 919 720 H1280 V535 C1090 512 1112 462 1052 414 C990 360 1132 319 1123 260 Z','url(#s02water)')
    s.path('M920 256 C1023 331 825 396 889 466 C952 535 782 551 710 592 C630 640 774 685 923 720','none',stroke='#b6f2ec',sw=7,opacity=.72)
    for i in range(16):
        x=935+(i%4)*48; y=328+i*21
        s.path(f'M{x},{y} q25,-4 46,2', 'none',stroke='#b1f0e8',sw=2,opacity=.65)
    # Stepping stones sweep in an S rhythm across the water
    rocks(s,[(914,315,35,18),(870,349,28,16),(828,387,31,17),(803,430,27,14),(823,477,29,15),(866,514,30,16),(830,565,33,18),(778,601,32,17),(749,650,25,13)],'url(#s02stone)')
    # little stream shrines and counting markers
    house(s,345,447,.73,p,'stilt'); house(s,570,430,.56,p)
    s.path('M122 451 L122 345 M122 373 L81 337 M122 389 L155 350 M122 413 L83 386 M122 424 L160 398','none',stroke='#745b3e',sw=7)
    for i in range(5):
        s.ellipse(122,365+i*17,14,9,['#d7ae6b','#bf6251','#61989b','#d6c28a','#8da86c'][i],stroke='#533f35',sw=1.5)
    # bamboo grove at the right bank
    for x,h in [(1134,310),(1190,350),(1242,282),(1060,278)]:
        s.path(f'M{x} 520 Q{x-5} {520-h/2} {x+4} {520-h}', 'none',stroke='#2f6a52',sw=15)
        for y in range(520-h+30,520,43): s.line(x-6,y,x+9,y,'#99b978',2,opacity=.7)
        s.path(f'M{x},{520-h+45} q-38,-26 -52,-9 q25,4 52,9 M{x},{520-h+84} q35,-31 55,-19 q-18,16 -55,19 M{x},{520-h+142} q-30,-23 -51,-12', 'none',stroke='#417e58',sw=8)
    s.path('M0 637 Q220 596 443 641 T882 632 T1280 616 V720 H0Z','#315d4e')
    for i in range(28):
        x=35+i*47; y=654+(i%4)*13
        grass(s,x,y,.65,['#d6d9a0','#90b78a','#f2d9a0'][i%3])
    # a small arched footbridge in the far bend
    s.path('M740 360 Q818 285 904 341 L894 356 Q819 318 752 374 Z','#b65e49','#5d4b46',2)
    for i in range(7): s.line(755+i*21,354-i*2,755+i*21,369-i*2,'#f3c89a',2)
    cloud(s,200,204,.55)

# Scene 03 — red arched bridge and a lantern-lit old-town stream crossing.
def region_03(s,p):
    s.rect(0,0,1280,720,'url(#s03sky)'); s.ellipse(205,126,195,155,'url(#s03glow)',opacity=.7); cloud(s,530,100,.7)
    s.path('M0 352 L126 253 221 317 334 227 441 331 550 251 682 350 814 238 921 328 1047 223 1153 316 1280 252 V470 H0Z','url(#s03far)')
    s.path('M0 453 Q165 398 335 433 T687 413 T1008 435 T1280 405 V720 H0Z','url(#s03ground)')
    # old town with asymmetrical roof silhouettes
    house(s,220,428,.80,p); house(s,445,390,.60,p,'stilt'); house(s,1030,414,.86,p); house(s,1170,452,.57,p)
    # waterfront band and reflections
    s.path('M0 555 C187 512 343 569 475 548 C625 521 708 574 862 541 C1010 510 1157 563 1280 534 V720 H0Z','url(#s03water)')
    for i in range(17):
        x=18+i*76; y=590+(i%4)*21
        s.path(f'M{x},{y} q{25+(i%3)*8},-6 {51+(i%3)*6},1', 'none',stroke='#a1e7eb',sw=2.5,opacity=.52)
    bridge(s,250,1050,525,1.18,p,True)
    # tiled bridge deck planks
    for i in range(18):
        x=266+i*43; y=519-106*4*(i/18)*(1-i/18)
        s.line(x,y,x+2,y+14,'#f7c993',2.2,opacity=.85)
    for x,y in [(238,431),(1060,425),(168,470),(1110,470)]: lantern(s,x,y,.93,p)
    # stone walkway feeds to bridge
    rocks(s,[(117,614,36,20),(176,631,28,15),(230,640,24,13),(1100,613,33,17),(1151,629,27,15)],'url(#s03stone)')
    # tree blossoming on far left and right bank
    broadleaf(s,88,478,.94,('#3f6659','#8a9e77','#c4b98e'))
    leaves(s,[(1130,330,.85),(1192,346,.7),(1224,311,.65)],('#3e754f','#73a667','#c1c978'))
    for x,y,k in [(56,325,.9),(90,295,.75),(130,316,.78),(1155,294,.65),(1210,277,.8)]: blossom(s,x,y,k)
    # distant torii peeking through the bridge rails
    s.path('M650 373 L650 438 M715 373 L715 438 M640 374 L725 374 L735 364 L630 364 Z M646 384 L720 384','none',stroke='#b95347',sw=7)
    cloud(s,930,151,.63)

# Scene 04 — station platform, iron tracks in perspective, rail signs and mountain range.
def region_04(s,p):
    s.rect(0,0,1280,720,'url(#s04sky)'); cloud(s,252,105,.8); cloud(s,833,130,.68)
    s.path('M0 377 L82 302 181 339 291 211 382 329 511 222 617 342 738 255 864 337 1000 222 1113 316 1216 263 1280 312 V480 H0Z','url(#s04far)')
    s.path('M0 460 Q220 407 396 460 T800 441 T1110 431 T1280 448 V720 H0Z','url(#s04ground)')
    # timber station sits above a platform
    house(s,360,417,.96,p,'station'); house(s,960,435,.48,p)
    s.path('M80 499 L1200 499 L1280 540 L0 540 Z','#a99e86','#5c5d59',2)
    s.path('M0 541 L1280 541 L1280 561 L0 561 Z','#545e61')
    for i in range(26):
        x=i*52-12
        s.path(f'M{x},543 L{x+32},543 L{x+46},559 L{x+14},559 Z','#755a46',opacity=.9)
    # two tracks converging at a central vanishing point
    s.path('M350 720 L578 540 L610 540 L480 720 Z','#4a535b')
    s.path('M510 720 L638 540 L664 540 L674 720 Z','#374a57')
    s.path('M240 720 L566 540 M430 720 L605 540 M780 720 L655 540 M1010 720 L683 540','none',stroke='#b4b7a8',sw=5)
    s.path('M175 720 L554 540 M1110 720 L696 540','none',stroke='#d0b47f',sw=2,opacity=.8)
    # canopy beams and platform lanterns
    s.path('M120 500 L120 376 L575 376 L575 500 M120 395 L575 395','none',stroke='#6d4f3a',sw=8)
    for x in (158,260,370,480,550):
        lantern(s,x,454,.65,p)
    # station clock and signboard
    s.circle(463,365,27,'#e8d3a2',stroke='#694c39',sw=4); s.circle(463,365,19,'#f4e9ca',stroke='#9b774e',sw=1.5)
    s.line(463,365,463,352,'#3a4050',3); s.line(463,365,475,371,'#3a4050',2.4)
    s.rect(700,386,100,56,'#304654',rx=3,stroke='#d8b77d',sw=3)
    for i in range(5): s.line(713+i*18,396,713+i*18,434,'#a1bac0',1.4,opacity=.6)
    # overhead rail lines angle in perspective
    s.line(610,330,610,414,'#3d4a56',4); s.line(902,330,902,427,'#3d4a56',4)
    s.line(580,329,935,329,'#7b8a8b',4); s.line(585,322,928,322,'#cfb782',1.5)
    for i in range(10): s.line(600+i*33,329,600+i*33,340,'#7b8a8b',1.4)
    grass(s,72,630,1.5,'#d4d6a3'); grass(s,1160,638,1.2,'#d4d6a3')

# Scene 05 — golden grasslands and windmill with a road through terraced fields.
def region_05(s,p):
    s.rect(0,0,1280,720,'url(#s05sky)'); s.ellipse(1002,131,170,138,'url(#s05glow)',opacity=.82); cloud(s,240,92,.7); cloud(s,662,141,1.05)
    s.path('M0 380 L116 300 222 343 364 222 484 347 612 274 747 369 877 262 1008 348 1114 270 1245 340 1280 326 V480 H0Z','url(#s05far)')
    s.path('M0 434 Q150 376 286 435 T585 423 T887 439 T1128 412 T1280 431 V720 H0Z','#a9bb77')
    # golden fields separated by sweeping field banks
    s.path('M0 489 Q207 418 400 490 Q594 557 795 490 T1280 472 V720 H0Z','#94a95b')
    for i in range(8):
        y=491+i*28
        s.path(f'M0 {y} Q240 {y-70} 475 {y+2} T930 {y-9} T1280 {y-26}', 'none',stroke=['#e7d891','#d1c775','#f1dfa1'][i%3],sw=5,opacity=.88)
    s.path('M0 589 Q285 513 512 604 T916 588 T1280 555 V720 H0Z','#c5bd6b')
    for i in range(31):
        x=(i*101+27)%1270; y=510+(i*29)%188
        grass(s,x,y,.7,['#f1df9e','#e5cb79','#bfd08c'][i%3])
    # windmill: masonry foot, timber tower, vane blades
    s.path('M865 441 L884 270 L948 270 L970 441 Z','#ded2ae','#7f806f',2)
    s.path('M882 300 L951 300 L947 329 L886 329 Z','#b2a88d')
    s.path('M885 353 L952 353 M879 400 L963 400','none',stroke='#9b967b',sw=3)
    s.circle(916,268,15,'#855a3f',stroke='#e3cb94',sw=3)
    for a in [0,90,180,270]:
        import math
        ang=math.radians(a)
        x1=916+math.cos(ang)*14; y1=268+math.sin(ang)*14
        x2=916+math.cos(ang)*132; y2=268+math.sin(ang)*132
        s.path(f'M{x1},{y1} L{x2-15*math.sin(ang)},{y2+15*math.cos(ang)} L{x2+15*math.sin(ang)},{y2-15*math.cos(ang)} Z','#ede0bd','#997c54',2)
        s.line(x1,y1,x2,y2,'#c1a77a',1.5)
    # calligraphy boards on a rural path, but no text in the artwork
    s.path('M0 676 Q244 624 458 663 T826 665 T1280 639','none',stroke='#ddc796',sw=27,opacity=.8)
    s.path('M0 676 Q244 624 458 663 T826 665 T1280 639','none',stroke='#a88b60',sw=2.5,opacity=.8)
    for x,y,tilt in [(164,546,-6),(412,572,6),(1093,527,-5)]:
        s.group(f'<rect x="-28" y="-48" width="56" height="96" rx="2" fill="#d5c094" stroke="#6f5b43" stroke-width="3"/><path d="M-18 -28 H18 M-18 -8 H13 M-18 12 H17 M-18 31 H6" stroke="#786b50" stroke-width="2" opacity=".7"/>',f'translate({x} {y}) rotate({tilt})')
    house(s,210,451,.48,p); house(s,1115,445,.48,p)

# Scene 06 — irrigated topic terraces, rice paddies, little hill shrines and stepped stone walls.
def region_06(s,p):
    s.rect(0,0,1280,720,'url(#s06sky)'); s.ellipse(1085,130,150,130,'url(#s06glow)',opacity=.75); cloud(s,306,101,.8); cloud(s,715,140,.6)
    s.path('M0 377 L120 281 218 327 340 222 452 326 572 229 684 348 810 238 932 326 1072 214 1170 322 1280 265 V470 H0Z','url(#s06far)')
    # step terraces follow the contour rather than generic ground bands
    for i,(y,left,right,col) in enumerate([(398,0,1280,'#92b66c'),(438,0,1240,'#8eac5f'),(482,35,1270,'#80a45b'),(528,0,1210,'#6f9556'),(572,40,1280,'#5d8552'),(622,0,1250,'#4d744c')]):
        s.path(f'M{left},{y} Q{left+180},{y-38} {left+370},{y+5} T{left+720},{y+1} T{right},{y-18} L{right},720 L{left},720 Z',col)
        s.path(f'M{left},{y} Q{left+180},{y-38} {left+370},{y+5} T{left+720},{y+1} T{right},{y-18}', 'none',stroke='#c3cb86',sw=4,opacity=.8)
        # thin water surfaces between rice rows
        for j in range(7):
            x=left+25+j*172
            s.path(f'M{x},{y+20} q44,-8 81,1', 'none',stroke='#bce6d4',sw=2,opacity=.65)
    # a small red shrine crowns the ridge
    s.path('M492 390 L492 443 M556 390 L556 443 M480 389 L568 389 L579 378 L469 378 Z M489 400 L559 400','none',stroke='#bd4f43',sw=7)
    s.path('M477 442 L568 442 L560 451 L484 451 Z','#a7493f')
    house(s,817,413,.56,p); house(s,1055,451,.62,p,'stilt')
    # retaining walls use irregular stone blocks
    for row in range(3):
        y=520+row*46
        for col in range(18):
            x=col*76-15+(row%2)*23
            s.path(f'M{x},{y} l31,-4 15,16 -7,20 -34,3 -10,-16 Z','#9a9b81','#5b6c62',1.4)
            s.line(x+5,y+11,x+25,y+8,'#d4d0a7',1.2,opacity=.6)
    # stone path through lower terrace and flowering border
    s.path('M622 720 C651 669 622 630 665 600 C698 580 748 577 770 552','none',stroke='#d5c9a4',sw=28)
    s.path('M622 720 C651 669 622 630 665 600 C698 580 748 577 770 552','none',stroke='#8a907d',sw=2.5)
    for x,y in [(85,694),(165,680),(280,699),(375,683),(940,687),(1160,675),(1240,701)]: blossom(s,x,y,.65,'#e8c4c0')
    for x,y in [(56,584),(1206,572),(1172,614)]: grass(s,x,y,1.3,'#e2d99e')

# Scene 07 — nighttime umbrella lane, wet stone reflections, hanging lanterns and shop fronts.
def region_07(s,p):
    s.rect(0,0,1280,720,'url(#s07sky)'); s.circle(1040,100,94,'#e4a99b',opacity=.13); cloud(s,810,113,.7,'#b49cc5',.17)
    # close alley walls frame a narrow view of the distant crossing
    s.path('M0 0 H390 L507 720 H0Z','#342d4e'); s.path('M1280 0 H895 L780 720 H1280Z','#282742')
    s.path('M0 0 H325 L440 720 H0Z','#493348'); s.path('M1280 0 H954 L830 720 H1280Z','#3b2b46')
    # lit windows and heavy timber storefronts
    for x,y,w,h in [(52,76,110,142),(192,42,99,123),(1012,60,103,135),(1144,95,91,152),(65,285,134,157),(1050,287,142,165)]:
        s.rect(x,y,w,h,'#5e394d',rx=3,stroke='#bf825f',sw=5)
        s.rect(x+12,y+12,w-24,h-24,'#f4a25f',rx=2)
        s.rect(x+20,y+21,w-40,h-42,'#ffd78a',rx=1,opacity=.48)
        s.line(x+w/2,y+9,x+w/2,y+h-9,'#9b5a4c',4)
        s.line(x+8,y+h*.58,x+w-8,y+h*.58,'#9b5a4c',3)
    # eaves and beams recede toward the alley center
    s.path('M0 0 L421 0 L499 80 L0 138 Z','#201e36','#6b4352',2)
    s.path('M1280 0 L862 0 L784 80 L1280 141 Z','#211d35','#6b4352',2)
    for i in range(8):
        x=10+i*52; s.path(f'M{x},0 L{x+12},0 L{x+80},88 L{x+68},89 Z','#6c3f4c',opacity=.75)
        xr=1270-i*52; s.path(f'M{xr},0 L{xr-12},0 L{xr-80},88 L{xr-68},89 Z','#6c3f4c',opacity=.75)
    # center alley and paving stones
    s.path('M419 0 L864 0 L1005 720 H251 Z','#24283f')
    s.path('M537 90 L743 90 L1000 720 H248 Z','#3b4355')
    for i in range(10):
        y=140+i*58; x1=548-i*23; x2=731+i*27
        s.path(f'M{x1},{y} L{x2},{y} L{x2+10},{y+8} L{x1-8},{y+8} Z','#566173',opacity=.82)
    # lantern canopy zig-zags between buildings
    for i in range(7):
        x=280+i*120; y=116+(i%2)*28
        s.path(f'M{max(0,x-95)},{y-40} Q{x},{y+4} {min(1280,x+95)},{y-40}','none',stroke='#79506a',sw=3)
        lantern(s,x,y,.93 if i%2 else .72,p)
    # umbrellas have separate canopy ribs and saturated fabric panels
    for x,y,r,col in [(350,378,68,'#df5a55'),(912,443,75,'#5f8ebc'),(590,315,48,'#cf8c56')]:
        s.path(f'M{x-r},{y} Q{x},{y-r*1.5} {x+r},{y} Q{x+r*.5},{y+9} {x},{y+2} Q{x-r*.5},{y+11} {x-r},{y} Z',col,'#281f38',2)
        for a in [-.65,-.3,.0,.3,.65]: s.path(f'M{x},{y} Q{x+a*r*.7},{y-r*.6} {x+a*r},{y+1}', 'none',stroke='#f2cc9a',sw=1.3,opacity=.75)
        s.line(x,y,x+4,y+100,'#6d504b',3)
    # puddle reflections
    for i in range(17):
        x=180+i*58; y=650+(i%3)*16
        s.path(f'M{x},{y} q{24+(i%4)*9},-8 {52+(i%3)*5},0', 'none',stroke=['#d58d75','#eeb273','#81b9cf'][i%3],sw=3,opacity=.7)
    s.circle(650,365,125,'url(#s07glow)',opacity=.22)

# Scene 08 — koi pond hills, tiered waterfalls, a red lakeside pavilion and ornamental koi.
def region_08(s,p):
    s.rect(0,0,1280,720,'url(#s08sky)'); s.ellipse(1080,116,155,130,'url(#s08glow)',opacity=.8); cloud(s,267,111,.6); cloud(s,702,92,.76)
    s.path('M0 390 L107 281 201 339 317 233 433 342 544 247 666 355 787 226 896 331 1004 229 1122 320 1228 255 1280 290 V470 H0Z','url(#s08far)')
    s.path('M0 445 Q190 379 356 444 T686 434 T1006 448 T1280 419 V720 H0Z','url(#s08ground)')
    # waterfall in the upper-left cliff with split white sheets
    s.path('M204 327 L327 327 L355 442 L250 476 Z','#677f83','#405e67',2)
    s.path('M251 340 L279 340 L291 438 L273 456 Z','#b9e6e6')
    s.path('M287 338 L309 338 L324 426 L307 447 Z','#edf4df')
    s.path('M250 455 Q283 468 321 443 Q344 461 372 459 L396 480 Q310 522 215 485 Z','#a7e5df',opacity=.8)
    # bowl-like pond wraps the hill, shaded near the shoreline
    s.path('M0 552 C154 495 283 505 399 557 C534 619 675 598 788 558 C956 500 1113 516 1280 558 V720 H0Z','url(#s08water)')
    s.path('M0 570 C154 515 281 528 398 579 C540 641 675 617 790 579 C950 526 1110 535 1280 578','none',stroke='#b7f1e8',sw=6,opacity=.72)
    s.path('M0 622 C205 575 330 618 461 646 S769 620 922 583 S1140 603 1280 628','none',stroke='#5fc5cc',sw=2.5,opacity=.7)
    house(s,808,427,.76,p,'stilt')
    # reed islands, lily pads, water grasses
    for x,y,k in [(118,590,.85),(235,645,.72),(510,609,.7),(1042,609,.78),(1182,626,.92)]:
        s.ellipse(x,y,42*k,14*k,'#4d9467',stroke='#2c674f',sw=2)
        s.path(f'M{x-3*k},{y} Q{x+10*k},{y-4*k} {x+18*k},{y-12*k}', 'none',stroke='#b0cb8b',sw=2)
        blossom(s,x+18*k,y-4*k,.45*k,'#f4ca91')
        for j in range(4): s.path(f'M{x-16*k+j*8*k},{y+3*k} q-5,-23 -2,-39','none',stroke='#2c775c',sw=2)
    # ornamental koi silhouettes under clear water
    for x,y,scale,col in [(510,620,1.0,'#e96d4f'),(705,668,.8,'#f0d89e'),(1010,595,.9,'#e66b4f')]:
        s.path(f'M{x-42*scale},{y} Q{x-12*scale},{y-25*scale} {x+18*scale},{y-7*scale} L{x+42*scale},{y-23*scale} L{x+36*scale},{y} L{x+45*scale},{y+19*scale} L{x+14*scale},{y+9*scale} Q{x-17*scale},{y+25*scale} {x-42*scale},{y} Z',col,'#354c5c',1.6)
        s.circle(x+20*scale,y-3*scale,2.3*scale,'#25384b')
        s.path(f'M{x-18*scale},{y-7*scale} q12,-6 19,1 M{x-12*scale},{y+7*scale} q8,5 17,0','none',stroke='#ffddb2',sw=2,opacity=.7)
    bridge(s,810,1130,581,.56,p,True)
    for x,y,k in [(60,491,1.2),(1175,477,.95),(1097,420,.65)]: pine(s,x,y,k,'#366c5b','#1a4a4b')

# Scene 09 — a broad sakura hillside with a winding pilgrimage path and blossom canopy.
def region_09(s,p):
    s.rect(0,0,1280,720,'url(#s09sky)'); s.ellipse(960,140,195,150,'url(#s09glow)',opacity=.84); cloud(s,335,105,.72); cloud(s,680,145,.6)
    s.path('M0 358 L108 281 204 335 318 224 431 333 562 224 680 336 805 244 913 339 1032 227 1160 336 1280 264 V466 H0Z','url(#s09far)')
    s.path('M0 425 Q185 364 346 420 T692 428 T1010 400 T1280 416 V720 H0Z','url(#s09ground)')
    # distant valley town, tiny roofs and roads
    for i in range(9):
        x=200+i*91; y=404+(i%3)*19
        s.path(f'M{x-31},{y} L{x},{y-20} L{x+32},{y} L{x+28},{y+25} L{x-27},{y+25} Z',['#8c786f','#b28e77','#7b7873'][i%3])
        s.rect(x-19,y+3,38,16,'#d8c9a6',rx=2)
    # giant sakura sweeps in from the right, its trunk framing the valley
    s.path('M1194 720 C1160 593 1118 499 1061 421 C1019 367 972 347 948 289 C994 326 1053 332 1077 373 C1098 413 1138 449 1177 461 C1162 393 1176 343 1215 302 C1195 374 1225 420 1268 446 L1280 720 Z','#694a43')
    s.path('M1179 506 C1130 430 1090 403 1034 385 M1205 470 C1233 414 1247 366 1260 323','none',stroke='#9c6c59',sw=10)
    leaves(s,[(1015,330,1.05),(1071,291,.96),(1137,321,1.12),(1205,290,1.18),(1250,352,.92),(1080,378,.8)],('#c46b8e','#e9a8bc','#f7d1cf'))
    for x,y,k in [(986,307,.8),(1054,265,.8),(1142,276,.92),(1210,323,.9),(1171,369,.75),(1249,391,.7),(1026,373,.6)]: blossom(s,x,y,k,'#f2b6ca','#ffe6ae')
    # winding stone path over terraces toward a torii
    s.path('M0 690 C218 642 290 684 451 625 C575 578 584 531 716 507 C839 482 888 450 894 407','none',stroke='#c9c4a3',sw=49)
    s.path('M0 690 C218 642 290 684 451 625 C575 578 584 531 716 507 C839 482 888 450 894 407','none',stroke='#857e70',sw=3)
    for i in range(22):
        x=30+i*36; y=675-(i*13)%68
        blossom(s,x,y,.39,'#f2bfd0')
    s.path('M820 386 L820 438 M886 386 L886 438 M806 385 L901 385 L911 373 L795 373 Z M814 396 L894 396','none',stroke='#c24e4a',sw=7)
    # a small viewing pavilion on the left hillside
    house(s,320,429,.56,p,'stilt')
    # airborne petals
    for x,y,r in [(720,250,5),(760,286,4),(682,327,5),(936,243,4),(1020,219,4),(1147,237,4)]: s.ellipse(x,y,r,r*1.7,'#f8c9d3',opacity=.85)

# Scene 10 — immense treasure peak, weathered mountain keep, mineral seams and ancient entrance.
def region_10(s,p):
    s.rect(0,0,1280,720,'url(#s10sky)'); s.ellipse(1010,126,170,148,'url(#s10glow)',opacity=.85); cloud(s,320,116,.8); cloud(s,770,88,.56)
    s.path('M0 490 L145 351 252 418 408 175 551 369 691 207 829 379 979 190 1110 353 1200 277 1280 331 V550 H0Z','url(#s10far)')
    # snow and mineral-flecked mountain spine
    s.path('M310 316 L408 175 L459 280 L430 260 L408 228 L385 274 L359 287 Z','#d6dfd2',opacity=.8)
    s.path('M620 350 L691 207 L761 312 L718 287 L693 248 L667 302 Z','#d1d8d0',opacity=.7)
    s.path('M914 319 L979 190 L1040 292 L1006 270 L980 230 L954 285 Z','#e0dfce',opacity=.7)
    s.path('M0 533 L182 462 350 512 507 404 654 506 819 407 956 503 1092 422 1280 485 V720 H0Z','#4f5d66')
    # jagged cliff shelves rise to a fortress on a high shelf
    s.path('M320 720 L425 560 L493 531 L524 463 L590 421 L642 368 L712 399 L754 466 L812 494 L894 570 L971 720 Z','#344652')
    s.path('M365 720 L449 594 L499 571 L543 506 L591 480 L631 423 L683 446 L731 510 L771 526 L853 605 L910 720 Z','#53606a')
    for d in ['M422 630 l42 -26 20 -38','M531 565 l29 -34 20 6','M748 541 l24 32 45 8','M809 611 l35 18 15 35','M603 471 l17 -19 12 7']:
        s.path(d,'none',stroke='#9da3a1',sw=3,opacity=.6)
    # embedded gold veins and exposed gemstone facets
    for d in ['M412 677 Q463 639 484 596 T532 540','M539 607 Q580 572 593 535','M744 581 Q775 604 816 622','M852 663 Q871 642 890 637','M627 503 l17 -30 22 10 10 24 Z','M481 612 l19 -22 20 10 -11 28 Z']:
        s.path(d,'none',stroke='#f0c36e',sw=4,opacity=.88)
    s.poly([(646,551),(668,524),(692,550),(684,581),(654,581)],'#56c1cf','#d9f1df',2)
    s.poly([(750,635),(764,610),(792,622),(797,651),(773,668)],'#e9a957','#fff1bd',2)
    # peak shrine, guarded by bronze gate and stone steps
    house(s,644,399,.58,p,'station')
    s.path('M580 424 L580 466 M707 424 L707 466 M565 424 L720 424 L730 410 L553 410 Z','none',stroke='#bd5341',sw=8)
    for i in range(5): s.path(f'M{576+i*28} {470+i*34} l96 0 l-9 10 l-78 0 Z','#a7a79b','#4b5a63',1.7)
    # stone treasure doors low in the cliff
    s.path('M890 720 L890 654 Q954 558 1018 654 L1018 720 Z','#192f40','#9a875f',4)
    s.path('M907 720 L907 657 Q954 594 1001 657 L1001 720 Z','#a2784b','#f2cf84',3)
    s.circle(954,663,15,'#e5b45e',stroke='#674c38',sw=3)
    for i in range(9):
        x=80+i*137; y=636+(i%3)*24
        s.poly([(x,y),(x+8,y-17),(x+18,y-13),(x+23,y),(x+13,y+10)],'#d8b368','#7e6c52',1.3,opacity=.85)

# Scene 11 — ancient grove with enormous knotted roots, moss, glowing fungi and spirit-lights.
def region_11(s,p):
    s.rect(0,0,1280,720,'url(#s11sky)'); s.ellipse(665,300,320,240,'url(#s11glow)',opacity=.38)
    # giant old trees create an uneven natural canopy arch
    for x,y,k in [(90,550,1.35),(267,548,1.1),(1093,556,1.2),(1240,545,1.42)]:
        s.path(f'M{x-25*k},{y} C{x-49*k},{y-130*k} {x-42*k},{y-263*k} {x-11*k},{y-348*k} L{x+25*k},{y-348*k} C{x+7*k},{y-209*k} {x+52*k},{y-113*k} {x+28*k},{y} Z','#3e5046','#172f37',2*k)
        for j in range(3):
            s.path(f'M{x},{y-220*k+j*30*k} Q{x-36*k},{y-177*k+j*18*k} {x-13*k},{y-110*k+j*24*k} M{x+5*k},{y-196*k+j*32*k} Q{x+42*k},{y-157*k+j*22*k} {x+25*k},{y-98*k+j*25*k}','none',stroke='#7e8d68',sw=5*k,opacity=.6)
        s.path(f'M{x},{y-23*k} Q{x-80*k},{y-36*k} {x-98*k},{y+18*k} Q{x-53*k},{y+3*k} {x-20*k},{y+44*k} L{x+30*k},{y+40*k} Q{x+63*k},{y+4*k} {x+100*k},{y+27*k} Q{x+75*k},{y-35*k} {x+16*k},{y-31*k} Z','#465247')
    # canopy holes reveal a forest-lit distant temple
    s.path('M0 280 C170 184 276 217 377 270 C487 157 621 202 706 257 C812 170 950 204 1043 267 C1146 177 1225 215 1280 270 V430 H0Z','#264f4b')
    leaves(s,[(75,270,1.2),(160,230,1.4),(269,256,1.3),(365,237,1.25),(462,261,1.1),(564,225,1.3),(688,249,1.4),(801,219,1.3),(923,252,1.2),(1030,224,1.35),(1147,245,1.35),(1226,281,1.2)],('#174b48','#2c6d5a','#6e9c70'))
    # mossy glade and root-laced earth
    s.path('M0 455 Q196 402 376 451 T718 429 T1020 459 T1280 422 V720 H0Z','#244547')
    s.path('M0 604 Q212 549 350 606 T687 586 T1004 601 T1280 560 V720 H0Z','#1b3b42')
    # old shrine steps at the glowing heart of the grove
    s.path('M506 477 L774 477 L747 498 L533 498 Z','#657467')
    for i in range(6): s.path(f'M{533+i*8} {500+i*23} L{747-i*8} {500+i*23} L{739-i*8} {514+i*23} L{541+i*8} {514+i*23} Z','#71806f','#3b5854',1)
    s.path('M602 388 L602 444 M680 388 L680 444 M590 388 L692 388 L704 375 L578 375 Z','none',stroke='#b76c51',sw=6)
    house(s,642,420,.35,p,'station')
    # bioluminescent mushrooms and exposed roots, with pale cyan pools
    for x,y,k in [(125,628,1.25),(235,663,.75),(406,640,1.0),(854,659,.9),(1028,639,1.15),(1177,672,.85)]:
        s.path(f'M{x-4*k},{y} Q{x-2*k},{y-27*k} {x},{y-42*k} Q{x+9*k},{y-26*k} {x+7*k},{y} Z','#a7cbb1')
        s.path(f'M{x-23*k},{y-39*k} Q{x-20*k},{y-64*k} {x+1*k},{y-60*k} Q{x+24*k},{y-64*k} {x+26*k},{y-40*k} Q{x+5*k},{y-30*k} {x-23*k},{y-39*k} Z','#71c7b3','#1c5c60',2)
        s.ellipse(x,y-45*k,5*k,3*k,'#e5f4cc')
        s.ellipse(x,y-41*k,36*k,23*k,'url(#s11glow)',opacity=.3)
    for x,y,r in [(483,560,8),(515,597,5),(793,569,6),(831,521,4),(440,500,5),(891,590,7),(718,630,5),(333,535,4)]:
        s.circle(x,y,r,'#d3f4d7',opacity=.85); s.circle(x,y,r*2.7,'url(#s11glow)',opacity=.35)
    # fern blades
    for x,y in [(314,692),(945,690),(73,570),(1180,584)]:
        for j in range(6): s.path(f'M{x},{y} Q{x+(j-2)*11},{y-14-j*7} {x+(j-2)*17},{y-22-j*8}', 'none',stroke='#76a77a',sw=2.5)

# Scene 12 — autumn memory trail, red maple canopy, layered amber ground and old stone markers.
def region_12(s,p):
    s.rect(0,0,1280,720,'url(#s12sky)'); s.ellipse(980,142,180,140,'url(#s12glow)',opacity=.7); cloud(s,360,111,.7,'#f6d6c2',.2)
    s.path('M0 360 L136 279 237 342 350 231 477 350 598 256 722 349 833 252 964 351 1086 243 1190 326 1280 269 V466 H0Z','url(#s12far)')
    s.path('M0 430 Q173 371 347 427 T680 416 T1003 431 T1280 406 V720 H0Z','#75584b')
    # maples have branching trunks and sharp layered five-lobed crowns
    for x,y,k in [(82,530,1.38),(260,478,1.1),(1128,492,1.4),(1240,532,1.1)]:
        s.path(f'M{x},{y} Q{x-16*k},{y-107*k} {x-3*k},{y-190*k} M{x-2*k},{y-126*k} Q{x-64*k},{y-160*k} {x-77*k},{y-206*k} M{x},{y-152*k} Q{x+49*k},{y-181*k} {x+73*k},{y-223*k} M{x-7*k},{y-173*k} Q{x-20*k},{y-216*k} {x-42*k},{y-238*k}', 'none',stroke='#57372f',sw=9*k)
        leaves(s,[(x-67*k,y-200*k,.85*k),(x-32*k,y-236*k,.92*k),(x+23*k,y-222*k,1.0*k),(x+70*k,y-209*k,.9*k),(x+10*k,y-177*k,1.06*k)],('#8f3f37','#c85b3f','#eea45c'))
        # individual maple lobes as pointed silhouette marks
        for dx,dy in [(-80,-209),(-46,-248),(9,-239),(53,-225),(82,-199)]:
            xx=x+dx*k; yy=y+dy*k
            s.path(f'M{xx},{yy} l-11,-10 2,12 -12,1 10,7 -3,11 12,-6 8,9 0,-12 12,-3 -10,-7 3,-11 -11,5 Z','#e7a06b',opacity=.9)
    # trail narrows toward a stone torii in the orange distance
    s.path('M0 720 C157 661 267 681 370 634 C486 580 494 518 601 481 C704 447 789 448 849 397','none',stroke='#b8a187',sw=91)
    s.path('M0 720 C157 661 267 681 370 634 C486 580 494 518 601 481 C704 447 789 448 849 397','none',stroke='#74645a',sw=3)
    for i in range(17):
        x=24+i*43; y=688-(i*17)%126
        s.path(f'M{x},{y} l12,-7 15,5 -4,12 -17,3 Z','#a69b84','#5b5149',1.2)
    s.path('M801 371 L801 430 M865 371 L865 430 M789 371 L878 371 L887 359 L777 359 Z','none',stroke='#a74639',sw=7)
    # weathered memorial stones along the edge
    for x,y,h in [(399,600,78),(923,546,103),(1003,578,72)]:
        s.path(f'M{x-20},{y} L{x-18},{y-h+14} Q{x},{y-h-8} {x+17},{y-h+12} L{x+22},{y} Z','#77776d','#494d4b',2)
        s.path(f'M{x-7},{y-h+22} L{x+2},{y-h+38} L{x-2},{y-h+55}','none',stroke='#b4aa89',sw=2.5,opacity=.6)
    # floating leaves cross the sunlight
    for x,y,angle in [(145,252,-18),(316,304,22),(518,225,-8),(690,284,33),(931,239,-15),(1089,312,12)]:
        s.group('<path d="M-10 0 Q-2 -12 12 -3 Q3 9 -10 0 Z" fill="#e77445" stroke="#f8b36d" stroke-width="1.2"/><path d="M-9 0 L9 -2" stroke="#7e4939" stroke-width="1"/>',f'translate({x} {y}) rotate({angle})')

# Scene 13 — moonlit garden, reflective koi pool, stepping stones and carefully pruned pines.
def region_13(s,p):
    s.rect(0,0,1280,720,'url(#s13sky)'); s.circle(987,131,83,'#f3e7cf',opacity=.88); s.circle(1010,110,83,'#31578c',opacity=.7)
    # tiny star points and thin cloud bands
    for x,y,r in [(135,110,2),(288,184,2),(410,80,3),(604,144,2),(720,64,2),(1133,178,2),(1168,95,3),(846,227,2),(217,236,2)]: s.circle(x,y,r,'#f4ebcb',opacity=.82)
    cloud(s,340,224,.72,'#849fc5',.16); cloud(s,1110,268,.62,'#9fb5c8',.13)
    s.path('M0 394 L101 315 205 352 310 272 424 365 548 277 663 362 794 269 903 356 1012 288 1127 354 1230 295 1280 321 V470 H0Z','url(#s13far)')
    s.path('M0 448 Q178 406 352 448 T699 437 T1038 445 T1280 420 V720 H0Z','#264a57')
    # pine trees sculpted into asymmetrical silhouettes
    pine(s,123,492,1.22,'#1d4548','#0e2a3c'); pine(s,1130,473,1.04,'#214c50','#122e3d'); pine(s,1030,482,.66,'#315f60','#173a47')
    # moonlit pond fills lower middle, split into light and dark reflections
    s.path('M0 535 C187 488 341 541 460 586 C595 638 765 632 881 586 C1024 531 1150 553 1280 591 V720 H0Z','url(#s13water)')
    s.path('M440 570 Q633 602 862 574 Q1020 561 1188 590','none',stroke='#b2d5e5',sw=5,opacity=.7)
    s.path('M476 614 Q677 648 885 607 Q1060 589 1234 621','none',stroke='#5a8ba9',sw=2,opacity=.86)
    for i in range(9):
        x=590+i*36; y=591+(i%4)*21
        s.path(f'M{x},{y} q19,-5 34,1', 'none',stroke='#d6e5e8',sw=1.8,opacity=.55)
    # stepping stones trace a gentle arc to a curved bridge
    rocks(s,[(380,593,33,17),(430,617,27,13),(489,636,25,12),(552,646,26,12),(620,650,29,14),(687,644,25,12)],'url(#s13stone)')
    bridge(s,765,1075,579,.72,p,False)
    # lantern on a stone pillar at waterside
    s.path('M208 593 L208 531 L244 531 L244 593 Z','#576d75','#1e3749',2)
    lantern(s,226,513,.9,p)
    # pruned ornamental trees and blossom around the back bank
    for x,y,k in [(368,432,.7),(444,452,.56),(902,439,.65)]: broadleaf(s,x,y,k,('#365f62','#698d84','#9eb5a3'))
    for x,y in [(367,340),(421,378),(916,362),(959,385),(875,395)]: blossom(s,x,y,.55,'#e3b9d1','#f8dfa9')
    # stone lantern hidden under a low branch
    s.path('M1056 544 L1060 490 L1105 490 L1110 544 Z','#62717a','#2d4351',2)
    s.path('M1045 490 L1084 466 L1120 490 Z','#8b9a99','#2d4351',2)
    s.rect(1068,502,29,25,'#f5dca7',rx=2,opacity=.8)

# Scene 14 — lively festival street, red-purple evening, warm shop windows and lantern strings.
def region_14(s,p):
    s.rect(0,0,1280,720,'url(#s14sky)'); s.circle(1045,130,126,'url(#s14glow)',opacity=.45)
    # compact Edo-style buildings lean into the street
    for x,y,w,h in [(0,85,240,480),(230,36,215,455),(1020,50,260,520),(827,102,205,393)]:
        s.path(f'M{x},{y+42} L{x+w},{y+42} L{x+w-12},{y+h} L{x+8},{y+h} Z','#62414b','#2d2437',2)
        s.path(f'M{x-17},{y+43} L{x+20},{y-1} L{x+w-20},{y-1} L{x+w+15},{y+43} L{x+w-5},{y+33} L{x+6},{y+33} Z','url(#s14roof)','#2a2639',2)
        for wy in range(y+83,y+h-55,80):
            for wx in range(x+22,x+w-35,79):
                s.rect(wx,wy,48,59,'#f7af66',rx=2,stroke='#593443',sw=4)
                s.rect(wx+7,wy+8,34,43,'#ffdb8b',rx=1,opacity=.55)
                s.line(wx+24,wy+2,wx+24,wy+57,'#7b4949',3)
        s.path(f'M{x-10},{y+94} L{x+w+10},{y+94} L{x+w+3},{y+109} L{x-5},{y+109} Z','#332b3d')
    # stall awnings repeat warm red, cream and indigo cloth panels
    for x,y in [(75,465),(283,433),(915,452),(1100,480)]:
        s.path(f'M{x-70},{y} L{x+75},{y} L{x+63},{y+30} L{x-62},{y+30} Z',['#a8454a','#e7c99a','#4b597c'][x%3], '#372a3e',2)
        for i in range(5): s.path(f'M{x-60+i*26},{y+1} l13,0 -6,29 -12,0 Z','#f4b9a0',opacity=.6)
        s.rect(x-64,y+30,130,62,'#7d4a42',rx=2,stroke='#392c3b',sw=2)
        s.rect(x-54,y+40,110,43,'#e6b677',rx=2)
        for i in range(4): s.circle(x-36+i*27,y+61,5,['#c24f45','#e3d4a2','#6b7f9d','#bc694c'][i],stroke='#5b3c3a',sw=1)
    # diagonal cords of paper lanterns create depth
    for i in range(7):
        x=165+i*160; y=106+(i%2)*35
        s.path(f'M{x-130},{y-20} Q{x},{y+52} {x+131},{y-11}','none',stroke='#81506c',sw=3)
        for j in range(3): lantern(s,x-60+j*60,y+8+(j%2)*7,.76,p)
    # paving radiates toward the central vanishing point
    s.path('M440 255 L842 255 L1160 720 H123 Z','#40354a')
    for i in range(11):
        y=306+i*39; half=38+i*28
        s.path(f'M{640-half},{y} L{640+half},{y} L{640+half+10},{y+4} L{640-half-10},{y+4} Z','#665367',opacity=.86)
    # festival pennants and hanging fabric signs (ornamental, not text)
    for i in range(9):
        x=430+i*52; y=220+(i%3)*16
        s.path(f'M{x},{y} L{x+25},{y+7} L{x+11},{y+52} L{x-1},{y+28} Z',['#d45a53','#ecba78','#617d9a'][i%3],'#543847',1)
        s.circle(x+8,y+24,3,'#f4ddaa')
    # reflected lantern pools and petals
    for i in range(15):
        x=190+i*68; y=662+(i%3)*14
        s.path(f'M{x},{y} q27,-6 53,1','none',stroke=['#e8a16b','#df7270','#8a91bf'][i%3],sw=3,opacity=.72)

# Scene 15 — coastal cove with fishing boats, tide pools, sea caves and marine foliage.
def region_15(s,p):
    s.rect(0,0,1280,720,'url(#s15sky)'); s.ellipse(1018,122,161,137,'url(#s15glow)',opacity=.78); cloud(s,285,105,.75); cloud(s,667,144,.62)
    s.path('M0 355 L115 276 239 339 352 223 465 343 584 257 704 355 835 242 947 330 1085 218 1193 312 1280 279 V475 H0Z','url(#s15far)')
    # steep coastal headlands enclose the cove
    s.path('M0 300 L118 271 L208 331 L255 425 L188 499 L0 520 Z','#446c70','#2c535e',2)
    s.path('M1280 292 L1174 267 L1084 347 L1030 431 L1099 497 L1280 525 Z','#427c78','#25565e',2)
    for d in ['M30 347 l48 -21 40 25 -18 47 -40 11 Z','M1203 350 l43 -12 24 37 -21 40 -48 -5 Z','M1068 415 l34 -25 35 31 -20 32 Z']:
        s.path(d,'#79968c','#36565d',2)
    # dark turquoise sea basin with luminous tide pools
    s.path('M0 462 Q185 432 344 483 T658 470 T1006 488 T1280 462 V720 H0Z','url(#s15water)')
    s.path('M0 517 Q190 487 351 526 T687 518 T1005 529 T1280 504','none',stroke='#a9eee5',sw=5,opacity=.68)
    for i in range(13):
        x=26+i*102; y=553+(i%4)*27
        s.path(f'M{x},{y} q26,-6 49,1', 'none',stroke='#b7f0e8',sw=2,opacity=.72)
    # shoreline tide-pool shelves and sea cave mouth
    s.path('M0 603 L126 579 L184 615 L247 610 L305 648 L0 720 Z','#476a66')
    s.path('M1280 599 L1150 573 L1098 609 L1040 610 L982 651 L1280 720 Z','#426b69')
    s.path('M972 510 Q1036 435 1114 511 L1125 584 L958 586 Z','#183d51','#71918c',3)
    s.path('M993 538 Q1040 480 1091 539 L1098 572 L984 573 Z','#092d48')
    # small wooden fishing boats in different orientations
    s.path('M316 491 L483 491 L452 532 Q395 551 346 531 Z','#7c533d','#2d4551',2)
    s.path('M350 489 L354 429 L358 489 Z','#c5a26b','#5d493e',2)
    s.path('M365 435 L445 480 L365 480 Z','#e6d4ad','#736453',2)
    s.line(357,432,355,489,'#b2aa8d',2)
    s.path('M742 484 L868 484 L844 515 Q793 530 762 515 Z','#a56549','#3b4b51',2)
    s.path('M794 482 L800 438 L805 482 Z','#e0bf86','#5e4c43',2)
    s.path('M808 444 L849 477 L808 477 Z','#d3c8a2','#7d7869',1.5)
    # dock timbers and mooring ropes
    s.path('M255 536 L494 536 L494 550 L255 550 Z','#70503b')
    for i in range(7): s.rect(264+i*32,536,25,14,'#b68a59',rx=1,stroke='#553e35',sw=1)
    s.line(465,527,477,545,'#e4c58c',2); s.line(817,520,835,539,'#e4c58c',2)
    # seaweed fans, coral and shells in the foreground
    for x,y,k,c in [(80,680,1.1,'#4f9b7d'),(188,694,.8,'#7ebd91'),(1000,684,1.1,'#50a49a'),(1178,692,.83,'#5b9e80')]:
        for j in range(7): s.path(f'M{x},{y} Q{x+(j-3)*9*k},{y-26*k} {x+(j-3)*14*k},{y-52*k}', 'none',stroke=c,sw=4*k)
    for x,y,r in [(570,666,17),(620,685,13),(930,655,16)]:
        s.path(f'M{x-r},{y} Q{x-r*.9},{y-r} {x},{y-r*.7} Q{x+r*.9},{y-r} {x+r},{y} Q{x},{y+r} {x-r},{y} Z','#f1ccac','#a87563',2)
        s.path(f'M{x},{y-r*.6} Q{x-3},{y} {x},{y+r*.6}','none',stroke='#ba8d79',sw=1.5)

# Scene 16 — a volcanic basin, fractured basalt, magma rivers and ash drifting past a shrine.
def region_16(s,p):
    s.rect(0,0,1280,720,'url(#s16sky)'); s.circle(1060,118,156,'url(#s16glow)',opacity=.68); cloud(s,280,124,.8,'#c57562',.18); cloud(s,830,83,.9,'#6c4649',.2)
    # distant serrated caldera and hot ash plumes
    s.path('M0 443 L119 347 208 399 319 292 413 386 525 247 635 382 734 255 832 379 945 221 1056 376 1166 280 1280 357 V545 H0Z','#4f4248')
    s.path('M220 381 L319 292 L373 346 L342 330 L320 313 L292 350 Z','#a58a7e',opacity=.65)
    s.path('M431 368 L525 247 L585 338 L552 322 L526 278 L498 332 Z','#b29b8b',opacity=.7)
    s.path('M865 358 L945 221 L1000 321 L967 299 L946 254 L923 307 Z','#bc9b87',opacity=.7)
    s.path('M0 501 L168 441 308 492 460 423 608 510 770 418 931 493 1084 419 1280 492 V720 H0Z','#3a353b')
    # central cone layered with cracked basalt plates
    s.path('M256 720 L390 507 L490 408 L566 299 L636 205 L707 311 L790 408 L878 506 L1007 720 Z','#332e34','#181f2a',3)
    s.path('M354 720 L454 544 L512 478 L568 384 L632 287 L688 391 L744 478 L810 548 L916 720 Z','#514044')
    s.path('M479 720 L521 568 L572 489 L610 420 L638 328 L677 425 L720 501 L767 567 L817 720 Z','#292b32')
    # glowing vents and magma fissures
    for d in ['M633 283 L624 356 L650 390 L619 443 L639 498 L600 555 L612 609 L577 720','M683 395 L704 446 L687 484 L733 530 L720 584 L768 642','M487 529 L524 545 L510 586 L540 624','M783 554 L756 578 L789 619 L778 664']:
        s.path(d,'none',stroke='#e34d30',sw=13,opacity=.9)
        s.path(d,'none',stroke='#ffbf57',sw=4.5,opacity=.98)
    s.path('M0 641 Q177 604 299 643 T516 677 L544 720 H0Z','#202832')
    s.path('M770 720 L812 675 Q964 624 1100 665 T1280 642 V720 Z','#202832')
    # lava rivers on the caldera floor
    s.path('M0 692 C171 657 234 689 331 720 L468 720 C378 673 289 644 194 655 C130 663 56 674 0 679 Z','#e15432')
    s.path('M0 690 C171 655 234 687 331 720','none',stroke='#ffc761',sw=5)
    s.path('M890 720 C990 660 1106 672 1280 637 V681 C1138 709 1067 704 1016 720 Z','#dc4d30')
    s.path('M890 720 C990 660 1106 672 1280 637','none',stroke='#ffca65',sw=4)
    # shattered obsidian boulders and red-lit edges
    for x,y,k in [(120,600,1.15),(210,650,.85),(1013,583,1.1),(1140,621,.85),(380,598,.75),(878,620,.9)]:
        s.poly([(x-32*k,y+22*k),(x-24*k,y-10*k),(x-3*k,y-31*k),(x+23*k,y-13*k),(x+31*k,y+18*k),(x+6*k,y+31*k)],'#262b33','#5d4544',2)
        s.line(x-18*k,y+6*k,x-5*k,y-13*k,'#db5839',2,opacity=.75)
    # falling embers and curling smoke bands
    for i in range(28):
        x=(i*97+41)%1270; y=330+(i*71)%320
        s.ellipse(x,y,1.8+(i%3),3+(i%4),'#ffc86b',opacity=.72)
    s.path('M450 220 C392 173 429 130 389 97 C366 81 382 48 410 38 M740 183 C794 132 766 98 820 73 C848 61 853 34 833 22','none',stroke='#6b5355',sw=24,opacity=.3)
    # small abandoned torii in a safe side ravine
    s.path('M111 496 L111 552 M174 496 L174 552 M100 496 L186 496 L194 484 L92 484 Z M108 507 L178 507','none',stroke='#b64c3b',sw=6)

# Scene 17 — celestial clockwork temple on a floating rock, bronze gears and moonlit terraces.
def region_17(s,p):
    s.rect(0,0,1280,720,'url(#s17sky)'); s.circle(1048,116,84,'#f4e6c4',opacity=.82); s.circle(1065,96,84,'#a2c6e0',opacity=.48)
    for x,y,r in [(133,127,3),(217,204,2),(370,95,2),(482,165,3),(703,105,2),(814,193,3),(1160,215,2),(110,288,2),(915,71,2)]: s.circle(x,y,r,'#fff0c7',opacity=.8)
    cloud(s,279,156,.8,'#d8e6e7',.32); cloud(s,873,250,.9,'#e6dfc8',.24)
    s.path('M0 435 L110 329 205 375 329 267 449 371 566 271 686 379 795 279 909 367 1031 257 1147 366 1250 291 1280 323 V520 H0Z','url(#s17far)')
    # broken floating crag under the temple
    s.path('M265 505 L372 472 L450 488 L516 459 L602 492 L681 463 L766 493 L866 472 L965 509 L935 575 L844 613 L769 652 L671 676 L586 641 L494 653 L410 611 L324 589 Z','#566976','#2c475b',3)
    s.path('M318 527 L408 506 L467 527 L523 499 L608 528 L686 503 L758 529 L851 507 L920 528 L899 560 L819 596 L752 624 L670 640 L590 610 L513 625 L432 592 L357 574 Z','#87999b',opacity=.82)
    # temple roof and tiered halls
    house(s,640,421,.98,p,'station')
    house(s,484,451,.58,p); house(s,805,450,.56,p)
    # a giant clock ring behind roof line
    s.circle(648,285,108,'none',stroke='#b78f55',sw=15,opacity=.8); s.circle(648,285,89,'none',stroke='#e6cc91',sw=3)
    s.circle(648,285,77,'#243c5a',stroke='#d5b77c',sw=3)
    for i in range(12):
        import math
        a=math.pi*2*i/12-math.pi/2; x=648+math.cos(a)*68; y=285+math.sin(a)*68
        s.circle(x,y,4.5,'#f2d9a1')
    s.line(648,285,648,239,'#f6e1a5',4); s.line(648,285,686,300,'#f6e1a5',3)
    s.circle(648,285,8,'#d8b16d',stroke='#5d513f',sw=2)
    # bronze gears float beside the building
    for cx,cy,r in [(330,408,46),(918,392,53),(967,282,28)]:
        s.circle(cx,cy,r,'#987b52',stroke='#e6c98e',sw=4)
        s.circle(cx,cy,r*.68,'#3c5270',stroke='#d6bf8d',sw=3)
        s.circle(cx,cy,r*.23,'#dcbf81',stroke='#654d39',sw=2)
        for i in range(8):
            import math
            a=math.pi*2*i/8
            x1=cx+math.cos(a)*(r-2); y1=cy+math.sin(a)*(r-2)
            x2=cx+math.cos(a)*(r+11); y2=cy+math.sin(a)*(r+11)
            s.line(x1,y1,x2,y2,'#ddbe7d',6)
        for i in range(6):
            import math
            a=math.pi*2*i/6
            s.circle(cx+math.cos(a)*r*.46,cy+math.sin(a)*r*.46,3,'#e8d09b')
    # small stairway and gold-edged slabs lead to the suspended landing
    for i in range(6):
        x=492-i*19; y=520+i*20
        s.path(f'M{x},{y} L{788+i*19},{y} L{769+i*19},{y+13} L{x+17},{y+13} Z','#8b9a99','#42596a',1.5)
        s.line(x+13,y+2,780+i*19,y+2,'#d7bf88',1.4,opacity=.65)
    # faint orbit arcs and drifting clock sparks
    for r in (162,193): s.ellipse(647,291,r,r*.72,'none',stroke='#d9d1b5',sw=1.5,opacity=.28)
    for x,y in [(410,248),(854,204),(1017,461),(281,544),(1006,565),(696,181)]:
        s.circle(x,y,4,'#f3dca1',opacity=.9); s.circle(x,y,10,'url(#s17glow)',opacity=.4)


# Art-directed finishing passes add material language unique to each environment.
def region_detail_01(s):
    # Cedar grain, roof shingles, stone joints and river reflections.
    for x,y in [(250,400),(510,366),(881,384)]:
        for j in range(5): s.path(f'M{x-57+j*24},{y-42} q-5,13 1,28', 'none',stroke='#d5b085',sw=1.4,opacity=.7)
        for j in range(4): s.path(f'M{x-70+j*35},{y-75} q17,-16 34,0', 'none',stroke='#8d9a91',sw=1.6,opacity=.7)
    for y in (594,610,628): s.path(f'M38 {y} C180 {y-20} 282 {y+22} 390 {y+4} M840 {y+1} Q990 {y-19} 1240 {y+8}', 'none',stroke='#b7e9e3',sw=2.2,opacity=.62)
    for x,y in [(140,548),(193,566),(242,580),(284,594)]:
        s.path(f'M{x-14},{y} l13,-7 17,5 M{x-7},{y+4} l9,-2', 'none',stroke='#d5d7bd',sw=1.3,opacity=.75)
    for x,y in [(312,333),(338,340),(365,327),(914,330),(944,346)]: blossom(s,x,y,.42,'#f9c8d7')

def region_detail_02(s):
    # Water eddies, creek stones, rice stems and bamboo nodes.
    for i in range(23):
        x=880+(i*37)%300; y=307+(i*43)%385
        s.path(f'M{x},{y} q12,-5 25,0', 'none',stroke='#d1f5e8',sw=1.8,opacity=.72)
    for x,y in [(914,315),(870,349),(828,387),(803,430),(823,477),(866,514),(830,565),(778,601),(749,650)]:
        s.path(f'M{x-20},{y-4} q18,-13 36,-2 M{x-9},{y+3} l17,2', 'none',stroke='#e8e5d1',sw=1.2,opacity=.75)
    for x,y in [(54,643),(127,667),(456,658),(545,682),(984,663),(1220,628)]:
        grass(s,x,y,.9,'#c8d99c')
    for x,y in [(1134,365),(1190,392),(1242,400),(1060,365)]:
        for j in range(4): s.line(x-5+j*3,y+25,x-4+j*4,y+50,'#a1c37e',1,opacity=.62)
    s.path('M102 449 Q121 430 143 449 M102 463 Q122 445 144 463','none',stroke='#d8c296',sw=2,opacity=.65)

def region_detail_03(s):
    # Distinct bridge plank grain and the timber shopfront latticework.
    for i in range(14):
        x=267+i*55; y=492-106*4*(i/17)*(1-i/17)
        s.path(f'M{x},{y} q18,-3 37,1', 'none',stroke='#f4d1a2',sw=1.5,opacity=.68)
    for x,y in [(220,428),(445,390),(1030,414),(1170,452)]:
        for j in range(4): s.line(x-54+j*34,y-18,x-54+j*34,y+16,'#d0a878',1.6,opacity=.7)
        for yy in (y-25,y+16): s.line(x-67,yy,x+67,yy,'#d3a673',1.6,opacity=.7)
    for i in range(12):
        x=40+i*103; y=601+(i%3)*22
        s.path(f'M{x},{y} q15,-4 30,0', 'none',stroke='#c1edeb',sw=2,opacity=.6)
    for x,y,k in [(171,441,.36),(184,420,.32),(1150,339,.36),(1207,316,.4)]: blossom(s,x,y,k)

def region_detail_04(s):
    # Rail ties, steel glints, platform grain and station joinery.
    for i in range(20):
        x=230+i*45; y=695-i*7.4
        s.line(x,y,x+11,y+7,'#8a8a7e',1.7,opacity=.74)
    for i in range(7):
        x=135+i*62
        s.line(x,505,x+5,539,'#d7b680',2,opacity=.8)
        s.path(f'M{x-6},475 l12,0 0,6 -12,0 Z','#e7ca95',opacity=.8)
    for x,y in [(296,373),(315,373),(334,373),(353,373),(372,373)]: s.line(x,y,x,y+34,'#c5a87a',1.5,opacity=.8)
    for d in ['M258 416 l14 5 -5 10','M478 417 l-9 6 4 11','M1005 448 l15 -4 6 9','M1080 452 l-12 4 0 9']:
        s.path(d,'none',stroke='#d8b987',sw=2,opacity=.7)

def region_detail_05(s):
    # Fine crop rows, windmill timber joints and sunlit seed heads.
    for i in range(25):
        x=(i*53+19)%1280; y=509+(i*31)%183
        s.path(f'M{x},{y} q13,-5 25,0', 'none',stroke='#f4e5ac',sw=1.6,opacity=.7)
    for x,y in [(164,546),(412,572),(1093,527)]:
        for j in range(4): s.line(x-17+j*11,y-33,x-14+j*11,y+33,'#a78a5f',1.4,opacity=.7)
    for d in ['M884 301 L943 301','M882 352 L951 352','M879 401 L962 401']:
        s.path(d,'none',stroke='#f0d9a8',sw=2.5,opacity=.72)
    for x,y in [(92,570),(121,587),(311,635),(744,620),(1005,608),(1204,594)]:
        grass(s,x,y,.76,'#f4e1a2')

def region_detail_06(s):
    # Rice planting lines, wall stone faces and trickling irrigation glints.
    for row,y in enumerate([438,481,526,573,620]):
        for j in range(12):
            x=25+j*108+(row%2)*27
            s.path(f'M{x},{y+8} q20,-8 42,-1', 'none',stroke='#d9e6a8',sw=1.5,opacity=.72)
            s.path(f'M{x+7},{y+14} l4,7 M{x+17},{y+12} l-1,9', 'none',stroke='#4b8658',sw=1.3,opacity=.8)
    for row in range(3):
        y=520+row*46
        for col in range(13):
            x=col*76-15+(row%2)*23
            s.path(f'M{x+5},{y+14} l11,-7 M{x+20},{y+22} l12,-4', 'none',stroke='#c1bca0',sw=1.2,opacity=.65)
    for x,y in [(87,691),(168,674),(284,696),(374,680),(939,686),(1158,675)]: blossom(s,x,y,.34,'#efc7c8')

def region_detail_07(s):
    # Rain tracks on lacquered beams, puddle reflections and patterned paper shades.
    for x in [35,76,117,157,218,263,1025,1070,1118,1171,1223]:
        s.path(f'M{x},110 q-5,34 -2,65 M{x+9},210 q-4,31 -1,51', 'none',stroke='#a2bad5',sw=1.5,opacity=.45)
    for x,y,w,h in [(52,76,110,142),(192,42,99,123),(1012,60,103,135),(1144,95,91,152),(65,285,134,157),(1050,287,142,165)]:
        for xx in range(int(x+14),int(x+w-8),16): s.line(xx,y+14,xx,y+h-14,'#d87f68',1.2,opacity=.58)
        s.line(x+8,y+h*.58,x+w-8,y+h*.58,'#f4c47c',2,opacity=.7)
    for i in range(17):
        x=80+i*68; y=628+(i%4)*18
        s.path(f'M{x},{y} q20,-7 43,0 q-16,6 -43,0 Z','#9bc9d4',opacity=.16)
    for x,y in [(277,160),(398,174),(754,178),(868,161),(1004,182)]:
        s.path(f'M{x},{y} q-6,15 -2,28', 'none',stroke='#aacfe0',sw=1.8,opacity=.42)

def region_detail_08(s):
    # Koi scale flecks, rippled pool reflections and reed-vein marks.
    for x,y,scale in [(510,620,1.0),(705,668,.8),(1010,595,.9)]:
        for row in range(3):
            for col in range(4):
                xx=x-25*scale+col*13*scale; yy=y-10*scale+row*8*scale
                s.path(f'M{xx},{yy} q5,-5 10,0 l-3,5 q-5,2 -7,-5 Z','#fff0c4',opacity=.7)
        s.path(f'M{x-28*scale},{y+3*scale} Q{x-6*scale},{y+13*scale} {x+12*scale},{y+4*scale}', 'none',stroke='#375f77',sw=1.3,opacity=.7)
    for i in range(21):
        x=20+i*59; y=548+(i%4)*29
        s.path(f'M{x},{y} q15,-5 31,1', 'none',stroke='#c8f0e5',sw=1.8,opacity=.65)
    for x,y in [(118,602),(236,651),(510,622),(1047,614),(1185,631)]:
        for j in range(4): s.line(x-12+j*7,y+2,x-19+j*9,y-25,'#4f9968',1.8,opacity=.78)

def region_detail_09(s):
    # blossom veins, tiled distant roofs, wind-shaped petals, and path stones.
    for x,y in [(200,404),(291,424),(382,442),(473,418),(564,433),(655,412),(746,430),(837,411)]:
        s.path(f'M{x-25},{y} L{x},{y-16} L{x+25},{y} M{x-20},{y+5} L{x+20},{y+5}', 'none',stroke='#d5c3a1',sw=1.4,opacity=.78)
    for x,y in [(986,307),(1054,265),(1142,276),(1210,323),(1171,369),(1249,391),(1026,373)]:
        for a in range(5):
            import math
            ang=a*math.pi*2/5-math.pi/2
            s.line(x,y,x+math.cos(ang)*8,y+math.sin(ang)*11,'#ffe0e3',1.1,opacity=.75)
    for i in range(17):
        x=45+i*45; y=670-(i*19)%75
        s.path(f'M{x},{y} l14,-4 11,6 -4,8 -18,0 Z','#c8c1a6','#847d70',1,opacity=.8)

def region_detail_10(s):
    # Faceted mineral seams, carved fortification stones and gold ore glints.
    for i in range(18):
        x=365+(i*51)%600; y=540+(i*37)%175
        s.path(f'M{x},{y} l13,-16 8,2 -6,13 Z',['#d7c9a4','#d7a95c','#66b5c0'][i%3],'#6c736f',1,opacity=.82)
    for d in ['M450 596 l18 -16 11 -1','M548 555 l17 -13 19 7','M783 567 l14 15 21 3','M833 633 l23 10 10 21','M613 474 l15 -16 21 8']:
        s.path(d,'none',stroke='#d5d5c5',sw=2,opacity=.7)
    for x,y in [(596,399),(615,388),(633,399),(657,392),(681,400)]: s.circle(x,y,3,'#f4dba2')
    for i in range(6):
        x=912+i*18; s.line(x,678,x+9,684,'#e0b45b',2,opacity=.7)

def region_detail_11(s):
    # tree bark grooves, moss freckles, lichen and tiny luminous spores.
    for x,y,k in [(90,550,1.35),(267,548,1.1),(1093,556,1.2),(1240,545,1.42)]:
        for j in range(7):
            xx=x-27*k+j*8*k
            s.path(f'M{xx},{y-305*k} Q{xx-7*k},{y-241*k} {xx+2*k},{y-195*k} T{xx-4*k},{y-82*k}', 'none',stroke=['#768369','#a1a87c','#314a43'][j%3],sw=2.1*k,opacity=.78)
        for j in range(5):
            xx=x-50*k+j*21*k; yy=y-71*k+(j%2)*13*k
            s.ellipse(xx,yy,7*k,3*k,'#92b485',opacity=.68)
    for x,y in [(510,562),(550,571),(737,551),(796,582),(434,516),(871,545),(333,607),(943,611)]:
        s.circle(x,y,2.6,'#d8f7cc',opacity=.86); s.circle(x,y,8,'url(#s11glow)',opacity=.22)
    for x,y in [(125,628),(235,663),(406,640),(854,659),(1028,639),(1177,672)]:
        for j in range(5): s.path(f'M{x-13+j*6},{y-44} q2,4 1,8', 'none',stroke='#b1e5c8',sw=1.2,opacity=.7)

def region_detail_12(s):
    # bark stripes, stone inscription-like marks and maple-vein etchings.
    for x,y,k in [(82,530,1.38),(260,478,1.1),(1128,492,1.4),(1240,532,1.1)]:
        for j in range(6):
            xx=x-14*k+j*6*k
            s.path(f'M{xx},{y-209*k} Q{xx-8*k},{y-168*k} {xx+3*k},{y-125*k} T{xx-1*k},{y-24*k}', 'none',stroke='#9b6650',sw=2*k,opacity=.7)
    for x,y,h in [(399,600,78),(923,546,103),(1003,578,72)]:
        for j in range(4): s.path(f'M{x-8+j*5},{y-h+26} l{(j%2)*3+2},13', 'none',stroke='#c8bca0',sw=1.7,opacity=.7)
    for i in range(24):
        x=(i*57+28)%1270; y=440+(i*43)%253
        s.path(f'M{x},{y} q12,4 8,14 q-12,-3 -8,-14 Z','#db7147',opacity=.75)

def region_detail_13(s):
    # garden stone grain, moon reflections, pine needles and lantern lattice.
    for i in range(18):
        x=460+i*42; y=577+(i%5)*23
        s.path(f'M{x},{y} q20,-4 37,1', 'none',stroke='#cce5ed',sw=1.5,opacity=.63)
    for x,y,rx,ry in [(380,593,33,17),(430,617,27,13),(489,636,25,12),(552,646,26,12),(620,650,29,14),(687,644,25,12)]:
        s.path(f'M{x-rx*.55},{y-ry*.4} q{rx*.3},-4 {rx*.6},1', 'none',stroke='#f3eee1',sw=1.5,opacity=.8)
    for x,y,k in [(123,492,1.22),(1130,473,1.04),(1030,482,.66)]:
        for j in range(5):
            s.path(f'M{x-48*k+j*23*k},{y-80*k} q-10,-12 -20,-9','none',stroke='#588276',sw=2.1*k,opacity=.8)
    for x,y in [(208,493),(226,489),(244,493)]: s.line(x,y,x,y+22,'#6c8b8d',1.3)

def region_detail_14(s):
    # lantern paper ribs, textile stitch marks, shop lattice and cobblestone grain.
    for i in range(15):
        x=18+i*88; y=650+(i%3)*16
        s.path(f'M{x},{y} q22,-5 41,0', 'none',stroke=['#f1b078','#d47c77','#9ca7cc'][i%3],sw=2,opacity=.72)
    for i in range(7):
        x=165+i*160; y=114+(i%2)*35
        for j in range(3):
            xx=x-60+j*60; yy=y+8+(j%2)*7
            s.path(f'M{xx-8},{yy-20} Q{xx},{yy-27} {xx+8},{yy-20} L{xx+7},{yy+17} Q{xx},{yy+24} {xx-7},{yy+17} Z','none',stroke='#f3cc91',sw=1,opacity=.8)
    for x,y,w,h in [(0,85,240,480),(230,36,215,455),(1020,50,260,520),(827,102,205,393)]:
        for wy in range(y+83,y+h-55,80):
            for wx in range(x+22,x+w-35,79):
                s.path(f'M{wx+4},{wy+4} h40 v51 h-40 Z','none',stroke='#ffda8b',sw=1.1,opacity=.7)
    for i in range(10):
        x=463+i*34; y=340+i*28
        s.path(f'M{x},{y} l22,0', 'none',stroke='#938098',sw=1.5,opacity=.6)

def region_detail_15(s):
    # topographic tide-pool outlines, boat planks, marine-shell ridges.
    for i in range(18):
        x=20+i*71; y=506+(i%4)*30
        s.path(f'M{x},{y} q19,-5 40,1', 'none',stroke='#c6f3e7',sw=1.8,opacity=.7)
    for x,y in [(316,491),(742,484)]:
        for j in range(5): s.line(x+10+j*29,y+3,x+14+j*25,y+20,'#d2ac7c',1.5,opacity=.8)
    for x,y,r in [(570,666,17),(620,685,13),(930,655,16)]:
        for j in range(4): s.path(f'M{x-r*.8+j*r*.45},{y-r*.3} q-2,8 2,15','none',stroke='#d39c85',sw=1.3,opacity=.7)
    for x,y in [(80,680),(188,694),(1000,684),(1178,692)]:
        for j in range(5): s.ellipse(x+(j-2)*12,y-10-abs(j-2)*6,4,2,'#9bd5af',opacity=.7)

def region_detail_16(s):
    # cracked basalt facets, glowing ember fractures and ash flecks.
    for x,y,k in [(120,600,1.15),(210,650,.85),(1013,583,1.1),(1140,621,.85),(380,598,.75),(878,620,.9)]:
        for j in range(4):
            s.path(f'M{x-18*k+j*9*k},{y-4*k} l{5*k},-{13*k} l{7*k},-{3*k}', 'none',stroke='#736068',sw=1.5,opacity=.8)
    for i in range(20):
        x=(i*63+17)%1280; y=424+(i*31)%279
        s.ellipse(x,y,2+(i%3),3+(i%4),'#ffcc68',opacity=.8)
    for d in ['M633 283 L624 356 L650 390','M619 443 L639 498 L600 555','M704 446 L687 484 L733 530','M756 578 L789 619']:
        s.path(d,'none',stroke='#ffdc7b',sw=2.2,opacity=.9)

def region_detail_17(s):
    # clock engravings, bronze rivets, masonry joints and suspended-stone fissures.
    for cx,cy,r in [(330,408,46),(918,392,53),(967,282,28)]:
        for i in range(12):
            import math
            a=math.pi*2*i/12
            x1=cx+math.cos(a)*r*.72; y1=cy+math.sin(a)*r*.72
            x2=cx+math.cos(a)*r*.9; y2=cy+math.sin(a)*r*.9
            s.line(x1,y1,x2,y2,'#e9d59a',1.8,opacity=.85)
    for x,y in [(318,547),(372,553),(432,571),(507,594),(582,585),(654,607),(728,594),(803,570),(872,552),(920,538)]:
        s.path(f'M{x},{y} l12,-5 8,7 -4,12 -15,0 Z','none',stroke='#536b79',sw=1.7,opacity=.8)
    for i in range(12):
        x=492+i*24; s.path(f'M{x},399 q8,-7 16,0', 'none',stroke='#f5dc9c',sw=1.5,opacity=.85)
    for x,y in [(410,248),(854,204),(1017,461),(281,544),(1006,565),(696,181)]:
        s.path(f'M{x-6},{y} L{x+6},{y} M{x},{y-6} L{x},{y+6}', 'none',stroke='#fff0c4',sw=1.5,opacity=.9)

REGION_DETAILS=[region_detail_01,region_detail_02,region_detail_03,region_detail_04,region_detail_05,region_detail_06,region_detail_07,region_detail_08,region_detail_09,region_detail_10,region_detail_11,region_detail_12,region_detail_13,region_detail_14,region_detail_15,region_detail_16,region_detail_17]

REGION_FUNCS = [region_01,region_02,region_03,region_04,region_05,region_06,region_07,region_08,region_09,region_10,region_11,region_12,region_13,region_14,region_15,region_16,region_17]

# Boss design helpers. Every boss uses an original silhouette, not a shared character model.
def boss_defs(s, colors):
    q=s.prefix
    s.add(f'''<defs>
    <linearGradient id="{q}body" x1="0" y1="0" x2="1" y2="1"><stop stop-color="{colors[0]}"/><stop offset=".46" stop-color="{colors[1]}"/><stop offset="1" stop-color="{colors[2]}"/></linearGradient>
    <linearGradient id="{q}cloth" x1="0" y1="0" x2=".2" y2="1"><stop stop-color="{colors[3]}"/><stop offset="1" stop-color="{colors[4]}"/></linearGradient>
    <linearGradient id="{q}metal" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#fff1bf"/><stop offset=".18" stop-color="#d7ac62"/><stop offset=".45" stop-color="#8d623d"/><stop offset=".69" stop-color="#f5db8f"/><stop offset="1" stop-color="#6c4936"/></linearGradient>
    <linearGradient id="{q}light" x1="0" y1="0" x2=".8" y2="1"><stop stop-color="#ffffff" stop-opacity=".82"/><stop offset=".55" stop-color="#fff7d1" stop-opacity=".18"/><stop offset="1" stop-color="#ffffff" stop-opacity="0"/></linearGradient>
    <radialGradient id="{q}glow"><stop stop-color="{colors[5]}" stop-opacity=".8"/><stop offset="1" stop-color="{colors[5]}" stop-opacity="0"/></radialGradient>
    <linearGradient id="{q}wood" x1="0" y1="0" x2="1" y2="0"><stop stop-color="#4b342b"/><stop offset=".42" stop-color="#b47c4c"/><stop offset=".7" stop-color="#805137"/><stop offset="1" stop-color="#3f322b"/></linearGradient>
    <linearGradient id="{q}fur" x1="0" y1="0" x2=".8" y2="1"><stop stop-color="#f5e4c7"/><stop offset=".45" stop-color="#c5a78b"/><stop offset="1" stop-color="#806957"/></linearGradient>
    </defs>''')

def line_detail(s, paths, color, width=2, opacity=.7):
    for d in paths: s.path(d,'none',stroke=color,sw=width,opacity=opacity)

def boss_01(s):
    # Yamabiko: ethereal, layered sound-spirit with flowing echo ribbons.
    boss_defs(s,('#e8f1ed','#9ccdcf','#4a8798','#e5b8b4','#816f9b','#8ce3e2'))
    for i,(cx,cy,rx,ry) in enumerate([(512,495,295,86),(512,491,245,62),(512,487,194,41)]):
        s.ellipse(cx,cy,rx,ry,'none',stroke=['#8be0dc','#b5eee3','#f0d9cf'][i],sw=4-i*.7,opacity=.3+i*.09)
    # flowing, split tails and long sound ribbons
    s.path('M420 658 C278 732 194 620 257 541 C302 484 341 485 330 413 C317 332 231 352 206 420 C180 480 209 522 164 549 C125 573 81 541 102 502 C117 475 149 468 144 438 C136 397 91 404 67 439 C26 501 76 590 132 606 C216 632 265 565 300 547', 'url(#b01body)','#477780',3)
    s.path('M606 659 C735 739 844 646 778 562 C738 511 690 512 707 440 C725 363 812 368 831 430 C847 480 821 525 862 550 C904 577 946 539 924 503 C906 475 878 471 884 440 C891 402 939 411 961 447 C996 506 958 584 902 604 C825 631 771 565 732 543', 'url(#b01body)','#477780',3)
    s.path('M371 618 C294 533 325 428 277 367 C244 325 275 284 317 299 C363 316 334 366 363 393 C414 438 405 498 436 537', 'none',stroke='#e4f9e9',sw=20,opacity=.85)
    s.path('M660 618 C731 542 697 435 752 376 C793 333 765 291 727 306 C685 321 712 363 680 397 C632 446 646 498 608 540', 'none',stroke='#d9f4ef',sw=17,opacity=.82)
    # body is made from cloud-like tapered lobes, not circular primitives
    s.path('M386 443 C349 397 366 339 419 318 C461 295 474 269 513 261 C554 270 570 301 606 320 C650 342 668 397 629 443 L665 538 C640 609 594 657 512 667 C432 655 380 611 356 540 Z','url(#b01body)','#497c88',3)
    s.path('M407 446 C399 399 420 361 460 351 C486 344 489 324 512 320 C539 329 546 348 572 354 C608 368 627 405 610 444 L632 533 C605 590 563 618 512 624 C460 619 419 587 394 533 Z','url(#b01light)',opacity=.85)
    s.path('M420 465 C458 482 487 471 512 453 C538 470 570 482 605 464', 'none',stroke='#f5fcf0',sw=5)
    # serene mask with long spirit ears
    s.path('M424 361 L391 291 Q431 297 462 337 M600 361 L635 291 Q594 299 563 337', 'url(#b01body)','#477780',3)
    s.path('M429 375 C449 336 480 330 512 331 C544 330 575 339 595 375 L584 421 C564 449 541 460 512 461 C483 460 458 449 439 421 Z','#e9e6d6','#5d8589',2)
    s.path('M447 394 Q462 371 485 391 Q468 413 447 394 Z','#263d57'); s.path('M539 391 Q562 371 578 394 Q556 414 539 391 Z','#263d57')
    s.circle(470,389,5,'#fff1cd'); s.circle(553,389,5,'#fff1cd')
    s.path('M495 423 Q512 437 529 423 Q512 449 495 423 Z','#a8657b')
    s.path('M512 438 L512 451', 'none',stroke='#496c7c',sw=2)
    # bell tassels, sound beads and fine whorl marks
    for x,y,r in [(375,487,19),(648,493,17),(420,565,10),(605,568,11),(479,298,8),(547,301,8)]:
        s.circle(x,y,r,'url(#b01cloth)',stroke='#a78a8e',sw=2); s.circle(x-4,y-5,r*.25,'#fff4d9')
    line_detail(s,['M426 505 Q452 533 480 516 T536 518 T594 500','M431 542 Q459 568 488 552 T544 551 T590 538','M453 585 Q486 605 512 590 Q539 604 571 583'], '#e5f7ed',2.3,.8)
    for i in range(7):
        x=444+i*23; y=624+(i%2)*9
        s.path(f'M{x},{y} q-8,13 -3,25', 'none',stroke='#a4dcd7',sw=2)

def boss_02(s):
    # Soroban Golem: carved timber chassis with nested abacus rails and loose beads.
    boss_defs(s,('#d5a16a','#9a633c','#593a31','#617c79','#263a46','#f4bb64'))
    # feet and heavy angular legs
    s.path('M386 760 L400 655 L469 639 L501 721 L480 787 L392 787 Z','url(#b02wood)','#49372d',4)
    s.path('M552 720 L584 636 L652 652 L667 759 L656 787 L567 787 Z','url(#b02wood)','#49372d',4)
    for x in (423,605):
        s.path(f'M{x-26} 735 l52 0 -6 23 -41 0 Z','#b98955','#46372f',2)
        s.circle(x,749,6,'#d8b870',stroke='#49372d',sw=1.5)
    # torso structure is an elaborate rectangular frame
    s.path('M345 333 L405 287 L619 287 L679 333 L678 601 L622 644 L402 644 L345 601 Z','url(#b02wood)','#4e372e',5)
    s.path('M376 337 L416 313 L608 313 L648 337 L648 582 L610 613 L416 613 L376 582 Z','#453a37','#d1a36a',3)
    s.path('M395 350 L629 350 L629 570 L395 570 Z','#26394a','#af8255',3)
    # abacus rods with wooden end caps and individually polished beads
    for i,y in enumerate([377,415,453,491,529,557]):
        s.line(407,y,616,y,'#d6ac75',5)
        for j in range(6):
            x=425+j*34+(i%2)*7
            color=['#d5a65e','#c56c4b','#6daba2','#e0cfa0','#8095a0','#bb8354'][(j+i)%6]
            s.path(f'M{x-11},{y-13} Q{x},{y-19} {x+11},{y-13} L{x+12},{y+10} Q{x},{y+17} {x-12},{y+10} Z',color,'#3d3c35',1.6)
            s.ellipse(x-3,y-8,3,5,'#f4d7a0',opacity=.65)
    # top beam and head like a carved abacus soroban
    s.path('M368 288 L368 211 L403 176 L622 176 L658 211 L658 288 Z','url(#b02wood)','#49352e',4)
    s.path('M389 222 L389 270 M435 220 L435 269 M481 220 L481 269 M527 220 L527 269 M573 220 L573 269 M619 220 L619 269','none',stroke='#d2a66e',sw=4)
    for i,x in enumerate([407,455,503,551,599]):
        for j in range(3):
            y=225+j*14
            s.ellipse(x,y,10,7,['#c9a263','#b75b42','#6fa59b'][(i+j)%3],stroke='#47362e',sw=1.4)
    s.path('M420 171 L420 133 L610 133 L610 171 Z','#71503b','#e1b77c',3)
    s.path('M399 139 L445 113 L583 113 L630 139 Z','#3f5260','#d2ad79',3)
    s.circle(514,143,16,'#d9bb80',stroke='#45372f',sw=3)
    # arms have timber beams, pivot joints and mallet-like fists
    for flip in (-1,1):
        tr=f'translate(512 430) scale({flip} 1) translate(-512 -430)'
        content='<path d="M355 356 L301 379 L273 438 L298 481 L335 459 L352 415 Z" fill="url(#b02wood)" stroke="#49372d" stroke-width="4"/><circle cx="308" cy="427" r="18" fill="#c8a064" stroke="#49372d" stroke-width="4"/><path d="M294 472 L274 495 L304 526 L346 514 L348 488 Z" fill="#7e583c" stroke="#49372d" stroke-width="4"/><path d="M290 494 l25 20 M304 482 l24 18" stroke="#e1b878" stroke-width="3"/>'
        s.group(content,tr)
    # carved tally marks and corner studs
    for x in (368,656):
        for y in (325,590): s.circle(x,y,8,'url(#b02metal)',stroke='#43352f',sw=2)
    line_detail(s,['M408 339 l16 -9 M432 339 l16 -9 M576 339 l16 -9','M408 578 l16 9 M432 578 l16 9 M576 578 l16 9','M405 196 l17 -7 M602 196 l17 7'], '#e6c28a',2,.9)
    s.ellipse(512,805,220,21,'#0b1d2d',opacity=.18)

def boss_03(s):
    # Tanuki gatekeeper: lively mask-faced raccoon dog in a patterned travel coat.
    boss_defs(s,('#b77d4e','#805039','#40323a','#bf5c4f','#653a4a','#ffd180'))
    # tail with alternating rings
    s.path('M614 613 C732 617 752 537 707 491 C675 458 647 485 663 510 C680 538 706 544 694 568 C678 594 640 574 614 589 Z','url(#b03fur)','#4a3735',4)
    for d in ['M680 507 Q715 516 714 544','M659 537 Q691 555 684 577','M633 560 Q656 579 652 596']:
        s.path(d,'none',stroke='#4d3d3e',sw=13)
    # short legs in straw sandals
    s.path('M409 643 L401 724 L453 738 L482 671 Z','url(#b03body)','#4b342e',3)
    s.path('M548 665 L579 734 L627 721 L605 631 Z','url(#b03body)','#4b342e',3)
    s.path('M390 726 Q426 707 466 733 L462 758 L390 756 Z','#b98a5b','#5d4432',3)
    s.path('M565 731 Q599 706 640 719 L653 745 L580 759 Z','#b98a5b','#5d4432',3)
    # coat/belly silhouette
    s.path('M390 438 C401 391 434 367 472 369 L553 369 C599 378 626 423 622 478 L603 626 C570 670 438 672 402 627 Z','url(#b03cloth)','#513740',4)
    s.path('M423 433 Q512 462 591 432 L574 591 Q511 630 439 592 Z','#ead8ac','#977956',2)
    s.path('M414 438 L468 408 L512 444 L556 408 L604 438 L581 474 L512 492 L438 473 Z','#6c3541','#d1a66c',3)
    # cream face and black eye band
    s.path('M417 301 C418 244 459 212 513 214 C567 211 608 245 608 303 L592 357 C567 389 541 404 512 405 C482 402 456 384 433 357 Z','url(#b03fur)','#5a3c34',4)
    s.path('M422 297 Q456 267 480 291 Q511 314 541 289 Q574 264 605 299 L592 330 Q561 340 539 323 Q510 341 481 323 Q451 341 428 329 Z','#302b35','#b38a67',2)
    s.path('M446 300 Q461 280 479 300 Q466 318 446 300 Z','#f2e3bc'); s.path('M545 300 Q565 280 581 300 Q562 319 545 300 Z','#f2e3bc')
    s.circle(463,300,6,'#27384a'); s.circle(562,300,6,'#27384a'); s.circle(460,297,2.4,'#fff4d5'); s.circle(559,297,2.4,'#fff4d5')
    s.path('M485 341 Q512 356 540 341 Q529 372 512 372 Q494 370 485 341 Z','#493541')
    s.path('M501 355 Q512 360 523 355','none',stroke='#e8d6ac',sw=2)
    # ears and forehead markings
    s.path('M431 261 L407 202 Q451 212 467 239 Z','url(#b03body)','#5c3c31',3)
    s.path('M569 239 Q586 211 620 203 L596 264 Z','url(#b03body)','#5c3c31',3)
    s.path('M419 218 Q442 226 451 245 M600 244 Q611 226 615 219','none',stroke='#d4a16b',sw=4)
    # travel hat and bundle, decorated staff
    s.path('M385 233 Q511 173 639 234 Q520 260 385 233 Z','#d9b478','#604738',4)
    s.path('M429 213 Q512 184 596 213','none',stroke='#8c6948',sw=3)
    s.path('M497 203 L511 183 L528 203 Z','#a84f49')
    s.line(675,375,646,713,'#86603e',10); s.line(673,376,644,711,'#e0ba78',2,opacity=.8)
    s.path('M650 424 L717 435 L705 485 L640 474 Z','#e2d4ad','#6a4c3c',2)
    for y in (438,450,462): s.line(650,y,708,y+10,'#9f7950',1.5)
    # leaf-shaped coat clasps, travel satchel, ornamental stitches
    s.path('M482 489 Q512 466 542 489 Q531 510 512 514 Q492 509 482 489 Z','url(#b03metal)','#5e4638',2)
    s.circle(512,493,7,'#f8e3a6',stroke='#694b39',sw=1)
    for i in range(7):
        x=431+i*23; s.path(f'M{x} 548 q7 8 2 17','none',stroke='#e1b97a',sw=2,opacity=.8)
    s.path('M359 514 Q332 535 352 580 L397 588 L408 555 Z','url(#b03cloth)','#513740',3)
    s.path('M355 537 L395 545 L389 574 L357 568 Z','#d4b27d','#5a4639',2)
    s.circle(374,553,6,'#9f554a',stroke='#5d3c35',sw=1.4)

def boss_04(s):
    # Kitsune stationmaster: tall fox silhouette, nine flowing tails, formal uniform.
    boss_defs(s,('#e8c9a5','#bd8559','#774e4b','#314f67','#1d3049','#f6c878'))
    # tails fan behind the body with separate brushed highlights
    tail_paths=[('M475 576 C347 636 265 565 304 491 C326 452 368 472 357 499 C346 521 329 535 349 551 C377 574 418 536 458 531 Z','#cc7655'),('M470 560 C353 539 310 451 370 405 C402 382 427 410 406 432 C385 453 391 472 419 477 L475 499 Z','#f0c28c'),('M473 548 C393 442 438 356 496 375 C530 386 514 415 491 426 C472 440 487 464 507 481 Z','#b35b49'),('M548 547 C654 442 616 363 561 377 C531 386 545 419 566 430 C587 447 571 465 553 482 Z','#ecc58d'),('M553 566 C690 601 768 521 718 461 C691 430 665 457 681 482 C695 506 704 525 681 539 C652 560 602 524 566 530 Z','#c8674e'),('M554 587 C681 674 781 610 758 546 C746 512 710 525 715 550 C720 575 689 590 656 580 Z','#f2d0a0')]
    for d,c in tail_paths: s.path(d,c,'#754b43',3); s.path(d.replace(' Z',''),'none',stroke='#ffe1b0',sw=5,opacity=.6)
    # legs under long uniform coat
    s.path('M440 650 L428 759 L484 776 L503 668 Z','url(#b04cloth)','#1f3043',3)
    s.path('M525 668 L542 776 L597 757 L584 648 Z','url(#b04cloth)','#1f3043',3)
    s.path('M417 758 L492 758 L490 785 L413 785 Z','#6d5147','#263747',2)
    s.path('M535 758 L610 755 L615 782 L543 786 Z','#6d5147','#263747',2)
    # long formal coat with split tails and embroidered hem
    s.path('M414 423 L457 396 L567 397 L610 426 L638 637 L562 691 L515 646 L469 691 L388 638 Z','url(#b04cloth)','#24364c',4)
    s.path('M457 403 L511 448 L567 403 L585 620 L546 647 L514 598 L482 647 L443 620 Z','#e3d5b9','#7a6552',2)
    s.path('M465 421 L510 456 L554 421 L540 482 L511 505 L480 480 Z','#b9534b','#e0ba7c',2)
    s.path('M414 627 Q511 653 612 625 L617 646 Q514 681 408 648 Z','#d2ad69','#33415a',2)
    for i in range(9):
        x=424+i*20; s.path(f'M{x} 641 q7 10 0 17','none',stroke='#f0d79c',sw=2)
    # fox head, tall ears, bright eyes
    s.path('M439 306 L414 207 L478 257 L513 245 L548 257 L612 205 L586 307 L574 349 Q547 385 512 387 Q477 382 451 349 Z','url(#b04body)','#6e493d',4)
    s.path('M430 225 L466 275 L454 307 Z','#e7b4a1'); s.path('M597 225 L560 275 L573 308 Z','#e7b4a1')
    s.path('M455 309 Q473 278 492 304 L481 322 Z','#263548'); s.path('M532 304 Q554 278 570 309 L544 322 Z','#263548')
    s.ellipse(474,306,6,9,'#f2d68d'); s.ellipse(552,306,6,9,'#f2d68d')
    s.path('M495 333 Q512 342 530 333 L512 350 Z','#5d3c41')
    s.path('M512 350 L512 361','none',stroke='#704a48',sw=2)
    # cap, gold badge and rail-ticket pin
    s.path('M432 267 Q513 225 591 267 L583 284 Q512 266 440 285 Z','#24384f','#d1a85f',3)
    s.path('M463 249 L473 218 L552 218 L563 249 Z','#31495f','#d1a85f',3)
    s.circle(512,238,11,'url(#b04metal)',stroke='#6c4e36',sw=2)
    s.path('M595 459 L630 466 L625 508 L590 502 Z','#d8c29b','#31465a',2)
    s.circle(607,481,5,'#b34f49',stroke='#f5d7a0',sw=1)
    # brass buttons and sleeve piping
    for y in [483,522,561,600]: s.circle(512,y,5,'url(#b04metal)',stroke='#685038',sw=1)
    line_detail(s,['M436 439 L413 548','M588 440 L616 548','M452 618 Q510 634 573 618'], '#d2ad6b',2,.85)

def boss_05(s):
    # Kakashi Scribe: straw bundle anatomy, parchment banners, ink-stained robes.
    boss_defs(s,('#d7b47a','#a57d4d','#56483e','#ceb16e','#72533e','#f8d58a'))
    # straw fan and ragged sleeves
    for i in range(11):
        x=512+(i-5)*22; y=435+abs(i-5)*8
        s.path(f'M{x},{y} Q{x-8},{y+58} {x+(i%2)*11},{y+110}', 'none',stroke=['#f0d18b','#c99f5a','#f5dfab'][i%3],sw=4,opacity=.95)
    s.path('M395 441 L343 473 L358 540 L411 522 Z','url(#b05cloth)','#70543c',3)
    s.path('M626 441 L680 473 L664 542 L611 521 Z','url(#b05cloth)','#70543c',3)
    s.path('M424 424 Q512 402 600 424 L614 595 L569 665 L453 665 L410 593 Z','url(#b05cloth)','#55443a',4)
    # patchwork panels and stitched hem
    s.path('M441 440 L487 453 L476 612 L438 594 Z','#b89151','#66503b',2)
    s.path('M537 453 L581 439 L598 594 L561 612 Z','#d4bc7b','#66503b',2)
    for i in range(8):
        x=444+i*18; s.path(f'M{x} 635 l5 8 -3 8','none',stroke='#e2c78c',sw=2)
    # head made from a straw hood with a carved wooden face
    s.path('M432 299 L447 255 L484 236 L540 236 L577 258 L590 304 L568 359 L512 379 L456 357 Z','url(#b05body)','#6e503b',4)
    s.path('M452 294 Q512 260 572 294 L563 337 Q540 363 512 364 Q481 362 461 337 Z','#d5bf8b','#796349',2)
    s.path('M463 305 Q481 291 496 308 L489 323 Z','#403b38'); s.path('M528 308 Q545 291 561 305 L536 323 Z','#403b38')
    s.circle(481,308,4,'#fff0c4'); s.circle(543,308,4,'#fff0c4')
    s.path('M492 341 Q512 350 532 341','none',stroke='#6d4d38',sw=3)
    # floppy kasa hat with woven radial straw
    s.path('M339 272 Q375 218 430 213 Q510 176 594 214 Q648 233 685 272 Q512 302 339 272 Z','#ae854b','#544638',4)
    s.path('M370 266 Q512 228 652 266 M405 235 Q514 262 620 235 M451 207 Q512 241 572 208','none',stroke='#e5c888',sw=3,opacity=.8)
    for i in range(9):
        x=367+i*36; s.path(f'M{x} 263 L{x+17} 228','none',stroke='#8c6a43',sw=2)
    # two calligrapher's hanging scrolls with ink-like abstract marks
    for x,ang in [(366,-8),(653,9)]:
        s.group('<path d="M-24 -4 L24 -4 L20 139 L0 152 L-20 139 Z" fill="#e5d5ad" stroke="#71523a" stroke-width="3"/><path d="M-16 12 H16 M-16 119 H16" stroke="#a88a59" stroke-width="2"/><path d="M0 27 Q-15 44 5 57 L-7 77 Q7 87 -1 104" fill="none" stroke="#293d4a" stroke-width="5" stroke-linecap="round"/><circle cx="8" cy="43" r="3" fill="#293d4a"/>',f'translate({x} 455) rotate({ang})')
    # brush and ink stone strapped at the waist
    s.path('M620 518 L672 590 L660 601 L607 530 Z','#473b36','#d6b77b',2)
    s.path('M656 590 L677 614 L662 622 L648 601 Z','#242e3a')
    s.path('M460 554 Q512 536 564 554 L556 591 Q511 608 467 591 Z','#3e4140','#d1ad76',2)
    s.ellipse(512,564,17,7,'#101d2a'); s.path('M487 572 Q512 583 537 572','none',stroke='#7e91a0',sw=2)
    # loose straw ends and crow-feather stitch details
    for i in range(9):
        x=428+i*20; s.path(f'M{x} 397 q-12 21 -4 40','none',stroke='#eed5a0',sw=2.5)

def boss_06(s):
    # Daruma of Wa: formidable red daruma guardian, layered ceremonial armor and brushwork.
    boss_defs(s,('#ee9b62','#c94e3f','#762e39','#d94e42','#87323a','#ffce73'))
    # squat armored feet and side talismans
    s.path('M408 650 L401 724 L475 744 L499 685 Z','url(#b06metal)','#71373a',4)
    s.path('M530 684 L555 742 L630 723 L614 650 Z','url(#b06metal)','#71373a',4)
    s.path('M388 721 L480 721 L481 759 L389 759 Z','#b94d3e','#70383c',3)
    s.path('M553 720 L647 718 L655 756 L562 760 Z','#b94d3e','#70383c',3)
    # spherical body with layered offset plates
    s.path('M354 461 C355 364 409 311 478 302 C526 294 579 314 618 356 C662 408 675 498 636 570 C606 630 563 664 508 668 C446 665 395 626 369 568 Z','url(#b06body)','#6e3039',5)
    s.path('M389 440 C413 371 463 348 514 348 C566 350 607 382 624 436 L624 511 C599 585 558 618 508 623 C455 619 417 587 393 518 Z','url(#b06light)',opacity=.72)
    # ceramic glaze rings and ornamental cloud motifs
    s.path('M379 465 Q505 509 647 458 M387 532 Q506 574 632 531','none',stroke='#f5c17b',sw=5,opacity=.85)
    s.path('M403 405 Q422 379 446 405 Q468 428 489 404 Q511 382 532 405 Q552 428 575 402 Q592 386 612 406','none',stroke='#7e2635',sw=7)
    s.path('M411 564 Q435 542 457 563 T503 563 T550 563 T599 560','none',stroke='#ffd68b',sw=4)
    for x,y in [(423,472),(587,472),(449,592),(568,590)]:
        s.path(f'M{x-17} {y} Q{x-20} {y-19} {x} {y-17} Q{x+21} {y-18} {x+17} {y} Q{x} {y+16} {x-17} {y} Z','none',stroke='#8d2834',sw=3)
    # face plate, sweeping brows and golden eye rims
    s.path('M423 376 Q507 339 591 376 L580 447 Q552 489 507 492 Q461 488 434 448 Z','#e5bd83','#8b433b',3)
    s.path('M439 402 Q463 380 490 403 L481 423 Z','#392f39'); s.path('M525 403 Q552 380 575 402 L533 423 Z','#392f39')
    s.path('M432 390 Q460 366 491 393 M525 393 Q552 366 582 390','none',stroke='#f5d18b',sw=7)
    s.circle(462,402,6,'#f7d56c'); s.circle(550,402,6,'#f7d56c')
    s.path('M480 451 Q507 467 535 450 L529 473 Q508 488 487 473 Z','#6c2d38')
    s.path('M485 456 L495 461 L505 456 L515 461 L526 455','none',stroke='#f0d6a0',sw=2.4)
    # painted brow crest and ceremonial top knot
    s.path('M480 365 Q506 321 535 365 Q512 357 480 365 Z','#83303b','#f1c980',2)
    s.circle(508,326,17,'url(#b06metal)',stroke='#713b38',sw=3)
    s.path('M496 313 L508 293 L521 313 Z','#dbb56d','#6d3e39',2)
    # shoulder guards and sleeve bands
    for flip in (-1,1):
        content='<path d="M-115 -32 L-73 -74 L-24 -58 L-9 -17 L-42 26 L-94 15 Z" fill="url(#b06metal)" stroke="#6e363b" stroke-width="4"/><path d="M-100 -25 l54 0 M-83 -52 l45 0 M-89 -2 l47 -3" fill="none" stroke="#fff0bd" stroke-width="3"/><circle cx="-60" cy="-20" r="8" fill="#e64d43" stroke="#6e363b" stroke-width="2"/>'
        s.group(content,f'translate({512} {479}) scale({flip} 1)')
    # belly medallion
    s.circle(508,548,38,'#c79d57',stroke='#71373a',sw=5); s.circle(508,548,28,'#a33e3c',stroke='#f4d28b',sw=3)
    s.path('M492 542 Q508 520 524 542 L517 563 L508 570 L499 563 Z','#edc878','#6e3537',2)
    for i in range(8): s.circle(508+math_cos(i*45)*49,548+math_sin(i*45)*49,3,'#f5d894')

def math_cos(deg):
    import math; return math.cos(deg*math.pi/180)
def math_sin(deg):
    import math; return math.sin(deg*math.pi/180)

def boss_07(s):
    # Karakasa Collector: one-eyed paper umbrella yokai with wooden foot and dangling charm.
    boss_defs(s,('#e4a1a5','#bd5b65','#703d5d','#4f6790','#292e52','#f7c0a4'))
    # long crooked wooden leg and foot
    s.path('M509 472 C531 543 506 625 529 688 L569 718 L554 741 L502 713 C477 631 493 550 478 493 Z','url(#b07wood)','#3f3040',4)
    s.path('M517 711 Q568 695 604 733 L594 754 L517 753 Z','#ab6e53','#4d3542',3)
    s.path('M525 721 l19 18 M540 715 l19 18 M554 714 l18 16','none',stroke='#e3b28a',sw=2)
    # canopy is a broad, pleated, irregular crescent
    s.path('M185 395 C226 286 345 217 511 201 C679 216 800 287 838 395 C786 387 735 425 690 420 C624 412 574 385 511 394 C447 385 393 416 330 422 C276 425 225 385 185 395 Z','url(#b07body)','#47334e',5)
    # alternating paper gores
    for d,col in [('M511 202 L510 394 Q455 384 410 412 Z','#e9b6aa'),('M511 202 L604 409 Q653 405 690 420 Z','#7c8eb1'),('M511 202 L410 412 Q370 419 330 422 Z','#c85b67'),('M511 202 L690 420 Q744 418 790 387 Z','#a64b65'),('M511 202 L330 422 Q276 425 225 389 Z','#dc7b7f')]:
        s.path(d,col,'#55405b',2)
    s.path('M197 391 Q511 314 826 391','none',stroke='#f1c6a8',sw=5,opacity=.8)
    for i in range(13):
        x=229+i*47; yy=395+abs(511-x)*.12
        s.line(511,204,x,yy,'#59405b',2.2,opacity=.8)
    # one glaring eye on a creamy patch
    s.path('M439 281 Q511 240 586 282 Q592 330 551 353 Q510 372 470 352 Q434 328 439 281 Z','#f4e3c3','#5a4255',3)
    s.ellipse(512,310,39,47,'#302d49',stroke='#bc6c6f',sw=3)
    s.ellipse(518,304,24,32,'#f7d6a0'); s.ellipse(522,301,13,24,'#24263d'); s.circle(526,292,6,'#fff4d5')
    # cheek seams and expressive brow
    s.path('M448 279 Q511 240 577 276','none',stroke='#f3e0c1',sw=5)
    s.path('M473 366 Q511 382 548 365','none',stroke='#49364c',sw=3)
    # handle cap, tassels and collector's paper charms
    s.circle(511,203,13,'url(#b07metal)',stroke='#4c354b',sw=3)
    s.path('M512 212 L512 166 Q535 147 529 129','none',stroke='#5e403c',sw=8)
    s.path('M528 130 Q555 130 567 152 L551 175 L529 156 Z','#c7aa7a','#5e403c',2)
    s.path('M341 421 L321 485 L354 489 L371 427 Z','#e7d1a5','#55415a',2)
    for y in [437,451,465,477]: s.line(333,y,358,y+4,'#9e7a65',1.6)
    s.path('M679 419 L693 487 L726 478 L708 411 Z','#a7bfd0','#55415a',2)
    for y in [432,447,462,473]: s.line(692,y,714,y-5,'#f5d8b0',1.6)
    # rain droplets and patched stitching
    for x,y,r in [(265,474,5),(747,502,4),(402,487,3),(617,459,4),(783,452,5)]:
        s.path(f'M{x},{y-r} Q{x-r*1.4},{y} {x},{y+r} Q{x+r*1.4},{y} {x},{y-r} Z','#9dd0dd',opacity=.78)
    for i in range(5): s.path(f'M{245+i*24} 360 q9 2 15 0','none',stroke='#f2c5a9',sw=2)

def boss_08(s):
    # Nishikigoi Dragon: flowing koi body with layered plate scales, whiskers, fins and antlers.
    boss_defs(s,('#79d0d4','#2b8fa2','#194c6b','#e7a6ac','#9b4d6c','#7de4e1'))
    # serpentine body loop and ribbon fins
    s.path('M342 676 C261 612 290 529 386 532 C492 535 584 625 650 562 C705 509 657 433 588 435 C519 439 494 479 456 444 C412 404 449 320 530 321 C592 322 623 359 655 381','none',stroke='#245b78',sw=113)
    s.path('M342 676 C261 612 290 529 386 532 C492 535 584 625 650 562 C705 509 657 433 588 435 C519 439 494 479 456 444 C412 404 449 320 530 321 C592 322 623 359 655 381','none',stroke='url(#b08body)',sw=101)
    s.path('M316 650 C270 601 306 559 366 560 C468 563 577 654 660 575 C724 514 670 416 589 411 C509 406 493 454 459 424 C430 398 463 350 522 350','none',stroke='#e7c58d',sw=10,opacity=.8)
    # dragon chest and upright neck
    s.path('M552 432 C576 382 567 325 603 289 C629 263 672 273 687 305 L704 357 L671 397 L655 456 L619 491 Z','url(#b08body)','#194c68',4)
    # fins: dorsal scallops and tail fins
    s.path('M312 562 L273 516 L305 524 L290 477 L329 502 L342 462 L365 502 L398 488 L399 532 Z','url(#b08cloth)','#24566e',3)
    s.path('M648 339 L665 292 L686 316 L712 278 L713 328 L748 307 L736 354 L763 360 L721 388 Z','url(#b08cloth)','#24566e',3)
    s.path('M289 668 L235 699 L253 643 L214 625 L275 618 L287 578 L318 623 Z','url(#b08cloth)','#24566e',3)
    # horned head
    s.path('M587 323 L572 271 L603 285 L623 243 L645 278 L679 268 L677 307 L709 326 L699 366 Q672 404 629 392 L596 366 Z','url(#b08body)','#194c68',4)
    s.path('M600 303 L603 244 L625 278 Z','#d4c79b','#23516b',2); s.path('M659 285 L684 242 L685 307 Z','#e7d29d','#23516b',2)
    s.path('M601 332 Q619 310 639 329 L625 344 Z','#182d46'); s.path('M653 328 Q676 308 691 333 L663 346 Z','#182d46')
    s.ellipse(620,331,5,7,'#f6d26a'); s.ellipse(675,330,5,7,'#f6d26a')
    s.path('M630 361 Q652 372 677 356 L668 375 Q650 387 636 373 Z','#9b4153')
    for x,y in [(628,361),(640,364),(652,365),(664,362)]: s.poly([(x,y),(x+4,y+7),(x+7,y)],'#fff0cc')
    # whiskers, gill fans, cheek plates
    s.path('M600 359 C552 355 545 390 505 388 C482 387 472 375 460 362 M692 356 C731 351 745 377 779 367 C797 362 810 348 819 338','none',stroke='#f3d9ad',sw=5)
    s.path('M599 369 Q579 395 592 416 M610 371 Q594 406 610 426 M699 365 Q722 392 708 412','none',stroke='#efbb7a',sw=4)
    # scales are arranged along each visible body curve, each a separate edged plate
    for row in range(5):
        for col in range(8):
            x=335+col*25+(row%2)*11; y=546+row*22+int(abs(x-435)*.10)
            if x<487 and y<639:
                s.path(f'M{x-11},{y-6} Q{x},{y-17} {x+11},{y-6} L{x+8},{y+6} Q{x},{y+13} {x-8},{y+6} Z',['#88ded9','#4caab8','#2f879f'][row%3],'#225d7b',1.2)
                s.path(f'M{x-7},{y-5} Q{x},{y-11} {x+5},{y-5}','none',stroke='#d9f4da',sw=1.2,opacity=.8)
    for row in range(4):
        for col in range(5):
            x=552+col*22; y=393+row*20
            if (x-589)**2+(y-435)**2 < 88**2:
                s.path(f'M{x-9},{y-3} Q{x},{y-14} {x+9},{y-3} L{x+7},{y+7} Q{x},{y+13} {x-7},{y+7} Z','#4eafbc','#235a75',1.1)
    # bright fin webbing and dorsal spots
    line_detail(s,['M301 527 Q335 540 371 529','M319 524 L311 492','M348 527 L341 486','M372 532 L383 507','M670 362 L691 320','M693 368 L726 337','M675 382 L709 360'], '#d8f1d5',2.5,.85)

def boss_09(s):
    # Konohana Spirit: floral humanoid with blossom halo, layered petal mantle and vine embroidery.
    boss_defs(s,('#f4d0d7','#db8eae','#985d86','#d94f80','#762e5b','#ffd9e9'))
    # skirt shaped as overlapping petals
    s.path('M435 479 Q393 541 363 628 Q428 670 478 645 Q508 696 544 646 Q602 671 665 626 Q633 547 586 479 Z','url(#b09cloth)','#8b4b70',3)
    for d,c in [('M433 491 Q421 567 391 617 Q426 639 463 629 Z','#f8c9d6'),('M464 493 Q464 584 443 649 Q479 666 506 649 L510 493 Z','#d97ba2'),('M513 493 Q532 576 549 650 Q579 666 610 637 Q576 553 580 491 Z','#f1afc6'),('M550 493 Q594 561 637 617 Q656 601 643 577 L586 483 Z','#b96e9c')]: s.path(d,c,'#b66a92',2)
    # arms, sleeves, translucent cuffs
    s.path('M432 407 L383 431 L348 488 L380 510 L430 464 Z','url(#b09body)','#99577d',3)
    s.path('M583 407 L633 431 L672 484 L642 510 L587 463 Z','url(#b09body)','#99577d',3)
    s.path('M353 482 Q370 467 389 489 L374 521 Q354 514 344 500 Z','#f8d4df','#a85c88',2)
    s.path('M637 487 Q656 466 675 484 L682 501 Q671 516 650 522 Z','#f8d4df','#a85c88',2)
    # torso with crossed kimono sash
    s.path('M444 378 L481 359 L535 359 L577 380 L590 478 L512 513 L431 476 Z','url(#b09cloth)','#924d76',3)
    s.path('M459 383 L506 421 L486 475 L450 463 Z','#f7d6df','#a3547c',2)
    s.path('M565 383 L517 422 L538 475 L576 461 Z','#f0b4cb','#a3547c',2)
    s.path('M464 446 Q512 467 562 444 L555 466 Q512 487 471 465 Z','url(#b09metal)','#87566e',2)
    s.path('M512 435 L534 454 L512 478 L491 454 Z','#e9c77d','#8c5268',2)
    # elegant face and sweeping pink hair
    s.path('M451 278 C453 231 480 204 513 204 C547 204 574 233 575 278 L565 321 Q543 353 512 354 Q482 352 461 321 Z','#f5d8cd','#a56a78',2)
    s.path('M445 277 Q427 215 475 188 Q516 164 555 194 Q597 224 578 285 L557 267 Q549 226 520 222 Q486 220 470 262 Z','url(#b09body)','#9b547b',3)
    s.path('M451 255 Q423 284 440 329 L460 348 L463 293 Z','#e9aac5','#9b547b',2)
    s.path('M574 251 Q603 281 586 326 L564 348 L562 290 Z','#e9aac5','#9b547b',2)
    s.path('M468 285 Q485 267 500 287 L490 302 Z','#49314a'); s.path('M525 287 Q542 267 558 285 L533 302 Z','#49314a')
    s.ellipse(485,285,4,6,'#f5d78d'); s.ellipse(545,285,4,6,'#f5d78d')
    s.path('M498 319 Q512 326 526 319','none',stroke='#b15e7c',sw=2.5)
    # crown of flowers, some blossoms spilling into the air
    for x,y,k in [(467,204,.82),(488,183,.75),(515,178,.9),(540,189,.72),(563,211,.76),(437,247,.56),(592,244,.56)]:
        blossom(s,x,y,k,'#f4b6d0','#ffe8b0')
    # botanical embroidery and vine tendrils
    line_detail(s,['M451 512 Q471 535 458 560 T442 598','M574 510 Q552 543 570 563 T592 604','M472 555 Q490 565 486 587','M547 555 Q531 574 541 592'], '#f5d6a0',2.4,.9)
    for x,y in [(459,541),(568,544),(477,590),(551,603),(500,624),(530,630)]: blossom(s,x,y,.3,'#f8d3df','#fff0bc')
    # petals float asymmetrically around the figure
    for x,y,rot in [(320,363,-24),(682,342,28),(361,570,12),(697,586,-12),(393,260,36),(641,270,-35)]:
        s.group('<path d="M-12 0 Q-2 -13 13 -2 Q2 8 -12 0 Z" fill="#ef9fbe" stroke="#f7d4de" stroke-width="1.2"/>',f'translate({x} {y}) rotate({rot})')

def boss_10(s):
    # Gold Oni: broad, plated guardian with twin horns, a huge kanabo and coin charms.
    boss_defs(s,('#f8d889','#c99039','#7a4c26','#b34832','#682d31','#ffc45d'))
    # heavy greaves and split skirt plates
    s.path('M407 638 L388 738 L463 761 L492 673 Z','url(#b10metal)','#6b442d',4)
    s.path('M535 675 L562 761 L640 738 L613 634 Z','url(#b10metal)','#6b442d',4)
    for x in [418,599]:
        s.path(f'M{x-30} 734 L{x+32} 734 L{x+42} 764 L{x-24} 769 Z','#a66e2f','#4e3429',3)
        for i in range(3): s.line(x-17+i*16,740,x-17+i*16,761,'#f5dd93',2)
    s.path('M410 523 L446 589 L470 655 L429 681 L389 637 L377 558 Z','url(#b10cloth)','#63323a',3)
    s.path('M615 520 L649 557 L644 630 L598 672 L560 651 L590 578 Z','url(#b10cloth)','#63323a',3)
    # torso is built from overlapping gold chest plates
    s.path('M393 393 L451 354 L575 354 L634 394 L624 559 L580 619 L447 619 L404 558 Z','url(#b10metal)','#613c28',5)
    s.path('M425 407 L474 383 L552 383 L601 407 L592 531 L559 574 L467 574 L435 531 Z','#b85c32','#633b2a',3)
    s.path('M443 413 L486 392 L540 392 L581 414 L569 477 L512 504 L455 478 Z','url(#b10metal)','#68452c',3)
    # segmented shoulder armor
    for flip in (-1,1):
        content='<path d="M-112 -14 L-98 -62 L-51 -80 L-15 -53 L-18 -8 L-56 28 L-98 14 Z" fill="url(#b10metal)" stroke="#68452c" stroke-width="4"/><path d="M-100 -51 L-57 -64 L-29 -46 M-98 -24 L-48 -39 M-78 0 L-36 -15" fill="none" stroke="#fff0b4" stroke-width="3"/><circle cx="-62" cy="-31" r="9" fill="#bc4b30" stroke="#6b392b" stroke-width="2"/>'
        s.group(content,f'translate({512} 414) scale({flip} 1)')
    # thick arms and giant studded kanabo on the left
    s.path('M403 414 L353 445 L342 519 L386 555 L424 524 L428 462 Z','url(#b10body)','#6b4028',4)
    s.path('M612 419 L668 447 L684 515 L647 552 L609 522 L594 461 Z','url(#b10body)','#6b4028',4)
    s.path('M300 209 L326 194 L372 555 L342 568 Z','url(#b10wood)','#4b3127',4)
    s.path('M275 219 Q291 180 330 171 Q365 181 389 216 L374 248 L292 248 Z','url(#b10metal)','#4f3327',4)
    for x,y,r in [(298,217,7),(322,204,7),(347,213,7),(367,230,7),(308,237,7),(340,239,7)]: s.circle(x,y,r,'#e9c46e',stroke='#69452d',sw=2)
    s.path('M326 550 L357 540 L370 574 L336 586 Z','#c88d3b','#57392a',3)
    # demon face, red skin and layered brow ridges
    s.path('M427 286 L419 228 L466 244 L490 202 L514 233 L544 204 L569 244 L608 229 L600 292 L589 339 Q555 383 512 384 Q466 380 439 341 Z','url(#b10body)','#663828',4)
    s.path('M450 260 L426 180 Q473 202 486 241 Z','#f0d59a','#734426',4)
    s.path('M539 241 Q555 202 600 180 L578 264 Z','#f0d59a','#734426',4)
    s.path('M447 293 Q470 266 494 292 L480 315 Z','#292637'); s.path('M530 292 Q555 266 579 293 L542 315 Z','#292637')
    s.ellipse(472,295,6,8,'#ffe46a'); s.ellipse(556,295,6,8,'#ffe46a')
    s.path('M486 342 Q512 354 538 341 L530 365 Q512 380 494 365 Z','#632c32')
    for x in [493,507,521,535]: s.poly([(x,353),(x+5,366),(x+9,351)],'#fff0c7','#8c5a38',1)
    # golden crest, ornamental plates, waist rings
    s.path('M470 249 Q512 215 553 249 L540 267 Q512 255 482 268 Z','url(#b10metal)','#68452d',2)
    s.circle(512,248,11,'#d84f32',stroke='#f5d58c',sw=3)
    s.path('M468 522 L512 540 L556 521 L545 571 L512 589 L479 571 Z','url(#b10metal)','#603c2c',3)
    s.circle(512,550,16,'#c14b2e',stroke='#fff0b2',sw=3); s.circle(512,550,5,'#ffdf83')
    for i in range(5):
        x=466+i*23; s.circle(x,605,5,'#fff0b0',stroke='#8c5f32',sw=1)
    # coin charms hang from the belt
    for x,y in [(436,634),(470,650),(550,650),(588,631)]:
        s.circle(x,y,13,'url(#b10metal)',stroke='#6f492c',sw=2); s.circle(x,y,5,'#6f452b')

def boss_11(s):
    # Kodama Elder: towering bark body, branching antlers, leafy beard and moss robes.
    boss_defs(s,('#a3bb85','#64876a','#31544f','#607f5c','#2d514b','#9ef0c3'))
    # long root legs and knotted bark trunk
    s.path('M426 630 C400 695 379 744 340 773 L394 785 L452 725 L489 654 Z','url(#b11wood)','#283f3d',4)
    s.path('M533 652 L572 728 L621 779 L676 770 C642 727 612 684 590 622 Z','url(#b11wood)','#283f3d',4)
    s.path('M404 759 L442 754 L453 778 L390 793 L365 780 Z','#6f8a67','#283e3b',3)
    s.path('M603 755 L642 758 L681 783 L645 796 L594 781 Z','#6f8a67','#283e3b',3)
    # main trunk-body with twisted growth rings and bark plates
    s.path('M414 407 C404 351 430 306 473 300 L546 300 C595 319 620 365 605 421 L632 593 Q570 662 512 661 Q453 660 391 593 Z','url(#b11wood)','#263e3c',5)
    s.path('M456 399 C449 359 475 334 504 330 L538 331 C568 347 577 374 567 415 L580 575 Q547 613 512 615 Q474 609 447 576 Z','#5d7761','#304844',2)
    line_detail(s,['M431 385 Q451 408 439 448 T449 514 T431 580','M465 364 Q482 392 471 422 T482 486','M580 381 Q557 405 572 440 T560 509 T580 570','M529 345 Q516 373 529 399 T519 448','M465 555 Q485 541 501 553 T532 552 T562 546'], '#a7b18a',4,.62)
    # branching shoulders and arms that feel like old limbs
    s.path('M414 408 C372 409 359 448 365 491 L392 528 L424 506 L417 470 L453 450 Z','url(#b11wood)','#2a4541',4)
    s.path('M603 405 C645 407 660 445 652 487 L626 528 L595 509 L600 472 L566 450 Z','url(#b11wood)','#2a4541',4)
    s.path('M371 490 L337 522 L350 551 L390 530 Z','#765e46','#2a4541',3); s.path('M647 486 L680 516 L667 549 L626 530 Z','#765e46','#2a4541',3)
    # face emerges from a deep tree hollow
    s.path('M441 316 Q445 250 512 237 Q580 250 584 316 L568 362 Q544 387 512 387 Q480 384 457 362 Z','#1d3538','#7a9274',4)
    s.path('M463 308 Q484 281 502 307 L489 326 Z','#e0c58d'); s.path('M522 307 Q543 281 562 308 L535 326 Z','#e0c58d')
    s.ellipse(483,308,5,7,'#203a43'); s.ellipse(544,308,5,7,'#203a43')
    s.circle(484,305,2.5,'#d1f5c8'); s.circle(545,305,2.5,'#d1f5c8')
    s.path('M493 346 Q512 359 532 346','none',stroke='#81a184',sw=3)
    # antlers fork into angular old branches with tiny leaves
    s.path('M469 263 C432 235 429 192 398 171 M443 222 L400 222 L379 195 M444 222 L459 185 L448 158 M554 264 C594 232 591 196 624 171 M582 222 L626 218 L647 192 M582 221 L565 182 L581 155','none',stroke='#674c39',sw=12)
    s.path('M469 263 C432 235 429 192 398 171 M443 222 L400 222 L379 195 M444 222 L459 185 L448 158 M554 264 C594 232 591 196 624 171 M582 222 L626 218 L647 192 M582 221 L565 182 L581 155','none',stroke='#bc9a6b',sw=3,opacity=.7)
    for x,y,k in [(387,190,.54),(448,166,.47),(627,180,.54),(579,164,.48),(398,230,.42),(629,226,.46)]: leaves(s,[(x,y,k)],('#2b674f','#5f9c65','#b0cb80'))
    # beard of curled roots, moss pads and mushrooms
    s.path('M465 357 Q449 392 471 417 Q490 439 474 462 Q498 448 504 425 Q524 451 536 471 Q548 441 532 417 Q562 399 560 359 Z','url(#b11wood)','#2b4540',3)
    for x,y,k in [(466,395,.68),(495,425,.64),(536,432,.7),(560,395,.62),(487,470,.54)]: leaves(s,[(x,y,k)],('#315e49','#5d8e5a','#abc57c'))
    for x,y in [(451,545),(582,531),(467,591),(562,588)]:
        s.path(f'M{x-8} {y+12} Q{x-5} {y-7} {x} {y-11} Q{x+11} {y-9} {x+12} {y+12} Z','#d7d9b1','#4b6c58',1.5)
        s.ellipse(x+1,y-8,7,3,'#b7e6b4')
    # root rune bands and chest moss sigil
    s.path('M449 504 Q511 530 573 504 M445 525 Q511 551 577 525','none',stroke='#b9c794',sw=4,opacity=.7)
    s.circle(512,486,28,'#457e67',stroke='#a9c18b',sw=3); s.path('M512 465 Q491 487 512 506 Q533 487 512 465 Z','#c4d39a')

def boss_12(s):
    # Nue of Yesterday: chimera with leopard forequarters, bird wings, horned feline face, serpent tail.
    boss_defs(s,('#d5af7a','#9a6c58','#4e4650','#6e7e91','#343748','#efb66e'))
    # long serpent tail curls with a feathered tip
    s.path('M581 615 C705 686 785 627 748 565 C723 524 680 544 694 568 C707 591 732 590 716 611 C700 632 670 612 650 592 Z','url(#b12body)','#4e3b3d',4)
    s.path('M738 566 L782 537 L772 580 L809 594 L769 611 L780 647 L744 621 L720 653 L715 613 Z','url(#b12cloth)','#454052',3)
    # hind legs and clawed feet
    s.path('M419 571 L385 668 L424 709 L467 683 L479 603 Z','url(#b12body)','#4c3b3a',4)
    s.path('M553 581 L565 676 L606 705 L643 672 L613 576 Z','url(#b12body)','#4c3b3a',4)
    for x,y in [(411,699),(594,694)]:
        s.path(f'M{x-24} {y-4} L{x+22} {y-8} L{x+38} {y+17} L{x-28} {y+25} Z','#67514b','#3c3339',3)
        for j in range(3): s.path(f'M{x+6+j*10} {y+13} l9 12','none',stroke='#e0c59a',sw=3)
    # muscular body and spotted flank
    s.path('M373 456 C388 393 452 371 507 395 L564 418 C608 441 626 501 591 558 L542 612 L432 606 L388 561 Z','url(#b12body)','#493a3c',4)
    s.path('M409 460 Q445 427 484 450 Q511 479 495 534 L463 576 L417 551 Z','#d7b88b',opacity=.78)
    for x,y in [(421,462),(447,473),(469,492),(429,510),(454,531),(480,550),(511,455),(531,482),(552,505),(531,534)]:
        s.path(f'M{x-7} {y-4} Q{x} {y-13} {x+7} {y-4} Q{x+3} {y+8} {x-5} {y+6} Z','#4c4244',opacity=.82)
    # feathered wings layered like a fan
    s.path('M445 436 C379 408 321 350 311 286 C368 306 411 333 455 364 C423 316 429 258 461 231 C502 286 515 338 508 391 Z','url(#b12cloth)','#4a414d',4)
    for i in range(6):
        x=325+i*25; y=306+i*12
        s.path(f'M{x} {y} Q{x+22} {y+41} {x+44} {y+78} Q{x+18} {y+57} {x-8} {y+34} Z',['#e3bf8e','#8a9aa0','#c57c62'][i%3],'#4e4652',1.4)
    s.path('M555 434 C614 399 683 354 705 292 C648 306 604 333 564 364 C589 316 582 264 552 236 C510 287 492 338 500 391 Z','url(#b12cloth)','#4a414d',4)
    for i in range(6):
        x=684-i*25; y=309+i*12
        s.path(f'M{x} {y} Q{x-22} {y+41} {x-44} {y+78} Q{x-18} {y+57} {x+8} {y+34} Z',['#e3bf8e','#8a9aa0','#c57c62'][i%3],'#4e4652',1.4)
    # feline head, two horns and bird-like cheek tufts
    s.path('M431 350 L417 292 L455 309 L477 273 L509 303 L546 279 L564 316 L600 302 L589 356 Q568 404 514 413 Q465 405 445 377 Z','url(#b12body)','#493b3e',4)
    s.path('M447 313 L439 252 L480 300 Z','#f0d0a1','#4f4142',3); s.path('M543 302 L580 251 L568 321 Z','#f0d0a1','#4f4142',3)
    s.path('M459 354 Q480 332 498 354 L482 370 Z','#263047'); s.path('M527 354 Q548 331 566 354 L537 371 Z','#263047')
    s.ellipse(481,354,5,7,'#f7c75e'); s.ellipse(547,354,5,7,'#f7c75e')
    s.path('M486 383 Q514 400 541 381 L530 402 Q513 415 497 401 Z','#3e3440')
    for x in [499,512,525]: s.poly([(x,397),(x+4,408),(x+8,396)],'#ead9ba')
    # beak-like upper mask detail and whiskers
    s.path('M497 363 L513 373 L529 362 L518 385 Z','#d7b982','#4c3c3c',2)
    s.path('M455 379 C424 392 404 379 389 366 M565 379 C594 390 617 379 634 362','none',stroke='#e5cb9b',sw=3)
    # shoulder feathers and temporal markings
    for i in range(5):
        x=438+i*17; y=420-(i%2)*7
        s.path(f'M{x} {y} l-11 27 20 -8 11 20 4 -30 Z','#8e5d55','#4a3b42',1.5)
    line_detail(s,['M453 320 l14 -8 M559 320 l-14 -8','M459 393 q12 5 20 0 M550 393 q-12 5 -20 0'], '#e8cfa0',2,.85)

def boss_13(s):
    # Tsuki Usagi: celestial rabbit with long ears, lunar robe, silver ornament and halo.
    boss_defs(s,('#f2f1e8','#b6cce0','#687fa0','#8195c3','#3b4b72','#d7e8ff'))
    s.ellipse(512,405,216,250,'none',stroke='#b7d0ed',sw=3,opacity=.34); s.ellipse(512,405,185,222,'none',stroke='#f2e8c8',sw=1.8,opacity=.3)
    # long ears trail up with pale interior
    s.path('M459 285 C421 219 389 129 413 87 C455 121 481 202 489 267 Z','url(#b13body)','#60799c',3)
    s.path('M433 238 C413 172 411 135 419 111 C446 158 459 208 465 249 Z','#e5a9ba',opacity=.8)
    s.path('M547 270 C554 196 578 118 618 87 C642 126 605 216 567 287 Z','url(#b13body)','#60799c',3)
    s.path('M570 249 C588 180 610 140 617 115 C622 158 595 219 579 258 Z','#e5a9ba',opacity=.8)
    # moon staff curves around one side
    s.path('M632 449 C709 377 706 279 649 258 C620 246 601 266 616 289 C631 311 651 303 654 287','none',stroke='#b7c8e1',sw=14)
    s.circle(654,262,42,'none',stroke='#e7cb88',sw=4); s.circle(654,262,27,'#c9d9e9',opacity=.45)
    # robe and wide flowing sleeves
    s.path('M440 411 L396 442 L360 505 L401 536 L455 490 Z','url(#b13cloth)','#3d4b6e',3)
    s.path('M581 412 L631 440 L660 503 L622 536 L569 488 Z','url(#b13cloth)','#3d4b6e',3)
    s.path('M407 496 Q383 502 371 521 L405 542 Q427 529 431 506 Z','#d4dfed','#637aa0',2)
    s.path('M620 499 Q645 500 658 521 L628 543 Q605 530 600 507 Z','#d4dfed','#637aa0',2)
    s.path('M432 377 L475 349 L550 349 L591 381 L606 542 Q561 628 512 659 Q462 628 414 542 Z','url(#b13cloth)','#354565',4)
    s.path('M457 393 L511 432 L489 578 L440 535 Z','#d8e2ee','#60799c',2)
    s.path('M566 392 L514 432 L535 578 L583 534 Z','#657db1','#354565',2)
    # silver waist knot and crescent embroidery
    s.path('M443 489 Q511 512 579 489 L574 511 Q512 538 448 511 Z','url(#b13metal)','#475779',2)
    s.path('M512 488 L542 513 L512 543 L482 513 Z','#e7c985','#52688f',2)
    s.path('M488 572 Q511 548 535 572 Q513 606 488 572 Z','none',stroke='#e8d19a',sw=4)
    for y in [590,609,628]: s.path(f'M494 {y} Q512 {y+9} 530 {y}','none',stroke='#a9c5e8',sw=2)
    # plush rabbit head with detailed fur tufts
    s.path('M444 298 C439 249 472 212 512 212 C553 212 585 248 580 298 L565 343 Q539 371 512 370 Q484 369 459 342 Z','url(#b13fur)','#667b99',3)
    s.path('M449 272 l-19 -12 11 31 M466 235 l-4 -17 17 18 M557 236 l8 -18 7 20','none',stroke='#fffaf0',sw=7)
    s.path('M462 303 Q480 284 498 304 L487 320 Z','#34425f'); s.path('M526 304 Q544 284 562 303 L537 320 Z','#34425f')
    s.ellipse(481,304,4,6,'#f7e0a4'); s.ellipse(544,304,4,6,'#f7e0a4')
    s.path('M499 327 Q512 339 525 327 Q520 347 512 348 Q504 347 499 327 Z','#b7758e')
    s.path('M512 347 L512 357','none',stroke='#69799a',sw=2)
    s.ellipse(487,337,8,4,'#efb9ca',opacity=.65); s.ellipse(537,337,8,4,'#efb9ca',opacity=.65)
    # silver hairpin and star charms
    s.path('M477 226 Q511 202 548 229 L539 244 Q511 232 485 245 Z','url(#b13metal)','#63799c',2)
    s.circle(512,227,9,'#e9d9a8',stroke='#687e9e',sw=2)
    for x,y in [(442,407),(581,414),(455,554),(568,558)]:
        s.path(f'M{x} {y-8} l3 6 7 1 -5 5 1 7 -6 -4 -6 4 1 -7 -5 -5 7 -1 Z','#e7d8a3',opacity=.9)

def boss_14(s):
    # Oni Shopkeeper: jovial red oni with horns, layered festival coat, fan of goods and wares.
    boss_defs(s,('#ee9f72','#c95e4a','#77363d','#d35b4c','#783749','#ffd17e'))
    # shoes and wide merchant trousers
    s.path('M424 626 L411 715 L474 743 L496 672 Z','url(#b14cloth)','#643342',3)
    s.path('M532 669 L554 740 L619 713 L604 623 Z','url(#b14cloth)','#643342',3)
    s.path('M398 714 Q442 697 489 729 L484 760 L401 760 Z','#66483f','#342c3a',3)
    s.path('M553 727 Q597 698 633 715 L642 745 L565 764 Z','#66483f','#342c3a',3)
    # generously padded festival jacket and sash
    s.path('M399 408 L451 373 L570 373 L622 409 L637 599 L584 653 L439 653 L384 600 Z','url(#b14cloth)','#653342',4)
    s.path('M425 414 L476 432 L465 608 L429 591 Z','#f0d4ae','#884b44',2)
    s.path('M599 414 L548 432 L559 608 L594 591 Z','#efbd9d','#884b44',2)
    s.path('M439 458 L585 458 L576 485 L447 485 Z','#f5d4a0','#703a3c',2)
    s.path('M442 612 Q512 640 584 612 L573 633 Q512 655 451 633 Z','#b85a48','#6b353a',2)
    for i in range(6):
        x=458+i*22; s.circle(x,622,3,'#ffdc93')
    # red demon shoulders and robust arms
    s.path('M408 413 C361 411 343 446 353 488 L388 518 L423 488 L421 452 Z','url(#b14body)','#70353a',4)
    s.path('M615 412 C663 411 683 449 670 489 L637 520 L604 489 L602 452 Z','url(#b14body)','#70353a',4)
    # head, swept horns and thick brows
    s.path('M424 293 L412 246 L449 260 L468 225 L500 250 L524 250 L555 225 L576 261 L612 246 L598 303 L582 350 Q550 383 512 383 Q474 381 443 350 Z','url(#b14body)','#6b3338',4)
    s.path('M456 261 L436 193 Q477 209 487 250 Z','#f0d4a0','#6f3d39',3)
    s.path('M543 250 Q558 208 599 193 L577 269 Z','#f0d4a0','#6f3d39',3)
    s.path('M449 300 Q470 278 493 301 L480 317 Z','#2b2938'); s.path('M531 301 Q553 277 575 300 L543 318 Z','#2b2938')
    s.ellipse(474,300,5,7,'#ffdb79'); s.ellipse(554,300,5,7,'#ffdb79')
    s.path('M475 340 Q512 364 549 340 Q538 375 512 376 Q486 374 475 340 Z','#522a36')
    for x in [489,504,519,534]: s.poly([(x,353),(x+5,367),(x+9,352)],'#f5e1b8')
    # head scarf and hanging paper shop tags
    s.path('M432 269 Q512 240 592 270 L584 291 Q512 272 440 293 Z','#eac88e','#6c3a38',3)
    s.path('M480 259 L496 231 L512 259 L527 231 L544 261','none',stroke='#c25146',sw=5)
    s.path('M380 485 L414 492 L405 555 L371 548 Z','#e4c79a','#723e3b',2)
    for y in [502,516,530,542]: s.line(378,y,405,y+2,'#9c7452',1.5)
    # raised tray of festival wares and little bottles
    s.path('M610 491 L699 473 L731 500 L640 525 Z','#6c4a36','#f2cc87',3)
    s.path('M632 485 Q621 456 643 447 Q662 457 653 484 Z','#d3aa68','#5d4539',2)
    s.path('M660 480 Q650 446 676 437 Q696 454 685 476 Z','#b85049','#5d4539',2)
    s.path('M687 492 Q680 466 700 460 Q720 469 710 497 Z','#789c9b','#43515a',2)
    for x,y in [(642,459),(674,450),(700,470)]: s.circle(x,y,3,'#fff0b8')
    # apron pocket with coin and blossom crest
    s.path('M468 517 Q512 500 556 517 L551 580 Q512 598 473 580 Z','#e0c59a','#7a4741',2)
    s.circle(512,546,17,'url(#b14metal)',stroke='#81503b',sw=2)
    blossom(s,512,545,.52,'#f1c7cc','#ffe6a0')
    for i in range(5): s.path(f'M{487+i*12} 581 q7 7 0 13','none',stroke='#e9cd96',sw=1.8)

def boss_15(s):
    # Giant Tako: huge octopus, individually curled tentacles, patterned suction cups and sailor ornaments.
    boss_defs(s,('#fa9e80','#dd5c54','#8c3550','#4f83a1','#294a67','#ffd2b3'))
    # eight tentacles with distinct curls and layered undersides
    paths=[
      ('M433 585 C354 624 331 719 240 703 C174 690 181 626 233 615 C267 608 282 636 263 654','M421 599 C344 642 333 697 252 683','#e56b65'),
      ('M460 606 C395 690 442 771 365 788 C306 801 275 755 311 724 C335 703 365 720 356 741','M447 621 C415 685 451 749 376 765','#d86b63'),
      ('M489 622 C481 697 527 751 484 791 C452 821 414 795 433 765 C446 745 470 755 467 770','M500 634 C502 693 534 737 497 770','#f08a76'),
      ('M535 618 C566 690 613 740 678 709 C730 685 701 629 664 638 C635 644 642 674 663 676','M546 629 C584 692 620 718 675 690','#df625e'),
      ('M574 600 C664 638 698 698 771 662 C826 633 801 578 762 586 C731 591 736 621 758 624','M584 611 C671 650 710 675 768 644','#f08d79'),
      ('M603 574 C706 586 762 627 821 571 C867 527 824 487 792 507 C767 524 784 547 802 540','M617 583 C709 605 761 615 813 557','#d65c5b'),
      ('M610 549 C696 528 736 470 705 425 C678 388 637 409 649 437 C657 456 681 451 684 436','M621 558 C697 535 722 482 690 441','#f28b77'),
      ('M413 557 C344 520 313 457 348 416 C380 379 423 402 407 428 C395 449 374 440 375 423','M422 550 C356 509 333 463 364 430','#d9625e')]
    for outer,inner,col in paths:
        s.path(outer,'none',stroke='#6f3851',sw=56)
        s.path(outer,'none',stroke=col,sw=48)
        s.path(inner,'none',stroke='#ffc3a7',sw=7,opacity=.7)
    # mantle with distinct ridges and speckled skin
    s.path('M382 402 C365 348 395 276 462 252 C498 224 545 228 580 253 C651 292 671 355 642 418 L615 477 L411 477 Z','url(#b15body)','#7f3f51',4)
    s.path('M411 390 Q429 315 484 302 Q521 287 558 306 Q611 331 620 394 L599 443 L426 443 Z','url(#b15light)',opacity=.7)
    for i in range(8):
        x=420+i*28; y=334+(i%3)*18
        s.circle(x,y,3.2,['#ffd9ad','#b74753','#f9c1a6'][i%3],opacity=.86)
    # brow ridge, two large eyes and beak
    s.path('M425 364 Q458 326 490 359 L482 394 Z','#30334b'); s.path('M533 359 Q566 326 599 364 L543 394 Z','#30334b')
    s.ellipse(461,367,16,21,'#f5d8bc'); s.ellipse(564,367,16,21,'#f5d8bc'); s.ellipse(465,367,7,12,'#29364c'); s.ellipse(568,367,7,12,'#29364c')
    s.circle(463,360,3.5,'#fff6dc'); s.circle(566,360,3.5,'#fff6dc')
    s.path('M489 406 Q511 389 536 406 L512 431 Z','#6c3949','#f0a58d',2)
    # suction cups down each limb, curved by their distinct paths
    for base_x,base_y,count,dx in [(239,658,4,7),(331,752,4,5),(453,770,3,4),(670,677,4,8),(770,627,4,6),(810,546,4,-4),(677,438,3,-7),(383,432,3,-6)]:
        for i in range(count):
            x=base_x+i*dx; y=base_y-i*16
            s.ellipse(x,y,7,5,'#f9c9a6',stroke='#a94d57',sw=1.2)
            s.ellipse(x,y,2.3,1.6,'#a94d57')
    # sailor bandana and gold sea charm
    s.path('M426 290 Q512 259 602 291 L593 312 Q512 283 435 313 Z','#31516b','#e5c48c',3)
    s.path('M579 300 L614 318 L595 356 L568 335 Z','#d9bd82','#5d4750',2)
    s.circle(592,329,8,'#e4cc91',stroke='#664c43',sw=2)
    s.path('M586 328 Q592 317 598 328 Q596 338 592 340 Q588 338 586 328 Z','#52849a')
    # little sea-glass barnacles along the mantle edge
    for x,y in [(402,421),(425,440),(449,449),(594,447),(621,424),(640,402)]:
        s.path(f'M{x-6} {y+7} Q{x-7} {y-4} {x} {y-12} Q{x+7} {y-4} {x+6} {y+7} Z','#b4d5c7','#577d88',1.2)

def boss_16(s):
    # Magma Ryu: predatory basalt dragon with ember fissures, curled horns and flame mane.
    boss_defs(s,('#ffcf7b','#d45d39','#632d37','#c24432','#542b35','#ff8d40'))
    # coiling dragon body
    s.path('M347 677 C259 631 286 551 377 541 C454 533 489 589 552 574 C616 558 603 494 561 467 C513 433 471 458 439 423 C401 382 435 333 493 332 C550 331 582 362 608 393','none',stroke='#321f2b',sw=95)
    s.path('M347 677 C259 631 286 551 377 541 C454 533 489 589 552 574 C616 558 603 494 561 467 C513 433 471 458 439 423 C401 382 435 333 493 332 C550 331 582 362 608 393','none',stroke='url(#b16body)',sw=83)
    # bright lava seams in the body
    line_detail(s,['M325 646 C296 615 322 574 372 572 C423 569 457 615 507 610','M459 430 C432 405 450 373 481 371 C522 368 547 391 565 416','M536 475 C576 489 585 525 562 550','M369 573 l-13 28 20 17 -5 25'], '#ff9c40',5,.96)
    # claws and forelegs
    s.path('M428 571 L395 641 L424 687 L463 658 L476 600 Z','url(#b16body)','#321f2b',4)
    s.path('M556 567 L571 641 L610 662 L638 624 L601 566 Z','url(#b16body)','#321f2b',4)
    for x,y in [(425,676),(610,654)]:
        s.path(f'M{x-21} {y-5} L{x+18} {y-10} L{x+31} {y+11} L{x-17} {y+20} Z','#302732','#b45339',3)
        for j in range(3): s.path(f'M{x+5+j*8} {y+11} l7 13','none',stroke='#f3a45b',sw=3)
    # wing structures with flame-shaped membranes
    s.path('M469 424 C411 388 353 321 363 250 C405 282 440 297 466 330 C454 278 477 225 522 207 C548 272 543 327 526 374 Z','url(#b16cloth)','#4c2632',4)
    s.path('M558 427 C616 391 676 324 666 252 C624 281 591 299 562 332 C575 278 552 226 508 207 C483 271 487 329 503 375 Z','url(#b16cloth)','#4c2632',4)
    for d in ['M388 271 Q429 319 470 390','M512 230 Q517 309 510 376','M641 271 Q600 319 559 390','M523 231 Q520 309 530 376']:
        s.path(d,'none',stroke='#ffb34d',sw=4,opacity=.72)
    # neck and horned head, obsidian plates and glowing eyes
    s.path('M541 395 C560 352 565 306 591 279 L640 265 L674 297 L704 301 L716 335 L697 374 L661 398 L629 432 Z','url(#b16body)','#311f2b',4)
    s.path('M591 292 L575 221 L622 265 Z','#35262f','#be5c3a',3); s.path('M660 271 L699 217 L684 301 Z','#35262f','#be5c3a',3)
    s.path('M599 323 Q622 301 641 322 L623 342 Z','#181f31'); s.path('M652 319 Q676 297 694 321 L661 342 Z','#181f31')
    s.ellipse(622,321,6,8,'#ffbe4f'); s.ellipse(676,318,6,8,'#ffbe4f')
    s.path('M621 356 Q655 378 686 353 L675 379 Q652 396 634 378 Z','#542634')
    for x in [634,650,666,679]: s.poly([(x,366),(x+5,381),(x+10,366)],'#f7d7a1','#6d3233',1)
    # obsidian back spikes and cheek horns
    for i in range(7):
        x=525+i*22; y=409-(i%2)*9
        s.path(f'M{x} {y+20} L{x+8} {y-24} L{x+18} {y+8} Z','#252532','#75433c',2)
    s.path('M611 365 L586 393 L619 389 M682 366 L711 392 L689 395','none',stroke='#f7a04a',sw=4)
    # ember scale plates along the neck and shoulders
    for row in range(3):
        for col in range(5):
            x=584+col*19; y=386+row*15
            s.path(f'M{x-8} {y-3} Q{x} {y-13} {x+8} {y-3} L{x+6} {y+5} L{x-6} {y+5} Z',['#a94335','#d86a3d','#452b34'][row], '#2d2731',1)
            s.path(f'M{x-4} {y-3} L{x+2} {y-5}','none',stroke='#ffc157',sw=1.4)

def boss_17(s):
    # Tokei Karakuri: ornate clockwork guardian with articulated bronze limbs and visible gears.
    boss_defs(s,('#e9ce8e','#b1844f','#665044','#416b88','#243a59','#ffdf8b'))
    # articulated legs with visible pistons and layered boots
    s.path('M432 602 L414 692 L449 724 L482 701 L480 624 Z','url(#b17metal)','#4d4037',4)
    s.path('M542 624 L540 702 L579 724 L611 686 L586 604 Z','url(#b17metal)','#4d4037',4)
    s.path('M408 700 L462 701 L478 748 L402 751 Z','#405a71','#d2b377',3)
    s.path('M538 701 L590 698 L617 744 L547 751 Z','#405a71','#d2b377',3)
    for x,y in [(433,667),(566,669)]:
        s.line(x,y-35,x+7,y+34,'#dfbb74',6); s.circle(x,y,14,'#31475b',stroke='#f1d491',sw=3); s.circle(x,y,5,'#e9c97e')
    # torso casing and shoulder collars
    s.path('M400 363 L448 325 L576 325 L624 363 L604 571 L569 608 L455 608 L418 570 Z','url(#b17metal)','#51413a',5)
    s.path('M434 367 L471 351 L553 351 L590 367 L579 549 L552 576 L472 576 L445 548 Z','#2c4860','#ba995e',3)
    # chest dial, ring gears and escapement
    s.circle(512,454,79,'url(#b17metal)',stroke='#4d4039',sw=5); s.circle(512,454,63,'#243d59',stroke='#e5c77f',sw=4)
    s.circle(512,454,49,'none',stroke='#c0a36d',sw=2)
    for i in range(12):
        a=i*30*3.14159265/180-1.5707963; x=512+math_cos(i*30)*42; y=454+math_sin(i*30)*42
        s.circle(x,y,3.6,'#f6dfa0')
    s.line(512,454,512,421,'#ffe3a0',4); s.line(512,454,540,464,'#ffe3a0',3); s.circle(512,454,7,'#d9b66e',stroke='#453b38',sw=2)
    # small side gears nested at the collar
    for cx,cy,r in [(457,389,20),(567,389,20),(468,526,17),(557,527,18)]:
        s.circle(cx,cy,r,'#8b754f',stroke='#e7cc8b',sw=2.5); s.circle(cx,cy,r*.45,'#314860',stroke='#d9bd7b',sw=2)
        for i in range(6):
            x=cx+math_cos(i*60)*(r+4); y=cy+math_sin(i*60)*(r+4)
            s.circle(x,y,2.7,'#e9d191')
    # long hinged arms with cuff plates and articulated hands
    s.path('M414 375 L366 398 L339 465 L371 493 L412 463 L442 414 Z','url(#b17metal)','#514139',4)
    s.path('M610 375 L659 398 L687 465 L654 493 L614 463 L584 414 Z','url(#b17metal)','#514139',4)
    for x,y,flip in [(366,455,-1),(660,455,1)]:
        s.circle(x,y,18,'#314b60',stroke='#e6c47f',sw=4); s.circle(x,y,7,'#d8b16c')
        s.path(f'M{x-22} {y+22} L{x+24} {y+22} L{x+27} {y+47} L{x-23} {y+47} Z','#a97d4a','#4b3d36',3)
        for j in range(4): s.line(x-14+j*9,y+25,x-14+j*9,y+42,'#f2d38c',2)
    # head is a compact brass helm beneath a gear halo
    s.path('M448 281 L452 234 L480 210 L546 210 L572 234 L576 281 L557 318 L512 332 L467 318 Z','url(#b17metal)','#4d4037',4)
    s.path('M470 247 L488 230 L536 230 L554 247 L547 276 L512 289 L477 276 Z','#29465e','#e5c584',3)
    s.path('M482 253 L499 245 L505 264 L489 269 Z','#f3d98d'); s.path('M519 264 L525 245 L542 253 L535 269 Z','#f3d98d')
    s.circle(494,257,4,'#253147'); s.circle(530,257,4,'#253147')
    s.path('M494 286 L512 296 L530 286','none',stroke='#d9bb7a',sw=3)
    # decorative crest gears and pendulum ornaments
    s.circle(512,207,28,'#354e64',stroke='#f0d18b',sw=4); s.circle(512,207,14,'#bb8e4e',stroke='#f6d88c',sw=2)
    for i in range(8):
        x=512+math_cos(i*45)*34; y=207+math_sin(i*45)*34
        s.circle(x,y,4,'#d9b66e')
    s.path('M587 467 L630 490 L619 551 L581 533 Z','#7d98a6','#34485a',2)
    s.circle(606,510,8,'#d9b66e',stroke='#4c413a',sw=2)
    s.path('M606 518 L606 585','none',stroke='#c2a26b',sw=3); s.path('M595 585 L606 607 L617 585 Z','#d9b66e','#53473c',2)
    # engraving strokes and rivets make the plates feel manufactured
    line_detail(s,['M432 370 L446 394','M592 369 L578 394','M445 559 Q512 580 578 558','M454 600 L570 600','M468 332 L480 314','M557 332 L545 314'], '#f3d69a',2,.82)
    for x,y in [(430,383),(593,383),(438,550),(585,550),(455,580),(568,580)]: s.circle(x,y,4,'#e7c780',stroke='#5c4737',sw=1)

BOSS_FUNCS=[boss_01,boss_02,boss_03,boss_04,boss_05,boss_06,boss_07,boss_08,boss_09,boss_10,boss_11,boss_12,boss_13,boss_14,boss_15,boss_16,boss_17]

# Boss art palettes are local to each unique character anatomy.

# Subject-specific finish strokes: fur, ceramic glaze, fabric, bark, metalwork and scales.
def boss_detail_01(s):
    for d in ['M402 474 Q427 487 448 478','M423 495 Q448 510 470 495','M554 495 Q578 510 601 493','M574 473 Q593 484 615 473','M451 532 Q470 541 485 531','M541 531 Q558 542 576 531']:
        s.path(d,'none',stroke='#f8fff0',sw=2.1,opacity=.84)
    for x,y in [(353,436),(373,451),(388,462),(627,445),(646,459),(665,473),(462,602),(488,615),(538,616),(562,600)]:
        s.path(f'M{x},{y} q-7,10 -2,17', 'none',stroke='#9adbd9',sw=2,opacity=.82)
    for cx,cy in [(270,488),(750,488),(320,559),(700,562)]:
        s.ellipse(cx,cy,24,7,'none',stroke='#effff1',sw=1.7,opacity=.65)
        s.ellipse(cx,cy,38,11,'none',stroke='#a0e4de',sw=1.2,opacity=.42)

def boss_detail_02(s):
    # Grain follows the bars; chipped corners and tool marks on the abacus housing.
    for x in [367,389,645,664]:
        for j in range(4): s.path(f'M{x},{334+j*55} q-5,15 1,28', 'none',stroke='#d8b17d',sw=1.8,opacity=.75)
    for y in [365,405,445,485,525]:
        s.path(f'M396,{y} q14,-4 25,0 M608,{y+7} q9,-4 17,0', 'none',stroke='#e5c38e',sw=1.7,opacity=.72)
    for x,y in [(386,309),(638,309),(386,588),(638,588)]:
        s.path(f'M{x-8},{y-4} l5,-5 8,2 3,8 -8,4 Z','none',stroke='#e5ba7f',sw=1.5)
    for x,y in [(415,401),(455,438),(525,476),(590,515),(435,547),(569,386)]:
        s.ellipse(x,y,3,2,'#f5dbab',opacity=.9)

def boss_detail_03(s):
    # Fine fur streaks, coat stitching and travel-kasa weave.
    for x,y in [(447,344),(462,352),(477,358),(548,356),(565,348),(580,338),(432,329),(590,326)]:
        s.path(f'M{x},{y} q7,7 5,15','none',stroke='#f0d7b5',sw=2,opacity=.8)
    for i in range(8):
        x=432+i*22; s.path(f'M{x} 574 q6 8 1 17','none',stroke='#efd49b',sw=2,opacity=.82)
    for i in range(11):
        x=392+i*22; s.path(f'M{x} 230 q26,-7 44,0','none',stroke='#efdbac',sw=1.5,opacity=.72)
    for x,y in [(424,469),(439,488),(585,474),(570,493)]:
        s.circle(x,y,3,'#f8e4bd',opacity=.9)
    s.path('M448 548 Q512 572 577 548 M453 565 Q512 586 572 565','none',stroke='#f0d2a0',sw=1.7,opacity=.72)

def boss_detail_04(s):
    # Tail brush strokes, uniform brocade, ticket edges and polished badge marks.
    for d in ['M335 508 Q362 485 391 504','M382 433 Q404 411 427 430','M464 390 Q478 403 489 419','M542 417 Q555 399 569 389','M650 504 Q686 486 706 506','M687 557 Q716 554 728 572']:
        s.path(d,'none',stroke='#fff0c6',sw=3,opacity=.72)
    for i in range(9):
        x=431+i*19; s.path(f'M{x} 568 q5 7 0 14','none',stroke='#cfb47b',sw=1.5,opacity=.8)
    for x,y in [(605,473),(611,489),(601,496)]: s.circle(x,y,2.3,'#fff0c3')
    s.path('M455 432 Q511 467 568 432','none',stroke='#f4d99c',sw=2,opacity=.8)

def boss_detail_05(s):
    # Distinct straw strands and paper fibers, with ink blots on the scrolls.
    for i in range(17):
        x=365+i*18; y=245+(i%4)*6
        s.path(f'M{x},{y} q-7,10 -9,22','none',stroke=['#f5dfa7','#997141','#d7b778'][i%3],sw=1.6,opacity=.82)
    for x,y in [(366,500),(653,498)]:
        for j in range(5): s.path(f'M{x-13+j*5},{y+8} q4,8 1,18','none',stroke='#c7b285',sw=1.2,opacity=.8)
    for x,y in [(464,300),(478,326),(550,326),(561,300)]:
        s.path(f'M{x},{y} q5,2 5,8','none',stroke='#f4dea3',sw=1.8,opacity=.8)
    for i in range(10):
        x=428+i*18; s.path(f'M{x} 605 l3 6 -1 5','none',stroke='#d9bc81',sw=1.5,opacity=.8)

def boss_detail_06(s):
    # Ceramic glaze lines, gold leaf flecks and brush-painted daruma scrollwork.
    for i in range(15):
        x=407+(i*31)%204; y=377+(i*47)%220
        s.path(f'M{x},{y} q7,-4 9,2', 'none',stroke='#ffd796',sw=1.7,opacity=.74)
    for d in ['M420 435 Q450 453 478 435','M541 435 Q570 453 601 432','M430 503 Q463 521 490 505','M535 507 Q567 519 591 502']:
        s.path(d,'none',stroke='#7f2e3a',sw=2.3,opacity=.82)
    for i in range(11):
        x=411+i*19; s.circle(x,610+(i%2)*8,2.2,'#f9db93',opacity=.9)
    s.path('M470 386 Q508 368 546 386','none',stroke='#ffdf96',sw=2,opacity=.8)

def boss_detail_07(s):
    # Canopy seam stitching, lacquer grain, rain-gloss along ribs and cheek crease.
    for i in range(10):
        x=223+i*61; y=360+abs(511-x)*.12
        s.path(f'M{x},{y} q8,3 12,1','none',stroke='#ffd3ad',sw=1.7,opacity=.8)
    for d in ['M510 214 Q494 283 490 342','M510 214 Q527 282 536 343','M510 214 Q454 282 443 352','M510 214 Q565 281 581 350']:
        s.path(d,'none',stroke='#f4cfb2',sw=2,opacity=.72)
    for x,y in [(302,406),(370,398),(649,402),(728,407),(775,392)]:
        s.path(f'M{x},{y} q-4,11 0,18', 'none',stroke='#f7c5b3',sw=1.8,opacity=.8)
    for i in range(6): s.path(f'M{469+i*15} 347 q4 4 7 0','none',stroke='#b86c73',sw=1.7,opacity=.8)

def boss_detail_08(s):
    # Scales curve with the dragon's body; face whiskers get fine barb strokes.
    for row in range(6):
        for col in range(9):
            x=302+col*27+(row%2)*10; y=584+row*18
            if x<493 and y<676:
                s.path(f'M{x-10},{y} Q{x},{y-12} {x+10},{y} Q{x+4},{y+10} {x-6},{y+7} Z',['#5fc1c1','#398fa8','#b2e6d5'][row%3],'#225a79',1.1,opacity=.92)
    for d in ['M650 345 q26,-4 37,7','M651 354 q24,0 36,10','M597 355 q-12,17 -9,29','M707 345 q12,10 17,20']:
        s.path(d,'none',stroke='#fff0c6',sw=2,opacity=.9)
    for x,y in [(614,293),(641,292),(676,303),(700,317),(699,345)]: s.circle(x,y,2.4,'#e0f3d9',opacity=.9)

def boss_detail_09(s):
    # Petal veins, silk folds and tiny flower knots in the mantle.
    for d in ['M416 521 Q432 565 402 608','M448 515 Q462 573 450 626','M477 517 Q489 574 486 637','M540 518 Q538 581 558 640','M571 510 Q589 570 621 608','M603 510 Q623 545 637 579']:
        s.path(d,'none',stroke='#f5d3df',sw=2,opacity=.78)
    for x,y in [(453,467),(478,478),(546,479),(571,466),(481,544),(546,551)]: blossom(s,x,y,.24,'#f8d2dd','#fff0c0')
    for i in range(9):
        x=459+i*12; s.path(f'M{x} 630 q4 5 0 10','none',stroke='#f4d8a4',sw=1.4,opacity=.85)

def boss_detail_10(s):
    # Hammered metal facets, rivet rows, etched armor borders and molten glints.
    for x,y in [(425,413),(443,405),(461,400),(559,400),(578,406),(598,416),(430,550),(449,570),(574,568),(594,549)]:
        s.circle(x,y,3,'#fff0b6',opacity=.92)
    for d in ['M451 421 L480 408 L500 418','M527 417 L548 408 L574 424','M445 477 Q512 516 578 476','M438 540 Q512 566 584 540','M460 585 Q512 602 562 584']:
        s.path(d,'none',stroke='#f9e0a0',sw=2.4,opacity=.9)
    for i in range(6):
        x=395+i*28; y=627+(i%2)*11
        s.path(f'M{x},{y} q8,-4 14,0','none',stroke='#dfb969',sw=2,opacity=.85)

def boss_detail_11(s):
    # Bark fibers, moss curls and small leaf veins reinforce the tree-like form.
    for d in ['M438 416 Q448 443 441 469 T451 518','M465 377 Q479 410 467 435 T478 480','M576 420 Q565 456 576 490 T565 548','M548 362 Q536 385 545 411','M432 556 Q451 581 445 601','M591 553 Q573 578 584 602']:
        s.path(d,'none',stroke='#a8b792',sw=2.4,opacity=.75)
    for x,y in [(435,459),(455,486),(571,472),(580,521),(457,566),(566,578),(493,610),(534,608)]:
        s.path(f'M{x-7},{y} q7,-11 14,0 q-6,8 -14,0 Z','#8dbd84',opacity=.88)
    for i in range(7):
        x=472+i*12; s.path(f'M{x} 340 q-3 8 2 15','none',stroke='#8b9e77',sw=1.7,opacity=.8)

def boss_detail_12(s):
    # feather barbs, fur spots and fine scale accents on the chimera's tail.
    for i in range(7):
        x=338+i*20; y=301+i*10
        s.path(f'M{x},{y} Q{x+11},{y+22} {x+34},{y+42}','none',stroke='#e7d8bd',sw=1.8,opacity=.8)
    for i in range(13):
        x=393+(i*37)%198; y=458+(i*29)%130
        s.ellipse(x,y,3.5,2.8,'#5c4b49',opacity=.85)
    for d in ['M728 569 Q751 582 757 602','M747 560 Q771 570 780 590','M758 556 Q783 564 793 579']:
        s.path(d,'none',stroke='#efd3a5',sw=2,opacity=.8)
    for x,y in [(437,318),(460,295),(486,332),(553,331),(581,318)]:
        s.path(f'M{x},{y} q5,4 2,9','none',stroke='#e6cfa6',sw=1.7,opacity=.85)

def boss_detail_13(s):
    # fur tufts, celestial-thread embroidery and silver hem borders.
    for x,y in [(454,245),(469,231),(483,222),(542,222),(558,232),(572,247),(451,330),(463,345),(560,337),(573,325)]:
        s.path(f'M{x},{y} l-4,8 5,-3','none',stroke='#fffaf2',sw=2.1,opacity=.88)
    for d in ['M436 525 Q462 555 451 589','M461 547 Q477 576 467 608','M563 549 Q551 580 565 611','M587 522 Q574 550 591 581']:
        s.path(d,'none',stroke='#b9cfe7',sw=2,opacity=.9)
    for x,y in [(475,410),(548,410),(462,565),(562,566),(491,603),(530,606)]:
        s.path(f'M{x} {y-6} l3 5 6 1 -4 4 1 6 -6 -3 -5 3 1 -6 -4 -4 6 -1 Z','#fff0c8',opacity=.85)

def boss_detail_14(s):
    # Textile weave, shoulder seam, festive embroidery and glossy horn striations.
    for i in range(7):
        x=432+i*23; s.path(f'M{x} 505 q5 7 1 13','none',stroke='#f2cc98',sw=1.6,opacity=.84)
    for x,y in [(443,283),(455,267),(466,259),(557,260),(570,270),(583,284)]:
        s.path(f'M{x},{y} l-5,-12','none',stroke='#ffe1b5',sw=2,opacity=.8)
    for d in ['M432 437 Q512 453 592 437','M430 592 Q512 622 596 592','M445 474 L456 505','M579 475 L568 505']:
        s.path(d,'none',stroke='#ffe0a6',sw=2,opacity=.82)
    for x,y in [(642,478),(658,473),(676,470),(694,481)]: s.circle(x,y,2.5,'#fff0b6',opacity=.9)

def boss_detail_15(s):
    # sucker rims with inner shadows, mantle freckles and flowing skin folds.
    for bx,by,count,dx in [(239,658,4,7),(331,752,4,5),(453,770,3,4),(670,677,4,8),(770,627,4,6),(810,546,4,-4),(677,438,3,-7),(383,432,3,-6)]:
        for i in range(count):
            x=bx+i*dx; y=by-i*16
            s.ellipse(x,y,4.8,3,'#d76b63',opacity=.9)
            s.ellipse(x,y,2.0,1.5,'#784153',opacity=.85)
    for i in range(16):
        x=413+(i*23)%195; y=284+(i*31)%112
        s.circle(x,y,1.8,'#fff0cc',opacity=.7)
    for d in ['M401 392 Q417 409 414 431','M431 418 Q449 438 445 451','M602 419 Q586 438 590 455','M628 392 Q618 410 622 429']:
        s.path(d,'none',stroke='#f7baa0',sw=2,opacity=.8)

def boss_detail_16(s):
    # Obsidian plate etching, molten seams and ember whiskers.
    for row in range(3):
        for col in range(7):
            x=530+col*21; y=409+row*20
            s.path(f'M{x-7},{y} Q{x},{y-10} {x+7},{y} L{x+4},{y+7} L{x-5},{y+7} Z','#5f3b3a','#2a2832',1,opacity=.9)
            s.path(f'M{x-3},{y-2} L{x+3},{y-4}','none',stroke='#ffb653',sw=1.5,opacity=.9)
    for d in ['M600 320 Q619 337 636 326','M653 322 Q672 336 691 319','M615 355 Q632 360 641 355','M663 357 Q678 364 689 355']:
        s.path(d,'none',stroke='#ffb457',sw=2.5,opacity=.9)
    for i in range(11):
        x=418+i*20; y=585+(i%4)*19
        s.path(f'M{x},{y} l5,-6 4,2','none',stroke='#e37b3d',sw=1.7,opacity=.8)

def boss_detail_17(s):
    # Screw slots, engraved dial marks, plate bevels and pin joints.
    for cx,cy,r in [(512,454,63),(457,389,20),(567,389,20),(468,526,17),(557,527,18),(512,207,28)]:
        for i in range(12):
            import math
            a=math.pi*2*i/12
            x=cx+math.cos(a)*(r*.83); y=cy+math.sin(a)*(r*.83)
            s.path(f'M{x-1.6},{y-1.6} l3.2,3.2','none',stroke='#f5df9f',sw=1.4,opacity=.86)
    for d in ['M432 367 L448 356','M592 367 L576 356','M449 552 Q512 567 575 551','M450 580 L477 592','M574 580 L547 592']:
        s.path(d,'none',stroke='#f5d89b',sw=2,opacity=.85)
    for x,y in [(480,386),(544,386),(486,514),(538,514),(455,600),(569,600)]:
        s.circle(x,y,3,'#fff0b7',opacity=.9)

BOSS_DETAILS=[boss_detail_01,boss_detail_02,boss_detail_03,boss_detail_04,boss_detail_05,boss_detail_06,boss_detail_07,boss_detail_08,boss_detail_09,boss_detail_10,boss_detail_11,boss_detail_12,boss_detail_13,boss_detail_14,boss_detail_15,boss_detail_16,boss_detail_17]

BOSS_PALETTES=[
 ('#f1f8ee','#aadbd9','#548d9a','#c5dce0','#9b9dc0','#a4f0e5'),
 ('#e4c28a','#b17a4d','#604031','#78918a','#324a52','#f5c16b'),
 ('#dbac7c','#a96d48','#68433b','#c66e59','#683a4b','#ffd49a'),
 ('#f0d1a9','#c58b60','#764b43','#526e89','#253951','#ffda8b'),
 ('#e6cc8e','#b38a53','#67503e','#bda16b','#654c3a','#ffd98b'),
 ('#ffb18a','#df5d49','#8e3441','#e65b48','#8d303a','#ffcb73'),
 ('#e6b2b4','#bb6671','#6c3f5c','#667ea3','#303354','#ffc5ab'),
 ('#a5e7da','#4eafbc','#245c7b','#edb5a1','#973f67','#73f1e4'),
 ('#f9e0e2','#e6a4c0','#a65b88','#e65f93','#8d3d70','#ffd5e8'),
 ('#ffdf8f','#dbad49','#855126','#c75136','#6a3034','#ffca55'),
 ('#bacd9f','#789a78','#355850','#718b64','#31524c','#b6f5c3'),
 ('#e4c99a','#ab7b63','#574a51','#8291a1','#3f4258','#f4c07d'),
 ('#ffffff','#cbdcf0','#7185a5','#8c9ac9','#3d4f79','#deebff'),
 ('#ffc19c','#df7157','#7b3840','#dd6451','#813849','#ffd58b'),
 ('#ffb19a','#e26761','#8c3c54','#6593af','#294d69','#ffd4b6'),
 ('#ffcf8a','#db6742','#74303a','#ce4c35','#552b37','#ff9d47'),
 ('#f7e0a3','#c49a60','#705442','#527997','#263c59','#ffdf8b'),
]

REGION_NAMES=['Echo Village','Counting Creek','Greeting Bridge','Crossroads Station','Hiragana Plains','Topic Terraces','Umbrella Lane','Koi Pond Hills','Sakura Hill','Treasure Peak','Kodama Grove','Maple Memory Trail','Moonlit Garden','Festival Street','Counter Cove','Verb Volcano','Time Temple']
BOSS_NAMES=['Yamabiko','Soroban Golem','Tanuki Gatekeeper','Kitsune Stationmaster','Kakashi Scribe','Daruma of Wa','Karakasa Collector','Nishikigoi Dragon','Konohana Spirit','Gold Oni','Kodama Elder','Nue of Yesterday','Tsuki Usagi','Oni Shopkeeper','Giant Tako','Magma Ryu','Tokei Karakuri']

def generate():
    # Region artwork is generated by a separate portrait-native art director.
    # It emits transparent 720x1280 vignettes which Flutter composes over one
    # continuous terrain canvas; it never writes full-bleed landscape map cards.
    from generate_vertical_regions import generate as generate_vertical_regions
    generate_vertical_regions()

    # Preserve the original 16:9 compositions as combat-arena backdrops. These
    # are used only by battle screens; the map now uses the portrait region art.
    ARENAS.mkdir(parents=True,exist_ok=True)
    for i,(func,detail,p) in enumerate(zip(REGION_FUNCS,REGION_DETAILS,PALETTES),1):
        s=SVG(f'a{i:02d}')
        s.defs(p)
        s.add('<g clip-path="url(#a%02dframe)">' % i)
        func(s,p)
        detail(s)
        if i not in (7,11,16):
            for j in range(15):
                x=(j*173+i*43)%1260+10; y=(j*79+i*31)%360+55
                col = '#fff2d3' if i not in (12,13) else ('#e7bdcb' if i==12 else '#c3d9ef')
                s.circle(x,y,1.5+(j%3)*.5,col,opacity=.35+(j%4)*.08)
        s.add('</g>')
        (ARENAS/f'{i:02d}.svg').write_text(s.finish_region(),encoding='utf-8')

    BOSSES.mkdir(parents=True,exist_ok=True)
    for i,(func,detail,colors) in enumerate(zip(BOSS_FUNCS,BOSS_DETAILS,BOSS_PALETTES),1):
        s=SVG(f'b{i:02d}',1024,1024); boss_defs(s,colors)
        # A low-opacity shadow pad is local to the character canvas; the rest remains transparent.
        s.ellipse(512,816,218,23,'#0c1e30',opacity=.15)
        func(s)
        detail(s)
        path=BOSSES/f'{i:02d}.svg'; path.write_text(s.finish_boss(),encoding='utf-8')

    # Validate that every artifact is self-contained vector XML with no image
    # elements or external resources, and that region artwork is portrait-native.
    for path in sorted(list(REGIONS.glob('*.svg'))+list(ARENAS.glob('*.svg'))+list(BOSSES.glob('*.svg'))):
        data=path.read_text(encoding='utf-8')
        root=ET.fromstring(data)
        assert root.tag.endswith('svg'), path
        assert not any(el.tag.endswith('image') for el in root.iter()), f'raster/image node in {path}'
        assert 'http://' not in data.replace('http://www.w3.org/2000/svg',''), f'external URL in {path}'
        if path.parent == REGIONS:
            assert root.attrib.get('viewBox') == '0 0 720 1280', f'region is not portrait-native: {path}'
            assert path.stat().st_size > 5000, f'Artwork unexpectedly small: {path}'
        elif path.parent == ARENAS:
            assert root.attrib.get('viewBox') == '0 0 1280 720', f'arena should retain its landscape aspect ratio: {path}'
    assert len(list(REGIONS.glob('*.svg'))) == 17
    assert len(list(ARENAS.glob('*.svg'))) == 17
    assert len(list(BOSSES.glob('*.svg'))) == 17
    print(f'Generated {len(list(REGIONS.glob("*.svg")))} portrait region SVGs, {len(list(ARENAS.glob("*.svg")))} arena SVGs, and {len(list(BOSSES.glob("*.svg")))} boss SVGs.')
    for folder in (REGIONS,ARENAS,BOSSES):
        print(folder.relative_to(ROOT), 'total bytes:', sum(p.stat().st_size for p in folder.glob('*.svg')))

if __name__=='__main__': generate()
