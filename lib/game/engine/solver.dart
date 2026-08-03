import 'dart:collection';

import 'board.dart';
import 'models.dart';

/// A shortest solution found by [BoardSolver].
class Solution {
  Solution(this.moves, this.states);

  final List<Move> moves;
  final List<SimState> states;

  int get length => moves.length;
}

/// Minimal state for search: which screws are gone (bitmask), which screw is
/// in hand. Slots-used is fully determined by (mask, hand) since slotting is
/// the only way a color screw leaves the hand.
class SimState {
  SimState(this.mask, this.hand);

  final int mask;
  final int hand; // -1 = empty hand, else screw id

  @override
  bool operator ==(Object other) =>
      other is SimState && other.mask == mask && other.hand == hand;

  @override
  int get hashCode => Object.hash(mask, hand);
}

/// Breadth-first solver over the logical board. Used for hints, par moves,
/// deadlock warnings and validating generated levels.
class BoardSolver {
  BoardSolver(this.level);

  final LevelDef level;

  static const int _maxStates = 60000;

  /// Solve from the given state. Returns null when unsolvable within limits.
  ///
  /// By default this is a fast depth-first search that returns a valid
  /// solution quickly (breadth-first search explodes combinatorially once
  /// levels have ~15+ mostly-independent screws). Pass [exact] to run the
  /// exhaustive BFS instead, which guarantees a shortest solution.
  Solution? solve({int fromRemovedMask = 0, int? fromHand, bool exact = false}) {
    final start = SimState(fromRemovedMask, fromHand ?? -1);
    final initial = _buildBoard(start);
    if (_isGoal(initial)) return Solution(const [], [start]);

    if (!exact) {
      final fast = _dfs(start, initial);
      if (fast != null) return fast;
    }
    return _bfs(start);
  }

  /// Solve and return just the first move (for the hint button).
  Move? firstMove({int fromRemovedMask = 0, int? fromHand}) {
    final s = solve(fromRemovedMask: fromRemovedMask, fromHand: fromHand);
    return (s == null || s.moves.isEmpty) ? null : s.moves.first;
  }

  /// Does the level have a solution within [maxMoves]?
  bool isSolvable({int maxMoves = 100}) {
    final s = solve();
    return s != null && s.length <= maxMoves;
  }

  /// Move-count lower bound ignoring slot constraints; cheap sanity check.
  int get screwCount => level.screws.length;

  /// Depth-first search: any solution, fast. Complete for reachability
  /// thanks to the permanent visited set.
  Solution? _dfs(SimState start, BoardState startBoard) {
    final visited = <SimState>{start};
    final path = <SimState>[start];
    final moves = <Move>[];
    if (_dfsGo(start, startBoard, visited, path, moves)) {
      return Solution(List.of(moves), List.of(path));
    }
    return null;
  }

  bool _dfsGo(
    SimState state,
    BoardState board,
    Set<SimState> visited,
    List<SimState> path,
    List<Move> moves,
  ) {
    if (visited.length >= _maxStates) return false;
    for (final move in board.availableMoves()) {
      final next = _apply(board, state, move);
      if (next == null) continue;
      if (!visited.add(next)) continue;
      final nextBoard = _buildBoard(next);
      path.add(next);
      moves.add(move);
      if (_isGoal(nextBoard)) return true;
      if (_dfsGo(next, nextBoard, visited, path, moves)) return true;
      path.removeLast();
      moves.removeLast();
    }
    return false;
  }

  /// Exhaustive breadth-first search: guarantees a shortest solution.
  Solution? _bfs(SimState start) {
    final queue = Queue<SimState>();
    final visited = <SimState>{};
    final parent = <SimState, SimState>{};
    final moveToParent = <SimState, Move>{};

    queue.add(start);
    visited.add(start);

    while (queue.isNotEmpty && visited.length < _maxStates) {
      final state = queue.removeFirst();
      final board = _buildBoard(state);
      for (final move in board.availableMoves()) {
        final next = _apply(board, state, move);
        if (next == null) continue;
        if (visited.contains(next)) continue;
        visited.add(next);
        parent[next] = state;
        moveToParent[next] = move;
        if (_isGoal(_buildBoard(next))) {
          return _reconstruct(start, next, parent, moveToParent);
        }
        queue.add(next);
      }
    }
    return null;
  }

  /// Goal test on a derived board (no move history, so use evaluateWon).
  bool _isGoal(BoardState b) => b.evaluateWon();

  SimState? _apply(BoardState board, SimState state, Move move) {
    if (move.isRemove) {
      final screw = level.screws.firstWhere((s) => s.id == move.screwId);
      if (screw.isColor) {
        return SimState(state.mask, screw.id);
      }
      return SimState(_cascade(state.mask | (1 << screw.id), state.hand), -1);
    }
    // slot
    final h = state.hand;
    if (h < 0) return null;
    return SimState(_cascade(state.mask | (1 << h), -1), -1);
  }

  /// Apply heavy-plate smash cascades to a removal mask: a detached heavy
  /// plate smashes the fragile plate directly below it, removing its screws
  /// too (chained through heavy targets).
  int _cascade(int mask, int hand) {
    var m = mask;
    var changed = true;
    while (changed) {
      changed = false;
      final b = BoardState(level);
      b.restoreFromMask(m, hand >= 0 ? hand : null);
      for (final p in level.plates) {
        if (!b.plateAttached(p.id) && p.heavy) {
          final target = p.below(level.plates);
          if (target == null || !target.fragile) continue;
          if (!b.plateAttached(target.id)) continue;
          for (final s in level.screws.where((s) => s.plateId == target.id)) {
            if (!b.screwGone(s.id)) {
              m |= 1 << s.id;
              changed = true;
            }
          }
        }
      }
    }
    return m;
  }

  BoardState _buildBoard(SimState state) {
    final b = BoardState(level);
    b.restoreFromMask(state.mask, state.hand >= 0 ? state.hand : null);
    return b;
  }

  Solution? _reconstruct(
    SimState start,
    SimState goal,
    Map<SimState, SimState> parent,
    Map<SimState, Move> moveToParent,
  ) {
    final moves = <Move>[];
    final states = <SimState>[];
    SimState cur = goal;
    while (cur != start) {
      moves.add(moveToParent[cur]!);
      states.add(cur);
      cur = parent[cur]!;
    }
    states.add(start);
    return Solution(moves.reversed.toList(), states.reversed.toList());
  }
}
