# Store Audit Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix all P0/P1 gaps from the Play Store and App Store release audit — producing upload-ready assets, a correct Android manifest, and an accurate production checklist.

**Architecture:** Six isolated changes in priority order: (1) one-line manifest fix, (2) icon exports via PIL added to render script, (3) root feature_graphic alpha flattened in-place, (4–5) two new synthetic screenshots added to render_store_assets.py, (6) checklist corrections. All image work flows through `store_assets/production/scripts/render_store_assets.py` → `store_assets/production/dist/`.

**Tech Stack:** Python 3, Pillow (PIL), Flutter/Android XML.

## Global Constraints

- App name in all stores: `OU Estimator` (capital O, capital U, capital E — no underscore)
- App background color: `(7, 11, 18)` — dark navy; use as flat background when stripping alpha
- All dist PNGs must be `RGB` mode (no alpha) before upload
- Font files live at `assets/google_fonts/` (Inter variants + JetBrainsMono-Bold)
- render_store_assets.py output dir: `store_assets/production/dist/`
- Apple screenshots: 1290 × 2796 px, RGB PNG
- Play phone screenshots: `dist/app-store-01-input.png` and `dist/app-store-02-results.png` are valid (1290 × 2796 RGB, sides within 320–3840)
- Apple icon: 1024 × 1024 px, RGB PNG, no transparency
- Play icon: 512 × 512 px, RGB PNG, no transparency
- Play feature graphic: use `dist/google-play-feature.png` (already RGB 1024 × 500)
- Run all render commands from `store_assets/production/` (script uses relative `ROOT` path)

---

### Task 1: Fix android:label

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml` (line 4)

**Interfaces:**
- Produces: correct app name shown on Play Store device shelf and Recent Apps

- [ ] **Step 1: Change the label**

In `android/app/src/main/AndroidManifest.xml`, find:
```xml
        android:label="ou_estimator"
```
Replace with:
```xml
        android:label="OU Estimator"
```

- [ ] **Step 2: Verify**

```bash
grep 'android:label' android/app/src/main/AndroidManifest.xml
```
Expected: `        android:label="OU Estimator"`

- [ ] **Step 3: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml
git commit -m "fix: set android:label to \"OU Estimator\" to match store listing"
```

---

### Task 2: Generate Apple icon (1024×1024) and flat Play icon (512×512)

**Files:**
- Modify: `store_assets/production/scripts/render_store_assets.py`
- Output: `store_assets/production/dist/apple-icon-1024.png`
- Output: `store_assets/production/dist/play-icon-512.png`

Icon source files: `assets/app_icon.jpg` (for Apple) and `store_assets/icon_512.png` (for Play — flatten alpha).

**Interfaces:**
- Produces: `apple_icon()` and `play_icon()` functions, both called from `main()`

- [ ] **Step 1: Add icon functions to render script**

In `render_store_assets.py`, add the two functions immediately after the `feature_graphic()` function (before `draw_phone_content`):

```python
def apple_icon() -> None:
    """1024 × 1024 RGB PNG — Apple App Store icon, no transparency."""
    src  = Image.open(REPO / "assets" / "app_icon.jpg").convert("RGB")
    side = min(src.width, src.height)
    left = (src.width  - side) // 2
    top  = (src.height - side) // 2
    icon = src.crop((left, top, left + side, top + side))
    icon.resize((1024, 1024), Image.Resampling.LANCZOS).save(
        DIST / "apple-icon-1024.png",
    )


def play_icon() -> None:
    """512 × 512 RGB PNG — Play Store icon, alpha flattened onto app background."""
    src = Image.open(REPO / "store_assets" / "icon_512.png").convert("RGBA")
    bg  = Image.new("RGB", src.size, (7, 11, 18))
    bg.paste(src, mask=src.split()[3])
    bg.resize((512, 512), Image.Resampling.LANCZOS).save(
        DIST / "play-icon-512.png",
    )
```

- [ ] **Step 2: Call both from `main()`**

In `main()`, add the two calls directly after `DIST.mkdir(parents=True, exist_ok=True)`:

```python
    DIST.mkdir(parents=True, exist_ok=True)
    apple_icon()
    play_icon()
    feature_graphic()
    ...
```

- [ ] **Step 3: Run and verify**

```bash
cd store_assets/production && python3 scripts/render_store_assets.py
python3 - <<'EOF'
from PIL import Image
for fname, expected_size in [
    ("dist/apple-icon-1024.png", (1024, 1024)),
    ("dist/play-icon-512.png",   (512,  512)),
]:
    img = Image.open(fname)
    assert img.size == expected_size, f"{fname}: size {img.size}"
    assert img.mode == "RGB",        f"{fname}: mode {img.mode}"
    print(f"{fname}: {img.size} {img.mode} ✓")
EOF
```
Expected:
```
dist/apple-icon-1024.png: (1024, 1024) RGB ✓
dist/play-icon-512.png: (512, 512) RGB ✓
```

- [ ] **Step 4: Commit**

```bash
git add store_assets/production/scripts/render_store_assets.py
git commit -m "feat: add apple-icon-1024 and play-icon-512 export to render script"
```

---

### Task 3: Fix root feature_graphic.png (RGBA → RGB)

**Files:**
- Modify: `store_assets/feature_graphic.png` (overwrite in place)

Root file is RGBA; Play Store rejects alpha on feature graphics. Flatten to RGB using the app background color.

**Interfaces:**
- Produces: `store_assets/feature_graphic.png` as 1024 × 500 RGB PNG

- [ ] **Step 1: Flatten alpha in place**

Run from repo root:

```bash
python3 - <<'EOF'
from PIL import Image
src = Image.open("store_assets/feature_graphic.png").convert("RGBA")
bg  = Image.new("RGB", src.size, (7, 11, 18))
bg.paste(src, mask=src.split()[3])
bg.save("store_assets/feature_graphic.png")
print("saved:", Image.open("store_assets/feature_graphic.png").mode)
EOF
```
Expected output: `saved: RGB`

- [ ] **Step 2: Verify dimensions and mode**

```bash
python3 -c "
from PIL import Image
img = Image.open('store_assets/feature_graphic.png')
assert img.size == (1024, 500), img.size
assert img.mode == 'RGB',       img.mode
print(img.size, img.mode, '✓')
"
```
Expected: `(1024, 500) RGB ✓`

- [ ] **Step 3: Commit**

```bash
git add store_assets/feature_graphic.png
git commit -m "fix: flatten store_assets/feature_graphic.png alpha (RGBA -> RGB for Play Store)"
```

---

### Task 4: Synthesize History screenshot (App Store slot 3)

**Files:**
- Modify: `store_assets/production/scripts/render_store_assets.py`
- Output: `store_assets/production/dist/app-store-03-history.png` (1290 × 2796 RGB)

Add `draw_history_content(w, h)` (synthetic History screen) and `screenshot_03_history()` (wraps it in the standard 1290 × 2796 frame). Insert both immediately after `screenshot_02_results()` and before `draw_phone_scaled()`.

**Interfaces:**
- Consumes: `background()`, `draw_grid()`, `draw_phone_content()`, `font()`, `ImageFilter`, `rounded_mask()` — all already defined above the insertion point
- Produces: `draw_history_content(w: int, h: int) -> Image.Image`, `screenshot_03_history() -> None`

- [ ] **Step 1: Add functions to render script**

Insert after `screenshot_02_results()` and before `draw_phone_scaled()`:

```python
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

    # Nav bar (History tab active)
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
```

- [ ] **Step 2: Call from `main()`**

In `main()`, add after `screenshot_02_results()`:

```python
    screenshot_03_history()
```

- [ ] **Step 3: Run and verify**

```bash
cd store_assets/production && python3 scripts/render_store_assets.py
python3 -c "
from PIL import Image
img = Image.open('dist/app-store-03-history.png')
assert img.size == (1290, 2796), img.size
assert img.mode == 'RGB',        img.mode
print(img.size, img.mode, '✓')
"
```
Expected: `(1290, 2796) RGB ✓`

- [ ] **Step 4: Commit**

```bash
git add store_assets/production/scripts/render_store_assets.py
git commit -m "feat: add synthetic History screenshot (app-store-03-history.png)"
```

---

### Task 5: Synthesize Export/Share screenshot (App Store slot 4)

**Files:**
- Modify: `store_assets/production/scripts/render_store_assets.py`
- Output: `store_assets/production/dist/app-store-04-export.png` (1290 × 2796 RGB)

Shows the results screen with a native share-sheet bottom drawer overlaid. Uses `draw_results_content(974, 2116)` as the base.

Insert after `screenshot_03_history()` and before `draw_phone_scaled()`.

**Interfaces:**
- Consumes: `draw_results_content()`, `draw_phone_content()`, `background()`, `draw_grid()`, `font()`, `ImageFilter`
- Produces: `draw_export_content(w: int, h: int) -> Image.Image`, `screenshot_04_export() -> None`

- [ ] **Step 1: Add functions to render script**

```python
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

    # Dim overlay above sheet
    sheet_top = int(h * 0.60)
    overlay   = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(overlay).rectangle((0, 0, w, sheet_top), fill=(0, 0, 0, 140))
    base.alpha_composite(overlay)

    # Sheet background
    draw.rounded_rectangle((0, sheet_top, w, h), radius=28, fill=SURFACE)
    draw.line((0, sheet_top, w, sheet_top), fill=(*BORDER, 255), width=1)

    # Drag handle
    hx = w // 2
    hy = sheet_top + 16
    draw.rounded_rectangle((hx - 24, hy, hx + 24, hy + 6), radius=3,
                            fill=(*T_SEC, 120))

    # Sheet title
    draw.text((PAD, sheet_top + 38), "Share Result", fill=(*T_PRI, 255),
              font=font(INTER_SEMI, 34))

    # JSON preview card
    card_y = sheet_top + 94
    draw.rounded_rectangle((PAD, card_y, w - PAD, card_y + 120), radius=14,
                            fill=(13, 17, 23), outline=(*BORDER, 255), width=1)
    draw.text((PAD + 16, card_y + 14), '{ "version": 1,',
              fill=(*T_SEC, 255), font=font(JET_BOLD, 22))
    draw.text((PAD + 16, card_y + 44), '  "theta": 0.4231,',
              fill=(*ACCENT, 255), font=font(JET_BOLD, 22))
    draw.text((PAD + 16, card_y + 74), '  "halfLife": 1.638, ... }',
              fill=(*T_SEC, 255), font=font(JET_BOLD, 22))

    # Share destination icons row
    icons_y      = card_y + 150
    labels       = ["Files", "Mail", "Notes", "More"]
    icon_spacing = (w - PAD * 2) // len(labels)
    for i, lbl in enumerate(labels):
        ix = PAD + icon_spacing * i + icon_spacing // 2
        draw.ellipse((ix - 32, icons_y, ix + 32, icons_y + 64),
                     fill=(32, 38, 50), outline=(*BORDER, 200), width=1)
        draw.text((ix, icons_y + 72), lbl, fill=(*T_SEC, 255),
                  font=font(INTER_REG, 20), anchor="mt")

    # "Copied" snackbar
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
```

- [ ] **Step 2: Call from `main()`**

In `main()`, add after `screenshot_03_history()`:

```python
    screenshot_04_export()
```

- [ ] **Step 3: Run and verify**

```bash
cd store_assets/production && python3 scripts/render_store_assets.py
python3 -c "
from PIL import Image
img = Image.open('dist/app-store-04-export.png')
assert img.size == (1290, 2796), img.size
assert img.mode == 'RGB',        img.mode
print(img.size, img.mode, '✓')
"
```
Expected: `(1290, 2796) RGB ✓`

- [ ] **Step 4: Commit**

```bash
git add store_assets/production/scripts/render_store_assets.py
git commit -m "feat: add synthetic Export/Share screenshot (app-store-04-export.png)"
```

---

### Task 6: Update production checklist

**Files:**
- Modify: `store_assets/production/docs/production-checklist.md`

Remove the non-existent `screen_results_final.png` reference, remove the incorrect `app-store-02-results.svg` source claim, add the full dist inventory.

- [ ] **Step 1: Replace file contents**

Overwrite `store_assets/production/docs/production-checklist.md` with:

```markdown
# Store Asset Production Checklist

## Required Assets

- Apple app icon: 1024 × 1024 PNG, no transparency.
- Apple screenshots: 6.9-inch set (1290 × 2796). Upload all four slots.
- Google Play icon: 512 × 512 PNG, RGB, no alpha.
- Google Play feature graphic: 1024 × 500 RGB PNG, no alpha.
- Google Play phone screenshots: at least 2, RGB PNG, sides 320–3840 px.
- Google Play 7-inch tablet: 1080 × 1920 RGB PNG (9:16 portrait).
- Google Play 10-inch tablet: 1440 × 2560 RGB PNG (9:16 portrait).
- Google Play Chromebook: 2560 × 1440 RGB PNG (16:9 landscape).

## Dist Package (all RGB — upload-ready)

| File | Store slot | Size |
|---|---|---|
| `dist/apple-icon-1024.png` | Apple icon | 1024 × 1024 |
| `dist/play-icon-512.png` | Play icon | 512 × 512 |
| `dist/google-play-feature.png` | Play feature graphic | 1024 × 500 |
| `dist/app-store-01-input.png` | Apple screenshot 1 · Play phone 1 | 1290 × 2796 |
| `dist/app-store-02-results.png` | Apple screenshot 2 · Play phone 2 | 1290 × 2796 |
| `dist/app-store-03-history.png` | Apple screenshot 3 | 1290 × 2796 |
| `dist/app-store-04-export.png` | Apple screenshot 4 | 1290 × 2796 |
| `dist/play-tablet-7in.png` | Play 7-inch tablet | 1080 × 1920 |
| `dist/play-tablet-10in.png` | Play 10-inch tablet | 1440 × 2560 |
| `dist/play-chromebook.png` | Play Chromebook | 2560 × 1440 |

## Source Files

- `src/google-play-feature.svg` — feature graphic source
- `src/app-store-01-input.svg` — input screen source

All other screens (results, history, export, tablet, Chromebook) are fully synthetic.
No additional SVG sources exist or are needed for them.

## Regenerate All Assets

```bash
cd store_assets/production && python3 scripts/render_store_assets.py
```

## Before Upload

- Confirm `android:label="OU Estimator"` in `android/app/src/main/AndroidManifest.xml`.
- Confirm `store_assets/feature_graphic.png` is RGB mode (no alpha).
- Confirm `pubspec.yaml` `version: X.Y.Z+N` versionCode `N` matches Play Console.
- App name in both stores must be exactly: `OU Estimator`.
```

- [ ] **Step 2: Verify stale references removed**

```bash
grep -c "screen_results_final\|app-store-02-results\.svg" \
  store_assets/production/docs/production-checklist.md
```
Expected: `0`

- [ ] **Step 3: Commit**

```bash
git add store_assets/production/docs/production-checklist.md
git commit -m "docs: update production checklist — correct file inventory, remove stale references"
```

---

## Final Verification

After all six tasks complete, run:

```bash
cd store_assets/production && python3 scripts/render_store_assets.py
python3 - <<'EOF'
from PIL import Image
checks = [
    ("dist/apple-icon-1024.png",     (1024, 1024), "RGB"),
    ("dist/play-icon-512.png",       (512,  512),  "RGB"),
    ("dist/google-play-feature.png", (1024, 500),  "RGB"),
    ("dist/app-store-01-input.png",  (1290, 2796), "RGB"),
    ("dist/app-store-02-results.png",(1290, 2796), "RGB"),
    ("dist/app-store-03-history.png",(1290, 2796), "RGB"),
    ("dist/app-store-04-export.png", (1290, 2796), "RGB"),
    ("dist/play-tablet-7in.png",     (1080, 1920), "RGB"),
    ("dist/play-tablet-10in.png",    (1440, 2560), "RGB"),
    ("dist/play-chromebook.png",     (2560, 1440), "RGB"),
]
all_ok = True
for fname, size, mode in checks:
    img = Image.open(fname)
    ok = img.size == size and img.mode == mode
    print(f"{'✓' if ok else '✗'} {fname}: {img.size} {img.mode}")
    all_ok = all_ok and ok
print("ALL PASS" if all_ok else "FAILURES — fix before upload")
EOF

grep 'android:label' android/app/src/main/AndroidManifest.xml
```

Expected last line: `        android:label="OU Estimator"`
