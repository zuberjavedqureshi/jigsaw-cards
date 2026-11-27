import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_cards/artwork/artwork_registry.dart';
import 'package:jigsaw_cards/artwork/puzzle_artwork.dart';
import 'package:jigsaw_cards/progression/level.dart';
import 'package:jigsaw_cards/progression/level_catalogue.dart';
import 'package:jigsaw_cards/progression/world.dart';

void main() {
  test('only Sunny Meadows level 1 has a picture: Sunny Castle, unchanged', () {
    expect(artworkRegistry, hasLength(1));
    final a = artworkFor(levelConfigFor(LevelId.first).artworkId);
    expect(a, isA<PlaceholderDaytimeArtwork>());
    expect(a!.title, 'Sunny Castle');
    expect(a.sourceSize, const Size(1024, 1024));
  });

  test('Sunny Meadows level 1 is playable; every other level is not', () {
    expect(isPlayable(LevelId.first), isTrue);
    expect(playableArtworkFor(LevelId.first).title, 'Sunny Castle');
    final others = levelCatalogue.where((c) => c.id != LevelId.first);
    expect(others, hasLength(49));
    for (final c in others) {
      expect(isPlayable(c.id), isFalse, reason: c.id.key);
      expect(artworkFor(c.artworkId), isNull, reason: 'no substitute');
    }
  });

  test('an unavailable level is rejected with a clear error', () {
    final l = LevelId(WorldId.enchantedForest, 3);
    expect(
      () => playableArtworkFor(l),
      throwsA(
        isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          'Enchanted Forest level 3 is not playable yet (no artwork)',
        ),
      ),
    );
    expect(
      () => playableArtworkFor(LevelId(WorldId.sunnyMeadows, 2)),
      throwsArgumentError,
    );
  });
}
