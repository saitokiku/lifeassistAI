#!/usr/bin/env bash
# Builds an .ipa archive for TestFlight / device installs.
# Requires macOS + Xcode + an Apple Developer account with signing set up.
# Output lands in build/ios/ipa/.
set -euo pipefail
cd "$(dirname "$0")/.."
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build ipa --release
