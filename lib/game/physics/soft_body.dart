import 'vec2.dart';

/// A particle of a soft body (Verlet integration).
class Particle {
  Particle(Vec2 pos)
      : pos = pos,
        prev = pos,
        rest = pos;

  Vec2 pos;
  Vec2 prev;
  final Vec2 rest;
  double mass = 1.0;

  /// Screw anchors holding this particle (a particle can be pinned by
  /// several screws near the same corner).
  final List<Vec2> pins = [];

  bool get isPinned => pins.isNotEmpty;

  /// Max position change per substep (cells/s). Caps solver blow-ups.
  static const double maxSpeed = 2.0;

  void integrate(Vec2 gravity, double damping, double dt2) {
    if (isPinned) {
      pos = rest;
      prev = rest;
      return;
    }
    var vel = (pos - prev) * damping;
    final vLen = vel.length;
    if (vLen > maxSpeed) {
      vel = vel * (maxSpeed / vLen);
    }
    prev = pos;
    pos = pos + vel + gravity * dt2;
  }

  void solvePin() {
    if (isPinned) {
      pos = rest;
      prev = rest;
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

/// Index layout of the 9-particle rectangle:
///
///   0--1--2
///   |  |  |
///   3--4--5
///   |  |  |
///   6--7--8
class SoftBody {
  SoftBody(this.id, this.origin, this.rectW, this.rectH,
      {this.gravityScale = 1.0}) {
    final w = rectW;
    final h = rectH;
    particles = List.generate(9, (i) {
      final px = origin.x + (i % 3) * w / 2;
      final py = origin.y + (i ~/ 3) * h / 2;
      return Particle(Vec2(px, py));
    });
    void spring(int a, int b, double stiffness) {
      final s = Spring(a, b, stiffness);
      s.rest = (particles[a].rest - particles[b].rest).length;
      springs.add(s);
    }

    // structure (edges) - stiff: holds the shape
    spring(0, 1, 0.9); spring(1, 2, 0.9);
    spring(3, 4, 0.9); spring(4, 5, 0.9);
    spring(6, 7, 0.9); spring(7, 8, 0.9);
    spring(0, 3, 0.9); spring(3, 6, 0.9);
    spring(1, 4, 0.9); spring(4, 7, 0.9);
    spring(2, 5, 0.9); spring(5, 8, 0.9);
    // shear (diagonals) - soft: lets the plate flex and bend like cardboard
    spring(0, 4, 0.18); spring(2, 4, 0.18);
    spring(6, 4, 0.18); spring(8, 4, 0.18);
    spring(0, 8, 0.12); spring(2, 6, 0.12);

    for (var i = 0; i < 9; i++) {
      particles[i].mass = i == 4 ? 1.6 : 1.0;
    }
  }

  final int id;
  final Vec2 origin;
  final double rectW;
  final double rectH;
  final double gravityScale;

  late final List<Particle> particles;
  final List<Spring> springs = [];

  /// Bodies this one must not collide with (they overlap in cells).
  final Set<int> noCollide = {};

  Vec2? _lastPos;

  Vec2 get center {
    var s = Vec2.zero;
    for (final p in particles) {
      s += p.pos;
    }
    return s / 9;
  }

  Vec2 get velocity {
    final c = center;
    final prev = _lastPos ?? c;
    _lastPos = c;
    return c - prev;
  }

  /// Corners in order: 0, 2, 8, 6 (for OBB).
  Obb get obb => Obb([
        particles[0].pos,
        particles[2].pos,
        particles[8].pos,
        particles[6].pos,
      ]);

  /// The body is released (all screws gone) when no particle is pinned.
  bool get released => particles.every((p) => !p.isPinned);

  int get pinnedCount => particles.where((p) => p.isPinned).length;

  /// Pin the particle nearest to [anchor] (a screw position) to it.
  int pinAt(Vec2 anchor) {
    var best = 0;
    var bestD = double.infinity;
    for (var i = 0; i < 9; i++) {
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

  void solveSprings() {
    for (final s in springs) {
      final pa = particles[s.a];
      final pb = particles[s.b];
      if (pa.isPinned && pb.isPinned) continue;
      final diff = pb.pos - pa.pos;
      final d = diff.length;
      if (d < 1e-12) continue;
      final corr = ((d - s.rest) / d) * s.stiffness * relaxation;
      if (pa.isPinned) {
        pb.pos += diff * corr;
      } else if (pb.isPinned) {
        pa.pos -= diff * corr;
      } else {
        final wa = 1 / pa.mass;
        final wb = 1 / pb.mass;
        final total = wa + wb;
        pa.pos -= diff * (corr * wa / total);
        pb.pos += diff * (corr * wb / total);
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
    }
    _lastPos = null;
  }
}
