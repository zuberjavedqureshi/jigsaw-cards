import 'package:flame/game.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puzzle_domain/puzzle_domain.dart';

import '../artwork/puzzle_artwork.dart';
import '../game/puzzle_game.dart';
import '../game/puzzle_game_bridge.dart';
import '../state/puzzle_controller.dart';
import 'storybook_theme.dart';

/// The puzzle screen: Flutter shell (header, phase hints, completion)
/// around the Flame board, which fills the remaining safe area. All
/// communication with the game goes through [PuzzleGameView.syncSession]
/// and [PuzzleGameIntents] (ADR-0001).
class PuzzleScreen extends ConsumerStatefulWidget {
  const PuzzleScreen({super.key, this.artwork});

  /// Defaults to the code-drawn placeholder (no final artwork exists).
  final PuzzleArtwork? artwork;

  @override
  ConsumerState<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends ConsumerState<PuzzleScreen> {
  late final PuzzleArtwork _artwork =
      widget.artwork ?? const PlaceholderStorybookArtwork();

  PuzzleGame? _game;
  int? _gameSeed;

  PuzzleController get _controller =>
      ref.read(puzzleControllerProvider.notifier);

  PuzzleGame _gameFor(PuzzleState s) {
    if (_game == null || _gameSeed != s.seed) {
      _gameSeed = s.seed;
      // Explicit initial sync: the game starts from the current session.
      _game = PuzzleGame(
        session: s.session,
        artwork: _artwork,
        intents: PuzzleGameIntents(
          onReady: () => _controller.gameReady(),
          onPreviewShown: () => _controller.previewShown(),
          onRevealRequested: (id) => _controller.reveal(id),
          onSelected: (id) => _controller.select(id),
          onDropRequested: (id, at) => _controller.drop(id, at),
          onLockComplete: (id) => _controller.lockFinished(id),
        ),
      );
    }
    return _game!;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(puzzleControllerProvider, (prev, next) {
      if (prev != null && prev.seed == next.seed) {
        _game?.syncSession(next.session);
      }
    });
    final s = ref.watch(puzzleControllerProvider);
    final game = _gameFor(s);

    return DecoratedBox(
      decoration: Storybook.background,
      child: SafeArea(
        child: Column(
          children: [
            _Header(state: s),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GameWidget(
                      key: ValueKey('game_${s.seed}'),
                      game: game,
                    ),
                  ),
                  if (s.phase == PuzzlePhase.intro)
                    const Positioned.fill(
                      child: IgnorePointer(child: _IntroBanner()),
                    ),
                  if (s.showCompletion)
                    Positioned.fill(
                      child: _CompletionOverlay(
                        total: s.totalCount,
                        onNewPuzzle: _controller.newPuzzle,
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
  const _Header({required this.state});

  final PuzzleState state;

  @override
  Widget build(BuildContext context) {
    final hint = switch (state.phase) {
      PuzzlePhase.intro => 'Get ready to memorise the picture…',
      PuzzlePhase.preview => 'Memorise the pieces!',
      PuzzlePhase.playing => 'Tap a card to reveal it · drag to place it',
      PuzzlePhase.complete => 'The picture is whole again!',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Moonlit Castle',
                  style: TextStyle(
                    color: Storybook.parchment,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'serif',
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0x33FFF6DA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Text(
                    '${state.placedCount} / ${state.totalCount}',
                    key: const Key('progress'),
                    style: const TextStyle(
                      color: Storybook.gold,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 22,
            child: Text(
              hint,
              key: const Key('hint'),
              style: const TextStyle(color: Color(0xDDF7EBCB), fontSize: 14),
            ),
          ),
          SizedBox(
            height: 6,
            child: state.phase == PuzzlePhase.preview
                ? _PreviewCountdown(
                    key: ValueKey('countdown_${state.seed}'),
                    duration: state.previewDuration,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

/// Visual 4 s countdown bar during the preview. Decorative only: the phase
/// change is driven by the controller's scheduler.
class _PreviewCountdown extends StatelessWidget {
  const _PreviewCountdown({super.key, required this.duration});

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: duration,
      builder: (context, v, _) => ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: v,
          minHeight: 6,
          backgroundColor: const Color(0x33FFF6DA),
          color: Storybook.gold,
        ),
      ),
    );
  }
}

class _IntroBanner extends StatelessWidget {
  const _IntroBanner();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        key: const Key('intro'),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutBack,
        builder: (context, v, child) => Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.85 + 0.15 * v, child: child),
        ),
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xE61A1E52),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2BC62), width: 2),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, color: Storybook.gold, size: 30),
              SizedBox(height: 6),
              Text(
                'Watch closely!',
                style: TextStyle(
                  color: Storybook.parchment,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'serif',
                ),
              ),
              SizedBox(height: 4),
              Text(
                'The pieces will show their picture for 4 seconds.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xDDF7EBCB), fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple completion state. Card reveal and rewards attach here later
/// (not in this milestone).
class _CompletionOverlay extends StatelessWidget {
  const _CompletionOverlay({required this.total, required this.onNewPuzzle});

  final int total;
  final VoidCallback onNewPuzzle;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const Key('completion'),
      color: const Color(0x88000000),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
          decoration: BoxDecoration(
            color: Storybook.parchment,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Storybook.wood, width: 4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, color: Storybook.wood, size: 40),
              const SizedBox(height: 8),
              const Text(
                'Puzzle complete!',
                style: TextStyle(
                  color: Storybook.ink,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'serif',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'All $total pieces placed',
                style: const TextStyle(color: Storybook.ink, fontSize: 16),
              ),
              const SizedBox(height: 18),
              FilledButton(
                key: const Key('new_puzzle'),
                onPressed: onNewPuzzle,
                style: FilledButton.styleFrom(
                  backgroundColor: Storybook.wood,
                  minimumSize: const Size(160, 48),
                ),
                child: const Text('New puzzle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
