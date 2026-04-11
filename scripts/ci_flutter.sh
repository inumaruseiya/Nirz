#!/usr/bin/env bash
# Local parity with .github/workflows/flutter_ci.yml (Flutter job).
set -euo pipefail
cd "$(dirname "$0")/.."
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
