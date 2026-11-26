import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_cards/game/intro/intro_director.dart';
import 'package:jigsaw_cards/game/intro/intro_timeline.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final tl = IntroTimeline.forGrid(4, 4);
  const timing = IntroTiming();

  test('default timings sit in the requested starting ranges', () {
    expect(timing.enterStagger, inInclusiveRange(0.05, 0.16));
    expect(timing.enterDuration, inInclusiveRange(0.30, 0.45));
    expect(timing.flipDuration, inInclusiveRange(0.18, 0.26));
    expect(timing.revealStagger, inInclusiveRange(0.04, 0.08));
    expect(tl.totalDuration, lessThan(3.0), reason: 'energetic, not slow');
  });

  test('phases: idle → entering → revealing → ready', () {
    expect(tl.phaseAt(0), IntroPhase.idle);
    expect(tl.phaseAt(0.01), IntroPhase.entering);
    expect(tl.phaseAt(tl.entranceEnd - 0.001), IntroPhase.entering);
    expect(tl.phaseAt(tl.entranceEnd + 0.001), IntroPhase.revealing);
    expect(tl.phaseAt(tl.totalDuration - 0.001), IntroPhase.revealing);
    expect(tl.phaseAt(tl.totalDuration), IntroPhase.ready);
  });

  test('tiles enter one by one, row by row from the top-left', () {
    expect(tl.entranceOrder, List.generate(16, (i) => i));
    for (var cell = 0; cell < 16; cell++) {
      final start = cell * timing.enterStagger;
      expect(tl.entranceProgress(cell, start), 0);
      expect(tl.entranceProgress(cell, start + timing.enterDuration + 1e-9), 1);
    }
  });

  test('no flip starts before every tile has arrived', () {
    for (var t = 0.0; t < tl.revealStart; t += 0.01) {
      for (var cell = 0; cell < 16; cell++) {
        expect(tl.faceProgress(cell, t), 0);
      }
    }
    for (var cell = 0; cell < 16; cell++) {
      expect(tl.entranceProgress(cell, tl.revealStart), 1);
    }
  });

  test('reveal follows the reveal order with a short stagger', () {
    expect(tl.revealOrder.toSet(), Set.of(List.generate(16, (i) => i)));
    expect(
      tl.revealOrder,
      isNot(List.generate(16, (i) => i)),
      reason: 'scattered, like the reference',
    );
    for (var r = 1; r < 16; r++) {
      expect(
        tl.revealMoment(tl.revealOrder[r]) -
            tl.revealMoment(tl.revealOrder[r - 1]),
        closeTo(timing.revealStagger, 1e-9),
      );
    }
    for (var cell = 0; cell < 16; cell++) {
      expect(tl.faceProgress(cell, tl.totalDuration), 1);
    }
  });

  test('the reveal order depends only on the board size', () {
    expect(IntroTimeline.forGrid(4, 4).revealOrder, tl.revealOrder);
    expect(IntroTimeline.forGrid(3, 5).revealOrder.length, 15);
  });

  test('orders must be permutations', () {
    expect(
      () => IntroTimeline(
        cellCount: 3,
        entranceOrder: [0, 0, 1],
        revealOrder: [0, 1, 2],
      ),
      throwsArgumentError,
    );
  });

  test('flight pose: starts below the play area tilted, ends in the cell', () {
    const area = Size(400, 800);
    final cell = Rect.fromLTWH(100, 100, 80, 80);
    final start = introPose(cell, area, 0);
    expect(start.centre.dy, greaterThan(area.height));
    expect(start.angle, greaterThan(0.2));
    final end = introPose(cell, area, 1);
    expect(end.centre, cell.center);
    expect(end.angle, closeTo(0, 1e-9));
    expect(end.scale, closeTo(1, 1e-9));
    // Rises monotonically.
    var lastY = double.infinity;
    for (var t = 0.0; t <= 1.0; t += 0.05) {
      final y = introPose(cell, area, t).centre.dy;
      expect(y, lessThanOrEqualTo(lastY + 1e-9));
      lastY = y;
    }
  });
}
