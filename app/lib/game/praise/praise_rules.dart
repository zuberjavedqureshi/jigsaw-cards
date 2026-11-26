import 'package:puzzle_domain/puzzle_domain.dart';

/// Praise tiers, weakest first (M3.3). A higher tier replaces a lower one.
enum PraiseLevel { nice, great, amazing, fantastic, perfect }

/// A praise message to show for one move.
class Praise {
  const Praise(this.level, this.text, this.cells);

  final PraiseLevel level;
  final String text;

  /// Board cells the praise refers to (where it is anchored).
  final Set<GridCell> cells;

  @override
  String toString() => 'Praise($level, "$text", ${cells.length} cells)';
}

/// Which praise to show for which gameplay result. Presentation policy only:
/// the facts come from the domain ([connectionEvents]); every value here is
/// tunable after playtesting.
class PraiseRules {
  const PraiseRules({
    this.messages = const {
      PraiseLevel.nice: 'Nice!',
      PraiseLevel.great: 'Great!',
      PraiseLevel.amazing: 'Amazing!',
      PraiseLevel.fantastic: 'Fantastic!',
      PraiseLevel.perfect: 'Perfect!',
    },
    this.largeGroupSize = 10,
    this.praiseCompletion = true,
    this.minInterval = 1.2,
    this.enabled = true,
  });

  /// Text for each level.
  final Map<PraiseLevel, String> messages;

  /// The first time in a puzzle that a group reaches at least this many
  /// tiles (by growing or merging), it earns [PraiseLevel.fantastic]. Later
  /// growth of a large group uses the ordinary levels.
  final int largeGroupSize;

  /// Show [PraiseLevel.perfect] when the puzzle is completed (together with
  /// the completion celebration). Ordinary connection praise is never shown
  /// for the completing move.
  final bool praiseCompletion;

  /// Seconds after a praise during which another praise of the same or a
  /// lower level is skipped (a higher level always shows).
  final double minInterval;

  /// Master switch.
  final bool enabled;

  /// The level a connection earns. [largeMilestoneOpen] is false once this
  /// puzzle's large-group milestone has been celebrated.
  PraiseLevel levelFor(ConnectionEvent e, {bool largeMilestoneOpen = true}) {
    if (largeMilestoneOpen && e.size >= largeGroupSize) {
      return PraiseLevel.fantastic;
    }
    return switch (e.kind) {
      ConnectionKind.merged => PraiseLevel.amazing,
      ConnectionKind.grew => PraiseLevel.great,
      ConnectionKind.formed =>
        e.size > 2 ? PraiseLevel.great : PraiseLevel.nice,
    };
  }

  /// The praise for a move with these connection [events], or null. When
  /// the move [completed] the puzzle, only the completion praise is
  /// considered. Several connections in one move: the highest level wins,
  /// then the largest group.
  ///
  /// [milestones] (one per puzzle) records the large-group milestone: when
  /// this returns [PraiseLevel.fantastic] it is marked as celebrated, so it
  /// is never awarded twice in the same puzzle.
  Praise? select(
    List<ConnectionEvent> events, {
    required bool completed,
    Set<GridCell> board = const {},
    PraiseMilestones? milestones,
  }) {
    if (!enabled) return null;
    if (completed) {
      return praiseCompletion
          ? Praise(PraiseLevel.perfect, _text(PraiseLevel.perfect), board)
          : null;
    }
    ConnectionEvent? best;
    PraiseLevel? bestLevel;
    final open = !(milestones?.largeGroupCelebrated ?? false);
    for (final e in events) {
      final l = levelFor(e, largeMilestoneOpen: open);
      if (best == null ||
          l.index > bestLevel!.index ||
          (l == bestLevel && e.size > best.size)) {
        best = e;
        bestLevel = l;
      }
    }
    if (best == null) return null;
    if (bestLevel == PraiseLevel.fantastic) {
      milestones?.largeGroupCelebrated = true;
    }
    return Praise(bestLevel!, _text(bestLevel), best.cells);
  }

  String _text(PraiseLevel l) => messages[l] ?? '';
}

/// Praise milestones already celebrated in one puzzle. Create a fresh one
/// for every puzzle (the game does: a new game per puzzle).
class PraiseMilestones {
  /// A group has already reached [PraiseRules.largeGroupSize] tiles.
  bool largeGroupCelebrated = false;
}

/// Keeps praise from piling up during rapid play: a praise of the same or
/// a lower level than the last one is skipped within [PraiseRules.minInterval]
/// seconds; a higher level always passes (and replaces the visible one).
class PraiseGate {
  PraiseGate(this.rules);

  final PraiseRules rules;
  double? _lastTime;
  PraiseLevel? _lastLevel;

  bool admit(Praise p, double now) {
    final last = _lastTime;
    final ok =
        last == null ||
        now - last >= rules.minInterval ||
        p.level.index > _lastLevel!.index;
    if (ok) {
      _lastTime = now;
      _lastLevel = p.level;
    }
    return ok;
  }
}
