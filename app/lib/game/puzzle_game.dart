import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flutter/animation.dart' show Curves;
import 'package:puzzle_domain/puzzle_domain.dart';

import '../artwork/card_back.dart';
import '../artwork/puzzle_artwork.dart';
import '../ui/play_area_layout.dart';
import 'board_style.dart';
import 'celebration/celebration_director.dart';
import 'celebration/celebration_timeline.dart';
import 'intro/intro_director.dart';
import 'intro/intro_timeline.dart';
import 'puzzle_game_bridge.dart';
import 'transition/exit_sequence.dart';

/// Flame scene for one picture-swap puzzle: the board, the tiles, the
/// introduction (via the reusable [IntroDirector]), the drag, the exchange
/// animation and the completion shine. The rules live in the
/// domain; state arrives through [syncPuzzle] and requests leave through
/// [PuzzleGameIntents] (ADR-0001). No Riverpod here.
class PuzzleGame extends FlameGame
    implements PuzzleGameView, IntroStage, CelebrationStage, ExitStage {
  PuzzleGame({
    required PicturePuzzle puzzle,
    required this.artwork,
    required this.intents,
    this.cardBack = const PlaceholderCardBack(),
    this.introTiming = const IntroTiming(),
    this.style = BoardStyle.sunlit,
  }) : _puzzle = puzzle; // ignore: prefer_initializing_formals

  static const swapDuration = 0.22;
  static const returnDuration = 0.18;

  final PuzzleArtwork artwork;
  final PuzzleGameIntents intents;
  final CardBackDesign cardBack;
  final IntroTiming introTiming;

  /// Board colours (Sunlit Storybook by default).
  final BoardStyle style;

  /// Coordinates the entrance and reveal; owns tile poses until finished.
  late final IntroDirector intro;

  PicturePuzzle _puzzle;
  PicturePuzzle get puzzle => _puzzle;

  late BoardLayout area;
  late final BoardFrame frame;

  /// Outline of the swap target, drawn above the dragged tile so it stays
  /// visible while the tile covers the target cell.
  late final TargetMarker targetMarker;

  /// Shadow of a lifted connected group (M3.2).
  late final GroupLiftShadow liftShadow;
  final Map<int, TileComponent> tiles = {};

  /// Tile animations still running (swap or cancel). Input waits for 0.
  int _moving = 0;
  bool _celebrating = false;

  /// The completion celebration, once started (at most once per puzzle).
  CelebrationDirector? celebration;

  /// The board-clearing exit before the next puzzle (at most once).
  ExitDirector? exit;
  void Function()? _onExitDone;

  bool get isExiting => exit != null && !exit!.isFinished;

  TileComponent? _dragged;
  int? _dragPointer;
  GridCell? _dragFrom;
  Offset _grab = Offset.zero;
  TileComponent? _hovered;

  /// Tiles showing press feedback: the pressed tile's whole unit.
  List<TileComponent> _pressedUnit = const [];

  /// The dragged unit (M3.2): the grabbed tile and, if it is in a connected
  /// group, the other members, each with its offset from the grabbed tile's
  /// centre at rest.
  Map<TileComponent, Offset> _dragUnit = const {};

  /// Tiles the current drop would displace (highlighted).
  List<TileComponent> _displaced = const [];

  /// The cell the dragged tile would land on, if that move is allowed.
  GridCell? _dropCell;
  GridCell? _lastOver;

  /// Accepts a new press or drag only when nothing is animating, so a
  /// second swap can never start while the board is settling.
  /// Input is also blocked until the introduction has finished.
  bool get inputEnabled =>
      intro.isFinished && !_puzzle.isComplete && _moving == 0 && !_celebrating;

  IntroPhase get introPhase => intro.phase;
  bool get isAnimating => _moving > 0 || _celebrating;
  TileComponent? get draggedTile => _dragged;
  TileComponent? get hoveredTile => _hovered;

  /// Every tile moving with the current drag (the grabbed tile first).
  List<TileComponent> get draggedUnit => _dragUnit.keys.toList();

  /// Tiles the current drop would displace.
  List<TileComponent> get displacedTiles => _displaced;

  @override
  Color backgroundColor() => const Color(0x00000000);

  Rect _srcRect(PictureTile t) {
    final r = _puzzle.sourceRectOf(t);
    return Rect.fromLTWH(r.left, r.top, r.width, r.height);
  }

  @override
  Future<void> onLoad() async {
    area = BoardLayout.compute(size.toSize(), _puzzle.grid, artwork.sourceSize);
    frame = BoardFrame(style);
    add(frame);
    for (final t in _puzzle.tiles) {
      final c =
          TileComponent(
              t,
              artwork,
              _srcRect(t),
              cardBack: cardBack,
              style: style,
            )
            ..correct = _puzzle.isTileCorrect(t)
            ..face = 0;
      tiles[t.id] = c;
      add(c);
    }
    targetMarker = TargetMarker(style)..priority = 1 << 19;
    add(targetMarker);
    liftShadow = GroupLiftShadow(style)..priority = (1 << 18) - 1;
    add(liftShadow);
    add(InputLayer()..priority = 1 << 20);
    intro = IntroDirector(
      timeline: IntroTimeline.forGrid(
        _puzzle.grid.rows,
        _puzzle.grid.columns,
        timing: introTiming,
      ),
      stage: this,
    );
    add(intro);
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
    if (next.frame == area.frame && next.board == area.board) return;
    area = next;
    _relayout();
  }

  Vector2 _centreOf(GridCell c) => area.cellRect(c).center.toVector2();

  void _relayout() {
    frame
      ..position = area.frame.topLeft.toVector2()
      ..size = area.frame.size.toVector2()
      ..thickness = area.frameThickness;
    if (!intro.isFinished || exit != null) {
      // A presentation sequence owns tile positions; re-pose them for the
      // new layout without restarting it.
      for (final c in tiles.values) {
        c.size = Vector2(area.cellWidth, area.cellHeight);
      }
      if (exit != null) {
        exit!.refresh();
      } else {
        intro.refresh();
      }
      return;
    }
    for (final t in _puzzle.tiles) {
      final c = tiles[t.id]!;
      c.size = Vector2(area.cellWidth, area.cellHeight);
      if (_dragUnit.containsKey(c)) continue;
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
    _refreshJoins();
  }

  /// Joined sides of every tile at rest, from the current groups (M3.2).
  Map<int, int> _restSides = const {};

  /// Recomputes which tile edges are joined inside a connected group, so a
  /// resting group is drawn seamlessly (outer outline only), wherever it is.
  void _refreshJoins() {
    final sides = <int, int>{};
    for (final g in _puzzle.connectedGroups) {
      for (final c in g) {
        sides[_puzzle.tileAt(c).id] = _joinedSides(c, g);
      }
    }
    _restSides = sides;
    for (final c in tiles.values) {
      if (_dragUnit.containsKey(c) || c.pressed || c.isMoving) continue;
      c.joinedSides = _restSidesOf(c);
    }
  }

  int _restSidesOf(TileComponent c) => _restSides[c.tile.id] ?? 0;

  // ---- IntroStage (reusable introduction) ---------------------------------

  @override
  int get introCellCount => _puzzle.grid.cellCount;

  @override
  Size get introPlayArea => size.toSize();

  @override
  Rect introCellRect(int cell) => area.cellRect(_puzzle.grid.cellAt(cell));

  /// Poses whichever tile currently sits in [cell]: the intro animates the
  /// actual shuffled arrangement and never changes it.
  @override
  void poseIntroTile(
    int cell, {
    required Offset centre,
    required double angle,
    required double scale,
    required double face,
    required bool inFlight,
  }) {
    final c = tiles[_puzzle.tileAt(_puzzle.grid.cellAt(cell)).id]!;
    c
      ..position = centre.toVector2()
      ..angle = angle
      ..scale = Vector2.all(scale)
      ..face = face
      // Tiles still flying pass over the ones that have landed.
      ..priority = inFlight ? 2 + cell : 1;
  }

  @override
  void introFinished() {
    for (final c in tiles.values) {
      c
        ..angle = 0
        ..scale = Vector2.all(1)
        ..face = 1;
    }
    _relayout();
    intents.onIntroFinished?.call();
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
      c.priority = _dragUnit.containsKey(c)
          ? (1 << 18) + _cellIndex(prev.cellOf(c.tile))
          : 1 << 17;
      c.moveTo(
        _centreOf(next.cellOf(c.tile)),
        swapDuration,
        onDone: () => _onMoveDone(c),
      );
    }
    _dragged = null;
    _dragUnit = const {};
  }

  int _cellIndex(GridCell c) => c.row * _puzzle.grid.columns + c.column;

  void _onMoveDone(TileComponent c) {
    c
      ..lifted = false
      ..pressed = false
      ..joinedSides = _restSidesOf(c)
      ..castsShadow = true
      ..priority = 1;
    final nowCorrect = _puzzle.isTileCorrect(c.tile);
    if (nowCorrect && !c.correct) c.celebrateCorrect();
    c.correct = nowCorrect;
    _moving--;
    if (_moving > 0) return;
    // Settled: every tile rests exactly at its logical cell.
    _relayout();
    intents.onSwapSettled();
    if (_puzzle.isComplete) _startCelebration();
  }

  void _startCelebration() {
    if (celebration != null) return; // exactly once
    _celebrating = true;
    celebration = CelebrationDirector(
      timeline: CelebrationTimeline.standard(),
      stage: this,
      style: style,
    )..priority = 1 << 19;
    add(celebration!);
  }

  // ---- Exit (next-puzzle transition, GP-40) --------------------------------

  @override
  bool playExit(void Function() onDone) {
    if (exit != null || !_puzzle.isComplete || _celebrating) return false;
    _onExitDone = onDone;
    exit = ExitDirector(
      timeline: ExitTimeline(_puzzle.grid.cellCount),
      stage: this,
    );
    add(exit!);
    return true;
  }

  @override
  int get exitCellCount => _puzzle.grid.cellCount;

  @override
  Size get exitPlayArea => size.toSize();

  @override
  Rect exitCellRect(int cell) => area.cellRect(_puzzle.grid.cellAt(cell));

  @override
  void poseExitTile(int cell, {required Offset centre, required double angle}) {
    final c = tiles[_puzzle.tileAt(_puzzle.grid.cellAt(cell)).id]!;
    c
      ..position = centre.toVector2()
      ..angle = angle
      ..priority = 2 + cell;
  }

  @override
  void exitFinished() {
    final done = _onExitDone;
    _onExitDone = null;
    done?.call();
  }

  // ---- CelebrationStage ----------------------------------------------------

  @override
  Rect get celebrationBoard => area.board;

  @override
  void celebrationFinished() {
    _celebrating = false;
    intents.onCompletionShown();
  }

  // ---- Input (called by InputLayer) ----------------------------------------

  /// Pointer down: immediate press feedback on the tile (and its group).
  void handlePress(Vector2 point) {
    if (!inputEnabled || _dragged != null) return;
    _clearPress();
    final cell = area.cellAt(point.toOffset());
    if (cell == null) return;
    final unit = _puzzle.unitAt(cell);
    _pressedUnit = [
      for (final m in unit)
        tiles[_puzzle.tileAt(m).id]!
          ..pressed = true
          ..joinedSides = _joinedSides(m, unit),
    ];
  }

  /// Pointer up without a drag (or a tap cancelled): clear the press.
  void handleRelease() {
    if (_dragged != null) return;
    _clearPress();
  }

  void _clearPress() {
    for (final c in _pressedUnit) {
      c
        ..pressed = false
        ..joinedSides = _restSidesOf(c);
    }
    _pressedUnit = const [];
  }

  /// Sides of [cell] that touch another member of [unit] (no outline is
  /// drawn there, so the group reads as one piece).
  int _joinedSides(GridCell cell, Set<GridCell> unit) {
    if (unit.length < 2) return 0;
    var sides = 0;
    if (unit.contains(GridCell(cell.row - 1, cell.column))) {
      sides |= TileComponent.sideTop;
    }
    if (unit.contains(GridCell(cell.row, cell.column + 1))) {
      sides |= TileComponent.sideRight;
    }
    if (unit.contains(GridCell(cell.row + 1, cell.column))) {
      sides |= TileComponent.sideBottom;
    }
    if (unit.contains(GridCell(cell.row, cell.column - 1))) {
      sides |= TileComponent.sideLeft;
    }
    return sides;
  }

  void handleDragStart(int pointer, Vector2 point) {
    if (!inputEnabled || _dragged != null) return;
    final p = point.toOffset();
    final cell = area.cellAt(p);
    if (cell == null) return;
    final c = tiles[_puzzle.tileAt(cell).id]!;
    _clearPress();
    _dragged = c;
    _dragPointer = pointer;
    _dragFrom = cell;
    _grab = p - area.cellRect(cell).center;
    _lastOver = null;
    _dropCell = null;
    // The grabbed tile and its connected group move as one unit (M3.2).
    final unit = _puzzle.unitAt(cell);
    final origin = area.cellRect(cell).center;
    _dragUnit = {
      c: Offset.zero,
      for (final m in unit)
        if (m != cell)
          tiles[_puzzle.tileAt(m).id]!: area.cellRect(m).center - origin,
    };
    liftShadow.members = unit.length > 1 ? _dragUnit.keys.toList() : const [];
    for (final m in unit) {
      tiles[_puzzle.tileAt(m).id]!
        ..stopMoving()
        ..lifted = true
        ..castsShadow = unit.length == 1
        ..joinedSides = _joinedSides(m, unit)
        // Lower rows drawn later, so a member's shadow never falls on
        // another member.
        ..priority = (1 << 18) + _cellIndex(m);
    }
  }

  void handleDragUpdate(int pointer, Vector2 point) {
    final c = _dragged;
    if (c == null || pointer != _dragPointer) return;
    final p = point.toOffset();
    // Keep the dragged tile's centre on the play area; group members keep
    // their places around it (scaled with the lift, so the group stays
    // seamless).
    final centre = Offset(
      (p - _grab).dx.clamp(0, size.x),
      (p - _grab).dy.clamp(0, size.y),
    );
    _dragUnit.forEach((m, offset) {
      m.position = (centre + offset * TileComponent.liftScale).toVector2();
    });
    final over = area.cellAt(p);
    if (over == _lastOver) return;
    _lastOver = over;
    final plan = (over == null || over == _dragFrom)
        ? null
        : switch (_puzzle.moveGroup(_dragFrom!, over)) {
            final GroupMoved m => m,
            GroupMoveRejected() => null,
          };
    final displaced = plan == null
        ? const <TileComponent>[]
        : [for (final d in plan.displaced.keys) tiles[_puzzle.tileAt(d).id]!];
    for (final t in _displaced) {
      t.hovered = false;
    }
    for (final t in displaced) {
      t.hovered = true;
    }
    _displaced = displaced;
    final target = plan == null ? null : tiles[_puzzle.tileAt(over!).id]!;
    _hovered = (target == null || _dragUnit.containsKey(target))
        ? null
        : target;
    _dropCell = plan == null ? null : over;
    targetMarker
      ..rect = plan == null ? null : area.cellRect(over!)
      ..groupRects = (plan == null || plan.unit.length < 2)
          ? const []
          : [for (final d in plan.destination) area.cellRect(d)];
  }

  void handleDragEnd(int pointer) {
    final c = _dragged;
    if (c == null || pointer != _dragPointer) return;
    for (final t in _displaced) {
      t.hovered = false;
    }
    _displaced = const [];
    _hovered = null;
    targetMarker
      ..rect = null
      ..groupRects = const [];
    _dragPointer = null;
    final from = _dragFrom!;
    final drop = _dropCell;
    _dragFrom = null;
    _dropCell = null;
    _lastOver = null;
    if (drop != null) {
      intents.onSwapRequested(from, drop);
      if (_dragged == c) _cancel(); // the move was not applied
    } else {
      _cancel();
    }
  }

  /// Released where no move is possible: the unit glides back to its cells.
  void _cancel() {
    final unit = _dragUnit.keys.toList();
    _dragged = null;
    _dragUnit = const {};
    _moving += unit.length;
    for (final c in unit) {
      c.moveTo(
        _centreOf(_puzzle.cellOf(c.tile)),
        returnDuration,
        onDone: () {
          c
            ..lifted = false
            ..joinedSides = _restSidesOf(c)
            ..castsShadow = true
            ..priority = 1;
          _moving--;
        },
      );
    }
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

/// One soft shadow under a lifted connected group (M3.2), so the members
/// read as one piece; a single lifted tile keeps its own shadow.
class GroupLiftShadow extends Component {
  GroupLiftShadow(this.style);

  final BoardStyle style;

  /// Members of the lifted group (shadow drawn while they are lifted).
  List<TileComponent> members = const [];

  @override
  void render(Canvas canvas) {
    final lifted = members.where((m) => m.lifted).toList();
    if (lifted.isEmpty) {
      members = const [];
      return;
    }
    final path = Path();
    for (final m in lifted) {
      path.addRect(
        Rect.fromCenter(
          center: m.position.toOffset(),
          width: m.size.x * TileComponent.liftScale,
          height: m.size.y * TileComponent.liftScale,
        ),
      );
    }
    canvas.drawPath(
      path.shift(const Offset(0, 8)),
      Paint()
        ..color = style.shadow.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }
}

/// Bright outline around the cell a dragged tile would swap into.
class TargetMarker extends Component {
  TargetMarker(this.style);

  final BoardStyle style;

  /// The cell the dragged tile would land on.
  Rect? rect;

  /// When a connected group is dragged: every cell it would occupy.
  List<Rect> groupRects = const [];

  @override
  void render(Canvas canvas) {
    if (groupRects.isNotEmpty) {
      _groupOutline(canvas);
      return;
    }
    final r = rect;
    if (r != null) _outline(canvas, r);
  }

  /// One outline around the whole group destination (no inner lines).
  void _groupOutline(Canvas canvas) {
    Path edges(double grow) {
      final path = Path();
      final cells = groupRects.toSet();
      for (final r in cells) {
        final o = r.inflate(grow);
        void side(Rect neighbour, Offset a, Offset b) {
          if (cells.contains(neighbour)) return;
          path
            ..moveTo(a.dx, a.dy)
            ..lineTo(b.dx, b.dy);
        }

        side(r.shift(Offset(0, -r.height)), o.topLeft, o.topRight);
        side(r.shift(Offset(r.width, 0)), o.topRight, o.bottomRight);
        side(r.shift(Offset(0, r.height)), o.bottomRight, o.bottomLeft);
        side(r.shift(Offset(-r.width, 0)), o.bottomLeft, o.topLeft);
      }
      return path;
    }

    canvas.drawPath(
      edges(3),
      Paint()
        ..color = style.targetGlow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawPath(
      edges(1.5),
      Paint()
        ..color = style.target
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  void _outline(Canvas canvas, Rect r) {
    canvas.drawRect(
      r.inflate(3),
      Paint()
        ..color = style.targetGlow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawRect(
      r.inflate(1.5),
      Paint()
        ..color = style.target
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }
}

/// Light honey-wood frame and pale bed behind the tiles (visible under a
/// lifted tile). Positioned at the frame's outer rect; [thickness] is the
/// frame width, so the bed exactly matches the board.
class BoardFrame extends PositionComponent {
  BoardFrame(this.style);

  final BoardStyle style;
  double thickness = 8;

  @override
  void render(Canvas canvas) {
    final outer = Offset.zero & size.toSize();
    final radius = Radius.circular(thickness * 1.4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(outer.shift(const Offset(0, 4)), radius),
      Paint()
        ..color = style.shadow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(outer, radius),
      Paint()..color = style.frame,
    );
    // Soft highlight on the upper half of the frame.
    canvas.drawRRect(
      RRect.fromRectAndRadius(outer.deflate(thickness * 0.2), radius),
      Paint()
        ..color = style.frameHighlight
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness * 0.25,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(outer.deflate(0.75), radius),
      Paint()
        ..color = style.frameEdge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final bed = outer.deflate(thickness);
    canvas.drawRect(bed.inflate(1), Paint()..color = style.frameEdge);
    canvas.drawRect(bed, Paint()..color = style.bed);
  }
}

/// One picture tile: always shows its own source slice. Incorrectly placed
/// tiles have a thin light edge; correctly placed tiles are drawn edge to
/// edge so correct neighbours read as one continuous picture.
class TileComponent extends PositionComponent {
  TileComponent(
    this.tile,
    this.artwork,
    this.source, {
    this.cardBack = const PlaceholderCardBack(),
    this.style = BoardStyle.sunlit,
  }) : super(anchor: Anchor.center);

  final PictureTile tile;
  final PuzzleArtwork artwork;
  final CardBackDesign cardBack;
  final BoardStyle style;

  /// Scale of a lifted (dragged) tile.
  static const liftScale = 1.08;

  static const sideTop = 1;
  static const sideRight = 2;
  static const sideBottom = 4;
  static const sideLeft = 8;

  /// Sides joined to another member of the lifted or pressed group (M3.2):
  /// no outline is drawn there. 0 for a single tile.
  int joinedSides = 0;

  /// False while the tile is part of a lifted group, whose shadow is drawn
  /// once by [GroupLiftShadow].
  bool castsShadow = true;

  /// 0 = card back, 1 = picture. Driven by the intro; 1 during gameplay.
  double face = 1;

  /// Whether the picture side is the visible one.
  bool get showsFront => face >= 0.5;

  /// Source region (source units).
  final Rect source;

  bool correct = false;
  bool pressed = false;
  bool lifted = false;
  bool hovered = false;

  double _glow = 0;
  Picture? _picture;
  Size? _pictureSize;
  Picture? _back;
  Size? _backSize;

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

  Picture _backArt(Size s) {
    if (_back == null || _backSize != s) {
      final rec = PictureRecorder();
      cardBack.paint(Canvas(rec), Offset.zero & s);
      _back?.dispose();
      _back = rec.endRecording();
      _backSize = s;
    }
    return _back!;
  }

  @override
  void onRemove() {
    _picture?.dispose();
    _picture = null;
    _back?.dispose();
    _back = null;
    super.onRemove();
  }

  /// 3D-style card flip: the card narrows to edge-on and widens again with
  /// the other side, lifting slightly and darkening towards the edge.
  void _renderFlip(Canvas canvas, Size s) {
    final rect = Offset.zero & s;
    final edge = math.cos(math.pi * face).abs();
    final lift = 1 + 0.07 * math.sin(math.pi * face);
    canvas.save();
    canvas.translate(s.width / 2, s.height / 2);
    canvas.scale(math.max(edge, 0.02) * lift, lift);
    canvas.translate(-s.width / 2, -s.height / 2);
    canvas.drawRect(
      rect.shift(const Offset(0, 4)),
      Paint()
        ..color = const Color(0x55000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    if (showsFront) {
      canvas.drawPicture(_art(s));
      canvas.drawRect(
        rect.deflate(0.5),
        Paint()
          ..color = const Color(0xB3FFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    } else {
      canvas.drawPicture(_backArt(s));
    }
    final shade = ((1 - edge) * 110).round();
    if (shade > 0) {
      canvas.drawRect(rect, Paint()..color = Color.fromARGB(shade, 0, 0, 0));
    }
    canvas.restore();
  }

  /// A rectangle outline, leaving out [joinedSides] (a single tile draws
  /// the full rectangle, as before).
  void _outline(Canvas canvas, Rect r, Paint paint) {
    if (joinedSides == 0) {
      canvas.drawRect(r, paint);
      return;
    }
    final path = Path();
    void side(int bit, Offset a, Offset b) {
      if (joinedSides & bit != 0) return;
      path
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy);
    }

    side(sideTop, r.topLeft, r.topRight);
    side(sideRight, r.topRight, r.bottomRight);
    side(sideBottom, r.bottomRight, r.bottomLeft);
    side(sideLeft, r.bottomLeft, r.topLeft);
    canvas.drawPath(path, paint);
  }

  @override
  void render(Canvas canvas) {
    final s = size.toSize();
    if (face < 1) {
      _renderFlip(canvas, s);
      return;
    }
    final rect = Offset.zero & s;
    final scale = lifted ? liftScale : (pressed ? 1.04 : 1.0);
    canvas.save();
    canvas.translate(s.width / 2, s.height / 2);
    canvas.scale(scale);
    canvas.translate(-s.width / 2, -s.height / 2);
    if (lifted && castsShadow) {
      canvas.drawRect(
        rect.shift(const Offset(0, 8)),
        Paint()
          ..color = style.shadow.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
    canvas.drawPicture(_art(s));
    if (!correct || lifted) {
      _outline(
        canvas,
        rect.deflate(0.5),
        Paint()
          ..color = style.tileEdge
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
    if (hovered) {
      canvas.drawRect(rect, Paint()..color = style.targetGlow);
    }
    if (pressed || lifted) {
      _outline(
        canvas,
        rect.deflate(1),
        Paint()
          ..color = style.selected
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    if (_glow > 0) {
      canvas.drawRect(
        rect,
        Paint()
          ..color = style.correctFill.withValues(
            alpha: style.correctFill.a * _glow,
          ),
      );
      canvas.drawRect(
        rect.deflate(1.5),
        Paint()
          ..color = style.correctGlow.withValues(alpha: _glow)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    canvas.restore();
  }
}
