import 'package:puzzle_domain/puzzle_domain.dart';
import 'package:test/test.dart';

PuzzlePiece p(String id, int r, int c, PieceSize s) =>
    PuzzlePiece(id: id, correctOrigin: GridCell(r, c), size: s);

/// A valid 10-piece 4x4 layout:
///   row 0: [a a][b][c]
///   row 1: [d d][e e]      d = 2x2 over rows 1-2, cols 0-1
///   row 2: [d d][f][g]
///   row 3: [h][i][j j]
List<PuzzlePiece> validPieces() => [
  p('a', 0, 0, PieceSize.oneByTwo),
  p('b', 0, 2, PieceSize.oneByOne),
  p('c', 0, 3, PieceSize.oneByOne),
  p('d', 1, 0, PieceSize.twoByTwo),
  p('e', 1, 2, PieceSize.oneByTwo),
  p('f', 2, 2, PieceSize.oneByOne),
  p('g', 2, 3, PieceSize.oneByOne),
  p('h', 3, 0, PieceSize.oneByOne),
  p('i', 3, 1, PieceSize.oneByOne),
  p('j', 3, 2, PieceSize.oneByTwo),
];

Set<LayoutViolationKind> kinds(List<PuzzlePiece> pieces) => {
  for (final v in validateLayout(
    GridSize(4, 4),
    pieces,
    LayoutConstraints.prototype,
  ))
    v.kind,
};

void main() {
  final grid = GridSize(4, 4);

  test('a valid layout has no violations and can be constructed', () {
    expect(kinds(validPieces()), isEmpty);
    final layout = PuzzleLayout.validated(grid: grid, pieces: validPieces());
    expect(layout.pieces, hasLength(10));
    expect(layout.pieceById('d')!.size, PieceSize.twoByTwo);
  });

  test('prototype constraints are the approved Q-009 values', () {
    final c = LayoutConstraints.prototype;
    expect(c.allowedSizes, {
      PieceSize.oneByOne,
      PieceSize.oneByTwo,
      PieceSize.twoByOne,
      PieceSize.twoByTwo,
    });
    expect((c.minPieces, c.maxPieces), (8, 12));
  });

  test('gap: an uncovered cell is reported', () {
    final pieces = validPieces()..removeWhere((x) => x.id == 'c');
    // Removing c also drops the count to 9, which is still allowed.
    expect(kinds(pieces), {LayoutViolationKind.gap});
  });

  test('overlap: a doubly covered cell is reported', () {
    final pieces = validPieces()
      ..removeWhere((x) => x.id == 'b')
      ..add(p('b', 0, 1, PieceSize.oneByTwo)); // overlaps a at (0,1)
    expect(kinds(pieces), containsAll([LayoutViolationKind.overlap]));
  });

  test('out of bounds: a piece extending past the grid is reported', () {
    final pieces = validPieces()
      ..removeWhere((x) => x.id == 'c')
      ..add(p('c', 0, 3, PieceSize.oneByTwo)); // would cover (0,4)
    expect(kinds(pieces), contains(LayoutViolationKind.outOfBounds));
  });

  test('invalid dimension: 1x3 is not an allowed size', () {
    final pieces = validPieces()
      ..removeWhere((x) => x.id == 'h' || x.id == 'i' || x.id == 'j')
      ..add(p('h', 3, 0, const PieceSize(1, 3)))
      ..add(p('j', 3, 3, PieceSize.oneByOne));
    expect(kinds(pieces), {LayoutViolationKind.invalidSize});
  });

  test('invalid count: 4 pieces (four 2x2) is below the minimum of 8', () {
    final pieces = [
      p('a', 0, 0, PieceSize.twoByTwo),
      p('b', 0, 2, PieceSize.twoByTwo),
      p('c', 2, 0, PieceSize.twoByTwo),
      p('d', 2, 2, PieceSize.twoByTwo),
    ];
    expect(kinds(pieces), {LayoutViolationKind.invalidPieceCount});
  });

  test('invalid count: 16 pieces (all 1x1) is above the maximum of 12', () {
    final pieces = [
      for (final cell in grid.cells)
        p(
          'x${cell.row}${cell.column}',
          cell.row,
          cell.column,
          PieceSize.oneByOne,
        ),
    ];
    expect(kinds(pieces), {LayoutViolationKind.invalidPieceCount});
  });

  test('boundary counts 8 and 12 are allowed', () {
    // 8 pieces: four 1x2 rows... use two 2x2 + six 1x1? -> build explicitly.
    final eight = [
      p('a', 0, 0, PieceSize.twoByTwo),
      p('b', 0, 2, PieceSize.twoByTwo),
      p('c', 2, 0, PieceSize.oneByTwo),
      p('d', 2, 2, PieceSize.oneByTwo),
      p('e', 3, 0, PieceSize.oneByOne),
      p('f', 3, 1, PieceSize.oneByOne),
      p('g', 3, 2, PieceSize.oneByOne),
      p('h', 3, 3, PieceSize.oneByOne),
    ];
    expect(kinds(eight), isEmpty);
    final twelve = [
      p('a', 0, 0, PieceSize.oneByTwo),
      p('b', 0, 2, PieceSize.oneByTwo),
      p('c', 1, 0, PieceSize.oneByTwo),
      p('d', 1, 2, PieceSize.oneByTwo),
      for (var r = 2; r < 4; r++)
        for (var c = 0; c < 4; c++) p('x$r$c', r, c, PieceSize.oneByOne),
    ];
    expect(twelve, hasLength(12));
    expect(kinds(twelve), isEmpty);
  });

  test('duplicate ids are reported', () {
    final pieces = validPieces()
      ..removeWhere((x) => x.id == 'c')
      ..add(p('b', 0, 3, PieceSize.oneByOne));
    expect(kinds(pieces), {LayoutViolationKind.duplicateId});
  });

  test('PuzzleLayout.validated throws with every violation listed', () {
    final pieces = validPieces()..removeWhere((x) => x.id == 'c');
    expect(
      () => PuzzleLayout.validated(grid: grid, pieces: pieces),
      throwsA(
        isA<InvalidLayoutException>().having(
          (e) => e.violations.map((v) => v.kind),
          'kinds',
          [LayoutViolationKind.gap],
        ),
      ),
    );
  });
}
