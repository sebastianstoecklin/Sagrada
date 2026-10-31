#!/usr/bin/env bash
cd "$(dirname "$0")/.."
source ./script/setup.sh

./script/check-uncommitted-files.sh

rm -rf ~/Library/Developer/Xcode/DerivedData/SagradaSpace-*
rm -rf ./.xcode-build

rm -rf SagradaSpace.xcodeproj
./generate.sh
