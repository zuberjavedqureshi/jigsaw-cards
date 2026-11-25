/// Pure-Dart puzzle domain for Jigsaw Cards (rectangular tile style).
///
/// Must never import Flutter, Flame or `dart:ui` (Development Rule 2,
/// ADR-0002). Rendering, gestures, animation and persistence live elsewhere.
library;

export 'src/board_space.dart';
export 'src/generator.dart';
export 'src/grid.dart';
export 'src/layout.dart';
export 'src/piece.dart';
export 'src/scatter.dart';
export 'src/session.dart';
