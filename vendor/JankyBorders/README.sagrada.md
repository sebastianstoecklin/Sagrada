# Bundled JankyBorders

Upstream: https://github.com/FelixKratz/JankyBorders
Version: v1.9.0, commit a7297ca7d1933f3a30b12e8f10750e8d84eeee1e
License: GNU GPL v3 (see LICENSE, also included in the app bundle).
This modified version is distributed under GNU GPL v3.
JankyBorders is a separate executable; its corresponding source and build script
are included in release archives under source/.

Modified by Sebastian Stoecklin for Sagrada on 2026-10-31:

- Private Mach service `com.sebastianstoecklin.sagrada.borders`, independent of a Homebrew instance.
- Parent-process watcher exits when Sagrada terminates unexpectedly.

Built as a universal arm64/x86_64 helper by script/build-borders.sh.
Sagrada passes explicit settings, so no external bordersrc is executed.
Do not enable another border service at the same time (it would draw duplicate borders).
