#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
mkdir -p build dist
xcodebuild -project WaterReminder.xcodeproj -target WaterReminder -configuration Release build CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
rm -rf dist/WaterReminder.app
cp -R build/Release/WaterReminder.app dist/WaterReminder.app
cd dist
zip -r WaterReminder-mac.zip WaterReminder.app
echo "输出文件：$(pwd)/WaterReminder-mac.zip"
