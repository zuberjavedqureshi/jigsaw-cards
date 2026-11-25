import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flutter/animation.dart' show Curves;
import 'package:puzzle_domain/puzzle_domain.dart';

import '../artwork/puzzle_artwork.dart';
import '../ui/play_area_layout.dart';
import 'puzzle_game_bridge.dart';

/// Flame scene for one picture-swap puzzle: the board, the tiles, the drag,
/// the exchange animation and the completion shine. The rules live in the
/// domain; state arrives through [syncPuzzle] and requests leave through
/// [PuzzleGameIntents] (ADR-0001). No Riverpod here.
class PuzzleGame extends FlameGame implements PuzzleGameView {
  PuzzleGame({
    required PicturePuzzle puzzle,
    required this.artwork,
    required this.intents,
  }) : _puzzle = puzzle; // ignore: prefer_initializing_formals

  static const swapDuration = 0.22;
  static const returnDuration = 0.18;

  final PuzzleArtwork artwork;
  final PuzzleGameIntents intents;

  PicturePuzzle _puzzle;
  PicturePuzzle get puzzle => _puzzle;

  late BoardLayout area;
  late final BoardFrame frame;
  final Map<int, TileComponent> tiles = {};

  /// Tile animations still running (swap or cancel). Input waits for 0.
  int _moving = 0;
  bool _celebrating = false;

  TileComponent? _pressed;
  TileComponent? _dragged;
  int? _dragPointer;
  GridCell? _dragFrom;
  Offset _grab = Offset.zero;
  TileComponent? _hovered;

  /// Accepts a new press or drag only when nothing is animating, so a
  /// second swap can never start while the board is settling.
  bool get inputEnabled => !_puzzle.isComplete && _moving == 0 && !_celebrating;
  bool get isAnimating => _moving > 0 || _celebrating;
  TileComponent? get draggedTile => _dragged;
  TileComponent? get hoveredTile => _hovered;

  @override
  Color backgroundColor() => const Color(0x00000000);

  Rect _srcRect(PictureTile t) {
    final r = _puzzle.sourceRectOf(t);
    return Rect.fromLTWH(r.left, r.top, r.width, r.height);
  }

  @override
  Future<void> onLoad() async {
    area = BoardLayout.compute(size.toSize(), _puzzle.grid, artwork.sourceSize);
    frame = BoardFrame();
    add(frame);
    for (final t in _puzzle.tiles) {
      final c = TileComponent(t, artwork, _srcRect(t))
        ..correct = _puzzle.isTileCorrect(t);
      tiles[t.id] = c;
      add(c);
    }
    add(InputLayer()..priority = 1 << 20);
    _relayout();
  }

  /// Flame calls this on every widget rebuild, not only on real size
  /// changes; relaying out unconditionally would cancel tile animations.
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (!isLoaded) return;
    final next = BoardLayout.compute(
      size.toSize(),
      _puzzle.grid,
      artwork.sourceSize,
    );
    if (next.board == area.board) return;
    area = next;
    _relayout();
  }

  Vector2 _centreOf(GridCell c) => area.cellRect(c).center.toVector2();

  void _relayout() {
    frame
      ..position = area.board.topLeft.toVector2()
      ..size = area.board.size.toVector2();
    for (final t in _puzzle.tiles) {
      final c = tiles[t.id]!;
      c.size = Vector2(area.cellWidth, area.cellHeight);
      if (c == _dragged) continue;
      final centre = _centreOf(_puzzle.cellOf(t));
      if (c.isMoving) {
        // Real resize mid-animation: re-aim at the tile's cell (a returning
        // tile's cell is still its original one), keeping its callback.
        c.retarget(centre);
      } else {
        c
          ..position = centre
          ..priority = 1;
      }
    }
  }

  // ---- PuzzleGameView ----------------------------------------------------

  @override
  void syncPuzzle(PicturePuzzle next) {
    final prev = _puzzle;
    _puzzle = next;
    if (!isLoaded) return;
    final moved = [
      for (final t in next.tiles)
        if (prev.cellOf(t) != next.cellOf(t)) tiles[t.id]!,
    ];
    if (moved.isEmpty) return;
    _moving += moved.length;
    for (final c in moved) {
      // The dragged tile flies from under the finger; the displaced tile
      // slides across, raised just below it.
      c.priority = c == _dragged ? 1 << 18 : 1 << 17;
      c.moveTo(
        _centreOf(next.cellOf(c.tile)),
        swapDuration,
        onDone: () => _onMoveDone(c),
      );
    }
    _dragged = null;
  }

  void _onMoveDone(TileComponent c) {
    c
      ..lifted = false
      ..pressed = false
      ..priority = 1;
    final nowCorrect = _puzzle.isTileCorrect(c.tile);
    if (nowCorrect && !c.correct) c.celebrateCorrect();
    c.correct = nowCorrect;
    _moving--;
    if (_moving > 0) return;
    // Settled: every tile rests exactly at its logical cell.
    _relayout();
    intents.onSwapSettled();
    if (_puzzle.isComplete) {
      _celebrating = true;
      add(
        CompletionShine(
          area.board,
          onDone: () {
            _celebrating = false;
            intents.onCompletionShown();
          },
        )..priority = 1 << 19,
      );
    }
  }

  // ---- Input (called by InputLayer) ----------------------------------------

  TileComponent? _tileAt(Offset p) {
    final cell = area.cellAt(p);
    return cell == null ? null : tiles[_puzzle.tileAt(cell).id];
  }

  /// Pointer down: immediate press feedback on the tile.
  void handlePress(Vector2 point) {
    if (!inputEnabled || _dragged != null) return;
    _pressed?.pressed = false;
    _pressed = _tileAt(point.toOffset())?..pressed = true;
  }

  /// Pointer up without a drag (or a tap cancelled): clear the press.
  void handleRelease() {
    if (_dragged != null) return;
    _pressed?.pressed = false;
    _pressed = null;
  }

  void handleDragStart(int pointer, Vector2 point) {
    if (!inputEnabled || _dragged != null) return;
    final p = point.toOffset();
    final cell = area.cellAt(p);
    if (cell == null) return;
    final c = tiles[_puzzle.tileAt(cell).id]!;
    _pressed?.pressed = false;
    _pressed = null;
    _dragged = c;
    _dragPointer = pointer;
    _dragFrom = cell;
    _grab = p - area.cellRect(cell).center;
    c
      ..stopMoving()
      ..lifted = true
      ..priority = 1 << 18;
  }

  void handleDragUpdate(int pointer, Vector2 point) {
    final c = _dragged;
    if (c == null || pointer != _dragPointer) return;
    final p = point.toOffset();
    // Keep the dragged tile's centre on the play area.
    final centre = p - _grab;
    c.position = Vector2(
      centre.dx.clamp(0, size.x),
      centre.dy.clamp(0, size.y),
    );
    final over = area.cellAt(p);
    final target = (over == null || over == _dragFrom)
        ? null
        : tiles[_puzzle.tileAt(over).id];
    if (target != _hovered) {
      _hovered?.hovered = false;
      _hovered = target?..hovered = true;
    }
  }

  void handleDragEnd(int pointer) {
    final c = _dragged;
    if (c == null || pointer != _dragPointer) return;
    final target = _hovered;
    _hovered?.hovered = false;
    _hovered = null;
    _dragPointer = null;
    final from = _dragFrom!;
    _dragFrom = null;
    if (target != null) {
      intents.onSwapRequested(from, _puzzle.cellOf(target.tile));
      if (_dragged == c) _cancel(c, from); // swap was not applied
    } else {
      _cancel(c, from);
    }
  }

  /// Released outside another tile: glide back to the original cell.
  void _cancel(TileComponent c, GridCell from) {
    _dragged = null;
    _moving++;
    c.moveTo(
      _centreOf(from),
      returnDuration,
      onDone: () {
        c
          ..lifted = false
          ..priority = 1;
        _moving--;
      },
    );
  }
}

/// Full-size, topmost input surface: press feedback on pointer down, and
/// drag-and-swap. Hit testing uses the board grid, so the tile under the
/// finger is always the one in that logical cell.
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
  void onTapDown(TapDownEvent event) => game.handlePress(event.canvasPosition);

  @override
  void onTapUp(TapUpEvent event) => game.handleRelease();

  @override
  void onTapCancel(TapCancelEvent event) => game.handleRelease();

  /// Reported at the initial touch point, so the grabbed tile is exact.
  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    game.handleDragStart(event.pointerId, event.canvasPosition);
  }

  /// `canvasStartPosition` is the pointer's current position
  /// (`canvasEndPosition` overshoots by one step in Flame 1.38).
  @override
  void onDragUpdate(DragUpdateEvent event) =>
      game.handleDragUpdate(event.pointerId, event.canvasStartPosition);

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    game.handleDragEnd(event.pointerId);
  }
}

/// Frame and dark bed behind the tiles (visible under a lifted tile).
class BoardFrame extends PositionComponent {
  @override
  void render(Canvas canvas) {
    final rect = Offset.zero & size.toSize();
    final pad = math.max(5.0, size.x * 0.018);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.inflate(pad).shift(const Offset(0, 5)),
        Radius.circular(pad * 1.4),
      ),
      Paint()
        ..color = const Color(0x55000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.inflate(pad), Radius.circular(pad * 1.4)),
      Paint()..color = const Color(0xFF6B4A2B),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.inflate(pad * 0.4), Radius.circular(pad)),
      Paint()..color = const Color(0xFFD9B86C),
    );
    canvas.drawRect(rect, Paint()..color = const Color(0xFF1B1636));
  }
}

/// One picture tile: always shows its own source slice. Incorrectly placed
/// tiles have a thin light edge; correctly placed tiles are drawn edge to
/// edge so correct neighbours read as one continuous picture.
class TileComponent extends PositionComponent {
  TileComponent(this.tile, this.artwork, this.source)
    : super(anchor: Anchor.center);

  final PictureTile tile;
  final PuzzleArtwork artwork;

  /// Source region (source units).
  final Rect source;

  bool correct = false;
  bool pressed = false;
  bool lifted = false;
  bool hovered = false;

  double _glow = 0;
  Picture? _picture;
  Size? _pictureSize;

  bool get isMoving => children.whereType<MoveEffect>().isNotEmpty;

  /// Completion callback of the current move; kept across [retarget].
  void Function()? _onArrive;
  bool get isGlowing => _glow > 0;

  void stopMoving() {
    for (final e in children.whereType<MoveEffect>().toList()) {
      e.removeFromParent();
    }
  }

  void moveTo(Vector2 centre, double duration, {void Function()? onDone}) {
    stopMoving();
    _onArrive = onDone;
    add(
      MoveToEffect(
        centre,
        EffectController(duration: duration, curve: Curves.easeInOutCubic),
        onComplete: () {
          position = centre;
          final done = _onArrive;
          _onArrive = null;
          done?.call();
        },
      ),
    );
  }

  /// Sends an in-flight tile to a new centre without losing its callback.
  void retarget(Vector2 centre) => moveTo(centre, 0.12, onDone: _onArrive);

  /// Brief golden glow when the tile lands in its correct cell.
  void celebrateCorrect() => _glow = 1;

  @override
  void update(double dt) {
    super.update(dt);
    if (_glow > 0) _glow = math.max(0, _glow - dt / 0.6);
  }

  Picture _art(Size s) {
    if (_picture == null || _pictureSize != s) {
      final rec = PictureRecorder();
      paintTile(Canvas(rec), artwork, Offset.zero & s, source);
      _picture?.dispose();
      _picture = rec.endRecording();
      _pictureSize = s;
    }
    return _picture!;
  }

  @override
  void onRemove() {
    _picture?.dispose();
    _picture = null;
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    final s = size.toSize();
    final rect = Offset.zero & s;
    final scale = lifted ? 1.08 : (pressed ? 1.04 : 1.0);
    canvas.save();
    canvas.translate(s.width / 2, s.height / 2);
    canvas.scale(scale);
    canvas.translate(-s.width / 2, -s.height / 2);
    if (lifted) {
      canvas.drawRect(
        rect.shift(const Offset(0, 8)),
        Paint()
          ..color = const Color(0x77000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
    canvas.drawPicture(_art(s));
    if (!correct || lifted) {
      canvas.drawRect(
        rect.deflate(0.5),
        Paint()
          ..color = const Color(0xB3FFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
    if (hovered) {
      canvas.drawRect(rect, Paint()..color = const Color(0x33FFF1C4));
      canvas.drawRect(
        rect.deflate(1.5),
        Paint()
          ..color = const Color(0xFFFFF1C4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    if (pressed || lifted) {
      canvas.drawRect(
        rect.deflate(1),
        Paint()
          ..color = const Color(0xFFFFC94D)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    if (_glow > 0) {
      final a = (_glow * 200).round();
      canvas.drawRect(
        rect,
        Paint()..color = Color.fromARGB(a ~/ 3, 255, 236, 170),
      );
      canvas.drawRect(
        rect.deflate(1.5),
        Paint()
          ..color = Color.fromARGB(a, 255, 214, 110)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    canvas.restore();
  }
}

/// A diagonal light sweep across the finished picture.
class CompletionShine extends PositionComponent {
  CompletionShine(this.board, {required this.onDone});

  final Rect board;
  final void Function() onDone;
  static const duration = 0.9;
  double _t = 0;

  @override
  void update(double dt) {
    _t += dt;
    if (_t >= duration) {
      removeFromParent();
      onDone();
    }
  }

  @override
  void render(Canvas canvas) {
    final p = (_t / duration).clamp(0.0, 1.0);
    final x = board.left - board.width * 0.5 + p * board.width * 2;
    canvas.save();
    canvas.clipRect(board);
    canvas.drawRect(
      board,
      Paint()
        ..shader = Gradient.linear(
          Offset(x - board.width * 0.25, board.top),
          Offset(x + board.width * 0.25, board.bottom),
          const [Color(0x00FFFFFF), Color(0x88FFF6DA), Color(0x00FFFFFF)],
          const [0, 0.5, 1],
        ),
    );
    canvas.restore();
  }
}
