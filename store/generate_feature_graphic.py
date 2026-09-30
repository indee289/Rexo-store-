#!/usr/bin/env python3
"""Generate the Google Play feature graphic (1024x500) for Rexo Collab.

Deliberately restrained: flat brand colours, a clean wordmark, one accent, and a
row of REAL feature labels. No neon, no gradients-on-gradients, no fake 3D, no
misleading claims. Run: python3 store/generate_feature_graphic.py
"""
from PIL import Image, ImageDraw, ImageFont

W, H = 1024, 500
NAVY = (16, 18, 38)        # deep indigo background
NAVY_2 = (26, 29, 58)      # panel
BLUE = (0, 149, 246)       # Instagram-style brand blue used across the app
SAND = (240, 237, 229)     # warm sand (app background)
WHITE = (255, 255, 255)
MUTED = (176, 182, 204)

FONT_DIR = "/usr/share/fonts/google-noto"


def font(name, size):
    return ImageFont.truetype(f"{FONT_DIR}/{name}", size)


black = lambda s: font("NotoSans-Black.ttf", s)
bold = lambda s: font("NotoSans-Bold.ttf", s)
semi = lambda s: font("NotoSans-SemiBold.ttf", s)
reg = lambda s: font("NotoSans-Regular.ttf", s)


def rounded(draw, box, radius, fill=None, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


img = Image.new("RGB", (W, H), NAVY)
d = ImageDraw.Draw(img)

# Subtle right-side panel to hold simple, honest UI motifs.
rounded(d, (600, -40, 1064, 540), 0, fill=NAVY_2)

# Thin accent bar.
d.rectangle((0, H - 8, W, H), fill=BLUE)

# ── Brand monogram tile ("R") ──
rounded(d, (72, 70, 168, 166), 24, fill=BLUE)
mono = black(64)
tb = d.textbbox((0, 0), "R", font=mono)
d.text((72 + (96 - (tb[2] - tb[0])) / 2 - tb[0],
        70 + (96 - (tb[3] - tb[1])) / 2 - tb[1]), "R", font=mono, fill=WHITE)

# ── Wordmark + tagline ──
d.text((188, 84), "Rexo Collab", font=black(58), fill=WHITE)
d.text((190, 156), "Creator & brand marketplace", font=semi(30), fill=MUTED)

# Value line (factual, no numbers/claims). Kept within the left column (x<590).
d.text((74, 238),
       "Discover campaigns.\nCollaborate & get\npaid securely.",
       font=bold(36), fill=WHITE, spacing=8)

# Feature pills — each maps to a real screen in the app.
pills = ["Campaigns", "Creators", "Wallet", "Recovery"]
x = 74
for p in pills:
    tw = d.textbbox((0, 0), p, font=semi(24))[2]
    w = tw + 44
    rounded(d, (x, 392, x + w, 440), 24, outline=BLUE, width=2)
    d.text((x + 22, 400), p, font=semi(24), fill=SAND)
    x += w + 16

# ── Simple UI motif on the right panel: stacked "cards" (flat) ──
def card(y, title_w):
    rounded(d, (656, y, 984, y + 92), 16, fill=(34, 38, 72))
    d.ellipse((676, y + 24, 720, y + 68), fill=BLUE)
    rounded(d, (736, y + 28, 736 + title_w, y + 44), 8, fill=(70, 78, 120))
    rounded(d, (736, y + 54, 736 + int(title_w * 1.5), y + 66), 6, fill=(52, 58, 92))

card(96, 150)
card(204, 120)
card(312, 170)

img.save("store/assets/feature_graphic.png", "PNG")
print("Wrote store/assets/feature_graphic.png (%dx%d)" % img.size)
