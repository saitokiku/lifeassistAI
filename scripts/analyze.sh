#!/usr/bin/env bash
# Static analysis. Must be clean before any release build.
set -euo pipefail
cd "$(dirname "$0")/.."
flutter pub get
flutter analyze
