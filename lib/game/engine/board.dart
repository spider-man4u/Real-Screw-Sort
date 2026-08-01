import 'models.dart';

/// Result of applying a move: everything the presentation layer needs.
class ApplyResult {
  ApplyResult({required this.move});

  final Move move;

  /// Plates that detached (all screws gone) as a result of this move,
  /// in dependency order (cover plates first).
  final List<Plate> detached = [];

  /// Screws smashed by a heavy cascade (gone instantly).
  final List<Screw> smashed = [];

  /// A detached plate that is heavy and smashed something below.
  bool get hadHeavyCascade => smashed.isNotEmpty;

  /// Set when this removal detaches the last attached plate / wins the level.
  bool won = false;
}

/// Mutable gameplay state over a static [LevelDef].
///
/// Single source of truth for the puzzle: which screws are gone, which color
/// screw sits in the hand, which slots are used. Physics is a visualization
/// layer only - this class drives everything logical.
class BoardState {
  BoardState(this.level) : _removed = <int>{}, _slotsUsed = <int, int>{};

  final LevelDef level;

  final Set<int> _removed;
  int? handScrew;
  final Map<int, int> _slotsUsed;

  /// History of snapshots for undo. Undo cannot pop below [undoFloor]
  /// (one-way screws act as commit points).
  final List<_Snapshot> _history = [];
  int undoFloor = 0;

  bool _done = false;
  bool _won = false;

  Screw screwById(int id) => level.screws.firstWhere((s) => s.id == id);

  Plate plateById(int id) => level.plates.firstWhere((p) => p.id == id);

  bool _gone(Screw s) => _removed.contains(s.id) || handScrew == s.id;

  /// All screws of a plate that are still physically attached.
  List<Screw> screwsOnPlate(int plateId) =>
      level.screws.where((s) => s.plateId == plateId && !_gone(s)).toList();

  bool plateAttached(int plateId) => screwsOnPlate(plateId).isNotEmpty;

  bool screwGone(int screwId) =>
      _removed.contains(screwId) || handScrew == screwId;

  /// Plates whose rect overlaps [s]'s cell (excluding s's own plate).
  /// These hide hidden screws and count as "surrounding" for frozen screws.
  List<Plate> touchingPlates(Screw s) {
    final own = plateById(s.plateId);
    return level.plates.where((p) {
      if (p.id == own.id) return false;
      return p.rect.contains(s.cell) || p.rect.touches(own.rect);
    }).toList();
  }

  /// Plates that visually cover a hidden screw until they fall.
  List<Plate> coverPlates(Screw s) {
    final own = plateById(s.plateId);
    return level.plates
        .where((p) => p.id != own.id && p.rect.contains(s.cell))
        .toList();
  }

  bool isHidden(Screw s) {
    if (s.type != ScrewType.hidden) return false;
    return coverPlates(s).any(plateAttached);
  }

  bool canRemoveScrew(Screw s) {
    if (_gone(s)) return false;
    if (handScrew != null) return false; // one thing at a time
    if (isHidden(s)) return false;
    if (!plateAttached(s.plateId)) return false;

    switch (s.type) {
      case ScrewType.locked:
        if (s.lockKey == null || !screwGone(s.lockKey!)) return false;
      case ScrewType.frozen:
        // Every screw on this plate and on touching plates must be gone.
        for (final p in touchingPlates(s)) {
          if (screwsOnPlate(p.id).isNotEmpty) return false;
        }
        if (screwsOnPlate(s.plateId).length > 1) return false;
      case ScrewType.color:
        // handled by handScrew check above
      case ScrewType.hidden:
      case ScrewType.heavy:
      case ScrewType.oneWay:
      case ScrewType.basic:
        break;
    }
    return true;
  }

  List<Screw> removableScrews() =>
      level.screws.where((s) => canRemoveScrew(s)).toList();

  /// A color screw in the hand can be placed into a free slot of its color.
  bool canSlot() {
    final h = handScrew;
    if (h == null) return false;
    final s = screwById(h);
    final used = _slotsUsed[s.color!] ?? 0;
    return used < level.slotCountFor(s.color!);
  }

  int get usedSlotCountFor(int color) => _slotsUsed[color] ?? 0;

  /// Remaining moves the player can still make.
  List<Move> availableMoves() {
    final moves = <Move>[];
    for (final s in level.screws) {
      if (canRemoveScrew(s)) moves.add(Move.remove(s.id));
    }
    if (canSlot()) moves.add(Move.slot(screwById(handScrew!).color!));
    return moves;
  }

  bool get isStuck => availableMoves().isEmpty && !isWon;

  bool get isDone => _done;

  bool get isWon => _won;

  bool get isLose => _done && !_won;

  /// True when the hand is holding a color screw that cannot be slotted
  /// (impossible with valid levels, guarded anyway).
  bool get handBlocked => handScrew != null && !canSlot();

  /// Apply a removal. Returns null when illegal.
  ApplyResult? removeScrew(int screwId) {
    if (_done) return null;
    final s = screwById(screwId);
    if (!canRemoveScrew(s)) return null;

    final result = ApplyResult(move: Move.remove(screwId));
    _history.add(_snapshot());

    if (s.isColor) {
      handScrew = s.id;
    } else {
      _removed.add(s.id);
      if (s.type == ScrewType.oneWay) {
        // Commit point: cannot undo past this removal.
        undoFloor = _history.length;
      }
    }

    _resolveDetaches(result);
    _checkDone(result);
    return result;
  }

  /// Slot the hand screw into a matching free slot.
  ApplyResult? slotHand() {
    if (_done || !canSlot()) return null;
    final h = handScrew!;
    final s = screwById(h);
    final result = ApplyResult(move: Move.slot(s.color!));
    _history.add(_snapshot());
    _removed.add(h);
    _slotsUsed[s.color!] = (_slotsUsed[s.color!] ?? 0) + 1;
    handScrew = null;
    _checkDone(result);
    return result;
  }

  void _resolveDetaches(ApplyResult result) {
    // Any plate with zero attached screws detaches. Heavy plates smash
    // fragile plates directly below (cascading).
    final detached = <Plate>[];
    for (final p in level.plates) {
      if (!plateAttached(p.id) && !_detachedPlates.contains(p.id)) {
        detached.add(p);
      }
    }
    for (final p in detached) {
      _detachedPlates.add(p.id);
      result.detached.add(p);
      if (p.heavy) {
        _smashBelow(p, result);
      }
    }
  }

  void _smashBelow(Plate heavy, ApplyResult result) {
    final target = heavy.below(level.plates);
    if (target == null || !target.fragile || _detachedPlates.contains(target.id)) {
      return;
    }
    _detachedPlates.add(target.id);
    result.detached.add(target);
    for (final s in level.screws.where((s) => s.plateId == target.id)) {
      if (!_gone(s)) {
        _removed.add(s.id);
        if (handScrew == s.id) handScrew = null;
        result.smashed.add(s);
      }
    }
    if (target.heavy) _smashBelow(target, result);
  }

  final Set<int> _detachedPlates = {};

  bool plateDetached(int plateId) => _detachedPlates.contains(plateId);

  /// Build a state directly from a removal bitmask + hand (used by the solver).
  void restoreFromMask(int mask, int? hand) {
    _removed.clear();
    for (var i = 0; i < level.screws.length; i++) {
      if ((mask & (1 << i)) != 0) _removed.add(i);
    }
    handScrew = hand;
    _detachedPlates.clear();
    for (final p in level.plates) {
      if (!plateAttached(p.id)) _detachedPlates.add(p.id);
    }
  }

  /// Win condition without mutating terminal flags.
  bool evaluateWon() {
    final target = level.targetPlateId;
    final cleared = target != null
        ? plateDetached(target)
        : level.plates.every(plateDetached);
    return cleared && handScrew == null;
  }

  void _checkDone(ApplyResult result) {
    if (_done) return;
    if (evaluateWon()) {
      _done = true;
      _won = true;
      result.won = true;
    }
  }

  /// Number of player moves made so far (removes + slots).
  int get moveCount => _history.length;

  bool get canUndo => _history.length > undoFloor;

  /// Undo the last move. One-way screws are commit points.
  bool undo() {
    if (!canUndo) return false;
    final snap = _history.removeLast();
    _restore(snap);
    _done = false;
    _won = false;
    return true;
  }

  _Snapshot _snapshot() => _Snapshot(Set.of(_removed), handScrew, Map.of(_slotsUsed));

  void _restore(_Snapshot s) {
    _removed..clear()..addAll(s.removed);
    handScrew = s.hand;
    _slotsUsed..clear()..addAll(s.slotsUsed);
    _detachedPlates.clear();
    for (final p in level.plates) {
      if (!plateAttached(p.id)) _detachedPlates.add(p.id);
    }
  }
}

class _Snapshot {
  _Snapshot(this.removed, this.hand, this.slotsUsed);

  final Set<int> removed;
  final int? hand;
  final Map<int, int> slotsUsed;
}
