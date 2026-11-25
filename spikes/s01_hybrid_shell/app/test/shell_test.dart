import 'package:flame/game.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_cards_spike/game/components.dart' show GameStatus;
import 'package:jigsaw_cards_spike/game/riverpod_shell_game.dart';
import 'package:jigsaw_cards_spike/game/shell_game.dart';
import 'package:jigsaw_cards_spike/ui/shell_screen.dart';
import 'package:material_ui/material_ui.dart';

/// Pumps the shell on a portrait phone-sized surface (360x780 dp).
Future<ShellScreenState> pumpShell(
  WidgetTester tester,
  BridgeKind bridge,
) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(home: ShellScreen(bridge: bridge)),
    ),
  );
  // Let the Flame game load and run a few frames.
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  return tester.state<ShellScreenState>(find.byType(ShellScreen));
}

int orbColor(FlameGame game) => switch (game) {
  final ShellGame g => g.orb.colorIndex,
  final RiverpodShellGame g => g.orb.colorIndex,
  _ => throw StateError('unknown game'),
};

GameStatus status(FlameGame game) => switch (game) {
  final ShellGame g => g.status,
  final RiverpodShellGame g => g.status,
  _ => throw StateError('unknown game'),
};

String text(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(Key(key))).data!;

/// Matches both GameWidget and its flame_riverpod subclass.
final gameWidget = find.byWidgetPredicate((w) => w is GameWidget);

Future<void> tapOrb(WidgetTester tester) async {
  // The orb sits at 32% of the game area's height (see Orb.onGameResize).
  final r = tester.getRect(gameWidget);
  await tester.tapAt(Offset(r.center.dx, r.top + r.height * 0.32));
  // Advance past the tap recogniser's long-press timer.
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  for (final bridge in BridgeKind.values) {
    group('bridge: ${bridge.name}', () {
      testWidgets(
        'Flutter -> Riverpod -> Flame: colour change reaches the game',
        (tester) async {
          final screen = await pumpShell(tester, bridge);
          expect(orbColor(screen.game), 0);

          await tester.tap(find.byKey(const Key('changeColor')));
          await tester.pump(const Duration(milliseconds: 16));

          expect(text(tester, 'colorIndex'), contains(': 1'));
          expect(orbColor(screen.game), 1);
        },
      );

      testWidgets('Flame -> Riverpod -> Flutter: game tap updates Flutter UI', (
        tester,
      ) async {
        await pumpShell(tester, bridge);
        expect(text(tester, 'gameTaps'), contains(': 0'));

        await tapOrb(tester);
        await tapOrb(tester);

        expect(text(tester, 'gameTaps'), contains(': 2'));
        // Domain package used by the app layer: tap 2 maps to cell (0,2).
        expect(text(tester, 'gameTaps'), contains('domain cell 0,2'));
      });

      testWidgets(
        'overlay shows/hides; game stays mounted, running and usable',
        (tester) async {
          final screen = await pumpShell(tester, bridge);
          final game = screen.game;
          expect(find.byKey(const Key('overlay')), findsNothing);

          await tester.tap(find.byKey(const Key('toggleOverlay')));
          await tester.pump(const Duration(milliseconds: 16));
          expect(find.byKey(const Key('overlay')), findsOneWidget);

          // Same game instance, still one GameWidget, loop still advancing.
          final before = status(game).elapsed;
          for (var i = 0; i < 10; i++) {
            await tester.pump(const Duration(milliseconds: 16));
          }
          expect(identical(screen.game, game), isTrue);
          expect(gameWidget, findsOneWidget);
          expect(status(game).elapsed, greaterThan(before));

          // Overlay control talks to Riverpod; game reflects it.
          await tester.tap(find.byKey(const Key('overlayChangeColor')));
          await tester.pump(const Duration(milliseconds: 16));
          expect(orbColor(game), 1);

          // Game is still tappable above the overlay.
          await tapOrb(tester);
          expect(text(tester, 'gameTaps'), contains(': 1'));

          await tester.tap(find.byKey(const Key('overlayClose')));
          await tester.pump(const Duration(milliseconds: 16));
          expect(find.byKey(const Key('overlay')), findsNothing);
          expect(identical(screen.game, game), isTrue);
        },
      );

      testWidgets('lifecycle: one pause and one resume per transition, no '
          'duplicate listeners after rebuilds', (tester) async {
        ShellScreenState.lifecycleListenersCreated = 0;
        final screen = await pumpShell(tester, bridge);

        // Force several rebuilds first.
        for (var i = 0; i < 3; i++) {
          await tester.tap(find.byKey(const Key('toggleOverlay')));
          await tester.pump(const Duration(milliseconds: 16));
          await tester.tap(find.byKey(const Key('changeColor')));
          await tester.pump(const Duration(milliseconds: 16));
        }
        expect(ShellScreenState.lifecycleListenersCreated, 1);

        final binding = tester.binding;
        for (final s in [
          AppLifecycleState.inactive,
          AppLifecycleState.hidden,
          AppLifecycleState.paused,
        ]) {
          binding.handleAppLifecycleStateChanged(s);
        }
        await tester.pump();
        expect(text(tester, 'lifecycle'), contains('Lifecycle: paused'));
        expect(text(tester, 'lifecycle'), contains('pauses 1 · resumes 0'));
        expect(status(screen.game).lifecycle, AppLifecycleState.paused);

        for (final s in [
          AppLifecycleState.hidden,
          AppLifecycleState.inactive,
          AppLifecycleState.resumed,
        ]) {
          binding.handleAppLifecycleStateChanged(s);
        }
        await tester.pump(const Duration(milliseconds: 16));
        expect(text(tester, 'lifecycle'), contains('Lifecycle: resumed'));
        expect(text(tester, 'lifecycle'), contains('pauses 1 · resumes 1'));
        expect(status(screen.game).lifecycle, AppLifecycleState.resumed);
      });
    });
  }
}
