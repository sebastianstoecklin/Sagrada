#!/usr/bin/env bash
cd "$(dirname "$0")"
source ./script/setup.sh

build_version="0.0.0-SNAPSHOT"
codesign_identity="sagrada-codesign-certificate"
while test $# -gt 0; do
    case $1 in
        --build-version) build_version="$2"; shift 2;;
        --codesign-identity) codesign_identity="$2"; shift 2;;
        *) echo "Unknown option $1" > /dev/stderr; exit 1 ;;
    esac
done

#############
### BUILD ###
#############

./build-docs.sh --release
./build-shell-completion.sh

./generate.sh
./script/check-uncommitted-files.sh
./generate.sh --build-version "$build_version" --codesign-identity "$codesign_identity" --generate-git-hash

swift_build_cli=(build -c release --arch arm64 --arch x86_64 --product sagrada)
swift "${swift_build_cli[@]}" -Xswiftc -warnings-as-errors
cli_bin_path="$(swift "${swift_build_cli[@]}" --show-bin-path)"

rm -rf .release && mkdir .release

cd ./xcode
    xcode_configuration="Release"
    xcodebuild -version
    xcodebuild-pretty ../.release/xcodebuild.log clean build \
        -scheme Sagrada \
        -destination "generic/platform=macOS" \
        -configuration "$xcode_configuration" \
        -derivedDataPath .xcode-build
cd -

# Keep local fork changes intact; never reset the working tree during a build.

cp -r "xcode/.xcode-build/Build/Products/$xcode_configuration/Sagrada.app" .release
cp -r "$cli_bin_path/sagrada" .release

################
### SIGN CLI ###
################

codesign -s "$codesign_identity" .release/sagrada

################
### VALIDATE ###
################

expected_layout=$(cat <<EOF
.release/Sagrada.app
.release/Sagrada.app/Contents
.release/Sagrada.app/Contents/_CodeSignature
.release/Sagrada.app/Contents/_CodeSignature/CodeResources
.release/Sagrada.app/Contents/MacOS
.release/Sagrada.app/Contents/MacOS/Sagrada
.release/Sagrada.app/Contents/Resources
.release/Sagrada.app/Contents/Resources/default-config.toml
.release/Sagrada.app/Contents/Resources/LICENSE
.release/Sagrada.app/Contents/Resources/sagrada-borders
.release/Sagrada.app/Contents/Resources/AppIcon.icns
.release/Sagrada.app/Contents/Resources/Assets.car
.release/Sagrada.app/Contents/Info.plist
.release/Sagrada.app/Contents/PkgInfo
EOF
)

if test "$(printf '%s\n' "$expected_layout" | sort)" != "$(find .release/Sagrada.app | sort)"; then
    echo "!!! Expect/Actual layout don't match !!!"
    find .release/Sagrada.app
    exit 1
fi

check-universal-binary() {
    if ! file "$1" | grep --fixed-string -q "Mach-O universal binary with 2 architectures: [x86_64:Mach-O 64-bit executable x86_64] [arm64"; then
        echo "$1 is not a universal binary"
        exit 1
    fi
}

check-contains-hash() {
    hash=$(git rev-parse HEAD)
    if ! strings "$1" | grep --fixed-string "$hash" > /dev/null; then
        echo "$1 doesn't contain $hash"
        exit 1
    fi
}

check-universal-binary .release/Sagrada.app/Contents/MacOS/Sagrada
check-universal-binary .release/sagrada
check-universal-binary .release/Sagrada.app/Contents/Resources/sagrada-borders

check-contains-hash .release/Sagrada.app/Contents/MacOS/Sagrada
check-contains-hash .release/sagrada

codesign --verify --deep --strict .release/Sagrada.app
codesign -v .release/sagrada

############
### PACK ###
############

mkdir -p ".release/Sagrada-v$build_version/manpage" && cp .man/*.1 ".release/Sagrada-v$build_version/manpage"
cp -r ./legal ".release/Sagrada-v$build_version/legal"
# GPLv3 corresponding source for the separately bundled JankyBorders helper.
mkdir -p ".release/Sagrada-v$build_version/source/vendor" ".release/Sagrada-v$build_version/source/script"
cp -r vendor/JankyBorders ".release/Sagrada-v$build_version/source/vendor/"
cp script/build-borders.sh ".release/Sagrada-v$build_version/source/script/"
cp -r .shell-completion ".release/Sagrada-v$build_version/shell-completion"
cd .release
    mkdir -p "Sagrada-v$build_version/bin" && cp -r sagrada "Sagrada-v$build_version/bin"
    cp -r Sagrada.app "Sagrada-v$build_version"
    zip -r "Sagrada-v$build_version.zip" "Sagrada-v$build_version"
cd -

#################
### Brew Cask ###
#################
for cask_name in sagrada sagrada-dev; do
    ./script/build-brew-cask.sh \
        --cask-name "$cask_name" \
        --zip-uri ".release/Sagrada-v$build_version.zip" \
        --build-version "$build_version"
done
