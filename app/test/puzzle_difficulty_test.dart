import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_cards/artwork/puzzle_artwork.dart';
import 'package:jigsaw_cards/state/puzzle_difficulty.dart';
import 'package:puzzle_domain/puzzle_domain.dart';

void main() {
  test('each difficulty maps to its square grid', () {
    expect(PuzzleDifficulty.easy.grid, GridSize(4, 4));
    expect(PuzzleDifficulty.medium.grid, GridSize(5, 5));
    expect(PuzzleDifficulty.hard.grid, GridSize(6, 6));
    for (final d in PuzzleDifficulty.values) {
      expect(d.grid.rows, d.grid.columns, reason: '$d is square');
      expect(d.grid.rows, d.size);
    }
  });

  test('labels', () {
    expect(PuzzleDifficulty.easy.label, 'Easy');
    expect(PuzzleDifficulty.medium.label, 'Medium');
    expect(PuzzleDifficulty.hard.label, 'Hard');
  });

  test('Easy uses the existing Sunny Castle artwork (1024 × 1024)', () {
    final a = artworkFor(PuzzleDifficulty.easy);
    expect(a, isA<PlaceholderDaytimeArtwork>());
    expect(a!.title, 'Sunny Castle');
    expect(a.sourceSize, const Size(1024, 1024));
  });

  test('Medium and Hard have no artwork yet', () {
    expect(artworkFor(PuzzleDifficulty.medium), isNull);
    expect(artworkFor(PuzzleDifficulty.hard), isNull);
  });

  test('only Easy is playable', () {
    expect(playableDifficulties, {PuzzleDifficulty.easy});
    expect(playableArtworkFor(PuzzleDifficulty.easy).title, 'Sunny Castle');
    for (final d in [PuzzleDifficulty.medium, PuzzleDifficulty.hard]) {
      expect(
        () => playableArtworkFor(d),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains(d.label),
          ),
        ),
      );
    }
  });
}
