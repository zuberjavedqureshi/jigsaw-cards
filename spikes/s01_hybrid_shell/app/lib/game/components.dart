import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;

/// Placeholder colours. Rendering detail only.
const orbColors = <Color>[
  Color(0xFFE8A33D),
  Color(0xFF4FA3D9),
  Color(0xFF7BC47F),
  Color(0xFFD96C9B),
];

class Backdrop extends RectangleComponent with HasGameReference {
  Backdrop() : super(paint: Paint()..color = const Color(0xFF1F2440));

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }
}

/// A pulsing, rotating placeholder object. Tapping it emits an intent.
/// No gameplay: it exists only to show the scene is alive and interactive.
class Orb extends PositionComponent with TapCallbacks, HasGameReference {
  Orb({required this.onTapped}) : super(anchor: Anchor.center);

  final void Function() onTapped;
  final Paint _fill = Paint()..color = orbColors.first;
  final Paint _mark = Paint()..color = const Color(0xCCFFFFFF);
  double _time = 0;

  int _colorIndex = 0;

  /// Palette index currently rendered. Kept as an int so tests can compare it.
  int get colorIndex => _colorIndex;
  set colorIndex(int index) {
    _colorIndex = index % orbColors.length;
    _fill.color = orbColors[_colorIndex];
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Upper part of the game area, so the overlay (bottom) never covers it.
    final side = math.min(size.x, size.y) * 0.3;
    this.size = Vector2.all(side);
    position = Vector2(size.x / 2, size.y * 0.32);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    angle = _time;
    scale = Vector2.all(1 + 0.06 * math.sin(_time * 3));
  }

  @override
  void render(Canvas canvas) {
    final r = size.x / 2;
    canvas.drawCircle(Offset(r, r), r, _fill);
    canvas.drawCircle(Offset(r * 1.5, r), r * 0.12, _mark);
  }

  @override
  void onTapUp(TapUpEvent event) => onTapped();
}

/// Text proving the game loop is running, plus the lifecycle as seen by Flame.
class GameStatus extends TextComponent {
  GameStatus()
    : super(
        position: Vector2(12, 12),
        textRenderer: TextPaint(
          style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 14),
        ),
      );

  double elapsed = 0;
  int frames = 0;
  AppLifecycleState? lifecycle;
  String bridge = '';

  @override
  void update(double dt) {
    super.update(dt);
    elapsed += dt;
    frames++;
    text =
        'Flame running · ${elapsed.toStringAsFixed(1)} s · $frames frames\n'
        'bridge: $bridge · lifecycle seen by game: ${lifecycle?.name ?? '-'}';
  }
}
