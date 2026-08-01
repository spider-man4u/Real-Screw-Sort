import 'package:flutter_test/flutter_test.dart';
import 'package:real_screw_sort/game/engine/board.dart';
import 'package:real_screw_sort/game/engine/models.dart';
import 'package:real_screw_sort/game/engine/solver.dart';

LevelDef level({
  int cols = 6,
  int rows = 6,
  List<Plate>? plates,
  List<Screw>? screws,
  Map<int, int> slots = const {},
  int? target,
}) {
  final ps = plates ??
      [
        const Plate(id: 0, rect: IntRect(1, 1, 3, 2)),
        const Plate(id: 1, rect: IntRect(1, 3, 3, 2)),
      ];
  final ss = screws ??
      [
        const Screw(id: 0, cell: Cell(1, 1), plateId: 0),
        const Screw(id: 1, cell: Cell(3, 1), plateId: 0),
        const Screw(id: 2, cell: Cell(1, 3), plateId: 1),
        const Screw(id: 3, cell: Cell(3, 3), plateId: 1),
      ];
  return LevelDef(
    id: 1,
    name: 't',
    cols: cols,
    rows: rows,
    plates: ps,
    screws: ss,
    slots: slots,
    targetPlateId: target,
  );
}

void main() {
  group('basic mechanic', () {
    test('removing all screws of a plate detaches it', () {
      final b = BoardState(level());
      final r = b.removeScrew(0)!;
      expect(r.detached, isEmpty);
      b.removeScrew(1);
      expect(b.plateDetached(0), isTrue);
      expect(b.availableMoves(), hasLength(2));
    });

    test('remove returns null for illegal moves', () {
      final b = BoardState(level());
      expect(b.removeScrew(99), isNull);
      expect(b.removeScrew(0), isNotNull);
      expect(b.removeScrew(0), isNull); // already gone
    });
  });

  group('locked', () {
    test('cannot remove locked screw before its key', () {
      final lvl = level(screws: [
        const Screw(id: 0, cell: Cell(1, 1), plateId: 0),
        const Screw(id: 1, cell: Cell(3, 1), plateId: 0, type: ScrewType.locked, lockKey: 0),
      ]);
      final b = BoardState(lvl);
      expect(b.canRemoveScrew(b.screwById(1)), isFalse);
      expect(b.canRemoveScrew(b.screwById(0)), isTrue);
      b.removeScrew(0);
      expect(b.canRemoveScrew(b.screwById(1)), isTrue);
    });
  });

  group('frozen', () {
    test('needs all screws on its plate and touching plates gone', () {
      // plate 0 touches plate 1 (they are stacked).
      final lvl = level(screws: [
        const Screw(id: 0, cell: Cell(2, 1), plateId: 0, type: ScrewType.frozen),
        const Screw(id: 1, cell: Cell(1, 3), plateId: 1),
        const Screw(id: 2, cell: Cell(3, 3), plateId: 1),
      ]);
      final b = BoardState(lvl);
      // frozen screw is the only one on plate 0 but plate 1 is touching.
      expect(b.canRemoveScrew(b.screwById(0)), isFalse);
      b.removeScrew(1);
      expect(b.canRemoveScrew(b.screwById(0)), isFalse);
      b.removeScrew(2);
      expect(b.canRemoveScrew(b.screwById(0)), isTrue);
    });
  });

  group('color', () {
    test('screw goes to hand, must be slotted to finish', () {
      final lvl = level(
        plates: [const Plate(id: 0, rect: IntRect(1, 1, 3, 2))],
        screws: [const Screw(id: 0, cell: Cell(2, 1), plateId: 0, type: ScrewType.color, color: 2)],
        slots: const {2: 1},
      );
      final b = BoardState(lvl);
      expect(b.handScrew, isNull);
      b.removeScrew(0);
      expect(b.handScrew, 0);
      // plate is detached logically although the screw is in hand
      expect(b.plateDetached(0), isTrue);
      expect(b.isWon, isFalse); // hand not empty
      expect(b.canSlot(), isTrue);
      b.slotHand();
      expect(b.handScrew, isNull);
      expect(b.isWon, isTrue);
    });

    test('cannot hold two screws at once', () {
      final lvl = level(
        plates: [const Plate(id: 0, rect: IntRect(1, 1, 3, 2))],
        screws: [
          const Screw(id: 0, cell: Cell(2, 1), plateId: 0, type: ScrewType.color, color: 2),
          const Screw(id: 1, cell: Cell(2, 2), plateId: 0, type: ScrewType.basic),
        ],
        slots: const {2: 1},
      );
      final b = BoardState(lvl);
      b.removeScrew(0);
      expect(b.canRemoveScrew(b.screwById(1)), isFalse);
    });
  });

  group('hidden', () {
    test('hidden screw revealed only after covering plate falls', () {
      final lvl = level(
        plates: [
          const Plate(id: 0, rect: IntRect(1, 2, 4, 2)), // front cover
          const Plate(id: 1, rect: IntRect(1, 3, 3, 2)), // panel behind it
        ],
        screws: [
          const Screw(id: 0, cell: Cell(1, 2), plateId: 0),
          const Screw(id: 1, cell: Cell(2, 3), plateId: 1, type: ScrewType.hidden),
        ],
      );
      final b = BoardState(lvl);
      // the hidden screw sits under cover plate 0 -> not removable
      expect(b.isHidden(b.screwById(1)), isTrue);
      expect(b.canRemoveScrew(b.screwById(1)), isFalse);
      b.removeScrew(0); // cover plate falls
      expect(b.isHidden(b.screwById(1)), isFalse);
      expect(b.canRemoveScrew(b.screwById(1)), isTrue);
    });
  });

  group('heavy', () {
    test('heavy plate smashes fragile plate below (cascade)', () {
      final lvl = level(
        plates: [
          const Plate(id: 0, rect: IntRect(1, 1, 3, 1), heavy: true),
          const Plate(id: 1, rect: IntRect(1, 2, 3, 1), heavy: true, fragile: true),
          const Plate(id: 2, rect: IntRect(1, 3, 3, 1), fragile: true),
        ],
        screws: [
          const Screw(id: 0, cell: Cell(2, 1), plateId: 0),
          const Screw(id: 1, cell: Cell(2, 2), plateId: 1),
          const Screw(id: 2, cell: Cell(2, 3), plateId: 2),
        ],
      );
      final b = BoardState(lvl);
      final r = b.removeScrew(0)!;
      expect(r.detached.map((p) => p.id), containsAll([0, 1, 2]));
      expect(r.smashed.map((s) => s.id), containsAll([1, 2]));
      expect(b.isWon, isTrue);
    });

    test('heavy plate does not smash non-fragile plates', () {
      final lvl = level(
        plates: [
          const Plate(id: 0, rect: IntRect(1, 1, 3, 1), heavy: true),
          const Plate(id: 1, rect: IntRect(1, 2, 3, 1)),
        ],
        screws: [
          const Screw(id: 0, cell: Cell(2, 1), plateId: 0),
          const Screw(id: 1, cell: Cell(2, 2), plateId: 1),
        ],
      );
      final b = BoardState(lvl);
      final r = b.removeScrew(0)!;
      expect(r.detached.map((p) => p.id), [0]);
      expect(b.plateDetached(1), isFalse);
    });
  });

  group('one-way', () {
    test('one-way screw is a commit point for undo', () {
      final lvl = level(
        plates: [const Plate(id: 0, rect: IntRect(1, 1, 3, 2))],
        screws: [
          const Screw(id: 0, cell: Cell(2, 1), plateId: 0, type: ScrewType.oneWay),
          const Screw(id: 1, cell: Cell(2, 2), plateId: 0),
        ],
      );
      final b = BoardState(lvl);
      b.removeScrew(1);
      expect(b.canUndo, isTrue);
      b.removeScrew(0);
      expect(b.canUndo, isFalse); // cannot undo past one-way
    });

    test('normal screws undo cleanly', () {
      final b = BoardState(level());
      b.removeScrew(0);
      b.removeScrew(1);
      expect(b.moveCount, 2);
      expect(b.canUndo, isTrue);
      b.undo();
      expect(b.screwGone(1), isFalse);
      expect(b.plateDetached(0), isFalse);
      expect(b.moveCount, 1);
    });
  });

  group('win conditions', () {
    test('target plate level wins when target falls', () {
      final lvl = level(target: 1);
      final b = BoardState(lvl);
      b.removeScrew(2);
      expect(b.isWon, isFalse);
      b.removeScrew(3);
      expect(b.isWon, isTrue);
    });
  });

  group('solver', () {
    test('finds a solution and par moves', () {
      final b = BoardState(level());
      final solver = BoardSolver(b.level);
      final sol = solver.solve()!;
      expect(sol.length, 4);
      // follow the solution
      var bb = BoardState(b.level);
      for (final m in sol.moves) {
        if (m.isRemove) {
          bb.removeScrew(m.screwId!);
        } else {
          bb.slotHand();
        }
      }
      expect(bb.isWon, isTrue);
    });

    test('firstMove returns a valid move', () {
      final solver = BoardSolver(level());
      final m = solver.firstMove()!;
      expect(m.isRemove, isTrue);
      final b = BoardState(level());
      expect(b.canRemoveScrew(b.screwById(m.screwId!)), isTrue);
    });

    test('handcrafted par override wins', () {
      final lvl = level(parMoves: 9);
      expect(lvl.parMoves, 9);
    });
  });
}
