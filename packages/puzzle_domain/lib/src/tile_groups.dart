import 'grid.dart';
import 'picture_puzzle.dart';

/// Why a group move was refused. The board is unchanged.
enum GroupMoveRejection {
  /// A cell is outside the grid, or the moved group would not fit on it.
  outOfBounds,

  /// The tile was dropped where it already is.
  sameCell,

  /// The puzzle is already complete.
  complete,
}

sealed class GroupMoveOutcome {
  const GroupMoveOutcome();
}

/// A unit (a connected group, or a single tile) moved by ([rowOffset],
/// [columnOffset]) and the tiles it displaced filled the cells it left.
final class GroupMoved extends GroupMoveOutcome {
  const GroupMoved({
    required this.puzzle,
    required this.from,
    required this.to,
    required this.unit,
    required this.displaced,
  });

  /// The board after the move.
  final PicturePuzzle puzzle;

  /// The grabbed tile's cell and the cell it was dropped on.
  final GridCell from;
  final GridCell to;

  /// Cells of the moved unit before the move (includes [from]).
  final Set<GridCell> unit;

  /// For every displaced tile: its cell before → its cell after.
  final Map<GridCell, GridCell> displaced;

  /// Row/column offset of the move.
  int get rowOffset => to.row - from.row;
  int get columnOffset => to.column - from.column;

  /// Cells the unit occupies after the move.
  Set<GridCell> get destination => {
    for (final c in unit) GridCell(c.row + rowOffset, c.column + columnOffset),
  };

  bool get completedPuzzle => puzzle.isComplete;
}

final class GroupMoveRejected extends GroupMoveOutcome {
  const GroupMoveRejected(this.reason);
  final GroupMoveRejection reason;
}

/// Connected tiles (M3.2), as a small extension of the picture-swap model.
/// [PicturePuzzle] itself is unchanged: groups are never stored, they are
/// derived from the current arrangement every time, so membership is always
/// up to date after any move.
extension TileGroups on PicturePuzzle {
  /// Groups of two or more tiles joined by **relative** picture alignment:
  /// two tiles that touch on the board join when they touch the same way in
  /// the original picture, i.e. both are shifted from their correct cells
  /// by the same offset. Joining is transitive. A group need not be at its
  /// final position (correctly placed tiles are the zero-offset case).
  ///
  /// Each group is a set of cells; groups are listed by their first cell in
  /// row-major order. A tile with no aligned neighbour is in no group.
  List<Set<GridCell>> get connectedGroups {
    final seen = <GridCell>{};
    final groups = <Set<GridCell>>[];
    for (final start in grid.cells) {
      if (seen.contains(start)) continue;
      final shift = _shiftAt(start);
      final group = <GridCell>{start};
      seen.add(start);
      final queue = [start];
      while (queue.isNotEmpty) {
        final c = queue.removeLast();
        for (final n in _neighbours(c)) {
          if (_shiftAt(n) == shift && seen.add(n)) {
            group.add(n);
            queue.add(n);
          }
        }
      }
      if (group.length > 1) groups.add(Set.unmodifiable(group));
    }
    return groups;
  }

  /// The connected group containing [cell], or null if its tile is in no
  /// group.
  Set<GridCell>? groupAt(GridCell cell) {
    for (final g in connectedGroups) {
      if (g.contains(cell)) return g;
    }
    return null;
  }

  /// What moves when the tile in [cell] is dragged: its whole connected
  /// group, or just that tile.
  Set<GridCell> unitAt(GridCell cell) => groupAt(cell) ?? {cell};

  /// Drags the tile in [from] — together with its connected group — so that
  /// it lands on [to]. Every tile of the unit moves by the same offset
  /// (`to − from`), keeping its shape. The board stays fully occupied: the
  /// tiles in the destination cells that the unit does not already cover
  /// slide back against the drag direction into the cells the unit left.
  ///
  /// For a single tile this is exactly [PicturePuzzle.swap], with any tile
  /// (as in M3.1). A group move is refused only if the group would not fit
  /// on the board. Tiles of another group in the way are displaced like any
  /// other tile: a group displaced whole keeps its shape (and stays joined);
  /// tiles knocked out of a group rejoin whatever they now line up with.
  ///
  /// Every board stays solvable: dragging any group so that its tiles land
  /// in their own cells is always allowed, never disturbs a correctly placed
  /// tile and adds at least one correct tile.
  GroupMoveOutcome moveGroup(GridCell from, GridCell to) {
    if (!grid.contains(from) || !grid.contains(to)) {
      return const GroupMoveRejected(GroupMoveRejection.outOfBounds);
    }
    if (from == to) return const GroupMoveRejected(GroupMoveRejection.sameCell);
    if (isComplete) return const GroupMoveRejected(GroupMoveRejection.complete);

    final dr = to.row - from.row;
    final dc = to.column - from.column;
    GridCell shift(GridCell c, int k) =>
        GridCell(c.row + k * dr, c.column + k * dc);

    final unit = unitAt(from);
    final dest = {for (final c in unit) shift(c, 1)};
    if (!dest.every(grid.contains)) {
      return const GroupMoveRejected(GroupMoveRejection.outOfBounds);
    }

    // Each displaced tile (in a destination cell the unit does not cover)
    // slides back by the offset until it leaves the destination; it then
    // lands in a cell the unit vacated. When the unit's old and new cells
    // do not overlap, every displaced tile moves by exactly −offset, so the
    // displaced block keeps its shape.
    final displaced = <GridCell, GridCell>{};
    for (final c in dest) {
      if (unit.contains(c)) continue;
      var k = 1;
      while (dest.contains(shift(c, -k))) {
        k++;
      }
      displaced[c] = shift(c, -k);
    }

    final PicturePuzzle next;
    if (unit.length == 1) {
      // A single tile: the original picture-swap move.
      next = (swap(from, to) as TilesSwapped).puzzle;
    } else {
      final before = arrangement;
      final after = [...before];
      int index(GridCell c) => c.row * grid.columns + c.column;
      for (final c in unit) {
        after[index(shift(c, 1))] = before[index(c)];
      }
      displaced.forEach((a, b) => after[index(b)] = before[index(a)]);
      next = PicturePuzzle.fromArrangement(grid, source, after);
    }
    return GroupMoved(
      puzzle: next,
      from: from,
      to: to,
      unit: Set.unmodifiable(unit),
      displaced: Map.unmodifiable(displaced),
    );
  }

  /// How far the tile in [c] is from its correct cell.
  (int, int) _shiftAt(GridCell c) {
    final t = tileAt(c).target;
    return (c.row - t.row, c.column - t.column);
  }

  Iterable<GridCell> _neighbours(GridCell c) sync* {
    for (final n in [
      GridCell(c.row - 1, c.column),
      GridCell(c.row + 1, c.column),
      GridCell(c.row, c.column - 1),
      GridCell(c.row, c.column + 1),
    ]) {
      if (grid.contains(n)) yield n;
    }
  }
}
