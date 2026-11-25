import 'dart:math';

import 'board_space.dart';
import 'layout.dart';
import 'piece.dart';

/// Initial (scattered) arrangement of pieces: positions and stacking order.
final class StartArrangement {
  StartArrangement({
    required Map<String, BoardPoint> positions,
    required List<String> stackOrder,
  }) : positions = Map.unmodifiable(positions),
       stackOrder = List.unmodifiable(stackOrder);

  final Map<String, BoardPoint> positions;

  /// Piece ids from bottom to top.
  final List<String> stackOrder;
}

/// Produces starting positions for a puzzle. Replaceable; the starting
/// arrangement is a presentation choice, not a product decision.
abstract interface class StartArranger {
  StartArrangement arrange({
    required PuzzleLayout layout,
    required PlayBounds bounds,
    required int seed,
  });
}

/// PROVISIONAL seeded scatter: places larger pieces first, sampling random
/// candidate positions and keeping the one with the least overlap with
/// pieces already placed. A candidate is never within [minTargetDistance]
/// (Chebyshev, cell units) of the piece's own correct position, so no piece
/// starts at or next to where it belongs. Later (smaller) pieces are stacked
/// on top, so they stay visible. Deterministic per seed and bounds.
final class SeededScatterArranger implements StartArranger {
  const SeededScatterArranger({
    this.candidatesPerPiece = 48,
    this.minTargetDistance = 1.0,
    this.step = 0.05,
  });

  final int candidatesPerPiece;
  final double minTargetDistance;

  /// Positions are quantised to this step (cell units).
  final double step;

  @override
  StartArrangement arrange({
    required PuzzleLayout layout,
    required PlayBounds bounds,
    required int seed,
  }) {
    final rng = Random(seed * 7919 + 17);
    final order = [...layout.pieces]
      ..sort((a, b) {
        final byArea = b.size.cellCount.compareTo(a.size.cellCount);
        return byArea != 0 ? byArea : a.id.compareTo(b.id);
      });
    // Shuffle within equal areas so ties do not always follow id order.
    _shuffleWithinAreas(order, rng);

    final placed = <String, BoardPoint>{};
    final sizes = <String, PieceSize>{};
    for (final piece in order) {
      final target = BoardPoint.ofCell(piece.correctOrigin);
      BoardPoint? best;
      var bestScore = double.infinity;
      for (var i = 0; i < candidatesPerPiece; i++) {
        final c = _randomOrigin(rng, bounds, piece.size);
        if (c.chebyshevTo(target) < minTargetDistance) continue;
        var score = 0.0;
        placed.forEach((id, p) {
          score += overlapArea(c, piece.size, p, sizes[id]!);
        });
        if (score < bestScore) {
          bestScore = score;
          best = c;
        }
      }
      best ??= _fallback(piece, bounds, target);
      placed[piece.id] = best;
      sizes[piece.id] = piece.size;
    }
    return StartArrangement(
      positions: placed,
      stackOrder: [for (final p in order) p.id],
    );
  }

  BoardPoint _randomOrigin(Random rng, PlayBounds b, PieceSize s) {
    double q(double lo, double hi) {
      final steps = ((hi - lo) / step).floor();
      return lo + rng.nextInt(steps + 1) * step;
    }

    return b.clampOrigin(
      BoardPoint(
        q(b.left, b.right - s.columnSpan),
        q(b.top, b.bottom - s.rowSpan),
      ),
      s,
    );
  }

  /// Farthest corner from the target; only used if every sample was too
  /// close (not expected with the prototype bounds).
  BoardPoint _fallback(PuzzlePiece piece, PlayBounds b, BoardPoint target) {
    final corners = [
      BoardPoint(b.left, b.top),
      BoardPoint(b.right - piece.size.columnSpan, b.top),
      BoardPoint(b.left, b.bottom - piece.size.rowSpan),
      BoardPoint(
        b.right - piece.size.columnSpan,
        b.bottom - piece.size.rowSpan,
      ),
    ];
    corners.sort(
      (a, c) => c.chebyshevTo(target).compareTo(a.chebyshevTo(target)),
    );
    return corners.first;
  }

  void _shuffleWithinAreas(List<PuzzlePiece> list, Random rng) {
    var start = 0;
    while (start < list.length) {
      var end = start;
      final area = list[start].size.cellCount;
      while (end < list.length && list[end].size.cellCount == area) {
        end++;
      }
      final group = list.sublist(start, end)..shuffle(rng);
      list.setRange(start, end, group);
      start = end;
    }
  }
}
