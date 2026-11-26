import 'dart:math' as math;

/// Timing of one praise animation (seconds; provisional tuning values).
class PraiseTiming {
  const PraiseTiming({
    this.popIn = 0.16,
    this.settle = 0.22,
    this.hold = 0.55,
    this.fadeOut = 0.32,
    this.dismiss = 0.16,
  });

  /// Quick scale-up.
  final double popIn;

  /// Subtle bounce down to the resting size.
  final double settle;

  /// Fully visible at rest.
  final double hold;

  /// Text and sparkles fade out.
  final double fadeOut;

  /// Fade when a newer praise replaces this one.
  final double dismiss;

  double get total => popIn + settle + hold + fadeOut;
}

/// Pure maths of a praise animation: scale, opacity and sparkles at time
/// `t` (seconds since it started). [dismissedAt] shortens it gracefully
/// when a newer praise supersedes it. With [reduceMotion] the text simply
/// fades in and out at full size, without sparkles.
class PraiseTimeline {
  const PraiseTimeline({
    this.timing = const PraiseTiming(),
    this.reduceMotion = false,
  });

  final PraiseTiming timing;
  final bool reduceMotion;

  static const startScale = 0.35;
  static const peakScale = 1.18;

  double scaleAt(double t) {
    if (reduceMotion) return 1;
    final s = timing;
    if (t <= 0) return startScale;
    if (t < s.popIn) {
      final p = t / s.popIn;
      final e = 1 - math.pow(1 - p, 3).toDouble(); // ease out cubic
      return startScale + (peakScale - startScale) * e;
    }
    if (t < s.popIn + s.settle) {
      // Damped bounce: peak → slightly under 1 → 1.
      final p = (t - s.popIn) / s.settle;
      return 1 + (peakScale - 1) * (1 - p) * math.cos(p * 1.5 * math.pi);
    }
    return 1;
  }

  double opacityAt(double t, {double? dismissedAt}) {
    final s = timing;
    if (t <= 0) return 0;
    var o = 1.0;
    final fadeIn = s.popIn * 0.6;
    if (t < fadeIn) o = t / fadeIn;
    final fadeStart = s.total - s.fadeOut;
    if (t > fadeStart) o = math.max(0, 1 - (t - fadeStart) / s.fadeOut);
    if (dismissedAt != null && t > dismissedAt) {
      o *= math.max(0, 1 - (t - dismissedAt) / s.dismiss);
    }
    return o.clamp(0.0, 1.0);
  }

  bool isFinishedAt(double t, {double? dismissedAt}) =>
      t >= timing.total ||
      (dismissedAt != null && t >= dismissedAt + timing.dismiss);

  /// Sparkle [i] of [count]: 0 before it appears, rising to 1 and back to 0
  /// (a twinkle); always 0 with [reduceMotion].
  double sparkleAt(int i, int count, double t) {
    if (reduceMotion) return 0;
    final start = timing.popIn * 0.5 + (i / count) * 0.25;
    const life = 0.6;
    final p = (t - start) / life;
    if (p <= 0 || p >= 1) return 0;
    return math.sin(p * math.pi);
  }
}
