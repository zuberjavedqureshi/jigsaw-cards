import 'package:flame/game.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puzzle_domain/puzzle_domain.dart';

import '../artwork/puzzle_artwork.dart';
import '../game/puzzle_game.dart';
import '../game/puzzle_game_bridge.dart';
import '../state/puzzle_controller.dart';
import 'play_area_layout.dart';
import 'storybook_theme.dart';
import 'tray.dart';

/// The puzzle screen: Flutter shell (header, tray, completion) around the
/// Flame board. All communication with the game goes through
/// [PuzzleGameView] and [PuzzleGameIntents] (ADR-0001).
class PuzzleScreen extends ConsumerStatefulWidget {
  const PuzzleScreen({super.key, this.artwork});

  /// Defaults to the code-drawn placeholder (no final artwork exists).
  final PuzzleArtwork? artwork;

  @override
  ConsumerState<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends ConsumerState<PuzzleScreen> {
  final _playAreaKey = GlobalKey();
  late final PuzzleArtwork _artwork =
      widget.artwork ?? const PlaceholderStorybookArtwork();

  PuzzleGame? _game;
  int? _gameSeed;
  Offset _lastPointer = Offset.zero;

  /// Piece whose drag gesture is active (between start and end).
  String? _draggingPieceId;

  PuzzleGame _gameFor(PuzzleState s) {
    if (_game == null || _gameSeed != s.seed) {
      _gameSeed = s.seed;
      // Explicit initial sync: the game starts from the session's locked
      // pieces (ADR-0001).
      _game = PuzzleGame(
        layout: s.session.layout,
        artwork: _artwork,
        lockedPieces: s.session.lockedPieces,
        intents: PuzzleGameIntents(
          onDropRequested: _onDropRequested,
          onLockComplete: (id) =>
              ref.read(puzzleControllerProvider.notifier).lockFinished(id),
          onReturnComplete: (id) =>
              ref.read(puzzleControllerProvider.notifier).returnFinished(id),
        ),
      );
    }
    return _game!;
  }

  void _onDropRequested(String pieceId, GridCell target) {
    final outcome = ref
        .read(puzzleControllerProvider.notifier)
        .drop(pieceId, target);
    switch (outcome) {
      case PlacementAccepted():
        _game?.animateLock(pieceId);
      case PlacementRejected():
        _game?.animateReturn(pieceId);
    }
  }

  Offset _toLocal(Offset global) {
    final box = _playAreaKey.currentContext!.findRenderObject()! as RenderBox;
    return box.globalToLocal(global);
  }

  late final _trayCallbacks = TrayDragCallbacks(
    onStart: (piece, global, previewGlobal) {
      if (_draggingPieceId != null ||
          ref.read(puzzleControllerProvider).inFlightPieceId != null) {
        return;
      }
      _draggingPieceId = piece.id;
      ref.read(puzzleControllerProvider.notifier).pickUp(piece.id);
      final local = _toLocal(global);
      _lastPointer = local;
      final tl = _toLocal(previewGlobal.topLeft);
      _game?.beginDrag(piece, local, tl & previewGlobal.size);
    },
    onUpdate: (piece, global) {
      if (_draggingPieceId != piece.id) return;
      _lastPointer = _toLocal(global);
      _game?.updateDrag(_lastPointer);
    },
    onEnd: (piece) {
      if (_draggingPieceId != piece.id) return;
      _draggingPieceId = null;
      _game?.endDrag(_lastPointer);
    },
  );

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(puzzleControllerProvider);
    final game = _gameFor(s);
    final trayPieces = [
      for (final id in s.session.trayOrder)
        if (!s.session.isLocked(id) || id == s.inFlightPieceId)
          s.session.layout.pieceById(id)!,
    ];

    return DecoratedBox(
      decoration: Storybook.background,
      child: SafeArea(
        child: Column(
          children: [
            _Header(placed: s.placedCount, total: s.totalCount),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final area = PlayAreaLayout.compute(
                    constraints.biggest,
                    s.session.layout.grid,
                  );
                  return Stack(
                    key: _playAreaKey,
                    children: [
                      Positioned.fill(
                        child: GameWidget(
                          key: ValueKey('game_${s.seed}'),
                          game: game,
                        ),
                      ),
                      Positioned.fromRect(
                        rect: area.tray,
                        child: PieceTray(
                          pieces: trayPieces,
                          hiddenPieceId: s.inFlightPieceId,
                          artwork: _artwork,
                          grid: s.session.layout.grid,
                          dragEnabled: s.inFlightPieceId == null,
                          callbacks: _trayCallbacks,
                        ),
                      ),
                      if (s.showCompletion)
                        Positioned.fill(
                          child: _CompletionOverlay(
                            total: s.totalCount,
                            onNewPuzzle: ref
                                .read(puzzleControllerProvider.notifier)
                                .newPuzzle,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.placed, required this.total});

  final int placed;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                '$placed / $total',
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
