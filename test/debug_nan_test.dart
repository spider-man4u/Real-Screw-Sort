import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:real_screw_sort/game/physics/soft_body.dart';
import 'package:real_screw_sort/game/physics/vec2.dart';
import 'package:real_screw_sort/game/physics/world.dart';

/// Temporary debug test to locate the first NaN in the PBD simulation.
/// Writes its diagnostics to build/nan_debug.txt so the CI job can upload it
/// as an artifact.
void main() {
  test('debug: locate first NaN', () {
    final out = StringBuffer();
    void probe(String label, PhysicsWorld world, SoftBody plate,
        List<(String, Vec2)> pins) {
      for (final (name, anchor) in pins) {
        world.pin(plate, anchor);
      }
      for (var frame = 0; frame < 30; frame++) {
        world.step(1 / 60);
        for (var i = 0; i < plate.particles.length; i++) {
          final p = plate.particles[i];
          if (p.pos.x.isNaN ||
              p.pos.y.isNaN ||
              p.prev.x.isNaN ||
              p.prev.y.isNaN) {
            out.writeln('[$label] NaN at frame $frame particle $i: '
                'pos=${p.pos} prev=${p.prev} rest=${p.rest} '
                'pins=${p.pins} mass=${p.mass}');
            out.writeln('[$label] all: '
                '${plate.particles.map((q) => q.pos.toString()).join(' ')}');
            out.writeln('[$label] sag=${world.sag(plate)} '
                'tilt=${world.tiltAngle(plate)}');
            return;
          }
        }
      }
      out.writeln('[$label] no NaN in first 30 frames; '
          'sag=${world.sag(plate)} tilt=${world.tiltAngle(plate)}');
    }

    // scenario A: sag test (3 pins, single body)
    {
      final world = PhysicsWorld(cols: 8, rows: 8);
      final plate = world.addBody(x: 1, y: 1, w: 3, h: 2);
      probe('sag', world, plate, [
        ('bottomL', const Vec2(1.5, 2.5)),
        ('bottomR', const Vec2(3.5, 2.5)),
        ('top', const Vec2(2.5, 1.5)),
      ]);
    }

    // scenario B: stacking test (two bodies, support collisions)
    {
      final world = PhysicsWorld(cols: 8, rows: 8);
      final bottom = world.addBody(x: 1, y: 5, w: 3, h: 1);
      probe('stack-bottom', world, bottom, [
        ('screwL', const Vec2(1.5, 5.5)),
        ('screwR', const Vec2(3.5, 5.5)),
      ]);
    }

    Directory('build').createSync(recursive: true);
    File('build/nan_debug.txt').writeAsStringSync(out.toString());
    // ignore: avoid_print
    print(out);
    expect(true, isTrue);
  });
}
