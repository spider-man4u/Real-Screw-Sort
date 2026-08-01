import 'dart:math';

import 'soft_body.dart';
import 'vec2.dart';

/// Fixed-step PBD world. Units: 1 grid cell = 1 unit.
///
/// Plates are soft bodies pinned to the board by screws. When a screw is
/// removed the pin is released, so the plate sags/bends under gravity and
/// tilts around the remaining screws - the satisfying "real physics" feel.
class PhysicsWorld {
  PhysicsWorld({
    required this.cols,
    required this.rows,
    this.gravity = 60,
    this.damping = 0.99,
  });

  final int cols;
  final int rows;

  /// Gravity in cells/s^2 (tuned for snappy arcade feel).
  final double gravity;

  final double damping;

  static const double _substep = 1 / 240;
  static const int _iterations = 12;

  final List<SoftBody> bodies = [];

  final Map<int, SoftBody> _byId = {};

  /// Called when a body's impact speed exceeds [impactThreshold].
  void Function(SoftBody body, double speed)? onImpact;

  double impactThreshold = 6.0;

  double _accumulator = 0;

  bool _paused = false;

  void setPaused(bool v) {
    _paused = v;
    _accumulator = 0;
  }

  /// Create a body for a plate occupying [x],[y] size [w]x[h] cells.
  SoftBody addBody({
    required int x,
    required int y,
    required int w,
    required int h,
    double gravityScale = 1.0,
    Set<int>? noCollideWith,
  }) {
    final body = SoftBody(
      _nextId++,
      Vec2(x.toDouble(), y.toDouble()),
      w,
      h,
      gravityScale: gravityScale,
    );
    if (noCollideWith != null) body.noCollide.addAll(noCollideWith);
    bodies.add(body);
    _byId[body.id] = body;
    return body;
  }

  int _nextId = 0;

  SoftBody? bodyById(int id) => _byId[id];

  /// Pin the body particle nearest to [anchor] (cell center of a screw).
  void pin(SoftBody body, Vec2 anchor) {
    body.pinAt(anchor);
  }

  /// Release all pins of a body -> it falls under gravity.
  void release(SoftBody body) {
    for (final p in body.particles) {
      p.pins.clear();
    }
  }

  /// Remove one pin (one screw) from a body.
  void unpin(SoftBody body, Vec2 anchor) {
    body.unpinAt(anchor);
  }

  void step(double dt) {
    if (_paused) return;
    _accumulator += min(dt, 1 / 20);
    while (_accumulator >= _substep) {
      _substepSim();
      _accumulator -= _substep;
    }
  }

  void _substepSim() {
    final g = Vec2(0, gravity);
    for (final body in bodies) {
      for (final p in body.particles) {
        p.integrate(g * body.gravityScale, damping, _substep);
      }
    }

    for (var iter = 0; iter < _iterations; iter++) {
      for (final body in bodies) {
        body.solveSprings();
        body.solvePins();
      }
      _solveFrameCollisions();
      _solveSupportCollisions();
    }
  }

  void _solveFrameCollisions() {
    final groundY = rows.toDouble();
    for (final body in bodies) {
      for (final p in body.particles) {
        // ground (board bottom lip)
        if (p.pos.y > groundY) {
          if (p.prev.y <= groundY &&
              p.vel.y > impactThreshold * max(1.0, body.gravityScale)) {
            onImpact?.call(body, p.vel.y);
          }
          p.pos = Vec2(p.pos.x, groundY);
          p.vel = Vec2(p.vel.x, 0);
        }
        // side walls
        if (p.pos.x < 0) {
          p.pos = Vec2(0, p.pos.y);
          p.vel = Vec2(0, p.vel.y);
        }
        if (p.pos.x > cols) {
          p.pos = Vec2(cols.toDouble(), p.pos.y);
          p.vel = Vec2(0, p.vel.y);
        }
      }
    }
  }

  /// Bodies support each other along their top edge: a particle crossing a
  /// body's top edge from above is clamped to it (plates stack).
  void _solveSupportCollisions() {
    final supportEdges = <(int, Vec2, Vec2)>[];
    for (final body in bodies) {
      supportEdges.add((
        body.id,
        body.particles[body.topLeft].pos,
        body.particles[body.topRight].pos,
      ));
    }
    for (final body in bodies) {
      for (final p in body.particles) {
        for (final (id, a, b) in supportEdges) {
          if (id == body.id) continue;
          if (!_collide(body.id, id)) continue;
          if ((b.x - a.x).abs() < 1e-9) continue;
          // only clamp particles that are horizontally over the edge
          final minX = a.x < b.x ? a.x : b.x;
          final maxX = a.x < b.x ? b.x : a.x;
          if (p.pos.x < minX || p.pos.x > maxX) continue;
          final t = ((p.pos.x - a.x) / (b.x - a.x)).clamp(0.0, 1.0);
          final yAt = a.y + (b.y - a.y) * t;
          if (p.prev.y <= yAt + 1e-9 && p.pos.y > yAt) {
            p.pos = Vec2(p.pos.x, yAt);
            if (p.vel.y > 0) p.vel = Vec2(p.vel.x, 0);
          }
        }
      }
    }
  }

  bool _collide(int a, int b) {
    final ba = bodyById(a);
    final bb = bodyById(b);
    if (ba == null || bb == null) return true;
    return !ba.noCollide.contains(b) && !bb.noCollide.contains(a);
  }

  /// Angle (radians) between the body's top edge and the horizontal.
  double tiltAngle(SoftBody body) {
    final top = body.particles[body.topRight].pos -
        body.particles[body.topLeft].pos;
    return atan2(top.y, top.x);
  }

  /// Vertical sag of the top edge: rest height minus current height.
  double sag(SoftBody body) {
    final topY = (body.particles[body.topLeft].pos.y +
            body.particles[body.topRight].pos.y) /
        2;
    return topY - body.origin.y - 0.5;
  }

  void reset() {
    for (final body in bodies) {
      body.reset();
    }
    _accumulator = 0;
  }
}
