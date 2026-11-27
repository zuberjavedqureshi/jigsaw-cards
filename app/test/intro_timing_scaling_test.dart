import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_cards/game/intro/intro_timeline.dart';

import 'puzzle_test_harness.dart';

void main() {
  const base = IntroTiming();
  const target = 2.685; // the approved 4×4 introduction length

  test('4×4 (and smaller) keeps the exact original timing object', () {
    expect(identical(IntroTiming.forCellCount(16), base), isTrue);
    expect(identical(IntroTiming.forCellCount(9), base), isTrue);
    final t = IntroTiming.forCellCount(16);
    expect(t.enterStagger, 0.085);
    expect(t.enterDuration, 0.40);
    expect(t.revealDelay, 0.04);
    expect(t.flipDuration, 0.22);
    expect(t.revealStagger, 0.05);
    final tl = IntroTimeline.forGrid(4, 4, timing: t);
    expect(tl.totalDuration, closeTo(target, 1e-9));
    expect(tl.entranceEnd, closeTo(1.675, 1e-9));
  });

  test('5×5 lasts as long as 4×4: only the per-tile delays shrink', () {
    final t = IntroTiming.forCellCount(25);
    expect(t.enterStagger, closeTo(0.085 * 15 / 24, 1e-12));
    expect(t.revealStagger, closeTo(0.05 * 15 / 24, 1e-12));
    expect(t.enterDuration, base.enterDuration, reason: 'same flight');
    expect(t.flipDuration, base.flipDuration, reason: 'same flip');
    expect(t.revealDelay, base.revealDelay);
    final tl = IntroTimeline.forGrid(5, 5, timing: t);
    expect(tl.totalDuration, closeTo(target, 1e-9));
    expect(tl.entranceEnd, closeTo(1.675, 1e-9));
    // Without scaling it would take 3.9 s.
    expect(IntroTimeline.forGrid(5, 5).totalDuration, closeTo(3.9, 1e-9));
  });

  test('5×5 order and phases are well formed', () {
    final tl = IntroTimeline.forGrid(
      5,
      5,
      timing: IntroTiming.forCellCount(25),
    );
    expect(tl.entranceOrder, List.generate(25, (i) => i));
    expect(tl.revealOrder.toSet(), {for (var i = 0; i < 25; i++) i});
    expect(tl.phaseAt(0), IntroPhase.idle);
    expect(tl.phaseAt(tl.entranceEnd - 0.001), IntroPhase.entering);
    expect(tl.phaseAt(tl.entranceEnd + 0.001), IntroPhase.revealing);
    expect(tl.phaseAt(tl.totalDuration), IntroPhase.ready);
    // Every tile has landed before the first flip, and every flip ends by
    // the total duration.
    for (var c = 0; c < 25; c++) {
      expect(tl.entranceProgress(c, tl.entranceEnd), 1);
      expect(tl.faceProgress(c, tl.revealStart), 0);
      expect(tl.faceProgress(c, tl.totalDuration), 1);
    }
  });

  testWidgets('the screen gives the 4×4 game its original timing', (
    tester,
  ) async {
    final h = await pumpPuzzle(tester, seed: 1000);
    expect(identical(h.game.introTiming, base), isTrue);
    expect(h.game.intro.timeline.totalDuration, closeTo(target, 1e-9));
  });
}
