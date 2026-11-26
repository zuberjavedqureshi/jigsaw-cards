import 'package:flame/game.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../artwork/puzzle_artwork.dart';
import '../game/puzzle_game.dart';
import '../game/puzzle_game_bridge.dart';
import '../state/puzzle_controller.dart';
import 'sunlit_theme.dart';

/// The puzzle screen: a slim header and the Flame board, which fills the
/// rest of the safe area. All communication with the game goes through
/// [PuzzleGameView.syncPuzzle] and [PuzzleGameIntents] (ADR-0001).
class PuzzleScreen extends ConsumerStatefulWidget {
  const PuzzleScreen({super.key});

  @override
  ConsumerState<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends ConsumerState<PuzzleScreen> {
  late final PuzzleArtwork _artwork = ref.read(artworkProvider);

  PuzzleGame? _game;
  int? _gameRound;

  /// True from the first Next puzzle tap until the new puzzle's game
  /// exists: further taps are ignored and sequences never overlap (GP-40).
  bool _transitioning = false;

  PuzzleController get _controller =>
      ref.read(puzzleControllerProvider.notifier);

  PuzzleGame _gameFor(PuzzleState s) {
    if (_game == null || _gameRound != s.round) {
      _gameRound = s.round;
      _transitioning = false;
      // Explicit initial sync: the game starts from the current puzzle.
      _game = PuzzleGame(
        puzzle: s.puzzle,
        artwork: _artwork,
        intents: PuzzleGameIntents(
          onSwapRequested: (from, to) => _controller.swap(from, to),
          onSwapSettled: () {},
          onCompletionShown: () => _controller.completionShown(),
        ),
      );
    }
    return _game!;
  }

  /// Next puzzle: hide the card, clear the board, then start a new puzzle,
  /// whose introduction runs as usual. Only the first tap counts.
  void _nextPuzzle() {
    if (_transitioning) return;
    setState(() => _transitioning = true);
    final started = _game?.playExit(_controller.newPuzzle) ?? false;
    if (!started) _controller.newPuzzle();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(puzzleControllerProvider, (prev, next) {
      if (prev != null && prev.round == next.round) {
        _game?.syncPuzzle(next.puzzle);
      }
    });
    final s = ref.watch(puzzleControllerProvider);
    final game = _gameFor(s);

    return SunlitBackground(
      child: SafeArea(
        child: Column(
          children: [
            _Header(state: s, artwork: _artwork),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GameWidget(
                      key: ValueKey('game_${s.round}'),
                      game: game,
                    ),
                  ),
                  if (s.showCompletion && !_transitioning)
                    Positioned.fill(
                      child: _CompletionOverlay(
                        artwork: _artwork,
                        swaps: s.swaps,
                        onNextPuzzle: _nextPuzzle,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state, required this.artwork});

  final PuzzleState state;
  final PuzzleArtwork artwork;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  artwork.title,
                  key: const Key('title'),
                  style: const TextStyle(
                    color: Sunlit.onBackdrop,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'serif',
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Sunlit.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Sunlit.sunflower, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Sunlit.shadow,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Text(
                    '${state.correctCount} / ${state.tileCount}',
                    key: const Key('progress'),
                    semanticsLabel:
                        '${state.correctCount} of ${state.tileCount} tiles in place',
                    style: const TextStyle(
                      color: Sunlit.deepTeal,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            state.isComplete
                ? 'The picture is whole again!'
                : 'Drag a tile onto another to swap them',
            key: const Key('hint'),
            style: const TextStyle(color: Sunlit.onBackdrop, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// Completion state (GP-39): the finished illustration and a Next puzzle
/// action. No rewards are shown in this milestone; reward presentation
/// attaches here later.
class _CompletionOverlay extends StatelessWidget {
  const _CompletionOverlay({
    required this.artwork,
    required this.swaps,
    required this.onNextPuzzle,
  });

  final PuzzleArtwork artwork;
  final int swaps;
  final VoidCallback onNextPuzzle;

  @override
  Widget build(BuildContext context) {
    final src = artwork.sourceSize;
    return ColoredBox(
      key: const Key('completion'),
      color: Sunlit.scrim,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutBack,
          builder: (context, v, child) => Opacity(
            opacity: v.clamp(0.0, 1.0),
            child: Transform.scale(scale: 0.88 + 0.12 * v, child: child),
          ),
          child: Container(
            margin: const EdgeInsets.all(28),
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
            constraints: const BoxConstraints(maxWidth: 360),
            decoration: BoxDecoration(
              color: Sunlit.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Sunlit.sunflower, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Sunlit.shadow,
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Puzzle complete!',
                  style: TextStyle(
                    color: Sunlit.ink,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'serif',
                  ),
                ),
                const SizedBox(height: 12),
                AspectRatio(
                  aspectRatio: src.width / src.height,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: Sunlit.frameEdge, width: 3),
                    ),
                    child: CustomPaint(
                      key: const Key('completed_picture'),
                      painter: _PicturePainter(artwork),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Solved in $swaps swaps',
                  style: const TextStyle(color: Sunlit.ink, fontSize: 15),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  key: const Key('next_puzzle'),
                  onPressed: onNextPuzzle,
                  child: const Text('Next puzzle'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PicturePainter extends CustomPainter {
  _PicturePainter(this.artwork);
  final PuzzleArtwork artwork;

  @override
  void paint(Canvas canvas, Size size) {
    final src = artwork.sourceSize;
    paintTile(canvas, artwork, Offset.zero & size, Offset.zero & src);
  }

  @override
  bool shouldRepaint(_PicturePainter old) => old.artwork != artwork;
}
