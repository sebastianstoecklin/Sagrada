#!/usr/bin/env bash
cd "$(dirname "$0")"
source ./script/setup.sh

rebuild=1
while test $# -gt 0; do
    case $1 in
        --dont-rebuild) rebuild=0; shift ;;
        *) echo "Unknown option $1"; exit 1 ;;
    esac
done

if test $rebuild == 1; then
    ./build-release.sh
fi

PATH="$PATH:$(brew --prefix)/bin"
export PATH

# Do not uninstall upstream AeroSpace or alter its tap automatically.
# The generated cask declares conflicts; quit/uninstall upstream explicitly first.
brew list --cask sagrada > /dev/null 2>&1 && brew uninstall --cask sagrada
which brew-install-path > /dev/null 2>&1 || brew install nikitabobko/tap/brew-install-path

# Override HOMEBREW_CACHE. Otherwise, homebrew refuses to "redownload" the snapshot file
# Maybe there is a better way, I don't know
rm -rf /tmp/sagrada-from-sources-brew-cache
HOMEBREW_CACHE=/tmp/sagrada-from-sources-brew-cache brew install-path ./.release/sagrada-dev.rb
