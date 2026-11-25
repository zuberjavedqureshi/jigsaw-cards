import 'dart:math' as math;
import 'dart:ui';

import 'package:puzzle_domain/puzzle_domain.dart';

/// Screen geometry of the play area, shared by the Flutter tray and the
/// Flame board so both agree exactly. Derived from the available size: no
/// hardcoded screen coordinates (Development Rule 6).
class PlayAreaLayout {
  const PlayAreaLayout({
    required this.board,
    required this.tray,
    required this.cellSize,
    required this.trayTile,
  });

  /// Tray: two rows (GP-16) of square tiles. 72 dp tiles keep touch targets
  /// well above the 48 dp Android minimum (GP-17; the exact comfortable size
  /// is not product-approved, so this value is provisional).
  static const trayTileSize = 72.0;
  static const trayGap = 10.0;
  static const trayPadding = 12.0;
  static const margin = 16.0;

  static double get trayHeight => 2 * trayTileSize + trayGap + 2 * trayPadding;

  final Rect board;
  final Rect tray;
  final double cellSize;
  final double trayTile;

  static PlayAreaLayout compute(Size size, GridSize grid) {
    final trayRect = Rect.fromLTWH(
      margin,
      size.height - trayHeight - margin,
      math.max(0, size.width - 2 * margin),
      trayHeight,
    );
    final availableW = size.width - 2 * margin;
    final availableH = trayRect.top - 2 * margin;
    final cell = math.max(
      0.0,
      math.min(availableW / grid.columns, availableH / grid.rows),
    );
    final boardW = cell * grid.columns;
    final boardH = cell * grid.rows;
    final board = Rect.fromLTWH(
      (size.width - boardW) / 2,
      margin + (availableH - boardH) / 2,
      boardW,
      boardH,
    );
    return PlayAreaLayout(
      board: board,
      tray: trayRect,
      cellSize: cell,
      trayTile: trayTileSize,
    );
  }

  /// Board rect for a piece whose top-left cell is [origin].
  Rect pieceRectAt(GridCell origin, PieceSize size) => Rect.fromLTWH(
    board.left + origin.column * cellSize,
    board.top + origin.row * cellSize,
    size.columnSpan * cellSize,
    size.rowSpan * cellSize,
  );

  /// Nearest cell for a piece whose top-left corner is at [topLeft]. This
  /// is the magnetic-snap candidate: rounding means a drop within half a
  /// cell of a cell boundary snaps to it (provisional feel parameter).
  GridCell nearestOrigin(Offset topLeft) => GridCell(
    ((topLeft.dy - board.top) / cellSize).round(),
    ((topLeft.dx - board.left) / cellSize).round(),
  );
}
