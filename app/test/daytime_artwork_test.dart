import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_cards/artwork/puzzle_artwork.dart';

/// Renders the artwork at [px]×[px] and returns RGBA bytes.
Future<Uint8List> render(WidgetTester tester, PuzzleArtwork art, int px) async {
  final rec = ui.PictureRecorder();
  final canvas = ui.Canvas(rec);
  canvas.scale(px / art.sourceSize.width);
  art.paint(canvas, art.sourceSize);
  final image = rec.endRecording().toImageSync(px, px);
  final data = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  );
  return data!.buffer.asUint8List();
}

double lin(int c) {
  final v = c / 255;
  return v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4) * 1.0;
}

void main() {
  const art = PlaceholderDaytimeArtwork();

  test('square source, titled', () {
    expect(art.sourceSize.width, art.sourceSize.height);
    expect(art.title, 'Sunny Castle');
  });

  testWidgets('the placeholder picture is bright (VI-07)', (tester) async {
    const px = 128;
    final rgba = await render(tester, art, px);
    var sum = 0.0;
    var dark = 0;
    for (var i = 0; i < rgba.length; i += 4) {
      final l =
          0.2126 * lin(rgba[i]) +
          0.7152 * lin(rgba[i + 1]) +
          0.0722 * lin(rgba[i + 2]);
      sum += l;
      if (l < 0.05) dark++;
    }
    final mean = sum / (px * px);
    expect(mean, greaterThan(0.35), reason: 'mean luminance $mean');
    expect(dark / (px * px), lessThan(0.03), reason: 'almost no dark areas');
  });

  testWidgets('all 16 tile regions are visibly distinct', (tester) async {
    const px = 128; // 32×32 per tile
    final rgba = await render(tester, art, px);
    // 8×8 thumbnail (mean RGB of 4×4 blocks) per tile.
    List<double> thumb(int row, int col) {
      final out = <double>[];
      for (var by = 0; by < 8; by++) {
        for (var bx = 0; bx < 8; bx++) {
          var r = 0.0, g = 0.0, b = 0.0;
          for (var y = 0; y < 4; y++) {
            for (var x = 0; x < 4; x++) {
              final px0 = col * 32 + bx * 4 + x;
              final py0 = row * 32 + by * 4 + y;
              final i = (py0 * px + px0) * 4;
              r += rgba[i];
              g += rgba[i + 1];
              b += rgba[i + 2];
            }
          }
          out.addAll([r / 16, g / 16, b / 16]);
        }
      }
      return out;
    }

    final thumbs = [
      for (var r = 0; r < 4; r++)
        for (var c = 0; c < 4; c++) thumb(r, c),
    ];
    var minDiff = double.infinity;
    for (var a = 0; a < 16; a++) {
      for (var b = a + 1; b < 16; b++) {
        var d = 0.0;
        for (var k = 0; k < thumbs[a].length; k++) {
          d += (thumbs[a][k] - thumbs[b][k]).abs();
        }
        d /= thumbs[a].length;
        minDiff = math.min(minDiff, d);
        expect(d, greaterThan(8), reason: "tiles $a and $b look alike ($d)");
      }
    }
    expect(minDiff, greaterThan(8));
  });
}
