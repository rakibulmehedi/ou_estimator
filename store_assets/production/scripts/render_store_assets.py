from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
REPO = ROOT.parents[1]
DIST = ROOT / "dist"
SCREENSHOTS = REPO / "store_assets" / "screenshots"
FONTS = REPO / "assets" / "google_fonts"


def font(name: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONTS / name), size)


INTER_REG = "Inter-Regular.ttf"
INTER_MED = "Inter-Medium.ttf"
INTER_SEMI = "Inter-SemiBold.ttf"
INTER_BOLD = "Inter-Bold.ttf"
JET_BOLD = "JetBrainsMono-Bold.ttf"


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size[0], size[1]), radius=radius, fill=255)
    return mask


def draw_grid(draw: ImageDraw.ImageDraw, width: int, height: int, step: int, color: tuple[int, int, int, int]) -> None:
    for x in range(step, width, step):
        draw.line((x, 0, x, height), fill=color, width=1)
    for y in range(step, height, step):
        draw.line((0, y, width, y), fill=color, width=1)


def paste_cover(base: Image.Image, image_path: Path, box: tuple[int, int, int, int], radius: int) -> None:
    src = Image.open(image_path).convert("RGBA")
    x, y, w, h = box
    scale = max(w / src.width, h / src.height)
    resized = src.resize((int(src.width * scale), int(src.height * scale)), Image.Resampling.LANCZOS)
    left = (resized.width - w) // 2
    top = (resized.height - h) // 2
    crop = resized.crop((left, top, left + w, top + h))
    base.paste(crop, (x, y), rounded_mask((w, h), radius))


def shadowed_round_rect(canvas: Image.Image, box: tuple[int, int, int, int], radius: int) -> None:
    x, y, w, h = box
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((x, y, x + w, y + h), radius=radius, fill=(0, 0, 0, 130))
    shadow = shadow.filter(ImageFilter.GaussianBlur(32))
    canvas.alpha_composite(shadow, (0, 0))


def background(width: int, height: int) -> Image.Image:
    img = Image.new("RGBA", (width, height), (7, 11, 18, 255))
    px = img.load()
    for y in range(height):
        for x in range(width):
            t = (x / width + y / height) / 2
            r = int(7 + 10 * t)
            g = int(11 + 15 * t)
            b = int(18 + 22 * t)
            if x > width * 0.58 and y < height * 0.35:
                b += 16
            if x > width * 0.45 and y > height * 0.62:
                g += 10
            px[x, y] = (r, g, b, 255)
    return img


def draw_phone(canvas: Image.Image, screenshot: Path, y_offset: int) -> None:
    draw = ImageDraw.Draw(canvas)
    x, y, w, h = 132, y_offset, 1026, 2170
    shadowed_round_rect(canvas, (x, y, w, h), 112)
    draw.rounded_rectangle((x, y, x + w, y + h), radius=112, fill=(5, 8, 14), outline=(4, 20, 14), width=18)
    paste_cover(canvas, screenshot, (158, y + 26, 974, 2116), 86)


def screenshot_asset(filename: str, eyebrow: str, headline: list[str], subhead: str, chips: list[str], screenshot: Path, accent: tuple[int, int, int]) -> None:
    img = background(1290, 2796)
    draw = ImageDraw.Draw(img)
    draw_grid(draw, 1290, 2796, 210, (138, 164, 199, 30))

    draw.text((90, 156), eyebrow, fill=accent, font=font(INTER_BOLD, 34))
    y = 224
    for line in headline:
        draw.text((90, y), line, fill=(239, 245, 255), font=font(INTER_BOLD, 86))
        y += 102
    draw.text((92, 444), subhead, fill=(154, 168, 187), font=font(INTER_MED, 39))

    chip_x = 90
    for chip in chips:
        tw = int(draw.textlength(chip, font=font(INTER_BOLD, 34)))
        draw.rounded_rectangle((chip_x, 548, chip_x + tw + 76, 634), radius=43, fill=(24, 34, 53), outline=(52, 65, 87), width=1)
        draw.text((chip_x + 38, 576), chip, fill=(223, 231, 244), font=font(INTER_BOLD, 34))
        chip_x += tw + 108

    draw_phone(img, screenshot, 722)
    img.convert("RGB").save(DIST / filename, quality=95)


def feature_graphic() -> None:
    img = background(1024, 500)
    draw = ImageDraw.Draw(img)
    draw_grid(draw, 1024, 500, 80, (138, 164, 199, 32))

    glow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse((680, -58, 960, 222), fill=(43, 124, 255, 42))
    gd.ellipse((210, 286, 520, 596), fill=(54, 217, 138, 36))
    img.alpha_composite(glow.filter(ImageFilter.GaussianBlur(18)))

    draw.text((64, 78), "OU Estimator", fill=(223, 231, 244), font=font(INTER_REG, 60))
    draw.text((66, 148), "Mean reversion parameter estimation", fill=(147, 164, 188), font=font(INTER_MED, 27))

    draw.rounded_rectangle((64, 214, 512, 356), radius=18, fill=(21, 28, 43), outline=(42, 52, 72), width=1)
    labels = [("theta", 98, (89, 217, 140)), ("mu", 256, (109, 160, 255)), ("sigma", 342, (89, 217, 140)), ("t1/2", 468, (223, 231, 244))]
    for text, x, color in labels:
        draw.text((x, 252), text, fill=color, font=font(JET_BOLD, 28), anchor="mm")
    draw.text((96, 300), "OLS + exact MLE", fill=(223, 231, 244), font=font(INTER_BOLD, 36))

    panel = (556, 84, 390, 312)
    shadowed_round_rect(img, panel, 28)
    x, y, w, h = panel
    draw.rounded_rectangle((x, y, x + w, y + h), radius=28, fill=(21, 28, 43), outline=(52, 65, 87), width=1)
    draw.text((580, 122), "Price Series", fill=(145, 160, 183), font=font(INTER_SEMI, 24))
    for gy in (176, 235, 294):
        draw.line((580, gy, 914, gy), fill=(44, 53, 72), width=1)
    points = [(580, 248), (620, 178), (666, 250), (710, 212), (750, 150), (790, 272), (835, 228), (914, 220)]
    draw.line(points, fill=(98, 160, 255), width=5, joint="curve")
    draw.line((580, 224, 914, 224), fill=(66, 219, 143), width=3)
    draw.rounded_rectangle((580, 302, 730, 366), radius=14, fill=(31, 39, 56), outline=(52, 65, 87), width=1)
    draw.text((598, 320), "Half-life", fill=(145, 160, 183), font=font(INTER_MED, 16))
    draw.text((598, 343), "1.644", fill=(223, 231, 244), font=font(JET_BOLD, 25))
    draw.rounded_rectangle((754, 302, 914, 366), radius=14, fill=(31, 39, 56), outline=(52, 65, 87), width=1)
    draw.text((772, 320), "R2 fit", fill=(145, 160, 183), font=font(INTER_MED, 16))
    draw.text((772, 343), "0.9142", fill=(66, 219, 143), font=font(JET_BOLD, 25))

    img.convert("RGB").save(DIST / "google-play-feature.png", quality=95)


def apple_icon() -> None:
    """1024 × 1024 RGB PNG — Apple App Store icon, no transparency."""
    src  = Image.open(REPO / "assets" / "app_icon.jpg").convert("RGB")
    side = min(src.width, src.height)
    left = (src.width  - side) // 2
    top  = (src.height - side) // 2
    icon = src.crop((left, top, left + side, top + side))
    icon.resize((1024, 1024), Image.Resampling.LANCZOS).save(DIST / "apple-icon-1024.png")


def play_icon() -> None:
    """512 × 512 RGB PNG — Play Store icon, alpha flattened onto app background."""
    src = Image.open(REPO / "store_assets" / "icon_512.png").convert("RGBA")
    bg  = Image.new("RGB", src.size, (7, 11, 18))
    bg.paste(src, mask=src.split()[3])
    bg.resize((512, 512), Image.Resampling.LANCZOS).save(DIST / "play-icon-512.png")


def draw_phone_content(canvas: Image.Image, content: Image.Image, y_offset: int) -> None:
    draw = ImageDraw.Draw(canvas)
    x, y, w, h = 132, y_offset, 1026, 2170
    shadowed_round_rect(canvas, (x, y, w, h), 112)
    draw.rounded_rectangle((x, y, x + w, y + h), radius=112, fill=(5, 8, 14), outline=(4, 20, 14), width=18)
    mask = rounded_mask((974, 2116), 86)
    canvas.paste(content.convert("RGBA"), (158, y_offset + 26), mask)


def draw_results_content(w: int, h: int) -> Image.Image:
    """Synthetic OU results screen — no screenshot needed."""
    # ── color palette (matches AppTheme) ─────────────────────────────────────
    BG       = (13,  17,  23)
    SURFACE  = (22,  27,  34)
    BORDER   = (44,  54,  69)
    ACCENT   = (79, 140, 255)
    ACCENT_D = (79, 140, 200)
    T_PRI    = (230, 237, 243)
    T_SEC    = (139, 148, 158)
    T_TER    = (110, 118, 129)
    POSITIVE = (63,  185,  80)
    NEGATIVE = (248,  81,  73)

    img  = Image.new("RGBA", (w, h), (*BG, 255))
    draw = ImageDraw.Draw(img)

    PAD    = 24
    CW     = w - PAD * 2          # 926
    CARD_W = (CW - 12) // 2       # 457
    CARD_H = 260
    GAP    = 12

    def tw(text: str, fnt: ImageFont.FreeTypeFont) -> int:
        return int(draw.textlength(text, font=fnt))

    def shadow_composite(layer: Image.Image, blur: int) -> None:
        img.alpha_composite(layer.filter(ImageFilter.GaussianBlur(blur)))

    def glass_card(x: int, y: int, cw: int, ch: int, r: int = 16) -> None:
        sh = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        ImageDraw.Draw(sh).rounded_rectangle(
            (x + 2, y + 5, x + cw + 2, y + ch + 5), radius=r, fill=(0, 0, 0, 55))
        shadow_composite(sh, 10)
        draw.rounded_rectangle((x, y, x + cw, y + ch), radius=r, fill=SURFACE)
        draw.rounded_rectangle((x, y, x + cw, y + ch), radius=r, outline=BORDER, width=1)

    def section_label(x: int, y: int, text: str) -> None:
        draw.text((x, y), text, fill=(*ACCENT_D, 200), font=font(INTER_BOLD, 22))

    def metric_card(x: int, y: int, sym: str, lbl: str, val: str, unit: str,
                    val_color: tuple = None) -> None:
        glass_card(x, y, CARD_W, CARD_H)
        # Accent top strip
        draw.rounded_rectangle((x + 1, y + 1, x + CARD_W - 1, y + 5),
                                radius=2, fill=(*ACCENT, 35))
        ix = x + 20
        sf = font(JET_BOLD, 32)
        sw = tw(sym, sf)
        # Row 1: symbol + label  (top zone)
        draw.text((ix, y + 20), sym, fill=(*ACCENT, 255), font=sf)
        draw.text((ix + sw + 10, y + 27), lbl, fill=(*T_SEC, 255), font=font(INTER_REG, 21))
        # Row 2: value
        vc = val_color if val_color else T_PRI
        draw.text((ix, y + 90), val, fill=(*vc, 255), font=font(JET_BOLD, 54))
        # Row 3: unit (pushed toward bottom for even vertical distribution)
        if unit:
            draw.text((ix, y + 185), unit, fill=(*T_TER, 255), font=font(INTER_REG, 20))
        # Hairline divider
        draw.line((ix, y + 76, x + CARD_W - 20, y + 76),
                  fill=(255, 255, 255, 10), width=1)

    # ── Status bar ───────────────────────────────────────────────────────────
    STATUS_H = 52
    draw.text((PAD, 14), "9:41", fill=(*T_PRI, 255), font=font(INTER_SEMI, 28))
    for i in range(3):
        bx_ = w - PAD - 96 + i * 28
        draw.rounded_rectangle((bx_, 18, bx_ + 20, 34), radius=3,
                                fill=(*T_PRI, 180 - i * 50))
    bx = w - PAD - 44
    draw.rounded_rectangle((bx, 17, bx + 38, 35), radius=4,
                            outline=(*T_SEC, 200), width=2)
    draw.rounded_rectangle((bx + 3, 20, bx + 28, 32), radius=2, fill=POSITIVE)
    draw.rectangle((bx + 38, 23, bx + 41, 29), fill=(*T_SEC, 120))

    # ── App bar ──────────────────────────────────────────────────────────────
    APP_BAR_H = 72
    ay = STATUS_H
    draw.text((PAD, ay + 17), "OU Estimator", fill=(*T_PRI, 255), font=font(INTER_SEMI, 38))
    chip_f  = font(INTER_BOLD, 23)
    chip_lbl = "MLE"
    ctw = tw(chip_lbl, chip_f)
    cx0 = w - PAD - ctw - 32
    draw.rounded_rectangle((cx0, ay + 18, cx0 + ctw + 32, ay + 54), radius=18,
                            fill=(*ACCENT, 28), outline=(*ACCENT, 90), width=1)
    draw.text((cx0 + 16, ay + 23), chip_lbl, fill=(*ACCENT, 255), font=chip_f)
    draw.line((0, ay + APP_BAR_H, w, ay + APP_BAR_H), fill=(255, 255, 255, 18), width=1)

    cur_y = STATUS_H + APP_BAR_H + 52

    # ── PARAMETERS grid ──────────────────────────────────────────────────────
    section_label(PAD, cur_y, "PARAMETERS")
    cur_y += 38

    params = [
        ("θ",  "Mean Reversion", "0.4231",   "per day"),
        ("μ",  "Equilibrium",    "104.8800",  "long-run mean"),
        ("σ",  "Volatility",     "0.3156",    "diffusion"),
        ("t½", "Half-Life",      "1.638",     "days"),
    ]
    for i, (sym, lbl, val, unit) in enumerate(params):
        metric_card(
            PAD + (i % 2) * (CARD_W + GAP),
            cur_y + (i // 2) * (CARD_H + GAP),
            sym, lbl, val, unit,
        )
    cur_y += CARD_H * 2 + GAP + 60

    # ── PRICE CHART ──────────────────────────────────────────────────────────
    section_label(PAD, cur_y, "PRICE CHART")
    cur_y += 38

    CHART_H = 500
    AXIS_W  = 58
    glass_card(PAD, cur_y, CW, CHART_H, r=16)

    series  = [105.42, 104.11, 103.58, 104.82, 106.34, 105.71, 104.43,
               103.89, 104.93, 105.61, 106.12, 105.24, 104.51, 103.92,
               104.76, 105.38, 104.15, 103.71, 104.63, 105.18]
    mu_v    = 104.88
    y_lo    = min(min(series), mu_v)
    y_hi    = max(max(series), mu_v)
    span    = y_hi - y_lo
    y_lo   -= span * 0.12
    y_hi   += span * 0.12

    ci_x = PAD + AXIS_W
    ci_w = CW - AXIS_W - 18
    ci_y = cur_y + 22
    ci_h = CHART_H - 48

    def to_pt(i: int, v: float) -> tuple[int, int]:
        sx = int(ci_x + i / (len(series) - 1) * ci_w)
        sy = int(ci_y + (y_hi - v) / (y_hi - y_lo) * ci_h)
        return sx, sy

    # Grid + y-axis labels
    for gi in range(5):
        gy = int(ci_y + gi * ci_h / 4)
        draw.line((ci_x, gy, ci_x + ci_w, gy), fill=(255, 255, 255, 12), width=1)
        gv = y_hi - gi * (y_hi - y_lo) / 4
        draw.text((PAD + 4, gy - 10), f"{gv:.1f}", fill=(*T_SEC, 255), font=font(JET_BOLD, 18))

    # μ dashed equilibrium line
    mu_sy = to_pt(0, mu_v)[1]
    dx = ci_x
    while dx < ci_x + ci_w:
        draw.line((dx, mu_sy, min(dx + 10, ci_x + ci_w), mu_sy),
                  fill=(*NEGATIVE, 170), width=2)
        dx += 18

    pts = [to_pt(i, v) for i, v in enumerate(series)]

    # Area fill with vertical gradient
    fill_pts = [(ci_x, ci_y + ci_h)] + pts + [(ci_x + ci_w, ci_y + ci_h)]
    area = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(area).polygon(fill_pts, fill=(*ACCENT, 55))
    mask_grad = Image.new("L", (w, h), 0)
    mg_draw   = ImageDraw.Draw(mask_grad)
    for gy in range(ci_y, ci_y + ci_h):
        a = int(255 * (1.0 - (gy - ci_y) / ci_h) ** 0.65)
        mg_draw.line((0, gy, w, gy), fill=a)
    r_, g_, b_, a_ = area.split()
    area = Image.merge("RGBA", (r_, g_, b_, ImageChops.multiply(a_, mask_grad)))
    img.alpha_composite(area)

    # Price line
    draw.line(pts, fill=(*ACCENT, 255), width=3)

    # x-axis labels
    for xi in [0, 5, 10, 15, 19]:
        sx, _ = to_pt(xi, mu_v)
        draw.text((sx, ci_y + ci_h + 7), str(xi), fill=(*T_TER, 200),
                  font=font(JET_BOLD, 18), anchor="mt")

    cur_y += CHART_H + 60

    # ── DIAGNOSTICS grid ─────────────────────────────────────────────────────
    section_label(PAD, cur_y, "DIAGNOSTICS")
    cur_y += 38

    diags = [
        ("R²",  "Goodness of Fit", "0.9142", "",      POSITIVE),
        ("s",   "Residual Std",    "0.0743", "",      None),
        ("ln L","Log-Likelihood",  "18.64",  "",      None),
        ("N",   "Observations",    "47",     "pairs", None),
    ]
    for i, (sym, lbl, val, unit, vc) in enumerate(diags):
        metric_card(
            PAD + (i % 2) * (CARD_W + GAP),
            cur_y + (i // 2) * (CARD_H + GAP),
            sym, lbl, val, unit, vc,
        )

    # ── Nav bar ──────────────────────────────────────────────────────────────
    nav_y = h - 86
    draw.line((0, nav_y, w, nav_y), fill=(255, 255, 255, 15), width=1)
    for ti, (tname, active) in enumerate([("Estimate", True), ("History", False)]):
        tx  = w // 4 + ti * w // 2
        tc  = ACCENT if active else T_TER
        ico = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        ImageDraw.Draw(ico).ellipse(
            (tx - 20, nav_y + 10, tx + 20, nav_y + 50),
            fill=(*ACCENT, 35) if active else None,
            outline=(*tc, 200), width=2,
        )
        img.alpha_composite(ico)
        draw.text((tx, nav_y + 58), tname, fill=(*tc, 220),
                  font=font(INTER_REG, 20), anchor="mt")

    return img


def screenshot_02_results() -> None:
    img  = background(1290, 2796)
    draw = ImageDraw.Draw(img)
    draw_grid(draw, 1290, 2796, 210, (138, 164, 199, 30))

    accent = (109, 160, 255)
    draw.text((90, 156), "PARAMETERS OUT", fill=accent, font=font(INTER_BOLD, 34))
    y_text = 224
    for line in ["Theta, mu, sigma", "and half-life"]:
        draw.text((90, y_text), line, fill=(239, 245, 255), font=font(INTER_BOLD, 86))
        y_text += 102
    draw.text((92, 444), "See diagnostics, equilibrium line, fit quality, and history.",
              fill=(154, 168, 187), font=font(INTER_MED, 39))

    chip_x = 90
    for chip in ["R2 0.9142", "t1/2 1.638"]:
        ctw = int(draw.textlength(chip, font=font(INTER_BOLD, 34)))
        draw.rounded_rectangle((chip_x, 548, chip_x + ctw + 76, 634),
                                radius=43, fill=(24, 34, 53), outline=(52, 65, 87), width=1)
        draw.text((chip_x + 38, 576), chip, fill=(223, 231, 244), font=font(INTER_BOLD, 34))
        chip_x += ctw + 108

    content = draw_results_content(974, 2116)
    draw_phone_content(img, content, 722)
    img.convert("RGB").save(DIST / "app-store-02-results.png", quality=95)


def draw_history_content(w: int, h: int) -> Image.Image:
    """Synthetic History screen — scrollable list of saved OU runs."""
    BG      = (13,  17,  23)
    SURFACE = (22,  27,  34)
    BORDER  = (44,  54,  69)
    ACCENT  = (79, 140, 255)
    T_PRI   = (230, 237, 243)
    T_SEC   = (139, 148, 158)
    T_TER   = (110, 118, 129)
    POSITIVE= (63,  185,  80)

    img  = Image.new("RGBA", (w, h), (*BG, 255))
    draw = ImageDraw.Draw(img)
    PAD  = 24

    def glass_card(x: int, y: int, cw: int, ch: int, r: int = 14) -> None:
        sh = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        ImageDraw.Draw(sh).rounded_rectangle(
            (x + 2, y + 5, x + cw + 2, y + ch + 5), radius=r, fill=(0, 0, 0, 50))
        img.alpha_composite(sh.filter(ImageFilter.GaussianBlur(8)))
        draw.rounded_rectangle((x, y, x + cw, y + ch), radius=r, fill=SURFACE)
        draw.rounded_rectangle((x, y, x + cw, y + ch), radius=r, outline=BORDER, width=1)

    # Status bar
    draw.text((PAD, 14), "9:41", fill=(*T_PRI, 255), font=font(INTER_SEMI, 28))
    for i in range(3):
        bx_ = w - PAD - 96 + i * 28
        draw.rounded_rectangle((bx_, 18, bx_ + 20, 34), radius=3,
                                fill=(*T_PRI, 180 - i * 50))
    bx = w - PAD - 44
    draw.rounded_rectangle((bx, 17, bx + 38, 35), radius=4,
                            outline=(*T_SEC, 200), width=2)
    draw.rounded_rectangle((bx + 3, 20, bx + 28, 32), radius=2, fill=POSITIVE)
    draw.rectangle((bx + 38, 23, bx + 41, 29), fill=(*T_SEC, 120))

    # App bar
    ay = 52
    draw.text((PAD, ay + 17), "OU Estimator", fill=(*T_PRI, 255), font=font(INTER_SEMI, 38))
    draw.line((0, ay + 72, w, ay + 72), fill=(255, 255, 255, 18), width=1)

    # Section label
    cur_y = ay + 100
    draw.text((PAD, cur_y), "SAVED RUNS", fill=(*ACCENT, 200), font=font(INTER_BOLD, 22))
    cur_y += 42

    runs = [
        ("MLE", "AAPL Close", "θ 0.4231", "t½ 1.638 d", "2 days ago"),
        ("OLS", "BTC / USD",  "θ 0.1892", "t½ 3.660 d", "5 days ago"),
        ("MLE", "EUR / USD",  "θ 0.8410", "t½ 0.824 d", "1 week ago"),
        ("OLS", "SPY close",  "θ 0.2145", "t½ 3.229 d", "2 weeks ago"),
    ]
    CARD_H = 130
    CW     = w - PAD * 2

    for method, name, theta, halflife, age in runs:
        glass_card(PAD, cur_y, CW, CARD_H)

        badge_c = ACCENT if method == "MLE" else (89, 217, 140)
        badge_f = font(INTER_BOLD, 20)
        bw_     = int(draw.textlength(method, font=badge_f)) + 24
        draw.rounded_rectangle(
            (PAD + 16, cur_y + 18, PAD + 16 + bw_, cur_y + 46),
            radius=8, fill=(*badge_c, 25), outline=(*badge_c, 90), width=1,
        )
        draw.text((PAD + 28, cur_y + 21), method, fill=(*badge_c, 255), font=badge_f)
        draw.text((PAD + 16 + bw_ + 14, cur_y + 20), name,
                  fill=(*T_PRI, 255), font=font(INTER_SEMI, 26))
        draw.text((PAD + 16, cur_y + 58), theta,
                  fill=(*T_PRI, 255), font=font(JET_BOLD, 28))
        draw.text((PAD + 16 + 180, cur_y + 58), halflife,
                  fill=(*T_SEC, 255), font=font(JET_BOLD, 28))
        draw.text((PAD + 16, cur_y + 96), age,
                  fill=(*T_TER, 255), font=font(INTER_REG, 20))

        for ix, color in enumerate([(139, 148, 158), (139, 148, 158), (248, 81, 73)]):
            ax = w - PAD - 30 - ix * 52
            ay_ = cur_y + CARD_H // 2
            draw.ellipse((ax - 18, ay_ - 18, ax + 18, ay_ + 18),
                         outline=(*color, 120), width=1)
            draw.ellipse((ax - 5, ay_ - 2, ax + 5, ay_ + 2), fill=(*color, 160))

        cur_y += CARD_H + 14

    # Nav bar — History tab active
    nav_y = h - 86
    draw.line((0, nav_y, w, nav_y), fill=(255, 255, 255, 15), width=1)
    for ti, (tname, active) in enumerate([("Estimate", False), ("History", True)]):
        tx  = w // 4 + ti * w // 2
        tc  = ACCENT if active else T_TER
        ico = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        ImageDraw.Draw(ico).ellipse(
            (tx - 20, nav_y + 10, tx + 20, nav_y + 50),
            fill=(*ACCENT, 35) if active else None,
            outline=(*tc, 200), width=2,
        )
        img.alpha_composite(ico)
        draw.text((tx, nav_y + 58), tname, fill=(*tc, 220),
                  font=font(INTER_REG, 20), anchor="mt")

    return img


def screenshot_03_history() -> None:
    img  = background(1290, 2796)
    draw = ImageDraw.Draw(img)
    draw_grid(draw, 1290, 2796, 210, (138, 164, 199, 30))

    accent = (89, 217, 140)
    draw.text((90, 156), "HISTORY", fill=accent, font=font(INTER_BOLD, 34))
    y_text = 224
    for line in ["Track saved", "runs"]:
        draw.text((90, y_text), line, fill=(239, 245, 255), font=font(INTER_BOLD, 86))
        y_text += 102
    draw.text((92, 444), "Reload, rename, delete, or export any saved estimation.",
              fill=(154, 168, 187), font=font(INTER_MED, 39))

    chip_x = 90
    for chip in ["Reload", "JSON export"]:
        ctw = int(draw.textlength(chip, font=font(INTER_BOLD, 34)))
        draw.rounded_rectangle((chip_x, 548, chip_x + ctw + 76, 634),
                                radius=43, fill=(24, 34, 53), outline=(52, 65, 87), width=1)
        draw.text((chip_x + 38, 576), chip, fill=(223, 231, 244), font=font(INTER_BOLD, 34))
        chip_x += ctw + 108

    content = draw_history_content(974, 2116)
    draw_phone_content(img, content, 722)
    img.convert("RGB").save(DIST / "app-store-03-history.png", quality=95)


def draw_export_content(w: int, h: int) -> Image.Image:
    """Results screen with a share-sheet bottom drawer overlaid."""
    base = draw_results_content(w, h)
    draw = ImageDraw.Draw(base)

    SURFACE = (22,  27,  34)
    BORDER  = (44,  54,  69)
    T_PRI   = (230, 237, 243)
    T_SEC   = (139, 148, 158)
    ACCENT  = (79, 140, 255)
    POSITIVE= (63,  185,  80)
    PAD     = 24

    sheet_top = int(h * 0.60)
    overlay   = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(overlay).rectangle((0, 0, w, sheet_top), fill=(0, 0, 0, 140))
    base.alpha_composite(overlay)

    draw.rounded_rectangle((0, sheet_top, w, h), radius=28, fill=SURFACE)
    draw.line((0, sheet_top, w, sheet_top), fill=(*BORDER, 255), width=1)

    hx = w // 2
    hy = sheet_top + 16
    draw.rounded_rectangle((hx - 24, hy, hx + 24, hy + 6), radius=3,
                            fill=(*T_SEC, 120))

    draw.text((PAD, sheet_top + 38), "Share Result", fill=(*T_PRI, 255),
              font=font(INTER_SEMI, 34))

    card_y = sheet_top + 94
    draw.rounded_rectangle((PAD, card_y, w - PAD, card_y + 120), radius=14,
                            fill=(13, 17, 23), outline=(*BORDER, 255), width=1)
    draw.text((PAD + 16, card_y + 14), '{ "version": 1,',
              fill=(*T_SEC, 255), font=font(JET_BOLD, 22))
    draw.text((PAD + 16, card_y + 44), '  "theta": 0.4231,',
              fill=(*ACCENT, 255), font=font(JET_BOLD, 22))
    draw.text((PAD + 16, card_y + 74), '  "halfLife": 1.638, ... }',
              fill=(*T_SEC, 255), font=font(JET_BOLD, 22))

    icons_y      = card_y + 150
    icon_spacing = (w - PAD * 2) // 4
    for i, lbl in enumerate(["Files", "Mail", "Notes", "More"]):
        ix = PAD + icon_spacing * i + icon_spacing // 2
        draw.ellipse((ix - 32, icons_y, ix + 32, icons_y + 64),
                     fill=(32, 38, 50), outline=(*BORDER, 200), width=1)
        draw.text((ix, icons_y + 72), lbl, fill=(*T_SEC, 255),
                  font=font(INTER_REG, 20), anchor="mt")

    snack_y = h - 108
    draw.rounded_rectangle((PAD, snack_y, w - PAD, snack_y + 56), radius=12,
                            fill=(32, 38, 50))
    draw.ellipse((PAD + 16, snack_y + 14, PAD + 44, snack_y + 42),
                 fill=(*POSITIVE, 255))
    draw.text((PAD + 60, snack_y + 15), "Result copied as JSON",
              fill=(*T_PRI, 255), font=font(INTER_MED, 26))

    return base


def screenshot_04_export() -> None:
    img  = background(1290, 2796)
    draw = ImageDraw.Draw(img)
    draw_grid(draw, 1290, 2796, 210, (138, 164, 199, 30))

    accent = (109, 160, 255)
    draw.text((90, 156), "EXPORT", fill=accent, font=font(INTER_BOLD, 34))
    y_text = 224
    for line in ["Export JSON", "and share"]:
        draw.text((90, y_text), line, fill=(239, 245, 255), font=font(INTER_BOLD, 86))
        y_text += 102
    draw.text((92, 444), "Share results via native OS sheet. Versioned JSON output.",
              fill=(154, 168, 187), font=font(INTER_MED, 39))

    chip_x = 90
    for chip in ["JSON v1", "Native share"]:
        ctw = int(draw.textlength(chip, font=font(INTER_BOLD, 34)))
        draw.rounded_rectangle((chip_x, 548, chip_x + ctw + 76, 634),
                                radius=43, fill=(24, 34, 53), outline=(52, 65, 87), width=1)
        draw.text((chip_x + 38, 576), chip, fill=(223, 231, 244), font=font(INTER_BOLD, 34))
        chip_x += ctw + 108

    content = draw_export_content(974, 2116)
    draw_phone_content(img, content, 722)
    img.convert("RGB").save(DIST / "app-store-04-export.png", quality=95)


def draw_phone_scaled(
    canvas: Image.Image,
    content: Path | Image.Image,
    cx: int,
    cy: int,
    scale: float,
) -> None:
    """Draw a phone frame centred at (cx, cy) with all dimensions scaled."""
    draw   = ImageDraw.Draw(canvas)
    pw     = int(1026 * scale)
    ph     = int(2170 * scale)
    px     = cx - pw // 2
    py     = cy - ph // 2
    r      = max(6,  int(112 * scale))
    sr     = max(4,  int(86  * scale))
    bw     = max(1,  int(18  * scale))
    sx_off = int(26 * scale)
    sy_off = int(26 * scale)
    sw     = int(974  * scale)
    sh     = int(2116 * scale)

    shadowed_round_rect(canvas, (px, py, pw, ph), r)
    draw.rounded_rectangle(
        (px, py, px + pw, py + ph),
        radius=r, fill=(5, 8, 14), outline=(4, 20, 14), width=bw,
    )
    if isinstance(content, Path):
        paste_cover(canvas, content, (px + sx_off, py + sy_off, sw, sh), sr)
    else:
        mask    = rounded_mask((sw, sh), sr)
        resized = content.convert("RGBA").resize((sw, sh), Image.Resampling.LANCZOS)
        canvas.paste(resized, (px + sx_off, py + sy_off), mask)


def tablet_portrait_screenshot(
    filename: str,
    width: int,
    height: int,
    eyebrow: str,
    headline: list[str],
    subhead: str,
    chips: list[str],
    content: Path | Image.Image,
    accent: tuple[int, int, int],
) -> None:
    """Portrait tablet screenshot scaled from the 1290-wide phone reference layout."""
    ws   = width / 1290
    img  = background(width, height)
    draw = ImageDraw.Draw(img)
    draw_grid(draw, width, height, max(80, int(210 * ws)), (138, 164, 199, 30))

    pad = int(90 * ws)

    draw.text(
        (pad, int(156 * ws)), eyebrow, fill=accent,
        font=font(INTER_BOLD, max(18, int(34 * ws))),
    )

    hl_sz = max(36, int(86 * ws))
    hl_y  = int(224 * ws)
    for line in headline:
        draw.text((pad, hl_y), line, fill=(239, 245, 255), font=font(INTER_BOLD, hl_sz))
        hl_y += int(hl_sz * 1.19)

    draw.text(
        (pad, int(444 * ws)), subhead, fill=(154, 168, 187),
        font=font(INTER_MED, max(18, int(39 * ws))),
    )

    cf_sz  = max(14, int(34 * ws))
    chip_f = font(INTER_BOLD, cf_sz)
    cy0    = int(548 * ws)
    cy1    = int(634 * ws)
    chip_x = pad
    for chip in chips:
        tw    = int(draw.textlength(chip, font=chip_f))
        pad_c = int(76 * ws)
        draw.rounded_rectangle(
            (chip_x, cy0, chip_x + tw + pad_c, cy1),
            radius=int(43 * ws), fill=(24, 34, 53), outline=(52, 65, 87), width=1,
        )
        draw.text(
            (chip_x + int(38 * ws), cy0 + int(28 * ws)), chip,
            fill=(223, 231, 244), font=chip_f,
        )
        chip_x += tw + pad_c + int(32 * ws)

    phone_top   = int(722 * ws)
    avail_h     = height - phone_top - int(60 * ws)
    phone_scale = min(ws, avail_h / 2170)
    draw_phone_scaled(img, content, width // 2, phone_top + avail_h // 2, phone_scale)

    img.convert("RGB").save(DIST / filename, quality=95)


def chromebook_screenshot() -> None:
    """2560 × 1440 landscape: phone mock centred with wide decorative side panels."""
    W, H = 2560, 1440
    img  = background(W, H)
    draw = ImageDraw.Draw(img)
    draw_grid(draw, W, H, 160, (138, 164, 199, 28))

    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd   = ImageDraw.Draw(glow)
    gd.ellipse((-80, 180, 860, 1060), fill=(43, 124, 255, 20))
    gd.ellipse((1750, -80, 2680, 640), fill=(54, 217, 138, 18))
    img.alpha_composite(glow.filter(ImageFilter.GaussianBlur(80)))

    phone_scale = (H - 160) / 2170
    content     = draw_results_content(974, 2116)
    draw_phone_scaled(img, content, W // 2, H // 2, phone_scale)

    pw       = int(1026 * phone_scale)
    phone_rx = W // 2 + pw // 2
    pad      = 100
    accent_g = (89, 217, 140)
    accent_b = (109, 160, 255)

    # Left panel
    lx = pad
    draw.text((lx, 240), "OU Estimator", fill=(239, 245, 255), font=font(INTER_BOLD, 72))
    draw.text((lx, 332), "Mean Reversion Toolkit", fill=(*accent_g, 255), font=font(INTER_SEMI, 36))
    draw.text((lx, 400), "Estimate theta, mu, sigma and", fill=(154, 168, 187), font=font(INTER_MED, 26))
    draw.text((lx, 436), "half-life from price series.", fill=(154, 168, 187), font=font(INTER_MED, 26))

    my = 530
    for sym, lbl, val in [
        ("θ",  "Mean Reversion", "0.4231"),
        ("μ",  "Equilibrium",    "104.88"),
        ("t½", "Half-Life",      "1.638 d"),
    ]:
        draw.rounded_rectangle((lx, my, lx + 380, my + 90), radius=16,
                               fill=(21, 28, 43), outline=(52, 65, 87), width=1)
        draw.text((lx + 20, my + 10), sym,  fill=(*accent_b, 255), font=font(JET_BOLD, 36))
        draw.text((lx + 20, my + 54), lbl,  fill=(139, 148, 158), font=font(INTER_REG, 18))
        draw.text((lx + 248, my + 22), val, fill=(230, 237, 243),  font=font(JET_BOLD, 30))
        my += 112

    # Right panel
    rx = phone_rx + pad
    draw.text((rx, 240), "OLS + exact MLE", fill=(239, 245, 255), font=font(INTER_BOLD, 56))
    draw.text((rx, 316), "Two estimation methods", fill=(154, 168, 187), font=font(INTER_MED, 26))

    fy = 398
    for feat in [
        "Paste values or import CSV / TXT",
        "History: reload, rename, delete",
        "Export JSON via native share sheet",
        "Fit diagnostics: R², σ̂, ln L, N",
    ]:
        draw.ellipse((rx, fy + 9, rx + 8, fy + 17), fill=(*accent_g, 255))
        draw.text((rx + 18, fy), feat, fill=(154, 168, 187), font=font(INTER_MED, 24))
        fy += 50

    img.convert("RGB").save(DIST / "play-chromebook.png", quality=95)


def main() -> None:
    DIST.mkdir(parents=True, exist_ok=True)
    apple_icon()
    play_icon()
    feature_graphic()
    screenshot_asset(
        "app-store-01-input.png",
        "PRICE SERIES IN",
        ["Estimate mean", "reversion fast"],
        "Paste values or import CSV/TXT. Run OLS or exact MLE.",
        ["OLS", "MLE"],
        SCREENSHOTS / "screen_main2.png",
        (89, 217, 140),
    )
    screenshot_02_results()
    screenshot_03_history()
    screenshot_04_export()
    tablet_portrait_screenshot(
        "play-tablet-7in.png",
        1080, 1920,
        "PRICE SERIES IN",
        ["Estimate mean", "reversion fast"],
        "Paste values or import CSV/TXT. Run OLS or exact MLE.",
        ["OLS", "MLE"],
        SCREENSHOTS / "screen_main2.png",
        (89, 217, 140),
    )
    tablet_portrait_screenshot(
        "play-tablet-10in.png",
        1440, 2560,
        "PARAMETERS OUT",
        ["Theta, mu, sigma", "and half-life"],
        "See diagnostics, equilibrium line, fit quality, and history.",
        ["R2 0.9142", "t1/2 1.638"],
        draw_results_content(974, 2116),
        (109, 160, 255),
    )
    chromebook_screenshot()


if __name__ == "__main__":
    main()
