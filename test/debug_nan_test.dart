import 'package:flutter_test/flutter_test.dart';
import 'package:real_screw_sort/game/physics/soft_body.dart';
import 'package:real_screw_sort/game/physics/vec2.dart';
import 'package:real_screw_sort/game/physics/world.dart';

/// Temporary debug test to locate the first NaN in the PBD simulation.
void main() {
  test('debug: locate first NaN', () {
    final world = PhysicsWorld(cols: 8, rows: 8);
    final plate = world.addBody(x: 1, y: 1, w: 3, h: 2);
    world.pin(plate, const Vec2(1.5, 2.5));
    world.pin(plate, const Vec2(3.5, 2.5));
    world.pin(plate, const Vec2(2.5, 1.5));

    for (var frame = 0; frame < 30; frame++) {
      world.step(1 / 60);
      for (var i = 0; i < 9; i++) {
        final p = plate.particles[i];
        if (p.pos.x.isNaN || p.pos.y.isNaN || p.prev.x.isNaN || p.prev.y.isNaN) {
          fail(
            'frame $frame particle $i NaN\n'
            '  pos=${p.pos} prev=${p.prev} rest=${p.rest} '
            'pins=${p.pins} pinned=${p.isPinned} mass=${p.mass}\n'
            '  all: ${plate.particles.map((q) => '${q.pos}').join(' ')}\n'
            '  sag=${world.sag(plate)} tilt=${world.tiltAngle(plate)}',
          );
        }
      }
    }
  });
}
