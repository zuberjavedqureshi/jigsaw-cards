import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flutter/animation.dart' show Curves;
import 'package:puzzle_domain/puzzle_domain.dart';

import '../artwork/puzzle_artwork.dart';
import '../ui/play_area_layout.dart';
import 'puzzle_game_bridge.dart';

/// Flame scene for one puzzle: board, locked pieces and the piece being
/// dragged. Rendering and animation only; no rules (the domain decides) and
/// no Riverpod (ADR-0001).
class PuzzleGame extends FlameGame implements PuzzleGameView {
  PuzzleGame({
    required this.layout,
    required this.artwork,
    required this.intents,
    Iterable<PuzzlePiece> lockedPieces = const [],
  }) : _initiallyLocked = lockedPieces.toList();

  static const pickUpDuration = 0.12;
  static const snapDuration = 0.18;
  static const returnDuration = 0.28;

  final PuzzleLayout layout;
  final PuzzleArtwork artwork;
  final PuzzleGameIntents intents;
  final List<PuzzlePiece> _initiallyLocked;

  late PlayAreaLayout area;
  late final BoardComponent board;
  final Map<String, LockedPieceComponent> lockedById = {};
  FloatingPieceComponent? floating;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    area = PlayAreaLayout.compute(size.toSize(), layout.grid);
    board = BoardComponent(layout.grid);
    add(board);
    for (final piece in _initiallyLocked) {
      _addLocked(piece, pulse: false);
    }
    _relayout();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) {
      area = PlayAreaLayout.compute(size.toSize(), layout.grid);
      _relayout();
    }
  }

  void _relayout() {
    board
      ..position = area.board.topLeft.toVector2()
      ..size = area.board.size.toVector2();
    for (final locked in lockedById.values) {
      final r = area.pieceRectAt(locked.piece.correctOrigin, locked.piece.size);
      locked
        ..position = r.center.toVector2()
        ..size = r.size.toVector2();
    }
  }

  void _addLocked(PuzzlePiece piece, {required bool pulse}) {
    final r = area.pieceRectAt(piece.correctOrigin, piece.size);
    final c = LockedPieceComponent(piece, artwork, layout.grid)
      ..position = r.center.toVector2()
      ..size = r.size.toVector2();
    lockedById[piece.id] = c;
    add(c);
    if (pulse) {
      c.add(
        ScaleEffect.by(
          Vector2.all(1.06),
          EffectController(duration: 0.09, reverseDuration: 0.12),
        ),
      );
    }
  }

  Size _boardPieceSize(PuzzlePiece p) =>
      Size(p.size.columnSpan * area.cellSize, p.size.rowSpan * area.cellSize);

  // ---- PuzzleGameView ----------------------------------------------------

  @override
  void beginDrag(PuzzlePiece piece, Offset pointer, Rect previewRect) {
    floating?.removeFromParent();
    final fx = ((pointer.dx - previewRect.left) / previewRect.width).clamp(
      0.0,
      1.0,
    );
    final fy = ((pointer.dy - previewRect.top) / previewRect.height).clamp(
      0.0,
      1.0,
    );
    final f =
        FloatingPieceComponent(
            piece,
            artwork,
            layout.grid,
            grab: Offset(fx, fy),
            previewRect: previewRect,
          )
          ..anchor = Anchor(fx, fy)
          ..position = pointer.toVector2()
          ..size = previewRect.size.toVector2()
          ..priority = 100;
    // Picking up enlarges the piece to board scale (GP-18).
    f.add(
      SizeEffect.to(
        _boardPieceSize(piece).toVector2(),
        EffectController(duration: pickUpDuration, curve: Curves.easeOut),
      ),
    );
    floating = f;
    add(f);
  }

  @override
  void updateDrag(Offset pointer) {
    final f = floating;
    if (f == null || f.settling) return;
    f.position = pointer.toVector2();
    board.hoverRect = _candidateRect(f, pointer);
  }

  Offset _topLeftAtBoardScale(FloatingPieceComponent f, Offset pointer) {
    final s = _boardPieceSize(f.piece);
    return pointer - Offset(f.grab.dx * s.width, f.grab.dy * s.height);
  }

  /// Highlight of the cells the piece would snap to, if on the board. Shows
  /// where the piece would land, not whether it is correct.
  Rect? _candidateRect(FloatingPieceComponent f, Offset pointer) {
    final origin = area.nearestOrigin(_topLeftAtBoardScale(f, pointer));
    final fits = f.piece.cellsAt(origin).every(layout.grid.contains);
    return fits ? area.pieceRectAt(origin, f.piece.size) : null;
  }

  @override
  void endDrag(Offset pointer) {
    final f = floating;
    if (f == null || f.settling) return;
    board.hoverRect = null;
    f.position = pointer.toVector2();
    final target = area.nearestOrigin(_topLeftAtBoardScale(f, pointer));
    intents.onDropRequested(f.piece.id, target);
  }

  @override
  void animateLock(String pieceId) {
    final f = floating;
    if (f == null || f.piece.id != pieceId) return;
    f.settling = true;
    final r = area.pieceRectAt(f.piece.correctOrigin, f.piece.size);
    final anchorPoint = Offset(
      r.left + f.grab.dx * r.width,
      r.top + f.grab.dy * r.height,
    );
    f
      ..add(
        SizeEffect.to(
          r.size.toVector2(),
          EffectController(duration: snapDuration),
        ),
      )
      ..add(
        MoveToEffect(
          anchorPoint.toVector2(),
          EffectController(duration: snapDuration, curve: Curves.easeOutCubic),
          onComplete: () {
            f.removeFromParent();
            if (floating == f) floating = null;
            _addLocked(f.piece, pulse: true);
            intents.onLockComplete(f.piece.id);
          },
        ),
      );
  }

  @override
  void animateReturn(String pieceId) {
    final f = floating;
    if (f == null || f.piece.id != pieceId) return;
    f.settling = true;
    final p = f.previewRect;
    final anchorPoint = Offset(
      p.left + f.grab.dx * p.width,
      p.top + f.grab.dy * p.height,
    );
    f
      ..rejected = true
      ..add(
        SizeEffect.to(
          p.size.toVector2(),
          EffectController(duration: returnDuration),
        ),
      )
      ..add(
        MoveToEffect(
          anchorPoint.toVector2(),
          EffectController(
            duration: returnDuration,
            curve: Curves.easeInOutBack,
          ),
          onComplete: () {
            f.removeFromParent();
            if (floating == f) floating = null;
            intents.onReturnComplete(f.piece.id);
          },
        ),
      );
  }
}

/// Board frame, cells and the drop highlight.
class BoardComponent extends PositionComponent {
  BoardComponent(this.grid);

  final GridSize grid;

  /// Board-space rect (game coordinates) of the current drop candidate.
  Rect? hoverRect;

  @override
  void render(Canvas canvas) {
    final rect = Offset.zero & size.toSize();
    final pad = size.x * 0.018;
    // Frame.
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.inflate(pad), Radius.circular(pad * 1.6)),
      Paint()..color = const Color(0xFF6B4A2B),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.inflate(pad * 0.45), Radius.circular(pad)),
      Paint()..color = const Color(0xFFD9B86C),
    );
    // Parchment surface.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = Gradient.radial(rect.center, rect.width * 0.75, const [
          Color(0xFFF7EBCB),
          Color(0xFFE6D2A2),
        ]),
    );
    // Cell grid.
    final cell = size.x / grid.columns;
    final line = Paint()
      ..color = const Color(0x557A5A33)
      ..strokeWidth = 1;
    for (var c = 1; c < grid.columns; c++) {
      canvas.drawLine(Offset(c * cell, 0), Offset(c * cell, size.y), line);
    }
    for (var r = 1; r < grid.rows; r++) {
      canvas.drawLine(Offset(0, r * cell), Offset(size.x, r * cell), line);
    }
    final h = hoverRect;
    if (h != null) {
      final local = h.shift(-position.toOffset());
      canvas.drawRRect(
        RRect.fromRectAndRadius(local.deflate(2), const Radius.circular(6)),
        Paint()..color = const Color(0x40FFC94D),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(local.deflate(2), const Radius.circular(6)),
        Paint()
          ..color = const Color(0xCCFFB627)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }
}

/// Paints a piece's artwork region into its bounds.
mixin PieceArt on PositionComponent {
  PuzzlePiece get piece;
  PuzzleArtwork get artwork;
  GridSize get grid;

  void paintArt(Canvas canvas, {double radius = 3}) {
    paintPieceRegion(
      canvas,
      artwork,
      Offset.zero & size.toSize(),
      row: piece.correctOrigin.row,
      column: piece.correctOrigin.column,
      rowSpan: piece.size.rowSpan,
      columnSpan: piece.size.columnSpan,
      gridRows: grid.rows,
      gridColumns: grid.columns,
      cornerRadius: radius,
    );
  }
}

/// A piece locked at its correct position (GP-15). Not interactive.
class LockedPieceComponent extends PositionComponent with PieceArt {
  LockedPieceComponent(this.piece, this.artwork, this.grid)
    : super(anchor: Anchor.center);

  @override
  final PuzzlePiece piece;
  @override
  final PuzzleArtwork artwork;
  @override
  final GridSize grid;

  @override
  void render(Canvas canvas) {
    paintArt(canvas, radius: 1.5);
    canvas.drawRect(
      (Offset.zero & size.toSize()).deflate(0.5),
      Paint()
        ..color = const Color(0x66FFF6DA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }
}

/// The piece under the player's finger (or animating to/from the board).
class FloatingPieceComponent extends PositionComponent with PieceArt {
  FloatingPieceComponent(
    this.piece,
    this.artwork,
    this.grid, {
    required this.grab,
    required this.previewRect,
  });

  @override
  final PuzzlePiece piece;
  @override
  final PuzzleArtwork artwork;
  @override
  final GridSize grid;

  /// Grab point as a fraction of the piece (also the component's anchor).
  final Offset grab;
  final Rect previewRect;

  /// True once a lock or return animation has started.
  bool settling = false;
  bool rejected = false;

  @override
  void render(Canvas canvas) {
    final rect = Offset.zero & size.toSize();
    // Lift shadow.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.shift(const Offset(0, 6)),
        const Radius.circular(6),
      ),
      Paint()
        ..color = const Color(0x55000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    paintArt(canvas, radius: 5);
    // Selection outline: gold while held, rose while returning.
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(1), const Radius.circular(5)),
      Paint()
        ..color = rejected ? const Color(0xFFE5737F) : const Color(0xFFFFC94D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }
}
