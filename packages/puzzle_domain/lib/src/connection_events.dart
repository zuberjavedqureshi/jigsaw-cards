import 'grid.dart';
import 'picture_puzzle.dart';
import 'tile_groups.dart';

/// How a connected group came about in a move (M3.3).
enum ConnectionKind {
  /// Loose tiles joined into a new group (two tiles: a pair).
  formed,

  /// An existing group gained one or more loose tiles.
  grew,

  /// Two or more existing groups joined (possibly with loose tiles).
  merged,
}

/// A connection made by a move: a group in the new arrangement that did not
/// exist before. Facts only; what to show for it is decided by the
/// presentation layer.
final class ConnectionEvent {
  const ConnectionEvent({
    required this.kind,
    required this.cells,
    required this.groupsJoined,
    required this.tilesAdded,
  });

  final ConnectionKind kind;

  /// Cells of the resulting group (after the move).
  final Set<GridCell> cells;

  /// Existing groups that are now part of this group (each still with at
  /// least two of its tiles together).
  final int groupsJoined;

  /// Tiles that were loose before (or left alone by a split group) and
  /// are now part of this group.
  final int tilesAdded;

  /// Tiles in the resulting group.
  int get size => cells.length;

  @override
  String toString() =>
      'ConnectionEvent($kind, size $size, groups $groupsJoined, '
      'added $tilesAdded)';
}

/// The connections made by going from [before] to [after]: one event for
/// every group in [after] that contains tiles which were not already joined
/// together in [before]. Groups that only moved, or became smaller, produce
/// no event. Pure and deterministic; works for any pair of arrangements of
/// the same puzzle.
List<ConnectionEvent> connectionEvents(
  PicturePuzzle before,
  PicturePuzzle after,
) {
  // Tile id → index of its group before the move (loose tiles: none).
  final groupBefore = <int, int>{};
  final beforeGroups = before.connectedGroups;
  for (var i = 0; i < beforeGroups.length; i++) {
    for (final c in beforeGroups[i]) {
      groupBefore[before.tileAt(c).id] = i;
    }
  }
  final events = <ConnectionEvent>[];
  for (final g in after.connectedGroups) {
    // Tiles per former group. A former group counts only if at least two of
    // its tiles are still together here; a single tile left over from a
    // split group counts as loose.
    final perGroup = <int, int>{};
    var loose = 0;
    for (final c in g) {
      final i = groupBefore[after.tileAt(c).id];
      if (i == null) {
        loose++;
      } else {
        perGroup[i] = (perGroup[i] ?? 0) + 1;
      }
    }
    final contributors = <int>{};
    perGroup.forEach((i, n) {
      if (n >= 2) {
        contributors.add(i);
      } else {
        loose += n;
      }
    });
    if (loose == 0 && contributors.length <= 1) continue; // nothing new
    final kind = contributors.length >= 2
        ? ConnectionKind.merged
        : contributors.length == 1
        ? ConnectionKind.grew
        : ConnectionKind.formed;
    events.add(
      ConnectionEvent(
        kind: kind,
        cells: g,
        groupsJoined: contributors.length,
        tilesAdded: loose,
      ),
    );
  }
  return events;
}
