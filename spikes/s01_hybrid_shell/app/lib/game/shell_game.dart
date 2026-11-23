import 'package:flame/game.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;

import 'components.dart';
import 'game_bridge.dart';

/// Flame scene wired through the manual bridge. Knows nothing about Riverpod.
class ShellGame extends FlameGame implements ShellGameView {
  ShellGame({
    required this.intents,
    this.initialColor = 0,
    this.initialLifecycle,
  });

  final ShellGameIntents intents;
  final int initialColor;
  final AppLifecycleState? initialLifecycle;

  late final Orb orb;
  late final GameStatus status;

  @override
  Future<void> onLoad() async {
    orb = Orb(onTapped: intents.onOrbTapped)..colorIndex = initialColor;
    // Initial sync: the host's listeners only deliver later changes.
    status = GameStatus()
      ..bridge = 'manual'
      ..lifecycle = initialLifecycle;
    addAll([Backdrop(), orb, status]);
  }

  @override
  void showColor(int colorIndex) {
    if (isLoaded) orb.colorIndex = colorIndex;
  }

  @override
  void showLifecycle(AppLifecycleState? state) {
    if (isLoaded) status.lifecycle = state;
  }
}
