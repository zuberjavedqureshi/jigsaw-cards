#!/usr/bin/env bash
# S-01 spike: verify packages/puzzle_domain stays pure Dart.
# 1. Its pubspec must not depend on Flutter or Flame.
# 2. Its sources must not import Flutter, Flame or dart:ui.
# 3. `dart analyze` must pass (depend_on_referenced_packages is an error there).
# 4. Its tests must run on the plain Dart VM (`dart test`, no Flutter engine).
set -euo pipefail
cd "$(dirname "$0")/../packages/puzzle_domain"

fail=0
if grep -nE '^\s*(flutter|flame[a-z_]*|sky_engine)\s*:' pubspec.yaml; then
  echo "FAIL: puzzle_domain/pubspec.yaml declares a Flutter/Flame dependency" >&2
  fail=1
fi
if grep -rnE "import\s+'(package:(flutter|flame)[a-z_]*/|dart:ui)" lib test; then
  echo "FAIL: puzzle_domain imports Flutter, Flame or dart:ui" >&2
  fail=1
fi
[ "$fail" -eq 0 ] || exit 1

dart analyze --fatal-infos
dart test
echo "OK: puzzle_domain boundary holds"
