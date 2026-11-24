#!/usr/bin/env bash
# Positive and negative tests for check_domain_boundary.sh.
# Each case copies packages/puzzle_domain to a temporary directory, applies one
# change, and runs the guard's static checks against the copy.
set -euo pipefail
tool="$(cd "$(dirname "$0")" && pwd)"
src="$tool/../packages/puzzle_domain"
guard="$tool/check_domain_boundary.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

pass=0
failed=0

fresh() {
  rm -rf "$work/pkg"
  mkdir -p "$work/pkg"
  cp -r "$src/lib" "$src/test" "$src/pubspec.yaml" "$work/pkg/"
}

# expect_reject NAME EXPECTED_MESSAGE  (stdin: shell commands run inside the copy)
expect_reject() {
  local name="$1" expected="$2"
  fresh
  (cd "$work/pkg" && bash -e)
  local out
  if out="$("$guard" --static-only "$work/pkg" 2>&1)"; then
    echo "FAIL  [reject] $name: guard passed"; failed=$((failed + 1))
  elif ! grep -qF -- "$expected" <<<"$out"; then
    echo "FAIL  [reject] $name: missing message '$expected'"; echo "$out" | sed 's/^/        /'
    failed=$((failed + 1))
  else
    echo "ok    [reject] $name"; pass=$((pass + 1))
  fi
}

# expect_accept NAME  (stdin: shell commands run inside the copy)
expect_accept() {
  local name="$1"
  fresh
  (cd "$work/pkg" && bash -e)
  local out
  if out="$("$guard" --static-only "$work/pkg" 2>&1)"; then
    echo "ok    [accept] $name"; pass=$((pass + 1))
  else
    echo "FAIL  [accept] $name: false positive"; echo "$out" | sed 's/^/        /'
    failed=$((failed + 1))
  fi
}

prepend() { # prepend TEXT to lib/src/grid.dart
  printf '%s\n' "$1" | cat - lib/src/grid.dart > g.tmp && mv g.tmp lib/src/grid.dart
}
export -f prepend

# --- Prohibited directives -----------------------------------------------------
expect_reject "import, single quotes, Flutter" "import of 'package:flutter/foundation.dart'" <<'EOF'
prepend "import 'package:flutter/foundation.dart';"
EOF
expect_reject "import, double quotes, Flutter" "import of 'package:flutter/widgets.dart'" <<'EOF'
prepend 'import "package:flutter/widgets.dart";'
EOF
expect_reject "import, single quotes, Flame" "import of 'package:flame/game.dart'" <<'EOF'
prepend "import 'package:flame/game.dart';"
EOF
expect_reject "import, double quotes, Flame (prefix + show)" "import of 'package:flame/components.dart'" <<'EOF'
prepend 'import "package:flame/components.dart" as flame show Component;'
EOF
expect_reject "import, Flutter-family package (flutter_riverpod)" "import of 'package:flutter_riverpod/flutter_riverpod.dart'" <<'EOF'
prepend "import 'package:flutter_riverpod/flutter_riverpod.dart';"
EOF
expect_reject "export, single quotes, Flutter" "export of 'package:flutter/foundation.dart'" <<'EOF'
echo "export 'package:flutter/foundation.dart';" >> lib/puzzle_domain.dart
EOF
expect_reject "export, double quotes, Flame" "export of 'package:flame/game.dart'" <<'EOF'
echo 'export "package:flame/game.dart";' >> lib/puzzle_domain.dart
EOF
expect_reject "import dart:ui, single quotes" "import of 'dart:ui'" <<'EOF'
prepend "import 'dart:ui';"
EOF
expect_reject "import dart:ui, double quotes" "import of 'dart:ui'" <<'EOF'
prepend 'import "dart:ui" show Color;'
EOF
expect_reject "export dart:ui, single quotes" "export of 'dart:ui'" <<'EOF'
echo "export 'dart:ui' show Offset;" >> lib/puzzle_domain.dart
EOF
expect_reject "export dart:ui, double quotes" "export of 'dart:ui'" <<'EOF'
echo 'export "dart:ui";' >> lib/puzzle_domain.dart
EOF
expect_reject "import split across lines" "import of 'package:flutter/foundation.dart'" <<'EOF'
prepend $'import\n    \'package:flutter/foundation.dart\'\n    show kDebugMode;'
EOF
expect_reject "import package:sky_engine/" "import of 'package:sky_engine/ui/ui.dart'" <<'EOF'
prepend "import 'package:sky_engine/ui/ui.dart';"
EOF
expect_reject "export package:sky_engine/" "export of 'package:sky_engine/ui/ui.dart'" <<'EOF'
echo 'export "package:sky_engine/ui/ui.dart";' >> lib/puzzle_domain.dart
EOF
expect_reject "import dart:ui_web" "import of 'dart:ui_web'" <<'EOF'
prepend "import 'dart:ui_web' as ui_web;"
EOF
expect_reject "export dart:ui_web" "export of 'dart:ui_web'" <<'EOF'
echo 'export "dart:ui_web";' >> lib/puzzle_domain.dart
EOF
expect_reject "conditional import URI" "import of 'package:flutter/foundation.dart'" <<'EOF'
prepend "import 'src/grid.dart' if (dart.library.ui) 'package:flutter/foundation.dart';"
EOF
expect_reject "import in a test file" "import of 'package:flutter/foundation.dart'" <<'EOF'
printf "import 'package:flutter/foundation.dart';\n" | cat - test/grid_test.dart > t.tmp && mv t.tmp test/grid_test.dart
EOF

# --- Prohibited pubspec declarations ---------------------------------------------
expect_reject "pubspec dependencies: flutter (sdk)" "dependencies: flutter" <<'EOF'
printf '\ndependencies:\n  flutter:\n    sdk: flutter\n' >> pubspec.yaml
EOF
expect_reject "pubspec dependencies: flame" "dependencies: flame" <<'EOF'
printf '\ndependencies:\n  flame: ^1.38.2\n' >> pubspec.yaml
EOF
expect_reject "pubspec dev_dependencies: flutter_test" "dev_dependencies: flutter_test" <<'EOF'
sed -i 's/^dev_dependencies:$/dev_dependencies:\n  flutter_test:\n    sdk: flutter/' pubspec.yaml
EOF
expect_reject "pubspec dependency_overrides: flame_riverpod" "dependency_overrides: flame_riverpod" <<'EOF'
printf '\ndependency_overrides:\n  "flame_riverpod": ^5.5.5\n' >> pubspec.yaml
EOF
expect_reject "pubspec SDK dependency under another name" "a dependency from the Flutter SDK (sdk: flutter)" <<'EOF'
printf '\ndependencies:\n  sky_engine_alias:\n    sdk: flutter\n' >> pubspec.yaml
EOF
expect_reject "pubspec inline dependency map" "dependencies: flutter" <<'EOF'
printf '\ndependencies: {flutter: {sdk: flutter}}\n' >> pubspec.yaml
EOF
expect_reject "pubspec environment Flutter constraint" "environment: Flutter SDK constraint" <<'EOF'
sed -i 's/^  sdk: \^3.14.0$/  sdk: ^3.14.0\n  flutter: ">=3.50.0"/' pubspec.yaml
EOF
expect_reject "pubspec top-level flutter section" "top-level 'flutter:' section" <<'EOF'
printf '\nflutter:\n  uses-material-design: true\n' >> pubspec.yaml
EOF

# --- Must NOT be rejected (no false positives) -----------------------------------
expect_accept "clean package" <<'EOF'
true
EOF
expect_accept "comments and doc comments mentioning Flutter/Flame/dart:ui" <<'EOF'
prepend "// import 'package:flutter/foundation.dart';
/// Never depends on package:flutter, package:flame or \"dart:ui\".
/* import \"package:flame/game.dart\";
   export 'dart:ui'; */"
EOF
expect_accept "string literals containing directive text" <<'EOF'
cat >> lib/src/grid.dart <<'DART'

const exampleImport = "import 'package:flutter/foundation.dart';";
const exampleBlock = '''
import "package:flame/game.dart";
export 'dart:ui';
''';
DART
EOF
expect_accept "identifiers that start with import/export" <<'EOF'
cat >> lib/src/grid.dart <<'DART'

const exportedCells = 'package:flutter/';
int importance(int x) => x;
DART
EOF
expect_accept "similar but allowed package names and URIs" <<'EOF'
prepend "import 'package:flutterish/x.dart';
import 'package:flameproof/y.dart';
import 'dart:math';"
printf '\ndependencies:\n  flutterish: ^1.0.0\n' >> pubspec.yaml
EOF
expect_accept "pubspec comments and description mentioning Flutter" <<'EOF'
printf '\n# flutter: must never be added here\n# dependencies:\n#   flame: any\n' >> pubspec.yaml
grep -q 'Must not depend on Flutter or Flame' pubspec.yaml
EOF

echo
echo "boundary guard tests: $pass passed, $failed failed"
[ "$failed" -eq 0 ]
