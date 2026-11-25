# Jigsaw Cards app

Flutter shell and Flame board for the first playable 4×4 rectangular puzzle. Puzzle rules live in the pure-Dart [`puzzle_domain`](../packages/puzzle_domain) package.

```
lib/
  main.dart                  ProviderScope, portrait, theme
  state/puzzle_controller.dart  Riverpod Notifier (ADR-0003)
  game/puzzle_game_bridge.dart  PuzzleGameView / PuzzleGameIntents (ADR-0001)
  game/puzzle_game.dart         Flame board, locked and floating pieces
  ui/puzzle_screen.dart         header, tray, completion; owns the bridge
  ui/tray.dart                  two-row horizontally scrollable tray
  ui/play_area_layout.dart      geometry shared by tray and board
  artwork/puzzle_artwork.dart   TEMPORARY code-drawn placeholder art
```

Run from the repository root workspace:

```sh
flutter test                 # in app/
flutter run --dart-define=PUZZLE_SEED=42   # fixed puzzle; omit for a time-based seed
```

Provisional choices and limitations are listed in [IMPLEMENTATION_STATUS](../planning/IMPLEMENTATION_STATUS.md).
