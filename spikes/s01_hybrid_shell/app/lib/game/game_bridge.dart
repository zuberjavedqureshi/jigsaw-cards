import 'package:flutter/widgets.dart' show AppLifecycleState;

/// Manual Flame <-> application bridge (TD-03, option 1).
///
/// The game depends only on this small contract, never on Riverpod.
/// - Outbound (Flame -> app): intent callbacks supplied by the host.
/// - Inbound (app -> Flame): the host pushes view state via [ShellGameView].
class ShellGameIntents {
  const ShellGameIntents({required this.onOrbTapped});

  final void Function() onOrbTapped;
}

/// What the host can push into the game. Implemented by the Flame game.
abstract interface class ShellGameView {
  void showColor(int colorIndex);
  void showLifecycle(AppLifecycleState? state);
}
