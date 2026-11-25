import 'dart:math';

import 'grid.dart';

/// Size of the source illustration in source units (e.g. pixels).
final class SourceSize {
  SourceSize(this.width, this.height) {
    if (!(width > 0 && height > 0)) {
      throw ArgumentError('SourceSize must be positive');
    }
  }

  final double width;
  final double height;

  double get aspectRatio => width / height;

  @override
  bool operator ==(Object other) =>
      other is SourceSize && other.width == width && other.height == height;

  @override
  int get hashCode => Object.hash(width, height);
}

/// Region of the source illustration shown by one tile (source units).
final class SourceRect {
  const SourceRect(this.left, this.top, this.width, this.height);
  final double left;
  final double top;
  final double width;
  final double height;

  @override
  bool operator ==(Object other) =>
      other is SourceRect &&
      other.left == left &&
      other.top == top &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(left, top, width, height);

  @override
  String toString() => 'SourceRect($left, $top, $width, $height)';
}

/// One picture tile. Its identity and its correct cell never change; its
/// current cell is held by [PicturePuzzle].
final class PictureTile {
  const PictureTile(this.id, this.target);

  /// Stable identity: the row-major index of the correct cell.
  final int id;

  /// Correct (target) cell.
  final GridCell target;

  @override
  bool operator ==(Object other) =>
      other is PictureTile && other.id == id && other.target == target;

  @override
  int get hashCode => Object.hash(id, target);

  @override
  String toString() => 'PictureTile($id @ $target)';
}

enum SwapRejection {
  /// A cell is outside the grid.
  outOfBounds,

  /// Both cells are the same; nothing to exchange.
  sameCell,

  /// The puzzle is already complete.
  complete,
}

sealed class SwapOutcome {
  const SwapOutcome();
}

/// Two tiles exchanged cells. Incorrect swaps are accepted too.
final class TilesSwapped extends SwapOutcome {
  const TilesSwapped({
    required this.puzzle,
    required this.from,
    required this.to,
    required this.movedTile,
    required this.displacedTile,
  });

  final PicturePuzzle puzzle;

  /// The dragged tile moved [from] → [to]; the other tile moved [to] → [from].
  final GridCell from;
  final GridCell to;
  final PictureTile movedTile;
  final PictureTile displacedTile;

  /// Tiles of this swap that are now in their correct cell.
  List<PictureTile> get nowCorrect =>
      [movedTile, displacedTile].where(puzzle.isTileCorrect).toList();

  bool get completedPuzzle => puzzle.isComplete;
}

final class SwapRejected extends SwapOutcome {
  const SwapRejected(this.reason);
  final SwapRejection reason;
}

/// Rectangular picture-swap puzzle (immutable).
///
/// The source illustration is divided into `rows × columns` equal tiles.
/// Every cell always holds exactly one tile (the arrangement is a
/// permutation), so there are no gaps or overlaps. The only move is
/// [swap]: two tiles exchange cells. Any permutation can be solved by swaps,
/// so every arrangement is solvable.
final class PicturePuzzle {
  PicturePuzzle._(this.grid, this.source, List<int> arrangement, this.seed)
    : _arrangement = List.unmodifiable(arrangement),
      tiles = List.unmodifiable([
        for (var i = 0; i < grid.cellCount; i++) PictureTile(i, grid.cellAt(i)),
      ]) {
    final problems = validateArrangement(grid, _arrangement);
    if (problems.isNotEmpty) {
      throw ArgumentError('Invalid arrangement: ${problems.join('; ')}');
    }
  }

  /// The solved board: tile `i` in cell `i`.
  factory PicturePuzzle.solved(GridSize grid, SourceSize source) =>
      PicturePuzzle._(grid, source, [
        for (var i = 0; i < grid.cellCount; i++) i,
      ], null);

  /// A board with an explicit arrangement (`arrangement[cell] = tileId`),
  /// e.g. restored or for tests. Throws if it is not a permutation.
  factory PicturePuzzle.fromArrangement(
    GridSize grid,
    SourceSize source,
    List<int> arrangement,
  ) => PicturePuzzle._(grid, source, arrangement, null);

  /// A deterministic shuffled board for [seed] (Fisher–Yates with a seeded
  /// generator). It is never already solved, and at least
  /// [minMisplacedFraction] of the tiles start out of place.
  factory PicturePuzzle.shuffled(
    GridSize grid,
    SourceSize source, {
    required int seed,
    double minMisplacedFraction = 0.75,
  }) {
    if (grid.cellCount < 2) {
      throw ArgumentError('A swap puzzle needs at least two tiles');
    }
    final rng = Random(seed);
    final n = grid.cellCount;
    final minMisplaced = max(2, (n * minMisplacedFraction).ceil());
    final a = [for (var i = 0; i < n; i++) i];
    for (var attempt = 0; attempt < 1000; attempt++) {
      for (var i = n - 1; i > 0; i--) {
        final j = rng.nextInt(i + 1);
        final t = a[i];
        a[i] = a[j];
        a[j] = t;
      }
      var misplaced = 0;
      for (var c = 0; c < n; c++) {
        if (a[c] != c) misplaced++;
      }
      if (misplaced >= minMisplaced) {
        return PicturePuzzle._(grid, source, a, seed);
      }
    }
    // Not reached in practice; fall back to a rotation by one (all
    // misplaced), still deterministic.
    return PicturePuzzle._(grid, source, [
      for (var c = 0; c < n; c++) (c + 1) % n,
    ], seed);
  }

  final GridSize grid;
  final SourceSize source;

  /// Seed of the shuffle, if this board came from [PicturePuzzle.shuffled].
  final int? seed;

  /// Every tile, by id. Identity and target never change.
  final List<PictureTile> tiles;

  /// `_arrangement[cellIndex] = tileId`.
  final List<int> _arrangement;

  /// Current arrangement, `arrangement[cellIndex] = tileId`, row-major.
  List<int> get arrangement => _arrangement;

  int _index(GridCell c) => c.row * grid.columns + c.column;

  PictureTile tileAt(GridCell cell) {
    if (!grid.contains(cell)) throw RangeError('$cell is outside the grid');
    return tiles[_arrangement[_index(cell)]];
  }

  GridCell cellOf(PictureTile tile) =>
      grid.cellAt(_arrangement.indexOf(tile.id));

  bool isTileCorrect(PictureTile tile) =>
      _arrangement[_index(tile.target)] == tile.id;

  int get correctCount {
    var n = 0;
    for (var c = 0; c < _arrangement.length; c++) {
      if (_arrangement[c] == c) n++;
    }
    return n;
  }

  int get tileCount => tiles.length;
  bool get isComplete => correctCount == tileCount;

  /// Minimum number of swaps that solves the board (`n − cycles`).
  int get minimumSwapsToSolve {
    final seen = List.filled(_arrangement.length, false);
    var cycles = 0;
    for (var i = 0; i < _arrangement.length; i++) {
      if (seen[i]) continue;
      cycles++;
      var j = i;
      while (!seen[j]) {
        seen[j] = true;
        j = _arrangement[j];
      }
    }
    return _arrangement.length - cycles;
  }

  /// The source region a tile shows: the cell-sized slice of the source at
  /// the tile's *target* cell, so content always follows identity. All
  /// tiles have the same size, so nothing is stretched.
  SourceRect sourceRectOf(PictureTile tile) {
    final w = source.width / grid.columns;
    final h = source.height / grid.rows;
    return SourceRect(tile.target.column * w, tile.target.row * h, w, h);
  }

  /// Exchanges the tiles in [from] and [to]. Wrong swaps are accepted.
  /// Invalid requests are rejected and leave the board unchanged.
  SwapOutcome swap(GridCell from, GridCell to) {
    if (!grid.contains(from) || !grid.contains(to)) {
      return const SwapRejected(SwapRejection.outOfBounds);
    }
    if (from == to) return const SwapRejected(SwapRejection.sameCell);
    if (isComplete) return const SwapRejected(SwapRejection.complete);
    final a = _index(from);
    final b = _index(to);
    final next = [..._arrangement];
    next[a] = _arrangement[b];
    next[b] = _arrangement[a];
    return TilesSwapped(
      puzzle: PicturePuzzle._(grid, source, next, seed),
      from: from,
      to: to,
      movedTile: tiles[_arrangement[a]],
      displacedTile: tiles[_arrangement[b]],
    );
  }
}

/// Occupancy check: the arrangement must place every tile in exactly one
/// cell and fill every cell (a permutation of `0 … cellCount−1`).
List<String> validateArrangement(GridSize grid, List<int> arrangement) {
  final problems = <String>[];
  if (arrangement.length != grid.cellCount) {
    problems.add('expected ${grid.cellCount} cells, got ${arrangement.length}');
  }
  final seen = <int>{};
  for (final id in arrangement) {
    if (id < 0 || id >= grid.cellCount) problems.add('unknown tile $id');
    if (!seen.add(id)) problems.add('tile $id occupies more than one cell');
  }
  if (problems.isEmpty && seen.length != grid.cellCount) {
    problems.add('some tiles are missing');
  }
  return problems;
}
