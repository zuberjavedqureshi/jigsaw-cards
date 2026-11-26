/// One timed step of the completion celebration, in seconds from its start.
class CelebrationStep {
  const CelebrationStep(this.id, {required this.start, required this.duration});

  final String id;
  final double start;
  final double duration;

  double get end => start + duration;
}

/// Pure timeline of the completion celebration (PRD GP-39), shared by every
/// puzzle. It is a list of named steps so future steps (for example the
/// card reveal and coin animation, GP-10 and GP-11) can be appended without
/// restructuring; this milestone has only visual steps and **no rewards**.
class CelebrationTimeline {
  CelebrationTimeline(List<CelebrationStep> steps)
    : steps = List.unmodifiable(steps) {
    if (steps.isEmpty) throw ArgumentError('at least one step');
    final ids = steps.map((s) => s.id).toSet();
    if (ids.length != steps.length) throw ArgumentError('duplicate step ids');
  }

  /// The M3.1 celebration: a light sweep across the finished picture, then
  /// a short sparkle burst overlapping it. About 1.1 s in total.
  factory CelebrationTimeline.standard() => CelebrationTimeline(const [
    CelebrationStep(shine, start: 0, duration: 0.7),
    CelebrationStep(sparkle, start: 0.3, duration: 0.8),
  ]);

  static const shine = 'shine';
  static const sparkle = 'sparkle';

  final List<CelebrationStep> steps;

  double get totalDuration =>
      steps.map((s) => s.end).reduce((a, b) => a > b ? a : b);

  CelebrationStep? step(String id) {
    for (final s in steps) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Progress of step [id] at time [t]: 0 before it starts, 1 once done.
  double progress(String id, double t) {
    final s = step(id);
    if (s == null) return 0;
    final p = (t - s.start) / s.duration;
    return p < 0 ? 0 : (p > 1 ? 1 : p);
  }

  bool isFinishedAt(double t) => t >= totalDuration;
}
