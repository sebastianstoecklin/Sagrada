#!/usr/bin/env bash
cd "$(dirname "$0")"
source ./script/setup.sh

build_version="0.0.0-SNAPSHOT"
codesign_identity="sagradaspace-codesign-certificate"
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

swift_build_cli=(build -c release --arch arm64 --arch x86_64 --product sagradaspace)
swift "${swift_build_cli[@]}" -Xswiftc -warnings-as-errors
cli_bin_path="$(swift "${swift_build_cli[@]}" --show-bin-path)"

rm -rf .release && mkdir .release

cd ./xcode
    xcode_configuration="Release"
    xcodebuild -version
    xcodebuild-pretty ../.release/xcodebuild.log clean build \
        -scheme SagradaSpace \
        -destination "generic/platform=macOS" \
        -configuration "$xcode_configuration" \
        -derivedDataPath .xcode-build
cd -

# Keep local fork changes intact; never reset the working tree during a build.

cp -r "xcode/.xcode-build/Build/Products/$xcode_configuration/SagradaSpace.app" .release
cp -r "$cli_bin_path/sagradaspace" .release

################
### SIGN CLI ###
################

codesign -s "$codesign_identity" .release/sagradaspace

################
### VALIDATE ###
################

expected_layout=$(cat <<EOF
.release/SagradaSpace.app
.release/SagradaSpace.app/Contents
.release/SagradaSpace.app/Contents/_CodeSignature
.release/SagradaSpace.app/Contents/_CodeSignature/CodeResources
.release/SagradaSpace.app/Contents/MacOS
.release/SagradaSpace.app/Contents/MacOS/SagradaSpace
.release/SagradaSpace.app/Contents/Resources
.release/SagradaSpace.app/Contents/Resources/default-config.toml
.release/SagradaSpace.app/Contents/Resources/AppIcon.icns
.release/SagradaSpace.app/Contents/Resources/Assets.car
.release/SagradaSpace.app/Contents/Info.plist
.release/SagradaSpace.app/Contents/PkgInfo
EOF
)

if test "$expected_layout" != "$(find .release/SagradaSpace.app)"; then
    echo "!!! Expect/Actual layout don't match !!!"
    find .release/SagradaSpace.app
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

check-universal-binary .release/SagradaSpace.app/Contents/MacOS/SagradaSpace
check-universal-binary .release/sagradaspace

check-contains-hash .release/SagradaSpace.app/Contents/MacOS/SagradaSpace
check-contains-hash .release/sagradaspace

codesign -v .release/SagradaSpace.app
codesign -v .release/sagradaspace

############
### PACK ###
############

mkdir -p ".release/SagradaSpace-v$build_version/manpage" && cp .man/*.1 ".release/SagradaSpace-v$build_version/manpage"
cp -r ./legal ".release/SagradaSpace-v$build_version/legal"
cp -r .shell-completion ".release/SagradaSpace-v$build_version/shell-completion"
cd .release
    mkdir -p "SagradaSpace-v$build_version/bin" && cp -r sagradaspace "SagradaSpace-v$build_version/bin"
    cp -r SagradaSpace.app "SagradaSpace-v$build_version"
    zip -r "SagradaSpace-v$build_version.zip" "SagradaSpace-v$build_version"
cd -

#################
### Brew Cask ###
#################
for cask_name in sagradaspace sagradaspace-dev; do
    ./script/build-brew-cask.sh \
        --cask-name "$cask_name" \
        --zip-uri ".release/SagradaSpace-v$build_version.zip" \
        --build-version "$build_version"
done
