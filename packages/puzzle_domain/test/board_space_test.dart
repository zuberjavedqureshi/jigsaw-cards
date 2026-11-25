import 'package:puzzle_domain/puzzle_domain.dart';
import 'package:test/test.dart';

void main() {
  final bounds = PlayBounds(left: -1, top: -1, right: 5, bottom: 9);

  test('clampOrigin keeps the whole piece inside', () {
    expect(
      bounds.clampOrigin(const BoardPoint(-3, 20), PieceSize.twoByTwo),
      const BoardPoint(-1, 7),
    );
    expect(
      bounds.clampOrigin(const BoardPoint(4.5, 2), PieceSize.oneByTwo),
      const BoardPoint(3, 2),
    );
    expect(
      bounds.clampOrigin(const BoardPoint(1.5, 2.5), PieceSize.oneByOne),
      const BoardPoint(1.5, 2.5),
    );
  });

  test('invalid bounds are rejected', () {
    expect(
      () => PlayBounds(left: 1, top: 0, right: 1, bottom: 2),
      throwsArgumentError,
    );
  });

  test('overlapArea', () {
    expect(
      overlapArea(
        BoardPoint.zero,
        PieceSize.twoByTwo,
        const BoardPoint(1, 1),
        PieceSize.twoByTwo,
      ),
      1,
    );
    expect(
      overlapArea(
        BoardPoint.zero,
        PieceSize.oneByOne,
        const BoardPoint(1, 0),
        PieceSize.oneByOne,
      ),
      0,
    );
  });

  test('chebyshev distance and cell conversion', () {
    expect(
      const BoardPoint(0, 0).chebyshevTo(const BoardPoint(0.2, -0.4)),
      closeTo(0.4, 1e-9),
    );
    expect(BoardPoint.ofCell(GridCell(2, 3)), const BoardPoint(3, 2));
  });
}
