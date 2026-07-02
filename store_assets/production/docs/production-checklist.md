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
