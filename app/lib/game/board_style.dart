import 'dart:ui';

import '../ui/sunlit_theme.dart';

/// Colours of the Flame board, injected into the game as a plain object
/// (no Riverpod in Flame, ADR-0001). Defaults follow the Sunlit Storybook
/// tokens (PRD VI-06).
class BoardStyle {
  const BoardStyle({
    this.outline = const Color(0xE6FFFBF2),
    this.outlineWidth = 2,
    this.cornerRadius = 5,
    this.bed = const Color(0xF2EAF4FA),
    this.shadow = Sunlit.shadow,
    this.tileEdge = const Color(0xCCFFFFFF),
    this.selected = Sunlit.sunflower,
    this.target = Sunlit.deepTeal,
    this.targetGlow = const Color(0x6619B3D1),
    this.correctGlow = Sunlit.leaf,
    this.correctFill = const Color(0x55FFC845),
  });

  /// The approved Sunlit Storybook board.
  static const sunlit = BoardStyle();

  /// Thin, light outline around the board (Sunlit surface, 90%): an open
  /// board instead of a thick wooden frame (W3).
  final Color outline;

  /// Visible outline width (dp). Visual only: the board's logical rectangle
  /// and touch area are set by `BoardLayout`, not by this value.
  final double outlineWidth;

  /// Corner radius of the outline (dp).
  final double cornerRadius;

  /// Board bed under the tiles (pale blue, 95%): visible only under a lifted
  /// tile, so an empty cell never shows the background.
  final Color bed;
  final Color shadow;
  final Color tileEdge;
  final Color selected;
  final Color target;
  final Color targetGlow;
  final Color correctGlow;
  final Color correctFill;
}
