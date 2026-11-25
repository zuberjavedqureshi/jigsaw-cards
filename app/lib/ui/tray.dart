import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:material_ui/material_ui.dart';
import 'package:puzzle_domain/puzzle_domain.dart';

import '../artwork/puzzle_artwork.dart';
import 'play_area_layout.dart';
import 'storybook_theme.dart';

/// Rect of a piece's preview inside a square tray tile of side [tile],
/// keeping the piece's aspect ratio (a 2×2 fills the tile, a 1×1 is half).
Rect previewRectInTile(double tile, PieceSize size) {
  const inset = 8.0;
  final unit = (tile - 2 * inset) / 2;
  final w = size.columnSpan * unit;
  final h = size.rowSpan * unit;
  return Rect.fromLTWH((tile - w) / 2, (tile - h) / 2, w, h);
}

/// Callbacks from the tray's drag gesture, in global coordinates.
class TrayDragCallbacks {
  const TrayDragCallbacks({
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
  });

  /// [previewGlobal] is the global rect of the piece preview that was
  /// grabbed.
  final void Function(PuzzlePiece piece, Offset global, Rect previewGlobal)
  onStart;
  final void Function(PuzzlePiece piece, Offset global) onUpdate;
  final void Function(PuzzlePiece piece) onEnd;
}

/// Two-row, horizontally scrollable tray (GP-16). A vertical drag on a
/// tile picks the piece up; a horizontal swipe scrolls the tray.
class PieceTray extends StatelessWidget {
  const PieceTray({
    super.key,
    required this.pieces,
    required this.hiddenPieceId,
    required this.artwork,
    required this.grid,
    required this.dragEnabled,
    required this.callbacks,
  });

  /// Pieces shown in the tray, in order.
  final List<PuzzlePiece> pieces;

  /// Piece currently in flight: its slot is shown empty.
  final String? hiddenPieceId;
  final PuzzleArtwork artwork;
  final GridSize grid;

  /// False while a piece is in flight, so only one piece moves at a time.
  final bool dragEnabled;
  final TrayDragCallbacks callbacks;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('tray'),
      decoration: BoxDecoration(
        color: Storybook.wood,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD9B86C), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(PlayAreaLayout.trayPadding - 2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: PlayAreaLayout.trayGap,
          crossAxisSpacing: PlayAreaLayout.trayGap,
        ),
        itemCount: pieces.length,
        itemBuilder: (context, i) => _TrayTile(
          key: Key('tray_${pieces[i].id}'),
          piece: pieces[i],
          hidden: pieces[i].id == hiddenPieceId,
          artwork: artwork,
          grid: grid,
          dragEnabled: dragEnabled,
          callbacks: callbacks,
        ),
      ),
    );
  }
}

class _TrayTile extends StatelessWidget {
  const _TrayTile({
    super.key,
    required this.piece,
    required this.hidden,
    required this.artwork,
    required this.grid,
    required this.dragEnabled,
    required this.callbacks,
  });

  final PuzzlePiece piece;
  final bool hidden;
  final PuzzleArtwork artwork;
  final GridSize grid;
  final bool dragEnabled;
  final TrayDragCallbacks callbacks;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: hidden ? 'Empty tray slot' : 'Puzzle piece',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        dragStartBehavior: DragStartBehavior.down,
        // Handlers stay attached for the whole gesture: removing them when
        // the tile rebuilds (piece picked up) would cancel the drag. The
        // host ignores starts while another piece is in flight.
        onVerticalDragStart: (d) {
          if (!dragEnabled || hidden) return;
          final box = context.findRenderObject()! as RenderBox;
          final local = previewRectInTile(box.size.shortestSide, piece.size);
          final topLeft = box.localToGlobal(local.topLeft);
          callbacks.onStart(piece, d.globalPosition, topLeft & local.size);
        },
        onVerticalDragUpdate: (d) =>
            callbacks.onUpdate(piece, d.globalPosition),
        onVerticalDragEnd: (_) => callbacks.onEnd(piece),
        onVerticalDragCancel: () => callbacks.onEnd(piece),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF8A6440),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0x55FFF6DA)),
          ),
          child: hidden
              ? const SizedBox.expand()
              : CustomPaint(
                  painter: _PiecePreviewPainter(piece, artwork, grid),
                  child: const SizedBox.expand(),
                ),
        ),
      ),
    );
  }
}

class _PiecePreviewPainter extends CustomPainter {
  _PiecePreviewPainter(this.piece, this.artwork, this.grid);

  final PuzzlePiece piece;
  final PuzzleArtwork artwork;
  final GridSize grid;

  @override
  void paint(Canvas canvas, Size size) {
    final r = previewRectInTile(size.shortestSide, piece.size);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        r.shift(const Offset(0, 2)),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0x55000000),
    );
    paintPieceRegion(
      canvas,
      artwork,
      r,
      row: piece.correctOrigin.row,
      column: piece.correctOrigin.column,
      rowSpan: piece.size.rowSpan,
      columnSpan: piece.size.columnSpan,
      gridRows: grid.rows,
      gridColumns: grid.columns,
      cornerRadius: 5,
    );
  }

  @override
  bool shouldRepaint(_PiecePreviewPainter old) =>
      old.piece != piece || old.artwork != artwork;
}
