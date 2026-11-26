import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_cards/game/praise/praise_director.dart';
import 'package:jigsaw_cards/game/praise/praise_rules.dart';
import 'package:jigsaw_cards/state/puzzle_controller.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puzzle_domain/puzzle_domain.dart';

import 'puzzle_test_harness.dart';

/// M3.3 positive feedback, driven through real drags. Seed 1000 starts with
/// the castle L (tiles 5, 9, 10 home); the moves below were checked with the
/// domain: path tile next to the pond (pair), trees above the pond (growth),
/// then the three dragged home onto the castle (merge into six).
const seed = 1000;
final pairMove = (GridCell(3, 3), GridCell(1, 2));
final growMove = (GridCell(0, 0), GridCell(0, 3));
final mergeMove = (GridCell(1, 3), GridCell(3, 3));

void main() {
  String? shown(Harness h) => h.game.praise.current?.praise.text;

  /// Releases a drag and waits until the move has settled and its praise
  /// (if any) is visible, without letting it expire.
  Future<void> move(Harness h, (GridCell, GridCell) m) async {
    final g = await h.dragTo(m.$1, h.globalOf(m.$2), release: false);
    await g.up();
    for (var i = 0; i < 8; i++) {
      await tester(h).pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('pair → Nice!, growth → Great!, merge below 10 → Amazing!', (
    tester,
  ) async {
    final h = await pumpPuzzle(tester, seed: seed);
    expect(h.game.praise.bursts, isEmpty);
    await move(h, pairMove);
    expect(shown(h), 'Nice!');
    await h.settle(frames: 30);
    expect(h.game.praise.bursts, isEmpty, reason: 'it fades out');
    await move(h, growMove);
    expect(shown(h), 'Great!');
    await h.settle(frames: 30);
    await move(h, mergeMove);
    final size = h.puzzle.groupAt(GridCell(3, 3))!.length;
    expect(size, inInclusiveRange(6, 9));
    expect(shown(h), 'Amazing!', reason: '$size tiles: below the threshold');
  });

  testWidgets('Fantastic! once per puzzle: on crossing the threshold, not '
      'for later growth, merges or moves', (tester) async {
    // Threshold 3 so the seed-1000 moves cross it early.
    final h = await pumpPuzzle(
      tester,
      seed: seed,
      praiseRules: const PraiseRules(largeGroupSize: 3),
    );
    await move(h, pairMove);
    expect(shown(h), 'Nice!');
    await h.settle(frames: 30);
    await move(h, growMove); // 2 → 3 tiles: crosses the threshold
    expect(shown(h), 'Fantastic!');
    expect(h.game.praiseMilestones.largeGroupCelebrated, isTrue);
    await h.settle(frames: 30);
    await move(h, mergeMove); // merge into a bigger group
    expect(shown(h), 'Amazing!');
    await h.settle(frames: 30);
    // Moving the big group without changing it shows nothing.
    final big = h.puzzle.groupAt(GridCell(3, 3))!;
    final from = big.first;
    final to = h.puzzle.grid.cells.firstWhere((c) {
      final o = h.puzzle.moveGroup(from, c);
      return o is GroupMoved && connectionEvents(h.puzzle, o.puzzle).isEmpty;
    });
    final swaps = h.state.swaps;
    await move(h, (from, to));
    expect(h.state.swaps, swaps + 1);
    expect(h.game.praise.bursts, isEmpty);
  });

  testWidgets('default threshold: one Fantastic! when a group first reaches '
      '10 tiles, then Perfect! at completion', (tester) async {
    final h = await pumpPuzzle(tester, seed: seed);
    final seen = <String>[];
    int? sizeAtFantastic;
    // Drag groups home one by one (always allowed, always progress).
    while (!h.puzzle.isComplete) {
      final t = h.puzzle.tiles.firstWhere((t) => !h.puzzle.isTileCorrect(t));
      final before = h.game.praise.current;
      await move(h, (h.puzzle.cellOf(t), t.target));
      final now = h.game.praise.current;
      if (now != null && now != before) {
        seen.add(now.praise.text);
        if (now.praise.text == 'Fantastic!') {
          sizeAtFantastic = now.praise.cells.length;
        }
      }
      await h.settle(frames: 30);
    }
    expect(seen.where((t) => t == 'Fantastic!'), hasLength(1), reason: '$seen');
    expect(sizeAtFantastic, greaterThanOrEqualTo(10));
    expect(seen.last, 'Perfect!');
  });

  testWidgets('Next puzzle starts with fresh milestones', (tester) async {
    final h = await pumpPuzzle(tester, seed: seed);
    final old = h.game;
    old.praiseMilestones.largeGroupCelebrated = true;
    await h.solve();
    await h.settle(frames: 40);
    await h.tapNextPuzzle();
    expect(h.game, isNot(same(old)));
    expect(h.game.praiseMilestones.largeGroupCelebrated, isFalse);
  });

  testWidgets('praise is anchored on the connected tiles and stays on '
      'screen', (tester) async {
    for (final size in const [Size(412, 915), Size(320, 568)]) {
      final h = await pumpPuzzle(tester, seed: seed, size: size);
      await move(h, pairMove);
      final b = h.game.praise.current!;
      final pair = h.game.area
          .cellRect(GridCell(1, 2))
          .expandToInclude(h.game.area.cellRect(GridCell(1, 3)));
      final half = b.halfExtent;
      final area = Offset.zero & h.gameSize;
      expect(b.position.x - half.width, greaterThanOrEqualTo(area.left));
      expect(b.position.x + half.width, lessThanOrEqualTo(area.right));
      expect(b.position.y - half.height, greaterThanOrEqualTo(area.top));
      expect(b.position.y + half.height, lessThanOrEqualTo(area.bottom));
      // Near the pair (shifted only as far as needed to stay on screen).
      expect((b.position.y - pair.center.dy).abs(), lessThan(pair.height));
      // Small enough not to cover the board.
      expect(b.size.x, lessThan(h.game.area.board.width * 0.6));
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('a higher praise replaces a visible one gracefully', (
    tester,
  ) async {
    final h = await pumpPuzzle(tester, seed: seed);
    await move(h, pairMove);
    final nice = h.game.praise.current!;
    expect(nice.praise.text, 'Nice!');
    final g = await h.dragTo(
      growMove.$1,
      h.globalOf(growMove.$2),
      release: false,
    );
    await g.up();
    // Find the moment the new praise appears.
    for (var i = 0; i < 20 && shown(h) == 'Nice!'; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(shown(h), 'Great!');
    expect(nice.isDismissed, isTrue, reason: 'old one fades, not cut off');
    await tester.pump(const Duration(milliseconds: 16));
    expect(nice.isMounted, isTrue, reason: 'still fading out');
    expect(
      h.game.praise.bursts.where((b) => !b.isDismissed),
      hasLength(1),
      reason: 'never two live messages at once',
    );
    await h.settle(frames: 6);
    expect(nice.isMounted, isFalse);
  });

  testWidgets('rapid equal praise is not repeated', (tester) async {
    final h = await pumpPuzzle(tester, seed: seed);
    final area = Offset.zero & h.gameSize;
    const p = Praise(PraiseLevel.nice, 'Nice!', {});
    expect(h.game.praise.show(p, area.center, area), isTrue);
    await tester.pump(const Duration(milliseconds: 300));
    expect(h.game.praise.show(p, area.center, area), isFalse);
    expect(h.game.praise.bursts, hasLength(1));
    await h.settle(frames: 24);
    expect(h.game.praise.show(p, area.center, area), isTrue);
  });

  testWidgets('ordinary swaps without a connection show nothing', (
    tester,
  ) async {
    final h = await pumpPuzzle(tester, seed: seed);
    // Find a loose-tile swap that connects nothing (checked with the
    // domain first).
    final p = h.puzzle;
    late GridCell a, b;
    search:
    for (final x in p.grid.cells) {
      for (final y in p.grid.cells) {
        if (x == y || p.groupAt(x) != null || p.groupAt(y) != null) continue;
        final o = p.moveGroup(x, y) as GroupMoved;
        if (connectionEvents(p, o.puzzle).isEmpty) {
          (a, b) = (x, y);
          break search;
        }
      }
    }
    await move(h, (a, b));
    expect(h.state.swaps, 1);
    expect(h.game.praise.bursts, isEmpty);
  });

  testWidgets('praise never blocks dragging', (tester) async {
    final h = await pumpPuzzle(tester, seed: seed);
    await move(h, pairMove);
    expect(h.game.praise.current, isNotNull);
    expect(h.game.inputEnabled, isTrue);
    // Drag right through the praise area.
    final before = h.state.swaps;
    await move(h, growMove);
    expect(h.state.swaps, before + 1);
  });

  testWidgets('the completing move shows Perfect! with the celebration, '
      'never connection praise', (tester) async {
    final h = await pumpPuzzle(tester, seed: seed);
    // Bring the board to one swap from complete via the domain path the
    // UI uses (moveTile), then make the final move with a real drag.
    while (h.puzzle.correctCount < h.puzzle.tileCount - 2) {
      final t = h.puzzle.tiles.firstWhere((t) => !h.puzzle.isTileCorrect(t));
      h.container
          .read(puzzleControllerProvider.notifier)
          .moveTile(h.puzzle.cellOf(t), t.target);
      await h.settle(frames: 8);
    }
    await h.settle(frames: 30);
    final last = h.puzzle.tiles.firstWhere((t) => !h.puzzle.isTileCorrect(t));
    await move(h, (h.puzzle.cellOf(last), last.target));
    expect(h.puzzle.isComplete, isTrue);
    expect(shown(h), 'Perfect!');
    expect(h.game.isAnimating, isTrue, reason: 'celebration running');
    // Completion still leads to the completion card.
    await h.settle(frames: 40);
    expect(find.byKey(const Key('completion')), findsOneWidget);
  });

  testWidgets('reduced motion: praise fades without bounce or sparkles', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final h = await pumpPuzzle(tester, seed: seed);
    expect(h.game.reduceMotion, isTrue);
    await move(h, pairMove);
    final b = h.game.praise.current!;
    expect(b.currentScale, 1);
    expect(b.timeline.sparkleAt(0, PraiseBurst.sparkleCount, b.elapsed), 0);
  });

  test('praise styles exist for every level', () {
    for (final l in PraiseLevel.values) {
      expect(PraiseStyle.byLevel[l], isNotNull);
    }
  });
}

WidgetTester tester(Harness h) => h.tester;
