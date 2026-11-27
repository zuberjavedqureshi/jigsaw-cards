import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_cards/artwork/puzzle_artwork.dart';
import 'package:jigsaw_cards/game/intro/intro_timeline.dart';
import 'package:jigsaw_cards/game/puzzle_game.dart';
import 'package:jigsaw_cards/game/puzzle_game_bridge.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puzzle_domain/puzzle_domain.dart';

/// TEST-ONLY artwork: 25 distinct coloured blocks with a diagonal band, so
/// every 5×5 tile differs. Never registered in the app.
class _TestGridArtwork implements PuzzleArtwork {
  const _TestGridArtwork();

  @override
  Size get sourceSize => const Size(1024, 1024);

  @override
  String get title => 'Test grid';

  @override
  void paint(ui.Canvas canvas, Size size) {
    final w = size.width / 5;
    for (var r = 0; r < 5; r++) {
      for (var c = 0; c < 5; c++) {
        canvas.drawRect(
          Rect.fromLTWH(c * w, r * w, w, w),
          ui.Paint()
            ..color = HSVColor.fromAHSV(
              1,
              (r * 5 + c) * 14.0,
              0.6,
              0.9,
            ).toColor(),
        );
      }
    }
    canvas.drawLine(
      Offset.zero,
      Offset(size.width, size.height),
      ui.Paint()
        ..color = const Color(0xFFFFFFFF)
        ..strokeWidth = 12,
    );
  }
}

/// Runs a 5×5 [PuzzleGame] directly, with the same intent → domain →
/// syncPuzzle loop the screen and controller use, since no Hard level is
/// playable in the app yet.
class _Game5 {
  _Game5(this.tester, PicturePuzzle start) : puzzle = start;

  final WidgetTester tester;
  PicturePuzzle puzzle;
  late final PuzzleGame game;
  var requests = 0;
  var settled = 0;
  var completionShown = 0;

  RenderBox get _box =>
      tester.renderObject<RenderBox>(find.byType(GameWidget<PuzzleGame>));

  Offset globalOf(GridCell c) =>
      _box.localToGlobal(game.area.cellRect(c).center);

  Offset globalLocal(Offset p) => _box.localToGlobal(p);

  TileComponent componentAt(GridCell c) => game.tiles[puzzle.tileAt(c).id]!;

  Future<void> settle({int frames = 12}) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<TestGesture> dragFromTo(
    Offset a,
    Offset b, {
    bool release = true,
  }) async {
    final g = await tester.startGesture(a);
    await tester.pump(const Duration(milliseconds: 16));
    for (var i = 1; i <= 10; i++) {
      await g.moveTo(Offset.lerp(a, b, i / 10)!);
      await tester.pump(const Duration(milliseconds: 16));
    }
    if (release) {
      await g.up();
      await settle();
    }
    return g;
  }

  Future<void> move(GridCell from, GridCell to) =>
      dragFromTo(globalOf(from), globalOf(to));
}

Future<_Game5> _pump5(
  WidgetTester tester, {
  int seed = 1000,
  Size size = const Size(412, 915),
  bool finishIntro = true,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final h = _Game5(
    tester,
    PicturePuzzle.shuffled(GridSize(5, 5), SourceSize(1024, 1024), seed: seed),
  );
  h.game = PuzzleGame(
    puzzle: h.puzzle,
    artwork: const _TestGridArtwork(),
    introTiming: IntroTiming.forCellCount(25),
    intents: PuzzleGameIntents(
      onSwapRequested: (from, to) {
        h.requests++;
        final o = h.puzzle.moveGroup(from, to);
        if (o is GroupMoved) {
          h.puzzle = o.puzzle;
          h.game.syncPuzzle(h.puzzle);
        }
      },
      onSwapSettled: () => h.settled++,
      onCompletionShown: () => h.completionShown++,
    ),
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: GameWidget(game: h.game)),
    ),
  );
  await tester.pump(const Duration(milliseconds: 16));
  if (finishIntro) {
    for (var i = 0; i < 100 && !h.game.intro.isFinished; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(h.game.intro.isFinished, isTrue);
    await tester.pump(const Duration(milliseconds: 16));
  }
  return h;
}

void main() {
  testWidgets('the 5×5 intro: card backs, input blocked, about 2.69 s', (
    tester,
  ) async {
    final h = await _pump5(tester, finishIntro: false);
    expect(h.game.tiles, hasLength(25));
    expect(h.game.tiles.values.every((c) => c.face == 0), isTrue);
    expect(h.game.inputEnabled, isFalse);
    var t = 0.0;
    while (!h.game.intro.isFinished && t < 6) {
      await tester.pump(const Duration(milliseconds: 20));
      t += 0.02;
      if (!h.game.intro.isFinished) {
        expect(h.game.inputEnabled, isFalse, reason: 'blocked at ${t}s');
      }
    }
    // ignore: avoid_print
    print('MEASURE 5x5 intro finished after ${t.toStringAsFixed(2)} s');
    expect(t, inInclusiveRange(2.6, 2.8), reason: 'finished after ${t}s');
    await tester.pump(const Duration(milliseconds: 16));
    expect(h.game.inputEnabled, isTrue);
    expect(h.game.tiles.values.every((c) => c.face == 1), isTrue);
  });

  testWidgets('25 unique tiles, each resting on its own cell', (tester) async {
    final h = await _pump5(tester);
    expect({for (final c in h.game.tiles.values) c.tile.id}, hasLength(25));
    for (final cell in h.puzzle.grid.cells) {
      final c = h.componentAt(cell);
      final want = h.game.area.cellRect(cell).center;
      expect(c.position.x, closeTo(want.dx, 0.01));
      expect(c.position.y, closeTo(want.dy, 0.01));
      expect(c.size.x, closeTo(h.game.area.cellWidth, 0.01));
    }
  });

  testWidgets('corner and edge tiles are grabbed and swapped', (tester) async {
    final h = await _pump5(tester);
    final grid = h.puzzle.grid;
    // Pick two loose tiles at opposite corners or edges (by the domain).
    final candidates = [
      GridCell(0, 0),
      GridCell(0, 4),
      GridCell(4, 0),
      GridCell(4, 4),
      GridCell(2, 0),
      GridCell(2, 4),
    ];
    final loose = [
      for (final c in candidates)
        if (h.puzzle.groupAt(c) == null) c,
    ];
    expect(loose.length, greaterThanOrEqualTo(2));
    final (a, b) = (loose.first, loose.last);
    // Press 2 dp inside the outer corner of the cell: still that tile.
    final corner = h.game.area.cellRect(a);
    final edgePoint = Offset(
      a.column == 0 ? corner.left + 2 : corner.right - 2,
      a.row == 0 ? corner.top + 2 : corner.bottom - 2,
    );
    final expected = h.puzzle.moveGroup(a, b) as GroupMoved;
    final g = await h.dragFromTo(
      h.globalLocal(edgePoint),
      h.globalOf(b),
      release: false,
    );
    expect(h.game.draggedTile, h.componentAt(a));
    await g.up();
    await h.settle();
    expect(h.puzzle.arrangement, expected.puzzle.arrangement);
    expect(grid.contains(a) && grid.contains(b), isTrue);
  });

  testWidgets('dropping outside the board cancels: nothing changes', (
    tester,
  ) async {
    final h = await _pump5(tester);
    final before = [...h.puzzle.arrangement];
    final from = h.puzzle.grid.cells.firstWhere(
      (c) => h.puzzle.groupAt(c) == null,
    );
    final below = Offset(
      h.game.area.board.center.dx,
      h.game.area.frame.bottom + 30,
    );
    await h.dragFromTo(h.globalOf(from), h.globalLocal(below));
    expect(h.requests, 0);
    expect(h.puzzle.arrangement, before);
    final c = h.componentAt(from);
    final want = h.game.area.cellRect(from).center;
    expect(c.position.x, closeTo(want.dx, 0.01));
    expect(c.position.y, closeTo(want.dy, 0.01));
    expect(c.lifted, isFalse);
  });

  testWidgets('a connected group is dragged as one unit on 5×5', (
    tester,
  ) async {
    // Find a seed whose 5×5 start has a group that can move home.
    late int seed;
    late GridCell from, to;
    for (var s = 0; s < 2000; s++) {
      final p = PicturePuzzle.shuffled(
        GridSize(5, 5),
        SourceSize(1024, 1024),
        seed: s,
      );
      final groups = p.connectedGroups;
      if (groups.isEmpty) continue;
      final c = groups.first.first;
      final target = p.tileAt(c).target;
      if (target != c && p.moveGroup(c, target) is GroupMoved) {
        (seed, from, to) = (s, c, target);
        break;
      }
    }
    final h = await _pump5(tester, seed: seed);
    final group = h.puzzle.groupAt(from)!;
    final expected = h.puzzle.moveGroup(from, to) as GroupMoved;
    final g = await h.dragFromTo(
      h.globalOf(from),
      h.globalOf(to),
      release: false,
    );
    expect(h.game.draggedUnit, hasLength(group.length));
    await g.up();
    await h.settle();
    expect(h.puzzle.arrangement, expected.puzzle.arrangement);
    for (final c in expected.destination) {
      expect(h.puzzle.isTileCorrect(h.puzzle.tileAt(c)), isTrue);
    }
  });

  testWidgets('a full 5×5 solve through drags completes and celebrates', (
    tester,
  ) async {
    final h = await _pump5(tester, seed: 7);
    var moves = 0;
    while (!h.puzzle.isComplete && moves < 30) {
      final t = h.puzzle.tiles.firstWhere((t) => !h.puzzle.isTileCorrect(t));
      await h.move(h.puzzle.cellOf(t), t.target);
      moves++;
    }
    expect(h.puzzle.isComplete, isTrue);
    expect(h.puzzle.connectedGroups.single, hasLength(25));
    expect(h.game.celebration, isNotNull);
    await h.settle(frames: 40);
    expect(h.completionShown, 1);
    expect(h.game.inputEnabled, isFalse, reason: 'complete');
  });

  testWidgets('5×5 works on a narrow 320×568 phone too', (tester) async {
    final h = await _pump5(tester, size: const Size(320, 568), seed: 42);
    expect(h.game.area.cellWidth, greaterThan(40));
    final t = h.puzzle.tiles.firstWhere((t) => !h.puzzle.isTileCorrect(t));
    final from = h.puzzle.cellOf(t);
    final expected = h.puzzle.moveGroup(from, t.target) as GroupMoved;
    await h.move(from, t.target);
    expect(h.puzzle.arrangement, expected.puzzle.arrangement);
  });
}
