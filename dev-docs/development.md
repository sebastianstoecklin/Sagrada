# Development Notes

## Dwindle fork

The fork adds `enable-dwindle` (default `true`) to the configuration parser and
implements binary insertion in `unbindAndGetBindingDataForNewTilingWindow`.
`DwindleTest` covers alternating splits, focus selection, weight preservation,
floating/accordion behavior, close/reinsert, and opting out. Legacy command tests
use the retained upstream configuration and disable Dwindle explicitly.

The bundled default is the personal configuration described in the repository
README. Tests must not run its external startup commands or depend on local apps.
No build step installs or overwrites user configuration files.

## Scroll Reverser

`ScrollReverserConfig` parses the opt-in `[scroll-reverser]` table. A successful
config reload applies it to `ScrollReverser.shared`; menu overrides last until
reload/restart. The session event tap subscribes only to scroll-wheel events and
runs on the main run loop. Disabling it, turning off both axes, or terminating the
app removes the source and invalidates the tap. A timeout re-enables the tap;
macOS user-input disablement surfaces a retry action instead.

`reverseDiscreteScroll` changes the line, fixed-point, and point deltas for the
selected axes. Read all representations before writing: CoreGraphics setters can
update related fields. Continuous events, gesture phases, and momentum events
pass through. This is event classification, not reliable physical-device
identification: smooth mouse drivers may be excluded, and touch input converted
to discrete wheel events cannot be distinguished.

`ScrollReverserTest` covers parsing/defaults, both axes, disabled behavior,
gesture passthrough, metadata preservation, and lifecycle without installing a
global filter. Real-device validation still needs
a classic wheel mouse, trackpad, and (where available) Magic Mouse. Check both
Natural Scrolling settings, both axes, enable/disable, config reload, restart,
and permission denial/retry. Do not run another scroll reverser concurrently.
Permission requests must remain tied to explicit user interaction; unit tests
must never request TCC access or install an event tap.

## Toolchain and testing

On macOS 27 beta Command Line Tools, SwiftUI may fail to find `SwiftUIMacros`.
Prefer a fully configured Xcode toolchain with its license accepted. For an app/CLI
build using Command Line Tools and the installed Xcode plugin:

```sh
swift build -Xswiftc -load-plugin-library -Xswiftc /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib/swift/host/plugins/libSwiftUIMacros.dylib
```

Command Line Tools alone also omit XCTest; use full Xcode for the standard test
commands. On the current beta setup, the following workaround built the tests;
invoking `xctest` directly runs the XCTest suite (the SwiftPM runner otherwise
reports zero tests):

```sh
platform=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer
swift test \
  -Xswiftc -load-plugin-library -Xswiftc "$platform/usr/lib/swift/host/plugins/libSwiftUIMacros.dylib" \
  -Xswiftc -F -Xswiftc "$platform/Library/Frameworks" \
  -Xswiftc -I -Xswiftc "$platform/usr/lib" \
  -Xlinker -rpath -Xlinker "$platform/Library/Frameworks" \
  -Xlinker -rpath -Xlinker "$platform/usr/lib" \
  -Xlinker "-L$platform/usr/lib"
DYLD_FRAMEWORK_PATH="$platform/Library/Frameworks" \
DYLD_LIBRARY_PATH="$platform/usr/lib" \
  /Applications/Xcode.app/Contents/Developer/usr/bin/xctest \
  "$(swift build --show-bin-path)/AppBundleTests.xctest"
```

The release script no longer resets the working tree after building; local fork
edits must never be discarded by a build.

To build/install from sources do the following:
1. Install dependencies
2. Create codesign certificate in `Keychain Access.app`
3. Run one of the entry point scripts to build/install from sources

If you struggle to build Sagrada locally, you can also refer to [builds in GitHub Actions](https://github.com/sebastianstoecklin/Sagrada/actions).

## Definitions

**SPM.** Swift package manager and Swift build tool. In other words, `swift` CLI tool

## 1. Install dependencies

1.  Install Xcode 26 or later from App Store https://apps.apple.com/us/app/xcode/id497799835
    (required to compile the native Icon Composer asset).
2.  Install [swiftly](https://github.com/swiftlang/swiftly).
    Swiftly is a Swift toolchain manager that will make sure that you use the same swift version as written in `.swift-version` file.
    `brew install swiftly`
3.  If you want to build shell completion, install rust, bash and fish
    -   Install Rust using rustup. https://www.rust-lang.org/tools/install
    -   `brew install bash fish`
4.  If you want to build man pages, install Ruby >= 3.0. I recommend using [rbenv](https://github.com/rbenv/rbenv).
    -   `rbenv install 3.3.4` (or whatever 3.x version)
    -   Install asciidoctor using Ruby `bundler`. `cd Sagrada && bundler install`
5.  Install optional `xcbeautify` to make Xcode build logs readable. `brew install xcbeautify`

## 2. Create codesign certificate

If you want to run Sagrada as an app bundle (Sagrada.app), create a self-signed certificate to sign it, or pass `--codesign-identity -` for a local ad-hoc build (not notarized).
Release artifact is built as App Bundle.
If you only plan to build the debug version of Sagrada, you can run it from the terminal and custom certificate is not required.

1.  Open `Keychain Access.app`
2.  Menu -> `Keychain Access` -> `Certificate Assistance` -> `Create a Certificate...`
    -   Name: `sagrada-codesign-certificate`
    -   Identity Type: `Self-Signed Root`
    -   Certificate Type: `Code Signing`

## 3. Entry point scripts

**Debug build**
-   `build-debug.sh` - Build debug build to `.debug` dir by using SPM. (Xcode is not involved)
-   `test.sh` - Run tests.
-   `format.sh` - Format the code.
-   `run-debug.sh` - Run the Sagrada debug build.
-   `run-cli.sh` - Run `sagrada` in CLI. Arguments are forwarded to the `sagrada` binary.
-   `build-docs.sh` - Build the site and man pages to `.site` and `.man` dirs respectively.
-   `build-shell-completion.sh` - Build shell completion to `.shell-completion`.
    You can test that the completion works properly by sourcing the file `source ./.shell-completion/zsh/_sagrada`
-   `generate.sh` - Regenerate generated project files. `xcode/Sagrada.xcodeproj` is generated, and some of the source files
    (the source files have `Generated` suffix in their names).

**Release build**
-   `build-release.sh` - Build release build to `.release` dir by using Xcode.
-   `install-from-sources.sh` - Build release build from sources and install it as `sagrada-dev` brew cask.
    This script is "work in progress".
    Use it on your own risk.

## IDE

-   You can obviously [open the project in Xcode](#xcode).
-   You can use your editor of choice (Neovim, Vim, Emacs, Sublime, VS Code) by using [sourcekit-lsp LSP](https://github.com/apple/sourcekit-lsp).
    I only tested it in Neovim
-   AppCode. The initial codebase was written in AppCode and the IDE was pretty solid.
    But AppCode was unfortunately sunsetted, and it started falling apart.
    Last time I checked it, it didn't support Swift 5.9 features, and I couldn't make it reliably import the project.
    RIP

## Xcode

Even if you use LSP and another text editor, Xcode is still useful to attach debugger (though you can use `lldb` in CLI).

1.  To open the project in Xcode: File -> Open -> Choose `Package.swift` file instead of `xcode/Sagrada.xcodeproj`.
    It's better to open `Package.swift`, because SPM project is more lightweight.
    `xcode/Sagrada.xcodeproj` is only used in `*release*.sh` build scripts.
2.  After you opened the project in Xcode.
    Edit Scheme... -> Options -> Console -> Choose `Terminal`.
    This way Accessibility permission will be requested from Terminal. The release app has its own `com.sebastianstoecklin.sagrada` identity and requires a new Accessibility grant when migrating from AeroSpace.
    If you don't change Console to `Terminal`, Accessibility permission will be requested on every rebuild, because the debug binary is unsigned.

## Release checks

- Build with an explicit `--build-version` and verify the app's
  `CFBundleShortVersionString` and `sagrada --version` both match the release tag.
- Keep `Contents/Resources/legal/` inside the signed app; do not remove it when
  packaging. It includes the MIT notice, dependency notices, and GPLv3 helper notice.
- Ship the exact `vendor/JankyBorders/` source and `script/build-borders.sh`
  used for the helper in every release archive. Update the dated modification
  notice when changing that source.
- Verify universal architectures, signatures, ZIP integrity, and SHA-256 checksum
  before publishing. The README does not need a version bump.

## Tips

- Use built-in "Accessibility Inspector.app" to inspect accessibility properties of windows
- Use [DeskPad](https://github.com/Stengo/DeskPad) or [BetterDisplay 2](https://github.com/waydabber/BetterDisplay) to emulate several monitors
- You can use `script/clean-project.sh` to clean the project when something goes wrong.
