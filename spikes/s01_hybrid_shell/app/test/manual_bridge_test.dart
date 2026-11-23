import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_cards_spike/game/game_bridge.dart';
import 'package:jigsaw_cards_spike/game/shell_game.dart';
import 'package:material_ui/material_ui.dart';

/// TD-03 testability evidence: the manual-bridge game needs no Riverpod.
/// It runs in a plain GameWidget with a plain callback and no ProviderScope.
void main() {
  testWidgets('manual-bridge game works without Riverpod', (tester) async {
    var taps = 0;
    final game = ShellGame(
      intents: ShellGameIntents(onOrbTapped: () => taps++),
      initialColor: 2,
    );
    tester.view.physicalSize = const Size(360, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(GameWidget(game: game));
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(game.orb.colorIndex, 2);
    game.showColor(3);
    expect(game.orb.colorIndex, 3);

    await tester.tapAt(const Offset(180, 600 * 0.32));
    await tester.pump(const Duration(milliseconds: 600));
    expect(taps, 1);
  });
}
