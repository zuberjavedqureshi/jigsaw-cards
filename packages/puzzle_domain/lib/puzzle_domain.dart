/// Pure-Dart puzzle domain for Jigsaw Cards (rectangular tile style).
///
/// Must never import Flutter, Flame or `dart:ui` (Development Rule 2,
/// ADR-0002). Rendering, gestures, animation and persistence live elsewhere.
///
/// Active gameplay: [PicturePuzzle] (picture-swap), with connected correct
/// tiles moving together ([TileGroups], M3.2). The mixed-size
/// partition generator ([LayoutGenerator]) is kept for PS-08 / Q-009 but is
/// not used by the picture-swap prototype (see OPEN_QUESTIONS Q-022).
library;

export 'src/connection_events.dart';
export 'src/generator.dart';
export 'src/grid.dart';
export 'src/layout.dart';
export 'src/picture_puzzle.dart';
export 'src/piece.dart';
export 'src/tile_groups.dart';
