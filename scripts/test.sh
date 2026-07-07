#!/usr/bin/env bash
# Runs the full test suite.
set -euo pipefail
cd "$(dirname "$0")/.."
flutter pub get
flutter test
