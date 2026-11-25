#!/usr/bin/env bash
# Verify that a domain package stays pure Dart (ADR-0002).
#
# Usage: check_domain_boundary.sh [--static-only] [PACKAGE_DIR]
#   PACKAGE_DIR defaults to ../packages/puzzle_domain.
#   --static-only runs only checks 1 and 2 (used by the negative tests).
#
# 1. pubspec.yaml: no Flutter/Flame dependency in dependencies,
#    dev_dependencies or dependency_overrides (by name, or via `sdk: flutter`),
#    no Flutter SDK constraint under `environment`, no top-level `flutter:`.
# 2. Dart sources: no import/export directive whose URI is
#    package:flutter*/, package:flame*/, package:sky_engine/, dart:ui or
#    dart:ui_web, with single or double quotes, including multi-line and
#    conditional (`if (...) 'uri'`) directives. Comments and multi-line strings
#    are removed first, so documentation and string contents are not matched.
# 3. `dart analyze --fatal-infos` (depend_on_referenced_packages is an error).
# 4. `dart test` on the plain Dart VM (no Flutter engine).
set -euo pipefail

static_only=0
if [ "${1:-}" = "--static-only" ]; then
  static_only=1
  shift
fi
pkg="${1:-$(dirname "$0")/../packages/puzzle_domain}"
cd "$pkg"

fail=0

# --- 1. pubspec.yaml -------------------------------------------------------
if ! perl - pubspec.yaml <<'PERL'; then fail=1; fi
use strict; use warnings;
my $banned = qr/^(?:(?:flutter|flame)(?:_\w+)?|sky_engine)$/;
my $deps = qr/^(?:dependencies|dev_dependencies|dependency_overrides)$/;
my ($section, $child, @errors) = ('', undef);
while (my $line = <>) {
  chomp $line;
  $line =~ s/(^|\s)#.*$//;                      # YAML comment
  next if $line =~ /^\s*$/;
  if ($line =~ /^([^\s#][^:]*):(.*)$/) {       # top-level key
    ($section, $child) = ($1, undef);
    my $rest = $2;
    push @errors, "top-level 'flutter:' section" if $section eq 'flutter';
    if ($section =~ $deps) {                     # inline map form
      while ($rest =~ /["']?([\w]+)["']?\s*:/g) {
        my $name = $1;
        push @errors, "$section: $name" if $name =~ $banned;
      }
    }
    next;
  }
  my ($indent, $key) = $line =~ /^(\s+)["']?([\w]+)["']?\s*:/ or next;
  if ($section eq 'environment' && $key eq 'flutter') {
    push @errors, 'environment: Flutter SDK constraint';
  }
  next unless $section =~ $deps;
  $child //= length $indent;
  push @errors, "$section: $key" if length($indent) == $child && $key =~ $banned;
  push @errors, "$section: a dependency from the Flutter SDK (sdk: flutter)"
    if $key eq 'sdk' && $line =~ /:\s*["']?flutter["']?\s*$/;
}
if (@errors) {
  print STDERR "FAIL: pubspec.yaml declares a Flutter/Flame dependency: $_\n" for @errors;
  exit 1;
}
PERL

# --- 2. import/export directives ---------------------------------------------
mapfile -t dart_files < <(find . -name '*.dart' -not -path './.dart_tool/*' -not -path './build/*' | sort)
if [ "${#dart_files[@]}" -gt 0 ]; then
  if ! perl - "${dart_files[@]}" <<'PERL'; then fail=1; fi
use strict; use warnings;
my $bad_uri = qr{(["'])(?:package:(?:(?:flutter|flame)(?:_\w+)?|sky_engine)/[^"']*|dart:ui(?:_web)?)\1};
my $found = 0;
for my $file (@ARGV) {
  open my $fh, '<', $file or die "$file: $!";
  my $src = do { local $/; <$fh> };
  # Remove multi-line strings and comments. Directives may only appear before
  # declarations in Dart, so a string containing "/*" or "//" cannot precede one.
  $src =~ s/'''.*?'''//gs;
  $src =~ s/""".*?"""//gs;
  $src =~ s{/\*.*?\*/}{ }gs;
  $src =~ s{//[^\n]*}{}g;
  while ($src =~ /(?:^|[;}\n])\s*(import|export)\b([^;]*);/g) {
    my ($kind, $body) = ($1, $2);
    while ($body =~ /$bad_uri/g) {
      my $uri = substr($&, 1, -1);
      print STDERR "FAIL: $file: $kind of '$uri' (Flutter, Flame or dart:ui)\n";
      $found = 1;
    }
  }
}
exit $found;
PERL
fi

[ "$fail" -eq 0 ] || exit 1
if [ "$static_only" -eq 1 ]; then
  echo "OK: static boundary checks passed"
  exit 0
fi

# --- 3 and 4. analyzer and plain-VM tests ------------------------------------
dart analyze --fatal-infos
dart test
echo "OK: puzzle_domain boundary holds"
