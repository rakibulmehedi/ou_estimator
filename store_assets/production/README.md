# Production Store Assets

Source assets live in `src/`. Export final PNGs into `dist/`.

Recommended exports:

- `google-play-feature.svg` -> `google-play-feature.png` at 1024 x 500
- `app-store-01-input.svg` -> `app-store-01-input.png` at 1290 x 2796
- `app-store-02-results.png` at 1290 x 2796 — rendered fully programmatically (no source SVG)

Use `python3 scripts/render_store_assets.py`. It renders exact-size production PNGs with local fonts.
`app-store-02-results` draws a synthetic results screen from app theme tokens; it does not require a device screenshot.

`scripts/export-store-assets.sh` is kept only as a macOS SVG preview fallback; `qlmanage` may output square thumbnails depending on system settings.
