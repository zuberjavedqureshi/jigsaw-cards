import 'dart:ui';

import '../ui/sunlit_theme.dart';

/// Colours of the Flame board, injected into the game as a plain object
/// (no Riverpod in Flame, ADR-0001). Defaults follow the Sunlit Storybook
/// tokens (PRD VI-06).
class BoardStyle {
  const BoardStyle({
    this.frame = Sunlit.frame,
    this.frameEdge = Sunlit.frameEdge,
    this.frameHighlight = const Color(0x99FFF4D6),
    this.bed = Sunlit.boardBed,
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

  final Color frame;
  final Color frameEdge;
  final Color frameHighlight;
  final Color bed;
  final Color shadow;
  final Color tileEdge;
  final Color selected;
  final Color target;
  final Color targetGlow;
  final Color correctGlow;
  final Color correctFill;
}
