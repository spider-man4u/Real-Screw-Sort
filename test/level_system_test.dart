import 'package:flutter_test/flutter_test.dart';
import 'package:real_screw_sort/data/levels/handcrafted.dart';
import 'package:real_screw_sort/data/levels/level_catalog.dart';
import 'package:real_screw_sort/data/levels/level_generator.dart';
import 'package:real_screw_sort/game/engine/models.dart';
import 'package:real_screw_sort/game/engine/solver.dart';

void validateLevel(LevelDef lvl) {
  // every screw sits inside its own plate's rect
  for (final s in lvl.screws) {
    final own = lvl.plates[s.plateId].rect;
    expect(own.contains(s.cell), isTrue,
        reason: 'level ${lvl.id}: screw ${s.id} outside its plate');
  }

  // every plate has at least one screw (no instant detach)
  for (final p in lvl.plates) {
    expect(lvl.screws.any((s) => s.plateId == p.id), isTrue,
        reason: 'level ${lvl.id}: plate ${p.id} has no screws');
  }

  // lock keys exist and are not self-referential
  for (final s in lvl.screws) {
    if (s.lockKey != null) {
      expect(s.lockKey, isNot(s.id));
      expect(lvl.screws.any((o) => o.id == s.lockKey), isTrue,
          reason: 'level ${lvl.id}: lock key ${s.lockKey} missing');
    }
  }

  // slot counts are at least the number of color screws per color
  for (final s in lvl.screws.where((s) => s.isColor)) {
    final count = lvl.screwCountOfColor(s.color!);
    expect(lvl.slotCountFor(s.color!), greaterThanOrEqualTo(count),
        reason: 'level ${lvl.id}: color ${s.color} slots < screws');
  }

  // hidden screws must sit under a cover plate
  for (final s in lvl.screws.where((s) => s.type == ScrewType.hidden)) {
    final covered = lvl.plates.any(
      (p) => p.id != s.plateId && p.rect.contains(s.cell),
    );
    expect(covered, isTrue, reason: 'level ${lvl.id}: hidden screw not covered');
  }

  // non-hidden screws must not sit under another plate (they would be drawn
  // beneath it - a visual bug)
  for (final s in lvl.screws.where((s) => s.type != ScrewType.hidden)) {
    final ownRect = lvl.plates[s.plateId].rect;
    final covered = lvl.plates.any(
      (p) => p.id != s.plateId && p.rect.contains(s.cell) && !ownRect.overlaps(p.rect),
    );
    expect(covered, isFalse,
        reason: 'level ${lvl.id}: visible screw ${s.id} sits under plate');
  }

  // solvable, with a sane par
  final solution = BoardSolver(lvl).solve();
  expect(solution, isNotNull, reason: 'level ${lvl.id} unsolvable');
  expect(solution!.length, inInclusiveRange(2, 55));
  expect(lvl.parMoves, isNotNull);
}

void main() {
  group('handcrafted levels', () {
    test('exactly 30 levels', () {
      expect(handcraftedLevels.length, 30);
    });

    test('every handcrafted level is valid and solvable', () {
      for (final lvl in handcraftedLevels) {
        validateLevel(lvl);
      }
    });

    test('handcrafted pars match the solver', () {
      for (final lvl in handcraftedLevels) {
        final solution = BoardSolver(lvl).solve()!;
        expect(solution.length, lvl.parMoves,
            reason: 'level ${lvl.id} par mismatch (authored ${lvl.parMoves}, '
                'solver ${solution.length})');
      }
    });
  });

  group('generated levels', () {
    test('deterministic for a given seed', () {
      final a = LevelGenerator(const GenParams(
        cols: 6, rows: 8, plateMin: 3, plateMax: 4, screwMin: 8, screwMax: 12,
      ), seed: 42).generate(31);
      final b = LevelGenerator(const GenParams(
        cols: 6, rows: 8, plateMin: 3, plateMax: 4, screwMin: 8, screwMax: 12,
      ), seed: 42).generate(31);
      expect(a.screws.length, b.screws.length);
      expect(a.plates.length, b.plates.length);
      expect(a.parMoves, b.parMoves);
    });

    test('sample generated levels are valid', () {
      for (final id in [31, 60, 100, 151, 180, 200]) {
        final lvl = LevelCatalog().level(id);
        validateLevel(lvl);
      }
    });
  });

  group('full catalog (200 levels)', () {
    test('all levels valid and solvable', () {
      final catalog = LevelCatalog(totalLevels: 200);
      for (var id = 1; id <= 200; id++) {
        final lvl = catalog.level(id);
        validateLevel(lvl);
      }
      expect(catalog.level(1).id, 1);
      expect(catalog.level(200).id, 200);
    });

    test('chapters follow the PDR structure', () {
      expect(LevelCatalog.chapterForLevel(1), 0); // tutorial
      expect(LevelCatalog.chapterForLevel(31), 1); // easy
      expect(LevelCatalog.chapterForLevel(100), 2); // medium
      expect(LevelCatalog.chapterForLevel(200), 3); // hard
    });
  });
}
