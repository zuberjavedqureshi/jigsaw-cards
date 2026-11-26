import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_cards/game/intro/intro_timeline.dart';
import 'package:jigsaw_cards/state/puzzle_controller.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puzzle_domain/puzzle_domain.dart';

import 'puzzle_test_harness.dart';

void main() {
  Future<void> step(WidgetTester tester, [int ms = 20]) =>
      tester.pump(Duration(milliseconds: ms));

  testWidgets('1. a new puzzle starts with every tile showing its back', (
    tester,
  ) async {
    final h = await pumpPuzzle(tester, waitForIntro: false);
    expect(h.game.introPhase, isNot(IntroPhase.ready));
    for (final c in h.game.tiles.values) {
      expect(c.face, 0);
      expect(c.showsFront, isFalse);
    }
    expect(h.game.inputEnabled, isFalse);
  });

  testWidgets('2. tiles fly in and settle in their actual shuffled cells', (
    tester,
  ) async {
    final h = await pumpPuzzle(tester, waitForIntro: false);
    final arrangement = [...h.puzzle.arrangement];
    final tl = h.game.intro.timeline;
    // Late in the entrance the first tile has landed, the last has not.
    while (h.game.intro.elapsed < tl.entranceEnd - tl.timing.enterDuration) {
      await step(tester);
    }
    final firstCell = tl.entranceOrder.first;
    final lastCell = tl.entranceOrder.last;
    final first = h.componentAt(h.puzzle.grid.cellAt(firstCell));
    final last = h.componentAt(h.puzzle.grid.cellAt(lastCell));
    final firstRect = h.game.area.cellRect(h.puzzle.grid.cellAt(firstCell));
    final lastRect = h.game.area.cellRect(h.puzzle.grid.cellAt(lastCell));
    expect(first.position.x, closeTo(firstRect.center.dx, 0.5));
    expect(first.position.y, closeTo(firstRect.center.dy, 0.5));
    expect(last.position.y, greaterThan(lastRect.center.dy + 1));
    await h.finishIntro();
    // Every tile rests in the cell the domain says, untilted; the
    // arrangement was never changed by the animation.
    expect(h.puzzle.arrangement, arrangement);
    for (final t in h.puzzle.tiles) {
      final r = h.game.area.cellRect(h.puzzle.cellOf(t));
      final c = h.game.tiles[t.id]!;
      expect(c.position.x, closeTo(r.center.dx, 0.01));
      expect(c.position.y, closeTo(r.center.dy, 0.01));
      expect(c.angle, 0);
      expect(c.scale.x, 1);
    }
  });

  testWidgets('3. no tile is revealed before every tile has arrived', (
    tester,
  ) async {
    final h = await pumpPuzzle(tester, waitForIntro: false);
    var sawEntering = false;
    while (!h.game.intro.isFinished) {
      final anyRevealing = h.game.tiles.values.any((c) => c.face > 0);
      if (h.game.introPhase == IntroPhase.entering) {
        sawEntering = true;
        expect(anyRevealing, isFalse);
      }
      if (anyRevealing) {
        // All tiles are settled in their cells, upright.
        for (final t in h.puzzle.tiles) {
          final r = h.game.area.cellRect(h.puzzle.cellOf(t));
          final c = h.game.tiles[t.id]!;
          expect(c.position.y, closeTo(r.center.dy, 0.5));
          expect(c.angle.abs(), lessThan(1e-6));
        }
      }
      await step(tester);
    }
    expect(sawEntering, isTrue);
  });

  testWidgets('4. tiles reveal in the intended sequence', (tester) async {
    final h = await pumpPuzzle(tester, waitForIntro: false);
    final tl = h.game.intro.timeline;
    final revealedAt = <int, double>{};
    while (!h.game.intro.isFinished) {
      await step(tester, 10);
      for (var cell = 0; cell < 16; cell++) {
        final c = h.componentAt(h.puzzle.grid.cellAt(cell));
        if (c.showsFront && !revealedAt.containsKey(cell)) {
          revealedAt[cell] = h.game.intro.elapsed;
        }
      }
    }
    expect(revealedAt.length, 16);
    final observed = revealedAt.keys.toList()
      ..sort((a, b) => revealedAt[a]!.compareTo(revealedAt[b]!));
    expect(observed, tl.revealOrder);
  });

  testWidgets('5. every tile ends showing its own image fragment', (
    tester,
  ) async {
    final h = await pumpPuzzle(tester);
    for (final t in h.puzzle.tiles) {
      final c = h.game.tiles[t.id]!;
      expect(c.face, 1);
      expect(c.showsFront, isTrue);
      final r = h.puzzle.sourceRectOf(t);
      expect(c.source, Rect.fromLTWH(r.left, r.top, r.width, r.height));
      expect(c.size.x, closeTo(h.game.area.cellWidth, 0.01));
      expect(c.size.y, closeTo(h.game.area.cellHeight, 0.01));
    }
  });

  testWidgets('6. input is disabled while entering and while revealing', (
    tester,
  ) async {
    final h = await pumpPuzzle(tester, waitForIntro: false);
    final before = [...h.puzzle.arrangement];
    final tl = h.game.intro.timeline;
    Future<void> tryToSwap() async {
      final g = await tester.startGesture(h.globalOf(GridCell(0, 0)));
      await step(tester, 16);
      for (var i = 1; i <= 6; i++) {
        await g.moveTo(
          Offset.lerp(
            h.globalOf(GridCell(0, 0)),
            h.globalOf(GridCell(0, 1)),
            i / 6,
          )!,
        );
        await step(tester, 16);
      }
      await g.up();
      await step(tester, 16);
    }

    while (h.game.intro.elapsed < tl.entranceEnd * 0.7) {
      await step(tester);
    }
    expect(h.game.introPhase, IntroPhase.entering);
    expect(h.game.inputEnabled, isFalse);
    await tryToSwap();

    while (h.game.introPhase != IntroPhase.revealing) {
      await step(tester);
    }
    expect(h.game.inputEnabled, isFalse);
    await tryToSwap();

    expect(h.puzzle.arrangement, before);
    expect(h.state.swaps, 0);
    expect(h.game.draggedTile, isNull);
    for (final c in h.game.tiles.values) {
      expect(c.pressed, isFalse);
    }
  });

  testWidgets('7. input is enabled once the reveal completes', (tester) async {
    final h = await pumpPuzzle(tester, waitForIntro: false);
    expect(h.game.inputEnabled, isFalse);
    await h.finishIntro();
    expect(h.game.introPhase, IntroPhase.ready);
    expect(h.game.inputEnabled, isTrue);
    final a = h.puzzle.tileAt(GridCell(0, 0));
    await h.swap(GridCell(0, 0), GridCell(1, 2));
    expect(h.puzzle.tileAt(GridCell(1, 2)), a);
    expect(h.state.swaps, 1);
  });

  testWidgets('8. starting a new puzzle runs the sequence again', (
    tester,
  ) async {
    final h = await pumpPuzzle(tester);
    final oldGame = h.game;
    h.container.read(puzzleControllerProvider.notifier).newPuzzle();
    await step(tester, 16);
    await step(tester, 16);
    expect(h.game, isNot(same(oldGame)));
    expect(h.game.intro.isFinished, isFalse);
    expect(h.game.tiles.values.every((c) => c.face == 0), isTrue);
    expect(h.game.inputEnabled, isFalse);
    await h.finishIntro();
    expect(h.game.inputEnabled, isTrue);
    expect(h.game.tiles.values.every((c) => c.face == 1), isTrue);
  });

  testWidgets('9. resizing and rebuilding do not restart the sequence', (
    tester,
  ) async {
    final h = await pumpPuzzle(tester, waitForIntro: false);
    final tl = h.game.intro.timeline;
    while (h.game.intro.elapsed < tl.entranceEnd * 0.5) {
      await step(tester);
    }
    final game = h.game;
    final before = game.intro.elapsed;
    // Real resize.
    tester.view.physicalSize = const Size(360, 700);
    await step(tester, 16);
    expect(h.game, same(game));
    expect(game.intro.elapsed, greaterThanOrEqualTo(before));
    expect(game.introPhase, isNot(IntroPhase.idle));
    // Rebuild without a state change (same container, same game).
    final mid = game.intro.elapsed;
    await tester.pumpWidget(
      tester.widget(find.byType(UncontrolledProviderScope)),
    );
    await step(tester, 16);
    expect(h.game, same(game));
    expect(game.intro.elapsed, greaterThanOrEqualTo(mid));
    await h.finishIntro();
    for (final t in h.puzzle.tiles) {
      final r = game.area.cellRect(h.puzzle.cellOf(t));
      expect(game.tiles[t.id]!.position.x, closeTo(r.center.dx, 0.01));
      expect(game.tiles[t.id]!.position.y, closeTo(r.center.dy, 0.01));
    }
    expect(game.inputEnabled, isTrue);
  });

  testWidgets('10. pause and resume leave a valid, finishing intro', (
    tester,
  ) async {
    final h = await pumpPuzzle(tester, waitForIntro: false);
    final tl = h.game.intro.timeline;
    while (h.game.intro.elapsed < tl.revealStart + 0.1) {
      await step(tester);
    }
    expect(h.game.introPhase, IntroPhase.revealing);
    final before = h.game.intro.elapsed;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 5));
    await step(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await step(tester);
    // Not restarted, and a long stall did not skip past the reveal state.
    expect(h.game.intro.elapsed, greaterThanOrEqualTo(before));
    expect(h.game.introPhase, isNot(IntroPhase.idle));
    expect(h.game.introPhase, isNot(IntroPhase.entering));
    await h.finishIntro();
    expect(h.game.inputEnabled, isTrue);
    expect(
      h.game.tiles.values.every((c) => c.face == 1 && c.angle == 0),
      isTrue,
    );
  });
}
