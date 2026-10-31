#!/usr/bin/env python3
"""Generate macOS icon sizes from the shared README/app artwork (requires Pillow)."""
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs/assets/branding/sagrada.png"
ICON_SET = ROOT / "resources/Assets.xcassets/AppIcon.appiconset"
COMPOSER_ASSETS = ROOT / "resources/AppIcon.icon/Assets"


def main():
    with Image.open(SOURCE) as source:
        source = source.convert("RGBA")
        if source.width != source.height:
            raise ValueError("App icon artwork must be square")
        # Native macOS icons are full-bleed; the OS supplies the mask and shadow.
        # Exclude the legacy artwork's transparent padding and baked outer halo,
        # which otherwise expose macOS's gray compatibility enclosure.
        full_bleed = source.crop((147, 147, 1107, 1107)).resize(
            (1024, 1024), Image.Resampling.LANCZOS
        )
        background = Image.new("RGBA", full_bleed.size, (8, 12, 28, 255))
        background.alpha_composite(full_bleed)
        COMPOSER_ASSETS.mkdir(parents=True, exist_ok=True)
        background.convert("RGB").save(COMPOSER_ASSETS / "stained-glass.png", optimize=True)
        images = []
        for size in (16, 32, 128, 256, 512):
            for scale in (1, 2):
                pixels = size * scale
                filename = f"sagrada-{pixels}.png"
                source.resize((pixels, pixels), Image.Resampling.LANCZOS).save(
                    ICON_SET / filename, optimize=True
                )
                images.append({
                    "filename": filename,
                    "idiom": "mac",
                    "scale": f"{scale}x",
                    "size": f"{size}x{size}",
                })
    (ICON_SET / "Contents.json").write_text(
        json.dumps({"images": images, "info": {"author": "xcode", "version": 1}}, indent=2)
        + "\n"
    )
    print(f"Generated all 10 macOS app icon slots in {ICON_SET}")


if __name__ == "__main__":
    main()
