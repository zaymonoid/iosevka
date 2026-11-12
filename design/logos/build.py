"""Generates the iosevka app-icon colourways (d*.svg) and preview-backgrounds.svg. Run: python3 build.py"""
HEAD = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">'
PAD = 0.9  # board scale about the centre; lower = more padding around the tiles
CS = (212, 512, 812)  # tile centres
WORD = [  # (column, row, glyph drawn as a stroke around the origin)
    (0, 0, '<path d="M-36 -70H36M0 -70V70M-36 70H36"/>'),
    (1, 0, '<ellipse rx="52" ry="70"/>'),
    (2, 0, '<path d="M48 -44C48 -84-50 -86-50 -38C-50 0 50 -2 50 38C50 86-48 84-50 44"/>'),
    (1, 1, '<path d="M46 -70H-44V70H46M-44 0H30"/>'),
    (0, 2, '<path d="M-52 -70 0 70 52 -70"/>'),
    (1, 2, '<path d="M-44 -70V70M48 -70-44 14M-10 -16 50 70"/>'),
    (2, 2, '<path d="M-54 70 0 -70 54 70M-33 22H33"/>'),
]
USED = {(c, r) for c, r, _ in WORD}
TRAIL = "M212 212H812L212 812H812"

def grad(i, a, b):
    return f'<linearGradient id="{i}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{a}"/><stop offset="1" stop-color="{b}"/></linearGradient>'

def board(p, bg, face, side, trail_top, trail_side, blank, blank_side, ink, ink_shadow, shadow):
    def tile(c, r):
        x, y = CS[c] - 136, CS[r] - 148
        on = (c, r) in USED
        f, s = (f"url(#{p}f)", f"url(#{p}s)") if on else (blank, blank_side)
        hi = f'<rect x="{x+5}" y="{y+5}" width="262" height="262" rx="59" fill="none" stroke="#FFFFFF" stroke-opacity=".28" stroke-width="5"/>' if on else ""
        return f'<rect x="{x}" y="{y+26}" width="272" height="272" rx="64" fill="{s}"/><rect x="{x}" y="{y}" width="272" height="272" rx="64" fill="{f}"/>{hi}'
    def letters(colour, dy):
        st = f'fill="none" stroke="{colour}" stroke-width="36" stroke-linecap="round" stroke-linejoin="round"'
        return "".join(f'<g transform="translate({CS[c]} {CS[r]-12+dy})" {st}>{g}</g>' for c, r, g in WORD)
    # The trail is a flat ribbon on the ground: over the empty tiles, under the lit ones. Width and offset
    # are chosen so the diagonal clears the neighbouring tiles' corners evenly on both sides.
    ribbon = f'<path d="{TRAIL}" transform="translate(0 6)" fill="none" stroke="{trail_top}" stroke-width="58" stroke-linecap="round" stroke-linejoin="round"/>'
    shadows = "".join(f'<rect x="{CS[c]-124}" y="{CS[r]-96}" width="248" height="272" rx="60"/>' for r in range(3) for c in range(3))
    return HEAD + f'''<defs>
<radialGradient id="{p}bg" cx=".5" cy=".3" r=".9"><stop offset="0" stop-color="{bg[0]}"/><stop offset="1" stop-color="{bg[1]}"/></radialGradient>
{grad(p+"f", *face)}{grad(p+"s", *side)}
<filter id="{p}b" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="22"/></filter>
</defs>
<rect width="1024" height="1024" fill="url(#{p}bg)"/>
<g transform="translate(512 518) scale({PAD}) translate(-512 -518)">
<g fill="{shadow[0]}" opacity="{shadow[1]}" filter="url(#{p}b)">{shadows}</g>
{"".join(tile(c, r) for r in range(3) for c in range(3) if (c, r) not in USED)}
{ribbon}
{"".join(tile(c, r) for r in range(3) for c in range(3) if (c, r) in USED)}
{letters(ink_shadow, 8) if ink_shadow else ""}{letters(ink, 0)}
</g></svg>
'''

BLUE, BLUE_SIDE = ("#6F89F8", "#3552D1"), ("#2A40B0", "#1F3090")
CREAM, CREAM_SIDE = ("#FFFFFF", "#F3EAD8"), ("#D8CCB2", "#B9AB8C")
V = {
    "d1-night": board("n", ("#262A4C", "#08090F"), ("#93A6FF", "#4D6BEB"), ("#3046C0", "#22339A"), "#5E79F2", "#22339A", "#2B2D3F", "#15161F", "#FFFFFF", "#2C44C4", ("#000000", .6)),
    "d2-blue": board("u", ("#6381F8", "#2030A0"), CREAM, CREAM_SIDE, "#FBF5E8", "#B9AB8C", "#5670E6", "#1F3090", "#3552D1", None, ("#0E1766", .55)),
    "d3-amber": board("y", ("#FFD966", "#F59A0B"), BLUE, BLUE_SIDE, "#3F5BDB", "#1F3090", "#FFF6DC", "#D99A1C", "#FFFFFF", "#2640B8", ("#9A5A00", .45)),
    "d4-coral": board("c", ("#FF8F70", "#E5412B"), CREAM, CREAM_SIDE, "#FBF5E8", "#B9AB8C", "#F98D75", "#B5301E", "#1F1D1A", None, ("#7A1A0E", .45)),
}
for n, s in V.items():
    open(f"{n}.svg", "w").write(s)

# Preview: large, then true 60 pt size on a light and a dark wallpaper
inner = lambda s: s.split(">", 1)[1].rsplit("</svg>", 1)[0]
out, k = ['<rect width="1200" height="740" fill="#FFFFFF"/>'], 0
def put(s, x, y, sz):
    global k; k += 1
    return (f'<clipPath id="k{k}"><rect x="{x}" y="{y}" width="{sz}" height="{sz}" rx="{sz*.2237}"/></clipPath>'
            f'<g clip-path="url(#k{k})"><svg x="{x}" y="{y}" width="{sz}" height="{sz}" viewBox="0 0 1024 1024">{inner(s)}</svg></g>')
for i, s in enumerate(V.values()):
    out.append(put(s, 40 + i * 290, 40, 250))
out.append(grad("wl", "#F6C7A8", "#8FB6E8") + grad("wd", "#1B1F3A", "#07080F"))
for r, (w, ph) in enumerate((("wl", "#FFFFFF"), ("wd", "#3A3D55"))):
    y, x = 340 + r * 200, 80
    out.append(f'<rect x="40" y="{y}" width="1120" height="170" rx="28" fill="url(#{w})"/>')
    for j in range(11):
        if j in (1, 4, 6, 9):
            out.append(put(list(V.values())[(1, 4, 6, 9).index(j)], x, y + 40, 60))
            out.append(f'<text x="{x+30}" y="{y+118}" text-anchor="middle" font-family="-apple-system, system-ui, Helvetica, sans-serif" font-size="12" fill="#FFFFFF">iosevka</text>')
        else:
            out.append(f'<rect x="{x}" y="{y+40}" width="60" height="60" rx="13.4" fill="{ph}" opacity=".35"/>')
        x += 97
body = "".join(out)
open("preview-backgrounds.svg", "w").write(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 740" width="1200" height="740">{body}</svg>\n')
open("/tmp/iosevka-logo-check.svg", "w").write(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 1200" width="1200" height="1200">{body}</svg>\n')
