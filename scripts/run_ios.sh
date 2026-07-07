#!/usr/bin/env bash
# Runs a debug build on a connected iPhone or the iOS simulator.
# Requires macOS + Xcode. Pass a device id to target a specific device:
#   ./scripts/run_ios.sh 00008110-XXXXXXXX
set -euo pipefail
cd "$(dirname "$0")/.."
flutter pub get
if [ $# -ge 1 ]; then
  flutter run -d "$1"
else
  flutter run
fi
