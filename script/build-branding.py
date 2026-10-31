#!/usr/bin/env python3
"""Generate macOS icon sizes from the shared README/app artwork (requires Pillow)."""
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs/assets/branding/sagrada.png"
ICON_SET = ROOT / "resources/Assets.xcassets/AppIcon.appiconset"


def main():
    with Image.open(SOURCE) as source:
        source = source.convert("RGBA")
        if source.width != source.height:
            raise ValueError("App icon artwork must be square")
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
