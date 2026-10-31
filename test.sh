#!/usr/bin/env bash
cd "$(dirname "$0")"
source ./script/setup.sh

./build-debug.sh -Xswiftc -warnings-as-errors
./swift-test.sh

./.debug/sagradaspace -h > /dev/null
./.debug/sagradaspace --help > /dev/null
./.debug/sagradaspace -v | grep -q "0.0.0-SNAPSHOT SNAPSHOT"
./.debug/sagradaspace --version | grep -q "0.0.0-SNAPSHOT SNAPSHOT"

./lint.sh
./generate.sh
./script/check-uncommitted-files.sh

echo
echo "✅ All tests have passed successfully"
