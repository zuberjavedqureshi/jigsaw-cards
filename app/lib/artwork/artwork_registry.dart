import '../progression/level.dart';
import '../progression/level_catalogue.dart';
import 'puzzle_artwork.dart';

/// Pictures that actually exist, by id. Only Sunny Meadows level 1 has a
/// picture so far (the approved Sunny Castle placeholder, unchanged). Other
/// levels get theirs in later content milestones; missing pictures are
/// never substituted.
final Map<ArtworkId, PuzzleArtwork> artworkRegistry = Map.unmodifiable({
  ArtworkId(LevelId.first.key): const PlaceholderDaytimeArtwork(),
});

/// The picture registered under [id], or null.
PuzzleArtwork? artworkFor(ArtworkId id) => artworkRegistry[id];

/// Whether [level] can be played: its picture is registered.
bool isPlayable(LevelId level) =>
    artworkFor(levelConfigFor(level).artworkId) != null;

/// The picture of a playable [level]. Throws [ArgumentError] naming the
/// level if its picture is not available.
PuzzleArtwork playableArtworkFor(LevelId level) {
  final artwork = artworkFor(levelConfigFor(level).artworkId);
  if (artwork == null) {
    throw ArgumentError.value(
      level,
      'level',
      '${level.world.title} level ${level.number} is not playable yet '
          '(no artwork)',
    );
  }
  return artwork;
}
