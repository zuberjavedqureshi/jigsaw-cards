# Jigsaw Cards app

Flutter shell and Flame board for the 4×4 picture-swap puzzle. Puzzle rules live in the pure-Dart [`puzzle_domain`](../packages/puzzle_domain) package.

```
lib/
  main.dart                  ProviderScope, portrait, theme
  state/puzzle_controller.dart  Riverpod Notifier (ADR-0003)
  game/puzzle_game_bridge.dart  PuzzleGameView.syncPuzzle / PuzzleGameIntents (ADR-0001)
  game/puzzle_game.dart         Flame board, tiles, drag-and-swap, animations, input
  ui/puzzle_screen.dart         header, progress, completion
  ui/play_area_layout.dart      board rect and cell geometry (keeps the artwork aspect)
  artwork/puzzle_artwork.dart   TEMPORARY code-drawn placeholder art; tile slicing
```

Run from the repository root workspace:

```sh
flutter test                 # in app/
flutter run --dart-define=PUZZLE_SEED=42   # fixed puzzle; omit for a time-based seed
```

Provisional choices and limitations are listed in [IMPLEMENTATION_STATUS](../planning/IMPLEMENTATION_STATUS.md).
