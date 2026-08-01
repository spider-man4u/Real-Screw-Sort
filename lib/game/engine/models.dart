import 'package:flutter/foundation.dart';

/// Grid cell coordinate. x = column, y = row (y=0 is the top row).
@immutable
class Cell {
  const Cell(this.x, this.y);

  final int x;
  final int y;

  @override
  bool operator ==(Object other) => other is Cell && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => '($x,$y)';
}

/// Integer rectangle in grid cells.
@immutable
class IntRect {
  const IntRect(this.x, this.y, this.w, this.h);

  final int x;
  final int y;
  final int w;
  final int h;

  int get right => x + w;
  int get bottom => y + h;
  int get cx => x + w ~/ 2;
  int get cy => y + h ~/ 2;
  bool get isEmpty => w <= 0 || h <= 0;

  bool contains(Cell c) => c.x >= x && c.x < right && c.y >= y && c.y < bottom;

  bool containsCell(int cx, int cy) => cx >= x && cx < right && cy >= y && cy < bottom;

  /// Overlaps if the two rectangles share at least one cell.
  bool overlaps(IntRect o) =>
      x < o.right && o.x < right && y < o.bottom && o.y < bottom;

  /// Touches when sharing an edge (no overlap) or overlapping.
  bool touches(IntRect o) {
    if (overlaps(o)) return true;
    final shareX = x < o.right && o.x < right;
    final shareY = y < o.bottom && o.y < bottom;
    if (shareX && (bottom == o.y || y == o.bottom)) return true;
    if (shareY && (right == o.x || x == o.right)) return true;
    return false;
  }

  @override
  bool operator ==(Object other) =>
      other is IntRect && other.x == x && other.y == y && other.w == w && other.h == h;

  @override
  int get hashCode => Object.hash(x, y, w, h);

  @override
  String toString() => '[$x,$y ${w}x$h]';
}

/// The seven screw types from the PDR.
enum ScrewType {
  basic('basic', 'Normal screw'),
  locked('locked', 'Locked: remove its key screw first'),
  frozen('frozen', 'Frozen: clear the surrounding pieces first'),
  color('color', 'Color screw: return it to a matching slot'),
  hidden('hidden', 'Hidden: revealed when the panel above falls'),
  heavy('heavy', 'Heavy panel above smashes fragile panels'),
  oneWay('oneWay', 'One-way: cannot be undone once removed');

  const ScrewType(this.key, this.description);

  final String key;
  final String description;

  static ScrewType fromKey(String k) => values.firstWhere(
        (t) => t.key == k,
        orElse: () => ScrewType.basic,
      );
}

@immutable
class Screw {
  const Screw({
    required this.id,
    required this.cell,
    required this.plateId,
    this.type = ScrewType.basic,
    this.lockKey,
    this.color,
    this.depth = 0,
  });

  final int id;
  final Cell cell;
  final int plateId;
  final ScrewType type;
  final int? lockKey;
  final int? color;
  final int depth;

  bool get isColor => type == ScrewType.color;

  Screw copyWith({ScrewType? type}) => Screw(
        id: id,
        cell: cell,
        plateId: plateId,
        type: type ?? this.type,
        lockKey: lockKey,
        color: color,
        depth: depth,
      );
}

@immutable
class Plate {
  const Plate({
    required this.id,
    required this.rect,
    this.depth = 0,
    this.heavy = false,
    this.fragile = false,
  });

  final int id;
  final IntRect rect;
  final int depth;
  final bool heavy;
  final bool fragile;

  /// The plate directly below [this] that shares columns, if any.
  Plate? below(List<Plate> plates) {
    for (final p in plates) {
      if (p.id == id) continue;
      if (p.rect.y == rect.bottom && p.rect.x < rect.right && p.rect.right > rect.x) {
        return p;
      }
    }
    return null;
  }
}

/// Static level definition. The generator produces these too.
@immutable
class LevelDef {
  const LevelDef({
    required this.id,
    required this.name,
    required this.cols,
    required this.rows,
    required this.plates,
    required this.screws,
    this.slots = const {},
    this.targetPlateId,
    this.parMoves,
    this.theme = 'workshop',
  });

  final int id;
  final String name;
  final int cols;
  final int rows;
  final List<Plate> plates;
  final List<Screw> screws;

  /// color index -> number of matching slots on the frame.
  final Map<int, int> slots;

  /// If set, the level is won when this plate falls.
  final int? targetPlateId;

  /// Optional hand-authored par (otherwise computed by the solver).
  final int? parMoves;

  /// Background theme key (see themes.dart).
  final String theme;

  int screwCountOfColor(int color) =>
      screws.where((s) => s.color == color).length;

  int slotCountFor(int color) => slots[color] ?? screwCountOfColor(color);

  int get maxColorSlots => slots.isEmpty ? 0 : slots.values.reduce((a, b) => a > b ? a : b);
}

/// A single player action.
@immutable
class Move {
  const Move.remove(int screwId) : screwId = screwId, color = null;

  const Move.slot(int color) : screwId = null, color = color;

  final int? screwId;
  final int? color;

  bool get isRemove => screwId != null;

  @override
  String toString() => isRemove ? 'remove #$screwId' : 'slot color $color';
}
