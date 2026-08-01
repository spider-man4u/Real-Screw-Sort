import 'vec2.dart';

class Particle {
  Particle(Vec2 pos)
      : pos = pos,
        prev = pos,
        rest = pos;

  Vec2 pos;
  Vec2 prev;
  final Vec2 rest;
  Vec2 vel = Vec2.zero;
  double mass = 1.0;

  /// Screw anchors holding this particle (a particle can be pinned by
  /// several screws near the same corner).
  final List<Vec2> pins = [];

  bool get isPinned => pins.isNotEmpty;

  /// Max speed in cells per second. Caps any solver blow-up.
  static const double maxSpeed = 480;

  /// Semi-implicit Euler: velocity is integrated first, then position.
  /// Spring/constraint solves only touch [pos], so they can never pump
  /// energy into the simulation - this is unconditionally stable.
  void integrate(Vec2 gravity, double damping, double dt) {
    if (isPinned) {
      pos = rest;
      vel = Vec2.zero;
      return;
    }
    vel = vel * damping + gravity * dt;
    final vLen = vel.length;
    if (vLen > maxSpeed) {
      vel = vel * (maxSpeed / vLen);
    }
    prev = pos;
    pos = pos + vel * dt;
  }

  void solvePin() {
    if (isPinned) {
      pos = rest;
      vel = Vec2.zero;
    }
  }

  void addPin(Vec2 anchor) {
    pins.add(anchor);
  }

  void removePin(Vec2 anchor) {
    pins.removeWhere((p) => (p - anchor).lengthSq < 1e-9);
  }
}

class Spring {
  Spring(this.a, this.b, this.stiffness);

  final int a;
  final int b;
  final double stiffness;
  late double rest = -1;
}

/// A soft body for a plate occupying `cols` x `rows` cells.
///
/// Particles sit at the CENTER of each covered cell, so a screw at a cell
/// center pins a particle exactly - a fully screwed plate stays rigid and
/// flat, and only unscrewed parts bend and sag. Grid layout:
///
///   0--1--2     (3x2 plate: particles at cell centers)
///   | /| /|
///   |/ |/ |
///   3--4--5
class SoftBody {
  SoftBody(this.id, this.origin, this.cols, this.rows,
      {this.gravityScale = 1.0}) {
    particles = List.generate(cols * rows, (i) {
      final col = i % cols;
      final row = i ~/ cols;
      return Particle(Vec2(origin.x + col + 0.5, origin.y + row + 0.5));
    });
    void spring(int a, int b, double stiffness) {
      final s = Spring(a, b, stiffness);
      s.rest = (particles[a].rest - particles[b].rest).length;
      springs.add(s);
    }

    // structure (horizontal + vertical edges) - stiff: holds the shape
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols - 1; col++) {
        spring(row * cols + col, row * cols + col + 1, 0.9);
      }
    }
    for (var col = 0; col < cols; col++) {
      for (var row = 0; row < rows - 1; row++) {
        spring(row * cols + col, (row + 1) * cols + col, 0.9);
      }
    }
    // shear (cell diagonals) - soft: lets the plate flex like cardboard
    for (var row = 0; row < rows - 1; row++) {
      for (var col = 0; col < cols - 1; col++) {
        spring(row * cols + col, (row + 1) * cols + col + 1, 0.18);
        spring(row * cols + col + 1, (row + 1) * cols + col, 0.18);
      }
    }
  }

  final int id;
  final Vec2 origin;
  final int cols;
  final int rows;
  final double gravityScale;

  late final List<Particle> particles;
  final List<Spring> springs = [];

  int get topLeft => 0;
  int get topRight => cols - 1;
  int get bottomLeft => (rows - 1) * cols;
  int get bottomRight => cols * rows - 1;

  /// Bodies this one must not collide with (they overlap in cells).
  final Set<int> noCollide = {};

  Vec2? _lastPos;

  Vec2 get center {
    var s = Vec2.zero;
    for (final p in particles) {
      s += p.pos;
    }
    return s / particles.length;
  }

  Vec2 get velocity {
    final c = center;
    final prev = _lastPos ?? c;
    _lastPos = c;
    return c - prev;
  }

  /// Corners in order: topLeft, topRight, bottomRight, bottomLeft (for OBB).
  Obb get obb => Obb([
        particles[topLeft].pos,
        particles[topRight].pos,
        particles[bottomRight].pos,
        particles[bottomLeft].pos,
      ]);

  /// The body is released (all screws gone) when no particle is pinned.
  bool get released => particles.every((p) => !p.isPinned);

  int get pinnedCount => particles.where((p) => p.isPinned).length;

  /// Pin the particle nearest to [anchor] (a screw position) to it.
  int pinAt(Vec2 anchor) {
    var best = 0;
    var bestD = double.infinity;
    for (var i = 0; i < particles.length; i++) {
      final d = (particles[i].rest - anchor).lengthSq;
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    particles[best].addPin(anchor);
    return best;
  }

  void unpinAt(Vec2 anchor) {
    for (final p in particles) {
      p.removePin(anchor);
    }
  }

  /// Fraction of the stretch corrected per solver iteration. Keeps the
  /// effective per-substep stiffness (stiffness x relaxation x iterations)
  /// below the verlet stability limit (~4), so pinned plates cannot resonate
  /// and blow up.
  static const double relaxation = 0.25;

  /// Max position change (cells) a single spring solve may apply. Guards
  /// against the (d - rest) / d factor exploding when two particles nearly
  /// coincide (squashed plate piles).
  static const double maxCorrection = 0.5;

  void solveSprings() {
    for (final s in springs) {
      final pa = particles[s.a];
      final pb = particles[s.b];
      if (pa.isPinned && pb.isPinned) continue;
      final diff = pb.pos - pa.pos;
      final d = diff.length;
      if (d < 1e-9) continue;
      final dir = diff / d;
      var move = (d - s.rest) * s.stiffness * relaxation;
      move = move.clamp(-maxCorrection, maxCorrection);
      if (pa.isPinned) {
        pb.pos -= dir * move;
      } else if (pb.isPinned) {
        pa.pos += dir * move;
      } else {
        final wa = 1 / pa.mass;
        final wb = 1 / pb.mass;
        final total = wa + wb;
        pa.pos += dir * (move * wa / total);
        pb.pos -= dir * (move * wb / total);
      }
    }
  }

  void solvePins() {
    for (final p in particles) {
      p.solvePin();
    }
  }

  void reset() {
    for (final p in particles) {
      p.pos = p.rest;
      p.prev = p.rest;
      p.vel = Vec2.zero;
    }
    _lastPos = null;
  }
}
