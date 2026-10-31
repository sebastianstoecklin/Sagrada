# Licenses and attribution

Sagrada is a modified fork of AeroSpace, licensed under MIT. The original
copyright and license are preserved in [LICENSE.txt](./LICENSE.txt).
Renaming the app does not replace the original authors' attribution.

## Bundled dependencies and materials

Sagrada retains these AeroSpace dependencies and notices:

**HotKey**.
[HotKey GitHub link](https://github.com/soffes/HotKey).
[HotKey MIT license](./third-party-license/LICENSE-HotKey.txt).
HotKey is used as a more convenient wrapper around macOS Carbon API to listen for global shortcuts.

**TOMLDecoder**.
[TOMLDecoder GitHub link](https://github.com/dduan/TOMLDecoder).
[TOMLDecoder MIT license](./third-party-license/LICENSE-TOMLDecoder.txt).
TOMLDecoder is used as TOML parsing library.

**swift-collections**.
[swift-collections GitHub link](https://github.com/apple/swift-collections).
[swift-collections Apache 2.0 license](./third-party-license/LICENSE-swift-collections.txt).
swift-collections is used for more advanced Swift collections.

**ISSoundAdditions**
[ISSoundAdditions GitHub link](https://github.com/InerziaSoft/ISSoundAdditions).
[ISSoundAdditions MIT license](./third-party-license/LICENSE-ISSoundAdditions.txt).
ISSoundAdditions is used as a convenient API to change system volume.

## JankyBorders (separate GPLv3 executable)

Sagrada bundles a modified [JankyBorders](https://github.com/FelixKratz/JankyBorders)
helper, launched as a separate process using command-line settings. JankyBorders
is licensed under GNU GPL v3, not MIT. Its original license and dated modification
notice are retained in `vendor/JankyBorders/LICENSE` and
`vendor/JankyBorders/README.sagrada.md` in the repository.

In the installed app, this directory is `Contents/Resources/legal/`, and the
helper's license and modification notice are in its `JankyBorders/` subdirectory.
All these notices remain available when the app is copied without the rest of
the download.

Every release ZIP includes the matching modified helper source under
`source/vendor/JankyBorders/` and its build script under `source/script/`.
From the extracted `source/` directory, run:

```sh
/bin/bash script/build-borders.sh
```

This requires Xcode command-line tools and produces an ad-hoc signed universal
helper at `.build/helpers/sagrada-borders`. No private signing key is required.
Release downloads: https://github.com/sebastianstoecklin/Sagrada/releases

The top-level MIT license covers Sagrada, not the separately licensed helper or
other third-party components.
