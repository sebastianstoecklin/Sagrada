# Sagrada branding

**Celestial light. Structured space.**

`sagrada.png` is the shared master for the README and macOS app icon:
1254 × 1254 RGBA artwork combining Sagrada Família-inspired stained glass,
organic branching geometry, nebula light, and recursive window tiles.
Its exterior includes a soft translucent halo.

Sagrada is the fork's identity: `Sagrada.app`, the `sagrada` CLI,
and bundle identifier `com.sebastianstoecklin.sagrada`. Existing AeroSpace
configuration paths and environment variables are retained for compatibility.
The original AeroSpace copyright and attribution are preserved.

## Rebuild app assets

From the repository root, using Python with Pillow installed:

```sh
python script/build-branding.py
# Maintainer environment:
# conda run -n agents python script/build-branding.py
```

This resamples the master with Lanczos to 16, 32, 64, 128, 256, 512, and 1024 pixels
and maps all ten macOS 1×/2× slots in
`resources/Assets.xcassets/AppIcon.appiconset/Contents.json` to `sagrada-*.png`.
The script also crops the existing artwork to its inner frame, composites it
onto an opaque navy background, and writes the full-bleed 1024px image in
`resources/AppIcon.icon/Assets/`. The Icon Composer package uses that image
without extra glass, translucency, or shadow effects. macOS supplies its native
mask and enclosure instead of placing the padded legacy icon on a gray tile.
The legacy asset catalog remains available for older macOS versions.

Rebuild with Xcode 26 or later to compile both icon formats. No new AI image
generation is needed for this conversion.

The upstream documentation keeps its original `docs/assets/icon.png`.
The app icon catalog uses only the generated Sagrada assets.

## Image generation

Created using Pi's `codex_generate_image` tool, with no fallback API.
The original generation remains in Pi's external generated-image storage.
No additional generation was needed to adopt the approved concept.

### Original generation prompt

```text
Use case: logo-brand. Create an alternative original macOS tiling window manager application icon inspired by the Sagrada Familia's luminous stained-glass mosaics, organic branching geometry and soaring architectural rhythm, reimagined for outer space. Not a photograph of a church. One bold clean front-facing rounded-square app icon centered on a perfectly uniform very dark midnight navy background. Square canvas. Icon occupies 84% of canvas with generous padding. Within the rounded-square silhouette, abstract interlocking window panes form a cosmic stained glass mosaic: a large tall pane left, a wide pane upper right, smaller subdivided panes below, with subtle organic branching mullions and gently pointed architectural curves. Suggest recursive window tiling with disciplined geometry rather than random shards. Deep cobalt and ultraviolet glass, luminous cyan highlights, a few restrained amber and rose accents like distant stars. The panes evoke a nebula illuminated from within, refined and dimensional, controlled soft glow, delicate beveled dark metallic boundaries. A tiny number of star points embedded in the panes establishes outer-space character, no planets or rockets or literal church towers. Premium Apple-style app-icon finish, simple enough to read at small size, serene and striking, rich color with generous dark negative space. No text, no letters, no Apple logo, no watermark, no presentation mockup, no extra objects. This is a distinct standalone alternative, not an edit to existing assets.
```
