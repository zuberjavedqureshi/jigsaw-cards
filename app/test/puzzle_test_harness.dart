import 'package:flame/game.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_cards/game/puzzle_game.dart';
import 'package:jigsaw_cards/state/puzzle_controller.dart';
import 'package:jigsaw_cards/ui/puzzle_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puzzle_domain/puzzle_domain.dart';

const testSeed = 42;

/// Explicitly controlled scheduler: nothing runs until [fireNext].
class ManualScheduler {
  final List<ScheduledCall> calls = [];

  Scheduler get scheduler => (delay, callback) {
    final c = ScheduledCall(delay, callback);
    calls.add(c);
    return () => c.cancelled = true;
  };

  List<ScheduledCall> get pending =>
      calls.where((c) => !c.cancelled && !c.fired).toList();

  /// Runs the oldest pending call and returns its delay.
  Duration fireNext() {
    final c = pending.first;
    c.fired = true;
    c.callback();
    return c.delay;
  }
}

class ScheduledCall {
  ScheduledCall(this.delay, this.callback);
  final Duration delay;
  final void Function() callback;
  bool cancelled = false;
  bool fired = false;
}

class Harness {
  Harness(this.tester, this.container, this.clock);
  final WidgetTester tester;
  final ProviderContainer container;
  final ManualScheduler clock;

  PuzzleState get state => container.read(puzzleControllerProvider);
  PuzzleSession get session => state.session;

  PuzzleGame get game => tester
      .widget<GameWidget<PuzzleGame>>(find.byType(GameWidget<PuzzleGame>))
      .game!;

  RenderBox get _gameBox =>
      tester.renderObject<RenderBox>(find.byType(GameWidget<PuzzleGame>));

  Size get gameSize => _gameBox.size;

  /// Global position of a board point.
  Offset global(BoardPoint p) => _gameBox.localToGlobal(game.area.toScreen(p));

  /// A board point inside [id] where it is the topmost selectable piece.
  BoardPoint visiblePointOf(String id) {
    final p = session.piece(id)!;
    for (var y = 0.5; y < p.piece.size.rowSpan * 10; y++) {
      for (var x = 0.5; x < p.piece.size.columnSpan * 10; x++) {
        final pt = p.position + BoardPoint(x / 10, y / 10);
        if (session.topmostSelectableAt(pt)?.id == id) return pt;
      }
    }
    throw StateError('$id has no visible point');
  }

  Future<void> settle({int frames = 14}) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Intro → preview (flip-up finished; 4 s timer scheduled).
  Future<void> toPreview() async {
    expect(clock.fireNext(), introDuration);
    await settle();
  }

  /// Preview → memory mode (flip-down finished, input enabled).
  Future<void> toPlaying() async {
    await toPreview();
    expect(clock.fireNext(), const Duration(seconds: 4));
    await settle();
    expect(game.inputEnabled, isTrue);
  }

  Future<void> tapPiece(String id) async {
    await tester.tapAt(global(visiblePointOf(id)));
    await settle();
  }

  Future<void> tapAt(BoardPoint p) async {
    await tester.tapAt(global(p));
    await settle();
  }

  /// Drags from [from] so that the grabbed piece moves by the board-space
  /// offset ([to] - [from]).
  Future<void> dragBoard(BoardPoint from, BoardPoint to) async {
    final a = global(from);
    final b = global(to);
    final g = await tester.startGesture(a);
    await tester.pump(const Duration(milliseconds: 16));
    const steps = 12;
    for (var i = 1; i <= steps; i++) {
      await g.moveTo(Offset.lerp(a, b, i / steps)!);
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await settle();
  }

  /// Drags piece [id] so its top-left lands at [topLeft].
  Future<void> dragPieceTo(String id, BoardPoint topLeft) async {
    final grab = visiblePointOf(id);
    final offset = grab - session.piece(id)!.position;
    await dragBoard(grab, topLeft + offset);
  }

  Future<void> reveal(String id) async {
    await tapPiece(id);
    expect(session.isFaceUp(id), isTrue, reason: 'reveal $id');
  }
}

Future<Harness> pumpPuzzle(
  WidgetTester tester, {
  Size size = const Size(412, 915),
  int seed = testSeed,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final clock = ManualScheduler();
  final container = ProviderContainer(
    overrides: [
      initialSeedProvider.overrideWithValue(seed),
      schedulerProvider.overrideWithValue(clock.scheduler),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: PuzzleScreen())),
    ),
  );
  final h = Harness(tester, container, clock);
  await h.settle();
  return h;
}
