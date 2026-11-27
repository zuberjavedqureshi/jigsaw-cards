import 'dart:math' as math;

/// Lifecycle of the puzzle introduction (shared by every puzzle).
enum IntroPhase {
  /// Not started: every tile is off-screen, showing its back.
  idle,

  /// Card backs fly in from below and settle into their cells.
  entering,

  /// Every tile has arrived; tiles flip to their picture one after another.
  revealing,

  /// Every tile shows its picture; gameplay may start.
  ready,
}

/// Timings of the introduction, in seconds. Provisional starting values,
/// to be tuned on a device.
class IntroTiming {
  const IntroTiming({
    this.enterStagger = 0.085,
    this.enterDuration = 0.40,
    this.revealDelay = 0.04,
    this.flipDuration = 0.22,
    this.revealStagger = 0.05,
  });

  /// Delay between two consecutive tiles starting their entrance.
  final double enterStagger;

  /// Flight time of one tile from below the screen into its cell.
  final double enterDuration;

  /// Pause between the last tile settling and the first flip.
  final double revealDelay;

  /// Duration of one card flip.
  final double flipDuration;

  /// Delay between two consecutive flips.
  final double revealStagger;

  /// Board size the default timing was tuned for (4×4).
  static const referenceCellCount = 16;

  /// Timing for a board of [cellCount] tiles, keeping the introduction at
  /// the length of the 4×4 one (about 2.69 s). Boards of up to
  /// [referenceCellCount] tiles get [base] itself, unchanged. Larger boards
  /// scale only the two per-tile delays by
  /// `(referenceCellCount − 1) / (cellCount − 1)`; flight time, the pause
  /// before the reveal and flip time stay the same, so each tile looks and
  /// moves exactly as before.
  static IntroTiming forCellCount(
    int cellCount, {
    IntroTiming base = const IntroTiming(),
  }) {
    if (cellCount <= referenceCellCount) return base;
    final k = (referenceCellCount - 1) / (cellCount - 1);
    return IntroTiming(
      enterStagger: base.enterStagger * k,
      enterDuration: base.enterDuration,
      revealDelay: base.revealDelay,
      flipDuration: base.flipDuration,
      revealStagger: base.revealStagger * k,
    );
  }
}

/// Pure timeline of the introduction for a board of [cellCount] cells.
///
/// It is keyed by **board cell** (row-major index), not by puzzle tile, so
/// it never depends on a puzzle's image, solution or shuffle: whatever tile
/// sits in a cell is animated into that cell. Every query is a pure function
/// of elapsed time, so the sequence is deterministic and can be resumed
/// after pauses or resizes without restarting.
class IntroTimeline {
  IntroTimeline({
    required this.cellCount,
    required List<int> entranceOrder,
    required List<int> revealOrder,
    this.timing = const IntroTiming(),
  }) : entranceOrder = List.unmodifiable(entranceOrder),
       revealOrder = List.unmodifiable(revealOrder),
       _entranceRank = _ranks(entranceOrder, cellCount),
       _revealRank = _ranks(revealOrder, cellCount);

  /// Default timeline for a `rows × columns` board: tiles enter row by row
  /// from the top-left (as in the reference recording) and are revealed in
  /// a fixed scattered order that depends only on the board size.
  factory IntroTimeline.forGrid(
    int rows,
    int columns, {
    IntroTiming timing = const IntroTiming(),
  }) {
    final n = rows * columns;
    return IntroTimeline(
      cellCount: n,
      entranceOrder: [for (var i = 0; i < n; i++) i],
      revealOrder: scatteredOrder(n),
      timing: timing,
    );
  }

  /// A fixed, scattered permutation of `0 … n−1` (same for every puzzle of
  /// that size), so the reveal reads as one coordinated sparkle rather than
  /// a mechanical sweep.
  static List<int> scatteredOrder(int n) =>
      [for (var i = 0; i < n; i++) i]..shuffle(math.Random(7919 + n));

  final int cellCount;
  final List<int> entranceOrder;
  final List<int> revealOrder;
  final IntroTiming timing;
  final List<int> _entranceRank;
  final List<int> _revealRank;

  static List<int> _ranks(List<int> order, int n) {
    if (order.length != n || order.toSet().length != n) {
      throw ArgumentError('order must be a permutation of 0..${n - 1}');
    }
    final ranks = List.filled(n, 0);
    for (var r = 0; r < n; r++) {
      if (order[r] < 0 || order[r] >= n) {
        throw ArgumentError('order must be a permutation of 0..${n - 1}');
      }
      ranks[order[r]] = r;
    }
    return ranks;
  }

  /// When the last tile has settled.
  double get entranceEnd =>
      (cellCount - 1) * timing.enterStagger + timing.enterDuration;

  /// When the first flip starts (only after every tile has arrived).
  double get revealStart => entranceEnd + timing.revealDelay;

  /// When the last flip ends: gameplay becomes ready.
  double get totalDuration =>
      revealStart +
      (cellCount - 1) * timing.revealStagger +
      timing.flipDuration;

  IntroPhase phaseAt(double t) {
    if (t <= 0) return IntroPhase.idle;
    if (t < entranceEnd) return IntroPhase.entering;
    if (t < totalDuration) return IntroPhase.revealing;
    return IntroPhase.ready;
  }

  /// Linear entrance progress of [cell] at time [t] (0 = not started,
  /// 1 = settled).
  double entranceProgress(int cell, double t) => _clamp01(
    (t - _entranceRank[cell] * timing.enterStagger) / timing.enterDuration,
  );

  /// Flip progress of [cell] at [t]: 0 = back, 1 = picture.
  double faceProgress(int cell, double t) => _clamp01(
    (t - revealStart - _revealRank[cell] * timing.revealStagger) /
        timing.flipDuration,
  );

  /// Time at which [cell] passes the edge-on point of its flip and starts
  /// showing its picture.
  double revealMoment(int cell) =>
      revealStart +
      _revealRank[cell] * timing.revealStagger +
      timing.flipDuration / 2;

  static double _clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);
}

/// Easing helpers (kept here so the timeline stays free of Flutter).
double easeOutCubic(double t) => 1 - math.pow(1 - t, 3).toDouble();

double easeOutBack(double t, [double overshoot = 1.4]) {
  final c3 = overshoot + 1;
  return 1 + c3 * math.pow(t - 1, 3) + overshoot * math.pow(t - 1, 2);
}

double easeInOut(double t) =>
    t < 0.5 ? 4 * t * t * t : 1 - math.pow(-2 * t + 2, 3) / 2;
