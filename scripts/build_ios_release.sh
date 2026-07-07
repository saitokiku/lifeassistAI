#!/usr/bin/env bash
# Release build of the iOS app (no IPA packaging).
# Requires macOS + Xcode + signing configured in ios/Runner.xcworkspace.
set -euo pipefail
cd "$(dirname "$0")/.."
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build ios --release
