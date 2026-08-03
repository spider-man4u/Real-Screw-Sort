import 'dart:math';

import '../../game/engine/models.dart';
import '../../game/engine/solver.dart';

/// Parameters for a band of generated levels.
class GenParams {
  const GenParams({
    required this.cols,
    required this.rows,
    required this.plateMin,
    required this.plateMax,
    required this.screwMin,
    required this.screwMax,
    this.lockedP = 0.0,
    this.frozenP = 0.0,
    this.colorP = 0.0,
    this.hiddenP = 0.0,
    this.heavyP = 0.0,
    this.oneWayP = 0.0,
    this.theme = 'workshop',
  });

  final int cols;
  final int rows;
  final int plateMin;
  final int plateMax;
  final int screwMin;
  final int screwMax;
  final double lockedP;
  final double frozenP;
  final double colorP;
  final double hiddenP;
  final double heavyP;
  final double oneWayP;
  final String theme;
}

/// Difficulty bands matching the PDR structure (easy/medium/hard).
const List<GenParams> difficultyBands = [
  // Easy
  GenParams(
    cols: 6, rows: 6, plateMin: 2, plateMax: 3, screwMin: 5, screwMax: 8,
    lockedP: 0.2, theme: 'workshop',
  ),
  // Medium
  GenParams(
    cols: 6, rows: 8, plateMin: 3, plateMax: 4, screwMin: 8, screwMax: 13,
    lockedP: 0.25, frozenP: 0.15, colorP: 0.2, hiddenP: 0.12, oneWayP: 0.12,
    theme: 'space',
  ),
  // Hard
  GenParams(
    cols: 7, rows: 9, plateMin: 4, plateMax: 5, screwMin: 12, screwMax: 18,
    lockedP: 0.3, frozenP: 0.2, colorP: 0.25, hiddenP: 0.15, heavyP: 0.15,
    oneWayP: 0.15, theme: 'temple',
  ),
];

/// Continuous difficulty curve for generated levels: every parameter grows
/// smoothly with the level id, so later levels are strictly more demanding
/// than earlier ones instead of jumping between flat random bands.
///
/// [id] must be greater than the handcrafted count ([LevelCatalog.handcraftedCount]).
GenParams paramsForLevel(int id) {
  assert(id > 30, 'generated levels start at 31');
  final t = (id - 31) / 169; // 0..1 across the 31..200 range

  final cols = t < 0.45 ? 6 : 7;
  final rows = t < 0.25 ? 6 : (t < 0.75 ? 8 : 9);

  // Boards grow before screw counts plateau: keep headroom for placement.
  final plateCount = 2 + (t * 3.2).floor().clamp(0, 3); // 2..5
  final screwMin = 5 + (t * 12).round(); // 5..17
  final screwMax = screwMin + 1 + (t * 3).round(); // 6..21

  return GenParams(
    cols: cols,
    rows: rows,
    plateMin: plateCount,
    plateMax: plateCount,
    screwMin: screwMin,
    screwMax: screwMax,
    lockedP: 0.15 + t * 0.25,
    frozenP: t < 0.18 ? 0 : (t - 0.18) * 0.5,
    colorP: t * 0.35,
    hiddenP: t < 0.1 ? 0 : (t - 0.1) * 0.3,
    heavyP: t < 0.45 ? 0 : (t - 0.45) * 0.55,
    oneWayP: t < 0.3 ? 0 : (t - 0.3) * 0.35,
    theme: 'workshop',
  );
}

/// Builds solver-validated levels. Every generated level is guaranteed
/// solvable and every screw sits inside its own plate's rect.
class LevelGenerator {
  LevelGenerator(this.params, {int? seed}) : _rng = Random(seed ?? 1);

  final GenParams params;
  final Random _rng;

  static const List<String> themes = [
    'workshop', 'construction', 'space', 'temple',
    'ice', 'steampunk', 'cyber', 'volcano',
  ];

  LevelDef? _result;
  int attempts = 0;

  /// Generates a level, retrying with new layouts until the solver accepts.
  LevelDef generate(int id, {int maxAttempts = 12}) {
    for (var i = 0; i < maxAttempts; i++) {
      attempts++;
      final def = _layout(id);
      if (def == null) continue;
      final solution = BoardSolver(def).solve();
      if (solution == null) continue;
      if (solution.length > 55 || solution.length < 2) continue;
      _result = LevelDef(
        id: def.id,
        name: def.name,
        cols: def.cols,
        rows: def.rows,
        plates: def.plates,
        screws: def.screws,
        slots: def.slots,
        targetPlateId: def.targetPlateId,
        parMoves: solution.length,
        theme: def.theme,
      );
      return _result!;
    }
    throw StateError('LevelGenerator failed to build level $id after $maxAttempts attempts');
  }

  LevelDef? _layout(int id) {
    final cols = params.cols;
    final rows = params.rows;
    final plateCount = _rng.nextInt(params.plateMax - params.plateMin + 1) + params.plateMin;

    final plates = <Plate>[];
    final rects = <IntRect>[];
    for (var p = 0; p < plateCount; p++) {
      var placed = false;
      for (var t = 0; t < 40 && !placed; t++) {
        final w = 2 + _rng.nextInt(2); // 2..3
        final h = 2 + _rng.nextInt(2); // 2..3
        final x = _rng.nextInt(cols - w + 1); // 0..cols-w
        final y = _rng.nextInt(rows - h + 1); // 0..rows-h
        final r = IntRect(x, y, w, h);
        if (rects.any((e) => e.overlaps(r))) continue;
        rects.add(r);
        plates.add(Plate(id: p, rect: r));
        placed = true;
      }
      if (!placed) return null;
    }

    // ---- screws on plate edges/corners ----
    final screws = <Screw>[];
    var screwCount = params.screwMin +
        _rng.nextInt(max(1, params.screwMax - params.screwMin + 1));
    screwCount = max(screwCount, plates.length);
    var target = 0;
    // every plate gets at least one screw
    for (final pl in plates) {
      final candidates = _edgeCells(pl.rect)..shuffle(_rng);
      screws.add(Screw(id: screws.length, cell: candidates.first, plateId: pl.id));
      target++;
    }
    // then spread the rest (bounded: a saturated plate must not loop forever)
    var idle = 0;
    while (target < screwCount && idle < screwCount * 4) {
      final pl = plates[_rng.nextInt(plates.length)];
      final candidates = _edgeCells(pl.rect);
      candidates.shuffle(_rng);
      var placed = false;
      for (final c in candidates) {
        if (screws.any((s) => s.cell == c)) continue;
        screws.add(Screw(id: screws.length, cell: c, plateId: pl.id));
        target++;
        placed = true;
        break;
      }
      idle = placed ? 0 : idle + 1;
    }
    if (screws.length < 2) return null;
    screwCount = screws.length;

    // ---- mechanics ----
    var depthMax = 0;
    final mutable = screws.toList();

    // frozen: at most one, on a plate touching another plate
    if (params.frozenP > 0 && _rng.nextDouble() < params.frozenP) {
      final touching = plates.where((p) {
        return plates.any((o) => o.id != p.id && o.rect.touches(p.rect));
      }).toList();
      if (touching.isNotEmpty) {
        final pl = touching[_rng.nextInt(touching.length)];
        final own = mutable.where((s) => s.plateId == pl.id).toList();
        if (own.isNotEmpty) {
          final s = own[_rng.nextInt(own.length)];
          mutable[mutable.indexOf(s)] = s.copyWith(type: ScrewType.frozen);
        }
      }
    }

    // color: give 1-2 screws matching colors
    final slots = <int, int>{};
    if (params.colorP > 0 && _rng.nextDouble() < params.colorP && mutable.length >= 4) {
      final count = 1 + _rng.nextInt(2); // 1..2 colors
      final basics = <int>[];
      for (var i = 0; i < mutable.length; i++) {
        if (mutable[i].type == ScrewType.basic) basics.add(i);
      }
      basics.shuffle(_rng);
      for (var c = 0; c < count && c < basics.length; c++) {
        final idx = basics[c];
        final color = mutable[idx].id % 3;
        mutable[idx] = mutable[idx].copyWith(type: ScrewType.color, color: color);
        slots[color] = (slots[color] ?? 0) + 1;
      }
    }

    // locked: key must be a non-locked screw (no lock cycles)
    if (params.lockedP > 0 && _rng.nextDouble() < params.lockedP) {
      final candidates = mutable.where((s) => s.type == ScrewType.basic).toList();
      final keys = mutable.where((s) => s.type == ScrewType.basic).toList();
      if (candidates.isNotEmpty && keys.length >= 2) {
        final s = candidates[_rng.nextInt(candidates.length)];
        final key = keys.where((k) => k.id != s.id).toList()..shuffle(_rng);
        if (key.isNotEmpty) {
          final idx = mutable.indexOf(s);
          mutable[idx] = Screw(
            id: s.id, cell: s.cell, plateId: s.plateId,
            type: ScrewType.locked, lockKey: key.first.id, color: s.color,
          );
        }
      }
    }

    // one-way
    if (params.oneWayP > 0 && _rng.nextDouble() < params.oneWayP) {
      final basics = mutable.where((s) => s.type == ScrewType.basic).toList();
      if (basics.isNotEmpty) {
        final s = basics[_rng.nextInt(basics.length)];
        final idx = mutable.indexOf(s);
        mutable[idx] = s.copyWith(type: ScrewType.oneWay);
      }
    }

    // hidden: place a cover plate over a random screw
    if (params.hiddenP > 0 && _rng.nextDouble() < params.hiddenP && mutable.length >= 3) {
      final targetScrew = mutable[_rng.nextInt(mutable.length)];
      final c = targetScrew.cell;
      final ownRect = plates[targetScrew.plateId].rect;
      for (var t = 0; t < 8; t++) {
        final w = 1 + _rng.nextInt(2);
        final h = 1 + _rng.nextInt(2);
        final x = (c.x - _rng.nextInt(w)).clamp(0, cols - w);
        final y = (c.y - _rng.nextInt(h)).clamp(0, rows - h);
        final r = IntRect(x, y, w, h);
        if (!r.contains(c)) continue;
        // must not overlap any plate other than the screw's own plate
        final overlapsOthers = rects.any((e) => e.overlaps(r) && e != ownRect);
        if (overlapsOthers) continue;
        final id = plates.length;
        depthMax++;
        rects.add(r);
        plates.add(Plate(id: id, rect: r, depth: depthMax));
        final mid = Cell(r.cx, r.cy);
        final idx = mutable.indexOf(targetScrew);
        mutable[idx] = Screw(
          id: targetScrew.id, cell: targetScrew.cell, plateId: targetScrew.plateId,
          type: ScrewType.hidden, lockKey: targetScrew.lockKey, color: targetScrew.color,
        );
        // the cover holds itself with 1-2 screws of its own
        final coverScrews = [mid];
        if (r.w > 1 && r.h > 1) {
          coverScrews.add(Cell(r.x + r.w - 1, r.y + r.h - 1));
        }
        for (final cs in coverScrews) {
          mutable.add(Screw(id: mutable.length, cell: cs, plateId: id));
        }
        break;
      }
    }

    // heavy: mark a plate heavy with a fragile plate directly below it
    if (params.heavyP > 0 && _rng.nextDouble() < params.heavyP && plates.length >= 2) {
      final heavy = plates.where((p) {
        return plates.any((o) => o.id != p.id && o.rect.y == p.rect.bottom);
      }).toList();
      if (heavy.isNotEmpty) {
        final h = heavy[_rng.nextInt(heavy.length)];
        plates[plates.indexOf(h)] = Plate(id: h.id, rect: h.rect, heavy: true, depth: h.depth);
        final below = plates.where((o) => o.id != h.id && o.rect.y == h.rect.bottom).toList();
        if (below.isNotEmpty) {
          final b = below[_rng.nextInt(below.length)];
          plates[plates.indexOf(b)] = Plate(id: b.id, rect: b.rect, fragile: true, depth: b.depth);
        }
      }
    }

    // ---- fix ids & validate geometry ----
    final platesOut = <Plate>[];
    for (var i = 0; i < plates.length; i++) {
      final p = plates[i];
      platesOut.add(Plate(id: i, rect: p.rect, depth: p.depth, heavy: p.heavy, fragile: p.fragile));
    }
    final screwsOut = <Screw>[];
    for (var i = 0; i < mutable.length; i++) {
      final s = mutable[i];
      if (s.plateId >= platesOut.length) return null;
      final own = platesOut[s.plateId].rect;
      if (!own.contains(s.cell)) return null; // screws must sit on their plate
      screwsOut.add(Screw(
        id: i, cell: s.cell, plateId: s.plateId, type: s.type,
        lockKey: s.lockKey, color: s.color, depth: s.depth,
      ));
    }

    final theme = themes[id % themes.length];
    return LevelDef(
      id: id,
      name: 'Level $id',
      cols: cols,
      rows: rows,
      plates: platesOut,
      screws: screwsOut,
      slots: slots,
      theme: theme,
    );
  }

  List<Cell> _edgeCells(IntRect r) {
    final out = <Cell>[];
    for (var x = r.x; x < r.right; x++) {
      out.add(Cell(x, r.y));
      out.add(Cell(x, r.bottom - 1));
    }
    for (var y = r.y + 1; y < r.bottom - 1; y++) {
      out.add(Cell(r.x, y));
      out.add(Cell(r.right - 1, y));
    }
    return out;
  }
}
