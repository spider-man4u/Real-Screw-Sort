import 'dart:collection';

import 'board.dart';
import 'models.dart';

/// A shortest solution found by [BoardSolver].
class Solution {
  Solution(this.moves, this.states);

  final List<Move> moves;
  final List<_SimState> states;

  int get length => moves.length;
}

/// Minimal state for search: which screws are gone (bitmask), which screw is
/// in hand. Slots-used is fully determined by (mask, hand) since slotting is
/// the only way a color screw leaves the hand.
class _SimState {
  _SimState(this.mask, this.hand);

  final int mask;
  final int hand; // -1 = empty hand, else screw id

  @override
  bool operator ==(Object other) =>
      other is _SimState && other.mask == mask && other.hand == hand;

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
  Solution? solve({int fromRemovedMask = 0, int? fromHand}) {
    final start = _SimState(fromRemovedMask, fromHand ?? -1);
    final initial = _buildBoard(start);
    if (_isGoal(initial)) return Solution(const [], [start]);

    final queue = Queue<_SimState>();
    final visited = <_SimState>{};
    final parent = <_SimState, _SimState>{};
    final moveToParent = <_SimState, Move>{};

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

  bool _isGoal(BoardState b) => b.isWon;

  _SimState? _apply(BoardState board, _SimState state, Move move) {
    if (move.isRemove) {
      final screw = level.screws.firstWhere((s) => s.id == move.screwId);
      if (screw.isColor) {
        return _SimState(state.mask, screw.id);
      }
      return _SimState(state.mask | (1 << screw.id), -1);
    }
    // slot
    final h = state.hand;
    if (h < 0) return null;
    return _SimState(state.mask | (1 << h), -1);
  }

  BoardState _buildBoard(_SimState state) {
    final b = BoardState(level);
    b.restoreFromMask(state.mask, state.hand >= 0 ? state.hand : null);
    return b;
  }

  Solution? _reconstruct(
    _SimState start,
    _SimState goal,
    Map<_SimState, _SimState> parent,
    Map<_SimState, Move> moveToParent,
  ) {
    final moves = <Move>[];
    final states = <_SimState>[];
    _SimState cur = goal;
    while (cur != start) {
      moves.add(moveToParent[cur]!);
      states.add(cur);
      cur = parent[cur]!;
    }
    states.add(start);
    return Solution(moves.reversed.toList(), states.reversed.toList());
  }
}
