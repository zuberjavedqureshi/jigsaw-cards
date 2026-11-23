import 'package:flame/game.dart';
import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/shell_state.dart';
import 'components.dart';

/// Same scene wired through `flame_riverpod` (TD-03, option 2).
/// Components read and listen to providers directly via `ref`.
class RiverpodShellGame extends FlameGame with RiverpodGameMixin {
  late final RiverpodOrb orb;
  late final RiverpodGameStatus status;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    orb = RiverpodOrb();
    status = RiverpodGameStatus()..bridge = 'flame_riverpod';
    addAll([Backdrop(), orb, status]);
  }
}

class RiverpodOrb extends Orb with RiverpodComponentMixin {
  RiverpodOrb() : super(onTapped: _noop);

  static void _noop() {}

  @override
  void onMount() {
    addToGameWidgetBuild(() {
      ref.listen(
        shellControllerProvider.select((s) => s.colorIndex),
        (_, next) => colorIndex = next,
      );
    });
    super.onMount();
    colorIndex = ref.read(shellControllerProvider).colorIndex;
  }

  @override
  void onTapUp(_) => ref.read(shellControllerProvider.notifier).recordGameTap();
}

class RiverpodGameStatus extends GameStatus with RiverpodComponentMixin {
  @override
  void onMount() {
    addToGameWidgetBuild(() {
      ref.listen(
        shellControllerProvider.select((s) => s.lifecycle),
        (_, next) => lifecycle = next,
      );
    });
    super.onMount();
    // Initial sync: ref.listen only delivers later changes.
    lifecycle = ref.read(shellControllerProvider).lifecycle;
  }
}
