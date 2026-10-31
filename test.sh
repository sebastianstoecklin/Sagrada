#!/usr/bin/env bash
cd "$(dirname "$0")"
source ./script/setup.sh

./build-debug.sh -Xswiftc -warnings-as-errors
./swift-test.sh

./.debug/sagrada -h > /dev/null
./.debug/sagrada --help > /dev/null
./.debug/sagrada -v | grep -q "0.0.0-SNAPSHOT SNAPSHOT"
./.debug/sagrada --version | grep -q "0.0.0-SNAPSHOT SNAPSHOT"

./lint.sh
./generate.sh
./script/check-uncommitted-files.sh

echo
echo "✅ All tests have passed successfully"
