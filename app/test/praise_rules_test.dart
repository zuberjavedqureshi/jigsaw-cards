import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_cards/game/praise/praise_rules.dart';
import 'package:jigsaw_cards/game/praise/praise_timeline.dart';
import 'package:puzzle_domain/puzzle_domain.dart';

ConnectionEvent event(ConnectionKind kind, int size, {int groups = 0}) =>
    ConnectionEvent(
      kind: kind,
      cells: {for (var i = 0; i < size; i++) GridCell(i ~/ 4, i % 4)},
      groupsJoined: groups,
      tilesAdded: size,
    );

void main() {
  const rules = PraiseRules();

  group('praise selection', () {
    test('pair → Nice, growth → Great, merge → Amazing', () {
      expect(rules.levelFor(event(ConnectionKind.formed, 2)), PraiseLevel.nice);
      expect(rules.levelFor(event(ConnectionKind.grew, 3)), PraiseLevel.great);
      expect(
        rules.levelFor(event(ConnectionKind.merged, 4, groups: 2)),
        PraiseLevel.amazing,
      );
      // Three loose tiles joining at once count as more than a pair.
      expect(
        rules.levelFor(event(ConnectionKind.formed, 3)),
        PraiseLevel.great,
      );
    });

    test('the large-group threshold is 10 tiles by default', () {
      expect(rules.largeGroupSize, 10);
      for (final k in ConnectionKind.values) {
        expect(rules.levelFor(event(k, 10)), PraiseLevel.fantastic);
      }
      expect(rules.levelFor(event(ConnectionKind.grew, 9)), PraiseLevel.great);
      expect(
        rules.levelFor(event(ConnectionKind.merged, 9, groups: 2)),
        PraiseLevel.amazing,
      );
      const custom = PraiseRules(largeGroupSize: 12);
      expect(
        custom.levelFor(event(ConnectionKind.grew, 11)),
        PraiseLevel.great,
      );
      expect(
        custom.levelFor(event(ConnectionKind.grew, 12)),
        PraiseLevel.fantastic,
      );
    });

    test('text comes from the configurable vocabulary', () {
      final p = rules.select([
        event(ConnectionKind.formed, 2),
      ], completed: false)!;
      expect(p.text, 'Nice!');
      const custom = PraiseRules(messages: {PraiseLevel.nice: 'Yay!'});
      expect(
        custom.select([
          event(ConnectionKind.formed, 2),
        ], completed: false)!.text,
        'Yay!',
      );
      expect(
        {for (final l in PraiseLevel.values) rules.messages[l]},
        {'Nice!', 'Great!', 'Amazing!', 'Fantastic!', 'Perfect!'},
      );
    });

    test('several connections in one move: the strongest wins', () {
      final p = rules.select([
        event(ConnectionKind.formed, 2),
        event(ConnectionKind.merged, 4, groups: 2),
        event(ConnectionKind.grew, 3),
      ], completed: false)!;
      expect(p.level, PraiseLevel.amazing);
      final tie = rules.select([
        event(ConnectionKind.grew, 3),
        event(ConnectionKind.grew, 5),
      ], completed: false)!;
      expect(tie.cells, hasLength(5));
    });

    test('no connection, no praise', () {
      expect(rules.select(const [], completed: false), isNull);
    });

    test('completion shows Perfect only, never connection praise', () {
      final board = {GridCell(0, 0), GridCell(3, 3)};
      final p = rules.select(
        [event(ConnectionKind.merged, 16, groups: 2)],
        completed: true,
        board: board,
      )!;
      expect(p.level, PraiseLevel.perfect);
      expect(p.text, 'Perfect!');
      expect(p.cells, board);
      const quiet = PraiseRules(praiseCompletion: false);
      expect(
        quiet.select([
          event(ConnectionKind.merged, 16, groups: 2),
        ], completed: true),
        isNull,
      );
    });

    test('disabled rules never praise', () {
      const off = PraiseRules(enabled: false);
      expect(
        off.select([event(ConnectionKind.formed, 2)], completed: false),
        isNull,
      );
    });
  });

  group('large-group milestone (once per puzzle)', () {
    Praise pick(List<ConnectionEvent> es, PraiseMilestones m) =>
        rules.select(es, completed: false, milestones: m)!;

    test('growing from 9 to 10 triggers Fantastic; 10 → 11 → 12 does not', () {
      final m = PraiseMilestones();
      expect(pick([event(ConnectionKind.grew, 9)], m).level, PraiseLevel.great);
      expect(m.largeGroupCelebrated, isFalse);
      expect(
        pick([event(ConnectionKind.grew, 10)], m).level,
        PraiseLevel.fantastic,
      );
      expect(m.largeGroupCelebrated, isTrue);
      for (final n in [11, 12, 13]) {
        expect(
          pick([event(ConnectionKind.grew, n)], m).level,
          PraiseLevel.great,
          reason: '$n tiles: ordinary growth praise',
        );
      }
    });

    test('a merge reaching 10 triggers Fantastic if not yet celebrated', () {
      final m = PraiseMilestones();
      expect(
        pick([event(ConnectionKind.merged, 11, groups: 2)], m).level,
        PraiseLevel.fantastic,
      );
      // A later merge into an even bigger group is ordinary Amazing.
      expect(
        pick([event(ConnectionKind.merged, 14, groups: 2)], m).level,
        PraiseLevel.amazing,
      );
    });

    test(
      'a large group formed after the milestone gets no second Fantastic',
      () {
        final m = PraiseMilestones()..largeGroupCelebrated = true;
        expect(
          pick([event(ConnectionKind.merged, 10, groups: 2)], m).level,
          PraiseLevel.amazing,
        );
      },
    );

    test('several events in one move: one praise, milestone marked once', () {
      final m = PraiseMilestones();
      final p = pick([
        event(ConnectionKind.formed, 2),
        event(ConnectionKind.merged, 10, groups: 2),
        event(ConnectionKind.grew, 3),
      ], m);
      expect(p.level, PraiseLevel.fantastic);
      expect(p.cells, hasLength(10));
      expect(m.largeGroupCelebrated, isTrue);
    });

    test('a move without connections leaves the milestone alone', () {
      final m = PraiseMilestones();
      expect(rules.select(const [], completed: false, milestones: m), isNull);
      expect(m.largeGroupCelebrated, isFalse);
    });

    test('completion is always Perfect and does not use the milestone', () {
      final m = PraiseMilestones();
      final p = rules.select(
        [event(ConnectionKind.grew, 16)],
        completed: true,
        milestones: m,
      )!;
      expect(p.level, PraiseLevel.perfect);
      expect(m.largeGroupCelebrated, isFalse);
    });

    test('a new puzzle (fresh milestones) can celebrate again', () {
      final first = PraiseMilestones();
      pick([event(ConnectionKind.grew, 10)], first);
      expect(first.largeGroupCelebrated, isTrue);
      final next = PraiseMilestones();
      expect(
        pick([event(ConnectionKind.grew, 10)], next).level,
        PraiseLevel.fantastic,
      );
    });
  });

  group('pacing gate', () {
    Praise p(PraiseLevel l) => Praise(l, 'x', const {});

    test('repeats of the same or a lower level wait for the interval', () {
      final gate = PraiseGate(const PraiseRules(minInterval: 1.2));
      expect(gate.admit(p(PraiseLevel.great), 0), isTrue);
      expect(gate.admit(p(PraiseLevel.great), 0.5), isFalse);
      expect(gate.admit(p(PraiseLevel.nice), 1.0), isFalse);
      expect(gate.admit(p(PraiseLevel.nice), 1.25), isTrue);
    });

    test('a higher level always passes (and supersedes)', () {
      final gate = PraiseGate(const PraiseRules(minInterval: 1.2));
      expect(gate.admit(p(PraiseLevel.nice), 0), isTrue);
      expect(gate.admit(p(PraiseLevel.great), 0.1), isTrue);
      expect(gate.admit(p(PraiseLevel.fantastic), 0.2), isTrue);
      expect(gate.admit(p(PraiseLevel.perfect), 0.3), isTrue);
      expect(gate.admit(p(PraiseLevel.amazing), 0.4), isFalse);
    });

    test('skipped praise does not restart the interval', () {
      final gate = PraiseGate(const PraiseRules(minInterval: 1));
      expect(gate.admit(p(PraiseLevel.nice), 0), isTrue);
      expect(gate.admit(p(PraiseLevel.nice), 0.9), isFalse);
      expect(gate.admit(p(PraiseLevel.nice), 1.0), isTrue);
    });
  });

  group('animation timeline', () {
    const tl = PraiseTimeline();
    const s = PraiseTiming();

    test('pops in, overshoots, bounces under 1 and settles at 1', () {
      expect(tl.scaleAt(0), PraiseTimeline.startScale);
      expect(tl.scaleAt(s.popIn / 2), greaterThan(PraiseTimeline.startScale));
      expect(tl.scaleAt(s.popIn), closeTo(PraiseTimeline.peakScale, 1e-9));
      var min = double.infinity;
      for (var t = s.popIn; t < s.popIn + s.settle; t += 0.005) {
        min = tl.scaleAt(t) < min ? tl.scaleAt(t) : min;
      }
      expect(min, lessThan(1), reason: 'a subtle bounce');
      expect(min, greaterThan(0.9));
      expect(tl.scaleAt(s.popIn + s.settle + 0.01), 1);
    });

    test('fades in quickly, holds, then fades out and finishes', () {
      expect(tl.opacityAt(0), 0);
      expect(tl.opacityAt(s.popIn), 1);
      expect(tl.opacityAt(s.popIn + s.settle + s.hold / 2), 1);
      expect(tl.opacityAt(s.total - s.fadeOut / 2), closeTo(0.5, 0.01));
      expect(tl.opacityAt(s.total), 0);
      expect(tl.isFinishedAt(s.total - 0.01), isFalse);
      expect(tl.isFinishedAt(s.total), isTrue);
      expect(s.total, lessThan(1.5), reason: 'short and light');
    });

    test('a dismissed praise fades out early', () {
      const d = 0.4;
      expect(tl.opacityAt(d, dismissedAt: d), 1);
      expect(
        tl.opacityAt(d + s.dismiss / 2, dismissedAt: d),
        closeTo(0.5, 1e-9),
      );
      expect(tl.isFinishedAt(d + s.dismiss, dismissedAt: d), isTrue);
    });

    test('sparkles twinkle in and out during the animation', () {
      var seen = 0;
      for (var i = 0; i < 8; i++) {
        var peak = 0.0;
        for (var t = 0.0; t < s.total; t += 0.01) {
          final v = tl.sparkleAt(i, 8, t);
          expect(v, inInclusiveRange(0, 1));
          if (v > peak) peak = v;
        }
        if (peak > 0.9) seen++;
        expect(tl.sparkleAt(i, 8, s.total), 0);
      }
      expect(seen, 8);
    });

    test('reduced motion: no bounce, no sparkles, still fades', () {
      const calm = PraiseTimeline(reduceMotion: true);
      for (var t = 0.0; t < s.total; t += 0.02) {
        expect(calm.scaleAt(t), 1);
        expect(calm.sparkleAt(0, 8, t), 0);
      }
      expect(calm.opacityAt(s.popIn + s.settle), 1);
      expect(calm.isFinishedAt(s.total), isTrue);
    });
  });
}
