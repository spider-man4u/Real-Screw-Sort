import '../../game/engine/models.dart';

/// Compact helpers for authoring levels by hand.
typedef _ScrewDef = ({Cell cell, int plate, ScrewType type, int? lock, int? color});

List<Screw> _screws(List<_ScrewDef> defs) => [
      for (var i = 0; i < defs.length; i++)
        Screw(
          id: i,
          cell: defs[i].cell,
          plateId: defs[i].plate,
          type: defs[i].type,
          lockKey: defs[i].lock,
          color: defs[i].color,
        ),
    ];

LevelDef _lvl(
  int id,
  String name,
  int cols,
  int rows,
  List<Plate> plates,
  List<_ScrewDef> screws, {
  String theme = 'workshop',
  Map<int, int> slots = const {},
  int? target,
  int? par,
}) =>
    LevelDef(
      id: id,
      name: name,
      cols: cols,
      rows: rows,
      plates: plates,
      screws: _screws(screws),
      slots: slots,
      targetPlateId: target,
      parMoves: par,
      theme: theme,
    );

/// The 30 handcrafted levels. Every screw sits inside its own plate's rect,
/// and cover plates overlap the hidden screws they hide.
final List<LevelDef> handcraftedLevels = [
  // ---------- 1-6: basic ----------
  _lvl(1, 'First Screw', 6, 6, [
    const Plate(id: 0, rect: IntRect(2, 1, 2, 3)),
  ], [
    (cell: Cell(2, 1), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(3, 1), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(2, 3), plate: 0, type: ScrewType.basic, lock: null, color: null),
  ], par: 3),
  _lvl(2, 'Corner First', 6, 6, [
    const Plate(id: 0, rect: IntRect(1, 1, 4, 2)),
  ], [
    (cell: Cell(1, 1), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(4, 1), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(1, 2), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(4, 2), plate: 0, type: ScrewType.basic, lock: null, color: null),
  ], par: 4),
  _lvl(3, 'Two Panels', 6, 6, [
    const Plate(id: 0, rect: IntRect(0, 1, 2, 3)),
    const Plate(id: 1, rect: IntRect(4, 1, 2, 3)),
  ], [
    (cell: Cell(0, 1), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(1, 1), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(0, 3), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(4, 1), plate: 1, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(5, 1), plate: 1, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(4, 3), plate: 1, type: ScrewType.basic, lock: null, color: null),
  ], par: 6),
  _lvl(4, 'The Stack', 6, 6, [
    const Plate(id: 0, rect: IntRect(1, 1, 4, 2)),
    const Plate(id: 1, rect: IntRect(1, 3, 4, 2)),
  ], [
    (cell: Cell(1, 1), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(4, 1), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(1, 3), plate: 1, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(4, 3), plate: 1, type: ScrewType.basic, lock: null, color: null),
  ], par: 4),
  _lvl(5, 'Triple Tower', 6, 6, [
    const Plate(id: 0, rect: IntRect(1, 1, 2, 2)),
    const Plate(id: 1, rect: IntRect(3, 1, 2, 2)),
    const Plate(id: 2, rect: IntRect(1, 3, 4, 2)),
  ], [
    (cell: Cell(1, 1), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(2, 1), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(3, 1), plate: 1, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(4, 1), plate: 1, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(1, 3), plate: 2, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(4, 3), plate: 2, type: ScrewType.basic, lock: null, color: null),
  ], par: 6),
  _lvl(6, 'Big Board', 6, 6, [
    const Plate(id: 0, rect: IntRect(0, 1, 6, 2)),
    const Plate(id: 1, rect: IntRect(0, 3, 3, 2)),
    const Plate(id: 2, rect: IntRect(3, 3, 3, 2)),
  ], [
    (cell: Cell(0, 1), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(2, 1), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(3, 1), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(5, 1), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(0, 3), plate: 1, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(2, 3), plate: 1, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(3, 3), plate: 2, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(5, 3), plate: 2, type: ScrewType.basic, lock: null, color: null),
  ], par: 8),

  // ---------- 7-9: locked ----------
  _lvl(7, 'Key First', 6, 7, [
    const Plate(id: 0, rect: IntRect(1, 1, 4, 1)),
    const Plate(id: 1, rect: IntRect(1, 2, 4, 2)),
  ], [
    (cell: Cell(1, 1), plate: 0, type: ScrewType.locked, lock: 2, color: null),
    (cell: Cell(4, 1), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(1, 2), plate: 1, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(4, 2), plate: 1, type: ScrewType.basic, lock: null, color: null),
  ], par: 4),
  _lvl(8, 'Chain of Keys', 6, 7, [
    const Plate(id: 0, rect: IntRect(1, 1, 4, 1)),
    const Plate(id: 1, rect: IntRect(1, 2, 4, 1)),
    const Plate(id: 2, rect: IntRect(1, 3, 4, 1)),
  ], [
    (cell: Cell(1, 1), plate: 0, type: ScrewType.locked, lock: 2, color: null),
    (cell: Cell(4, 1), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(1, 2), plate: 1, type: ScrewType.locked, lock: 4, color: null),
    (cell: Cell(4, 2), plate: 1, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(2, 3), plate: 2, type: ScrewType.basic, lock: null, color: null),
  ], par: 5),
  _lvl(9, 'Locked Tower', 6, 7, [
    const Plate(id: 0, rect: IntRect(1, 1, 2, 3)),
    const Plate(id: 1, rect: IntRect(3, 1, 2, 3)),
  ], [
    (cell: Cell(1, 1), plate: 0, type: ScrewType.locked, lock: 5, color: null),
    (cell: Cell(2, 1), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(1, 3), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(3, 1), plate: 1, type: ScrewType.locked, lock: 2, color: null),
    (cell: Cell(4, 1), plate: 1, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(3, 3), plate: 1, type: ScrewType.basic, lock: null, color: null),
  ], par: 6),

  // ---------- 10-12: frozen ----------
  _lvl(10, 'Cold Screw', 6, 6, [
    const Plate(id: 0, rect: IntRect(1, 1, 4, 2)),
  ], [
    (cell: Cell(2, 1), plate: 0, type: ScrewType.frozen, lock: null, color: null),
    (cell: Cell(1, 1), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(4, 1), plate: 0, type: ScrewType.basic, lock: null, color: null),
  ], theme: 'ice', par: 3),
  _lvl(11, 'Ice Block', 6, 6, [
    const Plate(id: 0, rect: IntRect(0, 1, 3, 2)),
    const Plate(id: 1, rect: IntRect(3, 1, 3, 2)),
  ], [
    (cell: Cell(0, 1), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(1, 1), plate: 0, type: ScrewType.frozen, lock: null, color: null),
    (cell: Cell(3, 1), plate: 1, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(5, 1), plate: 1, type: ScrewType.basic, lock: null, color: null),
  ], theme: 'ice', par: 4),
  _lvl(12, 'Frozen Deep', 6, 6, [
    const Plate(id: 0, rect: IntRect(0, 1, 3, 2)),
    const Plate(id: 1, rect: IntRect(0, 3, 3, 2)),
    const Plate(id: 2, rect: IntRect(3, 1, 3, 2)),
  ], [
    (cell: Cell(1, 1), plate: 0, type: ScrewType.frozen, lock: null, color: null),
    (cell: Cell(0, 3), plate: 1, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(2, 3), plate: 1, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(3, 1), plate: 2, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(5, 1), plate: 2, type: ScrewType.basic, lock: null, color: null),
  ], theme: 'ice', par: 5),

  // ---------- 13-15: color ----------
  _lvl(13, 'Color Match', 6, 6, [
    const Plate(id: 0, rect: IntRect(1, 1, 4, 2)),
  ], [
    (cell: Cell(1, 1), plate: 0, type: ScrewType.color, lock: null, color: 0),
    (cell: Cell(4, 1), plate: 0, type: ScrewType.color, lock: null, color: 0),
  ], slots: const {0: 2}, par: 4),
  _lvl(14, 'Color Cross', 6, 6, [
    const Plate(id: 0, rect: IntRect(0, 1, 3, 2)),
    const Plate(id: 1, rect: IntRect(3, 1, 3, 2)),
  ], [
    (cell: Cell(1, 1), plate: 0, type: ScrewType.color, lock: null, color: 0),
    (cell: Cell(4, 1), plate: 1, type: ScrewType.color, lock: null, color: 1),
  ], slots: const {0: 1, 1: 1}, par: 4),
  _lvl(15, 'Color Queue', 6, 6, [
    const Plate(id: 0, rect: IntRect(1, 1, 4, 2)),
  ], [
    (cell: Cell(1, 1), plate: 0, type: ScrewType.color, lock: null, color: 0),
    (cell: Cell(2, 1), plate: 0, type: ScrewType.color, lock: null, color: 1),
    (cell: Cell(3, 1), plate: 0, type: ScrewType.color, lock: null, color: 2),
    (cell: Cell(4, 1), plate: 0, type: ScrewType.color, lock: null, color: 0),
  ], slots: const {0: 2, 1: 1, 2: 1}, par: 8),

  // ---------- 16-18: hidden ----------
  _lvl(16, 'Hidden Gem', 6, 7, [
    const Plate(id: 0, rect: IntRect(0, 2, 4, 2), depth: 1),
    const Plate(id: 1, rect: IntRect(0, 1, 4, 2)),
  ], [
    (cell: Cell(0, 2), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(3, 2), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(1, 1), plate: 1, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(2, 1), plate: 1, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(1, 2), plate: 1, type: ScrewType.hidden, lock: null, color: null),
  ], par: 5),
  _lvl(17, 'Double Hidden', 6, 7, [
    const Plate(id: 0, rect: IntRect(0, 2, 2, 2), depth: 1),
    const Plate(id: 1, rect: IntRect(2, 2, 2, 2), depth: 1),
    const Plate(id: 2, rect: IntRect(0, 1, 4, 2)),
  ], [
    (cell: Cell(0, 2), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(0, 3), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(3, 2), plate: 1, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(3, 3), plate: 1, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(1, 1), plate: 2, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(2, 1), plate: 2, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(1, 2), plate: 2, type: ScrewType.hidden, lock: null, color: null),
    (cell: Cell(2, 2), plate: 2, type: ScrewType.hidden, lock: null, color: null),
  ], par: 8),
  _lvl(18, 'Hidden Puzzle', 6, 7, [
    const Plate(id: 0, rect: IntRect(0, 1, 6, 2), depth: 1),
    const Plate(id: 1, rect: IntRect(1, 2, 4, 2)),
  ], [
    (cell: Cell(0, 1), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(2, 1), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(3, 1), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(5, 1), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(1, 2), plate: 1, type: ScrewType.hidden, lock: null, color: null),
    (cell: Cell(2, 3), plate: 1, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(3, 3), plate: 1, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(4, 2), plate: 1, type: ScrewType.hidden, lock: null, color: null),
  ], par: 8),

  // ---------- 19-21: heavy ----------
  _lvl(19, 'Heavy Drop', 6, 7, [
    const Plate(id: 0, rect: IntRect(0, 1, 3, 2), heavy: true),
    const Plate(id: 1, rect: IntRect(0, 3, 3, 1), fragile: true),
    const Plate(id: 2, rect: IntRect(3, 1, 3, 2)),
    const Plate(id: 3, rect: IntRect(3, 3, 3, 1)),
  ], [
    (cell: Cell(0, 1), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(1, 1), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(2, 1), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(1, 3), plate: 1, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(3, 1), plate: 2, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(5, 1), plate: 2, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(4, 3), plate: 3, type: ScrewType.basic, lock: null, color: null),
  ], theme: 'construction', par: 6),
  _lvl(20, 'Heavy Chain', 6, 7, [
    const Plate(id: 0, rect: IntRect(1, 1, 4, 1), heavy: true),
    const Plate(id: 1, rect: IntRect(1, 2, 4, 1), heavy: true, fragile: true),
    const Plate(id: 2, rect: IntRect(1, 3, 4, 1), fragile: true),
  ], [
    (cell: Cell(1, 1), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(4, 1), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(1, 2), plate: 1, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(4, 2), plate: 1, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(2, 3), plate: 2, type: ScrewType.basic, lock: null, color: null),
  ], theme: 'construction', par: 2),
  _lvl(21, 'Heavy Guard', 6, 7, [
    const Plate(id: 0, rect: IntRect(1, 1, 4, 1), heavy: true),
    const Plate(id: 1, rect: IntRect(1, 2, 4, 1), fragile: true),
  ], [
    (cell: Cell(1, 1), plate: 0, type: ScrewType.locked, lock: 2, color: null),
    (cell: Cell(4, 1), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(2, 2), plate: 1, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(3, 2), plate: 1, type: ScrewType.basic, lock: null, color: null),
  ], theme: 'construction', par: 3),

  // ---------- 22-24: one-way ----------
  _lvl(22, 'One Way Bridge', 6, 7, [
    const Plate(id: 0, rect: IntRect(1, 1, 4, 1)),
    const Plate(id: 1, rect: IntRect(1, 2, 4, 2)),
  ], [
    (cell: Cell(1, 1), plate: 0, type: ScrewType.oneWay, lock: null, color: null),
    (cell: Cell(4, 1), plate: 0, type: ScrewType.oneWay, lock: null, color: null),
    (cell: Cell(1, 2), plate: 1, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(2, 2), plate: 1, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(3, 2), plate: 1, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(4, 2), plate: 1, type: ScrewType.basic, lock: null, color: null),
  ], theme: 'space', par: 6),
  _lvl(23, 'One Way Only', 6, 7, [
    const Plate(id: 0, rect: IntRect(0, 1, 3, 2)),
    const Plate(id: 1, rect: IntRect(3, 1, 3, 2)),
  ], [
    (cell: Cell(0, 1), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(1, 1), plate: 0, type: ScrewType.oneWay, lock: null, color: null),
    (cell: Cell(2, 1), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(3, 1), plate: 1, type: ScrewType.oneWay, lock: null, color: null),
    (cell: Cell(5, 1), plate: 1, type: ScrewType.basic, lock: null, color: null),
  ], theme: 'space', par: 5),
  _lvl(24, 'One Way Trap', 6, 7, [
    const Plate(id: 0, rect: IntRect(1, 1, 4, 2)),
  ], [
    (cell: Cell(1, 1), plate: 0, type: ScrewType.oneWay, lock: null, color: null),
    (cell: Cell(4, 1), plate: 0, type: ScrewType.locked, lock: 2, color: null),
    (cell: Cell(1, 2), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(4, 2), plate: 0, type: ScrewType.basic, lock: null, color: null),
  ], theme: 'space', par: 4),

  // ---------- 25-30: mixed masters ----------
  _lvl(25, 'The Works', 6, 8, [
    const Plate(id: 0, rect: IntRect(0, 1, 3, 2)),
    const Plate(id: 1, rect: IntRect(3, 1, 3, 2)),
    const Plate(id: 2, rect: IntRect(1, 3, 4, 2)),
  ], [
    (cell: Cell(0, 1), plate: 0, type: ScrewType.color, lock: null, color: 0),
    (cell: Cell(1, 1), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(3, 1), plate: 1, type: ScrewType.locked, lock: 1, color: null),
    (cell: Cell(5, 1), plate: 1, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(1, 3), plate: 2, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(2, 3), plate: 2, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(3, 3), plate: 2, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(4, 3), plate: 2, type: ScrewType.basic, lock: null, color: null),
  ], slots: const {0: 1}, theme: 'workshop', par: 9),
  _lvl(26, 'Full House', 6, 8, [
    const Plate(id: 0, rect: IntRect(0, 1, 3, 2)),
    const Plate(id: 1, rect: IntRect(3, 1, 3, 2)),
    const Plate(id: 2, rect: IntRect(0, 3, 3, 2)),
    const Plate(id: 3, rect: IntRect(3, 3, 3, 2)),
  ], [
    (cell: Cell(0, 1), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(2, 1), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(3, 1), plate: 1, type: ScrewType.locked, lock: 6, color: null),
    (cell: Cell(5, 1), plate: 1, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(0, 3), plate: 2, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(2, 3), plate: 2, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(4, 3), plate: 3, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(5, 3), plate: 3, type: ScrewType.basic, lock: null, color: null),
  ], theme: 'temple', par: 8),
  _lvl(27, 'Deep Freeze', 6, 8, [
    const Plate(id: 0, rect: IntRect(0, 1, 2, 2)),
    const Plate(id: 1, rect: IntRect(2, 1, 2, 2)),
    const Plate(id: 2, rect: IntRect(4, 1, 2, 2)),
  ], [
    (cell: Cell(1, 1), plate: 0, type: ScrewType.frozen, lock: null, color: null),
    (cell: Cell(2, 1), plate: 1, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(3, 1), plate: 1, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(4, 1), plate: 2, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(5, 1), plate: 2, type: ScrewType.basic, lock: null, color: null),
  ], theme: 'ice', par: 5),
  _lvl(28, 'Hidden Treasure', 6, 8, [
    const Plate(id: 0, rect: IntRect(1, 2, 3, 2), depth: 1),
    const Plate(id: 1, rect: IntRect(1, 1, 4, 3)),
  ], [
    (cell: Cell(1, 2), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(3, 2), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(1, 1), plate: 1, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(4, 1), plate: 1, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(2, 2), plate: 1, type: ScrewType.hidden, lock: null, color: null),
    (cell: Cell(4, 2), plate: 1, type: ScrewType.color, lock: null, color: 2),
  ], slots: const {2: 1}, theme: 'temple', par: 7),
  _lvl(29, 'Heavy Storm', 7, 8, [
    const Plate(id: 0, rect: IntRect(0, 1, 3, 2), heavy: true),
    const Plate(id: 1, rect: IntRect(4, 1, 3, 2), heavy: true),
    const Plate(id: 2, rect: IntRect(0, 3, 3, 1), fragile: true),
    const Plate(id: 3, rect: IntRect(4, 3, 3, 1), fragile: true),
  ], [
    (cell: Cell(0, 1), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(2, 1), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(4, 1), plate: 1, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(6, 1), plate: 1, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(1, 3), plate: 2, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(5, 3), plate: 3, type: ScrewType.basic, lock: null, color: null),
  ], theme: 'construction', par: 4),
  _lvl(30, 'Master Blend', 7, 9, [
    const Plate(id: 0, rect: IntRect(0, 1, 4, 2), depth: 1),
    const Plate(id: 1, rect: IntRect(0, 2, 3, 2)),
    const Plate(id: 2, rect: IntRect(3, 1, 4, 2), heavy: true),
    const Plate(id: 3, rect: IntRect(1, 4, 5, 1), fragile: true),
    const Plate(id: 4, rect: IntRect(3, 3, 4, 1), fragile: true),
  ], [
    (cell: Cell(0, 1), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(2, 1), plate: 0, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(1, 2), plate: 1, type: ScrewType.hidden, lock: null, color: null),
    (cell: Cell(0, 3), plate: 1, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(2, 3), plate: 1, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(3, 1), plate: 2, type: ScrewType.locked, lock: 9, color: null),
    (cell: Cell(6, 1), plate: 2, type: ScrewType.oneWay, lock: null, color: null),
    (cell: Cell(5, 2), plate: 2, type: ScrewType.basic, lock: null, color: null),
    (cell: Cell(3, 4), plate: 3, type: ScrewType.frozen, lock: null, color: null),
    (cell: Cell(2, 4), plate: 3, type: ScrewType.color, lock: null, color: 1),
    (cell: Cell(4, 3), plate: 4, type: ScrewType.basic, lock: null, color: null),
  ], slots: const {1: 1}, theme: 'steampunk', par: 11),
];
