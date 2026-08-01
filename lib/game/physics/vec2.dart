import 'dart:math';
import 'dart:ui';

/// Lightweight 2D vector for the physics simulation.
class Vec2 {
  const Vec2(this.x, this.y);

  final double x;
  final double y;

  static const zero = Vec2(0, 0);

  Vec2 operator +(Vec2 o) => Vec2(x + o.x, y + o.y);
  Vec2 operator -(Vec2 o) => Vec2(x - o.x, y - o.y);
  Vec2 operator *(double s) => Vec2(x * s, y * s);
  Vec2 operator /(double s) => Vec2(x / s, y / s);

  double get length => sqrt(x * x + y * y);

  double get lengthSq => x * x + y * y;

  double cross(Vec2 o) => x * o.y - y * o.x;

  Vec2 normalized() {
    final l = length;
    return l < 1e-12 ? Vec2.zero : Vec2(x / l, y / l);
  }

  double dot(Vec2 o) => x * o.x + y * o.y;

  Vec2 lerpTo(Vec2 o, double t) => Vec2(x + (o.x - x) * t, y + (o.y - y) * t);

  Offset toOffset() => Offset(x, y);

  @override
  String toString() => '(${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)})';
}

/// Oriented bounding box defined by 4 corners (convex, consistent winding).
class Obb {
  Obb(this.corners);

  final List<Vec2> corners;

  Vec2 get center => (corners[0] + corners[1] + corners[2] + corners[3]) * 0.25;

  Vec2 edgeNormal(int i) {
    final a = corners[i];
    final b = corners[(i + 1) % 4];
    return Vec2(-(b.y - a.y), b.x - a.x).normalized();
  }

  /// Signed distance of [p] to edge [i] (positive = outside).
  double edgeDistance(Vec2 p, int i) {
    final a = corners[i];
    return (p - a).dot(edgeNormal(i));
  }

  bool contains(Vec2 p) {
    var sign = 0;
    for (var i = 0; i < 4; i++) {
      final a = corners[i];
      final b = corners[(i + 1) % 4];
      final c = p - a;
      final cross = (b - a).cross(c);
      if (cross.abs() < 1e-9) continue;
      final s = cross.sign;
      if (sign == 0) {
        sign = s;
      } else if (s != sign) {
        return false;
      }
    }
    return true;
  }

  /// Push [p] and its previous position out of this box by [margin].
  void pushOut(Vec2 p, Vec2 prev, double margin) {
    for (var i = 0; i < 4; i++) {
      final d = edgeDistance(p, i);
      if (d < margin) {
        final n = edgeNormal(i);
        p += n * (margin - d);
        prev += n * (margin - d) * 0.85;
      }
    }
  }
}
