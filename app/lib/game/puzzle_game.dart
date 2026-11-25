import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flutter/animation.dart' show Curve, Curves;
import 'package:puzzle_domain/puzzle_domain.dart';

import '../artwork/puzzle_artwork.dart';
import '../ui/play_area_layout.dart';
import 'puzzle_game_bridge.dart';

/// Flame scene for one free-placement memory puzzle: the board, every piece
/// (face-down or face-up), flips, dragging, stacking and snap-and-lock
/// animations. Rules live in the domain; state arrives through
/// [syncSession] and requests leave through [PuzzleGameIntents] (ADR-0001).
/// No Riverpod here.
class PuzzleGame extends FlameGame implements PuzzleGameView {
  PuzzleGame({
    required PuzzleSession session,
    required this.artwork,
    required this.intents,
  }) : _session = session; // ignore: prefer_initializing_formals

  static const flipDuration = 0.34;
  static const flipStagger = 0.045;
  static const snapDuration = 0.2;
  static const settleDuration = 0.14;

  final PuzzleArtwork artwork;
  final PuzzleGameIntents intents;

  PuzzleSession _session;
  PuzzleSession get session => _session;

  late BoardLayout area;
  late final BoardComponent board;
  final Map<String, PieceComponent> pieces = {};

  /// Pieces still running a whole-board flip (preview start or end).
  int _bulkFlipsPending = 0;

  String? draggingId;
  int? _dragPointer;
  Offset _grab = Offset.zero;

  /// Input is accepted only in memory mode, after the flip-down finished.
  bool get inputEnabled => _session.isInteractive && _bulkFlipsPending == 0;

  /// True while any piece is flipping or moving.
  bool get isAnimating =>
      pieces.values.any((p) => p.isFlipping || p.isMoving) ||
      _bulkFlipsPending > 0;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    area = BoardLayout.compute(size.toSize(), _session.bounds);
    board = BoardComponent(_session.layout.grid);
    add(board);
    for (final s in _session.pieces) {
      final c = PieceComponent(
        s.piece,
        artwork,
        _session.layout.grid,
        faceUp: _session.isFaceUp(s.id),
        locked: s.locked,
      )..boardPosition = s.position;
      pieces[s.id] = c;
      add(c);
    }
    add(InputLayer()..priority = 1 << 20);
    _relayout();
    _applyStack();
    intents.onReady();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) {
      area = BoardLayout.compute(size.toSize(), _session.bounds);
      _relayout();
    }
  }

  void _relayout() {
    board
      ..position = area.workspace.topLeft.toVector2()
      ..size = area.workspace.size.toVector2()
      ..gridRect = area
          .gridRect(_session.layout.grid)
          .shift(-area.workspace.topLeft);
    for (final c in pieces.values) {
      c.size = area.pieceSize(c.piece.size).toVector2();
      if (c.piece.id != draggingId) {
        c.position = _centreOf(c.boardPosition, c.piece.size);
      }
    }
  }

  Vector2 _centreOf(BoardPoint topLeft, PieceSize s) =>
      area.pieceRect(topLeft, s).center.toVector2();

  void _applyStack() {
    final order = _session.stackOrder;
    for (var i = 0; i < order.length; i++) {
      final c = pieces[order[i]]!;
      if (c.piece.id != draggingId) c.priority = i + 1;
    }
  }

  // ---- PuzzleGameView ----------------------------------------------------

  @override
  void syncSession(PuzzleSession next) {
    final prev = _session;
    _session = next;
    if (!isLoaded) return;

    if (prev.phase == PuzzlePhase.intro && next.phase == PuzzlePhase.preview) {
      _bulkFlip(faceUp: true, onAllDone: intents.onPreviewShown);
    } else if (prev.phase == PuzzlePhase.preview &&
        next.phase == PuzzlePhase.playing) {
      _bulkFlip(faceUp: false, onAllDone: () {});
    } else {
      for (final s in next.pieces) {
        final c = pieces[s.id]!;
        final up = next.isFaceUp(s.id);
        if (c.targetFaceUp != up) c.flipTo(up);
      }
    }

    for (final s in next.pieces) {
      final c = pieces[s.id]!;
      final wasLocked = prev.piece(s.id)!.locked;
      if (s.locked && !wasLocked) {
        _snapAndLock(c, s);
      } else if (s.position != c.boardPosition && s.id != draggingId) {
        c.boardPosition = s.position;
        c.moveTo(_centreOf(s.position, s.piece.size), settleDuration);
      }
    }
    _applyStack();
  }

  void _bulkFlip({required bool faceUp, required void Function() onAllDone}) {
    final targets = [
      for (final id in _session.stackOrder)
        if (pieces[id]!.targetFaceUp != (faceUp ? true : _session.isFaceUp(id)))
          pieces[id]!,
    ];
    if (targets.isEmpty) {
      onAllDone();
      return;
    }
    _bulkFlipsPending = targets.length;
    for (var i = 0; i < targets.length; i++) {
      targets[i].flipTo(
        faceUp,
        delay: i * flipStagger,
        onDone: () {
          _bulkFlipsPending--;
          if (_bulkFlipsPending == 0) onAllDone();
        },
      );
    }
  }

  void _snapAndLock(PieceComponent c, PieceState s) {
    c
      ..boardPosition = s.position
      ..locked = true
      ..lifted = false;
    c.moveTo(
      _centreOf(s.position, s.piece.size),
      snapDuration,
      onDone: () {
        c.add(
          ScaleEffect.by(
            Vector2.all(1.05),
            EffectController(duration: 0.08, reverseDuration: 0.14),
          ),
        );
        add(
          SparkleRing(area.pieceRect(s.position, s.piece.size))
            ..priority = 1 << 19,
        );
        intents.onLockComplete(s.id);
      },
    );
  }

  // ---- Input (called by InputLayer) ----------------------------------------

  PieceState? _hit(Vector2 canvasPoint) =>
      _session.topmostSelectableAt(area.toBoard(canvasPoint.toOffset()));

  void handleTap(Vector2 canvasPoint) {
    if (!inputEnabled || draggingId != null) return;
    final hit = _hit(canvasPoint);
    if (hit == null) return;
    if (_session.isFaceUp(hit.id)) {
      pieces[hit.id]!.bounce();
      intents.onSelected(hit.id);
    } else {
      intents.onRevealRequested(hit.id);
    }
  }

  void handleDragStart(int pointer, Vector2 canvasPoint) {
    if (!inputEnabled || draggingId != null) return;
    final hit = _hit(canvasPoint);
    if (hit == null) return;
    final c = pieces[hit.id]!;
    if (!_session.isFaceUp(hit.id)) {
      // Face-down pieces are revealed by tapping, not dragged.
      c.shake();
      return;
    }
    c.stopMoving();
    draggingId = hit.id;
    _dragPointer = pointer;
    final topLeft = area.toScreen(c.boardPosition);
    _grab = canvasPoint.toOffset() - topLeft;
    c
      ..lifted = true
      ..priority = 1 << 18;
    intents.onSelected(hit.id);
  }

  void handleDragUpdate(int pointer, Vector2 canvasPoint) {
    final id = draggingId;
    if (id == null || pointer != _dragPointer) return;
    final c = pieces[id]!;
    final clamped = _clampedTopLeft(c, canvasPoint);
    c.position = _centreOf(clamped, c.piece.size);
  }

  BoardPoint _clampedTopLeft(PieceComponent c, Vector2 canvasPoint) => _session
      .bounds
      .clampOrigin(area.toBoard(canvasPoint.toOffset() - _grab), c.piece.size);

  void handleDragEnd(int pointer) {
    final id = draggingId;
    if (id == null || pointer != _dragPointer) return;
    final c = pieces[id]!;
    final topLeft = area.toBoard((c.position - c.size / 2).toOffset());
    draggingId = null;
    _dragPointer = null;
    c
      ..lifted = false
      ..boardPosition = topLeft;
    intents.onDropRequested(id, topLeft);
  }
}

/// Full-size, topmost input surface. Taps reveal or select; drags move
/// face-up pieces. Hit testing is done against the domain stack so
/// overlapping pieces resolve to the topmost selectable one.
class InputLayer extends PositionComponent
    with TapCallbacks, DragCallbacks, HasGameReference<PuzzleGame> {
  @override
  bool containsLocalPoint(Vector2 point) => true;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  void onTapUp(TapUpEvent event) => game.handleTap(event.canvasPosition);

  /// Reported at the initial touch point, so the grab offset is exact.
  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    game.handleDragStart(event.pointerId, event.canvasPosition);
  }

  /// `DragUpdateEvent.canvasStartPosition` is the pointer's current
  /// position. (`canvasEndPosition` adds the delta to a global position that
  /// already includes it, overshooting by one movement step in Flame 1.38.)
  @override
  void onDragUpdate(DragUpdateEvent event) =>
      game.handleDragUpdate(event.pointerId, event.canvasStartPosition);

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    game.handleDragEnd(event.pointerId);
  }
}

/// The parchment workspace with the framed 4×4 target area.
class BoardComponent extends PositionComponent {
  BoardComponent(this.grid);

  final GridSize grid;

  /// Target grid rect in this component's local coordinates.
  Rect gridRect = Rect.zero;

  @override
  void render(Canvas canvas) {
    final rect = Offset.zero & size.toSize();
    final r = math.max(10.0, size.x * 0.035);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.shift(const Offset(0, 5)),
        Radius.circular(r),
      ),
      Paint()
        ..color = const Color(0x55000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(r)),
      Paint()..color = const Color(0xFF6B4A2B),
    );
    final inner = rect.deflate(math.max(4.0, size.x * 0.012));
    canvas.drawRRect(
      RRect.fromRectAndRadius(inner, Radius.circular(r * 0.8)),
      Paint()
        ..shader = Gradient.radial(
          inner.center,
          inner.longestSide * 0.7,
          const [Color(0xFFF7EBCB), Color(0xFFE3CD98)],
        ),
    );
    // Target picture area: recessed, framed, with faint cell lines.
    final g = gridRect;
    if (g.isEmpty) return;
    canvas.drawRect(g, Paint()..color = const Color(0x33805A2E));
    final cell = g.width / grid.columns;
    final line = Paint()
      ..color = const Color(0x407A5A33)
      ..strokeWidth = 1;
    for (var c = 1; c < grid.columns; c++) {
      canvas.drawLine(
        Offset(g.left + c * cell, g.top),
        Offset(g.left + c * cell, g.bottom),
        line,
      );
    }
    for (var row = 1; row < grid.rows; row++) {
      canvas.drawLine(
        Offset(g.left, g.top + row * cell),
        Offset(g.right, g.top + row * cell),
        line,
      );
    }
    canvas.drawRect(
      g.inflate(2),
      Paint()
        ..color = const Color(0xFFC9A04E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }
}

/// One puzzle piece. Renders its card back or its image fragment, with a
/// horizontal flip between them, a lift when selected and a gold edge once
/// locked.
class PieceComponent extends PositionComponent {
  PieceComponent(
    this.piece,
    this.artwork,
    this.grid, {
    required bool faceUp,
    this.locked = false,
  }) : _face = faceUp ? 1 : 0,
       targetFaceUp = faceUp,
       super(anchor: Anchor.center);

  final PuzzlePiece piece;
  final PuzzleArtwork artwork;
  final GridSize grid;

  /// Board position this component rests at (or is animating to).
  BoardPoint boardPosition = BoardPoint.zero;

  bool locked;
  bool lifted = false;

  /// 0 = back fully shown, 1 = front fully shown.
  double _face;
  bool targetFaceUp;
  double _flipFrom = 0;
  double _flipElapsed = 0;
  double _flipDelay = 0;
  bool _flipping = false;
  void Function()? _flipDone;

  bool get isFlipping => _flipping;
  bool get showsFront => _face >= 0.5;
  bool get isMoving => children.whereType<MoveEffect>().isNotEmpty;

  Picture? _front;
  Size? _frontSize;

  void flipTo(bool up, {double delay = 0, void Function()? onDone}) {
    targetFaceUp = up;
    _flipFrom = _face;
    _flipElapsed = 0;
    _flipDelay = delay;
    _flipping = true;
    _flipDone = onDone;
  }

  void stopMoving() {
    for (final e in children.whereType<MoveEffect>().toList()) {
      e.removeFromParent();
    }
  }

  void moveTo(
    Vector2 centre,
    double duration, {
    Curve curve = Curves.easeOutCubic,
    void Function()? onDone,
  }) {
    stopMoving();
    if ((centre - position).length < 0.5) {
      position = centre;
      onDone?.call();
      return;
    }
    // Non-overshooting curves only: Flame applies moves incrementally, and
    // the final position is set exactly on completion.
    add(
      MoveToEffect(
        centre,
        EffectController(duration: duration, curve: curve),
        onComplete: () {
          position = centre;
          onDone?.call();
        },
      ),
    );
  }

  void bounce() => add(
    ScaleEffect.by(
      Vector2.all(1.06),
      EffectController(duration: 0.07, reverseDuration: 0.1),
    ),
  );

  void shake() => add(
    MoveByEffect(
      Vector2(size.x * 0.04, 0),
      EffectController(duration: 0.05, reverseDuration: 0.05, repeatCount: 2),
    ),
  );

  @override
  void update(double dt) {
    super.update(dt);
    if (!_flipping) return;
    if (_flipDelay > 0) {
      _flipDelay -= dt;
      if (_flipDelay > 0) return;
      dt = -_flipDelay;
      _flipDelay = 0;
    }
    _flipElapsed += dt;
    final target = targetFaceUp ? 1.0 : 0.0;
    final t = (_flipElapsed / PuzzleGame.flipDuration).clamp(0.0, 1.0);
    _face = _flipFrom + (target - _flipFrom) * Curves.easeInOut.transform(t);
    if (t >= 1) {
      _face = target;
      _flipping = false;
      final done = _flipDone;
      _flipDone = null;
      done?.call();
    }
  }

  Picture _frontPicture(Size s) {
    if (_front == null || _frontSize != s) {
      final rec = PictureRecorder();
      paintPieceRegion(
        Canvas(rec),
        artwork,
        Offset.zero & s,
        row: piece.correctOrigin.row,
        column: piece.correctOrigin.column,
        rowSpan: piece.size.rowSpan,
        columnSpan: piece.size.columnSpan,
        gridRows: grid.rows,
        gridColumns: grid.columns,
        cornerRadius: 0,
      );
      _front?.dispose();
      _front = rec.endRecording();
      _frontSize = s;
    }
    return _front!;
  }

  @override
  void onRemove() {
    _front?.dispose();
    _front = null;
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    final s = size.toSize();
    final rect = Offset.zero & s;
    // Flip: squash horizontally through edge-on, with a small lift.
    final edge = math.cos(math.pi * _face).abs();
    final flipLift = 1 + 0.07 * math.sin(math.pi * _face);
    final lift = lifted ? 1.06 : 1.0;
    canvas.save();
    canvas.translate(s.width / 2, s.height / 2);
    canvas.scale(math.max(edge, 0.02) * flipLift * lift, flipLift * lift);
    canvas.translate(-s.width / 2, -s.height / 2);

    final radius = locked ? 1.5 : math.min(s.width, s.height) * 0.07;
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    if (!locked) {
      canvas.drawRRect(
        rr.shift(Offset(0, lifted ? 7 : 3)),
        Paint()
          ..color = Color(lifted ? 0x66000000 : 0x40000000)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, lifted ? 7 : 3),
      );
    }
    if (showsFront) {
      canvas.save();
      canvas.clipRRect(rr);
      canvas.drawPicture(_frontPicture(s));
      canvas.restore();
      canvas.drawRRect(
        rr.deflate(0.5),
        Paint()
          ..color = locked ? const Color(0x55FFF6DA) : const Color(0xCCFFF1C9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = locked ? 1 : 1.5,
      );
    } else {
      paintCardBack(canvas, rect, cornerRadius: radius);
    }
    if (lifted) {
      canvas.drawRRect(
        rr.inflate(1.5),
        Paint()
          ..color = const Color(0xFFFFC94D)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    canvas.restore();
  }
}

/// Short-lived golden ring and sparks around a newly locked piece.
class SparkleRing extends PositionComponent {
  SparkleRing(this.rect);

  final Rect rect;
  static const duration = 0.55;
  double _t = 0;

  @override
  void update(double dt) {
    _t += dt;
    if (_t >= duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final p = (_t / duration).clamp(0.0, 1.0);
    final alpha = ((1 - p) * 255).round();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.inflate(2 + p * 10),
        const Radius.circular(6),
      ),
      Paint()
        ..color = Color.fromARGB(alpha, 255, 214, 110)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * (1 - p) + 0.5,
    );
    final spark = Paint()..color = Color.fromARGB(alpha, 255, 241, 196);
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + p;
      final d = rect.shortestSide * (0.55 + p * 0.45);
      canvas.drawCircle(
        rect.center + Offset(math.cos(a) * d, math.sin(a) * d),
        2.2 * (1 - p) + 0.4,
        spark,
      );
    }
  }
}
