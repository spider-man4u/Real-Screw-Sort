import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:real_screw_sort/game/physics/soft_body.dart';
import 'package:real_screw_sort/game/physics/vec2.dart';
import 'package:real_screw_sort/game/physics/world.dart';

void main() {
  // A 3x2 plate sitting at cells (1,1)-(4,3): rect origin (1,1), w=3, h=2.
  SoftBody buildPlate(PhysicsWorld world, {double gravityScale = 1.0}) {
    return world.addBody(
      x: 1,
      y: 1,
      w: 3,
      h: 2,
      gravityScale: gravityScale,
    );
  }

  void run(PhysicsWorld world, int frames, [double dt = 1 / 60]) {
    for (var i = 0; i < frames; i++) {
      world.step(dt);
    }
  }

  group('real board physics', () {
    test('unscrewing the top screw bends the plate down at an angle', () {
      final world = PhysicsWorld(cols: 8, rows: 8);
      final plate = buildPlate(world);

      // screws at bottom corners and on the top edge
      final bottomL = const Vec2(1.5, 2.5);
      final bottomR = const Vec2(3.5, 2.5);
      final top = const Vec2(2.5, 1.5);
      world.pin(plate, bottomL);
      world.pin(plate, bottomR);
      world.pin(plate, top);

      run(world, 240); // settle with the top screw still in place
      final sagWhileHeld = world.sag(plate);
      expect(sagWhileHeld, lessThan(0.01), reason: 'held plate must not sag');

      // the player unscrews the top -> the top edge now bends down
      world.unpin(plate, top);
      run(world, 1200);

      final sagAfterUnscrew = world.sag(plate);
      expect(sagAfterUnscrew, greaterThan(sagWhileHeld + 0.005),
          reason: 'unscrewing the top must make the plate bend downward');
    });

    test('a plate hanging from a single screw tilts at an angle', () {
      final world = PhysicsWorld(cols: 8, rows: 8);
      final plate = buildPlate(world);
      world.pin(plate, const Vec2(1.5, 1.5)); // only top-left screw

      run(world, 1500);

      final angle = world.tiltAngle(plate);
      expect(angle.abs(), greaterThan(0.3),
          reason: 'a single screw lets the plate swing to a steep angle');
    });

    test('a plate with all screws removed falls freely', () {
      final world = PhysicsWorld(cols: 8, rows: 8);
      final plate = buildPlate(world);
      final startY = plate.center.y;
      run(world, 30);
      expect(plate.center.y, greaterThan(startY + 0.1),
          reason: 'plate should fall under gravity');
    });

    test('falling plate rests on the board lip and stops', () {
      final world = PhysicsWorld(cols: 8, rows: 8);
      final plate = buildPlate(world);
      run(world, 2400);
      for (final p in plate.particles) {
        expect(p.pos.y, lessThanOrEqualTo(world.rows + 1e-6));
      }
    });

    test('a released plate lands on a screwed-down plate below (stacking)', () {
      final world = PhysicsWorld(cols: 8, rows: 8);
      final bottom = world.addBody(x: 1, y: 5, w: 3, h: 1);
      // hold the bottom plate with two screws on its top edge
      world.pin(bottom, const Vec2(1.5, 5.5));
      world.pin(bottom, const Vec2(3.5, 5.5));

      final top = world.addBody(x: 1, y: 1, w: 3, h: 1);
      run(world, 1500);

      final bottomTop = (bottom.particles[0].pos.y + bottom.particles[2].pos.y) / 2;
      final topCenter = top.center.y;
      // top must rest ON the bottom plate, not pass through it
      expect(topCenter, lessThan(bottomTop + 0.6), reason: 'no falling through');
      expect(topCenter, greaterThan(bottomTop - 0.9), reason: 'actually rests on it');
    });

    test('overlapping (cover) plates do not collide with each other', () {
      final world = PhysicsWorld(cols: 8, rows: 8);
      final cover = world.addBody(
        x: 1,
        y: 1,
        w: 3,
        h: 2,
        noCollideWith: {2},
      );
      final behind = world.addBody(
        x: 1,
        y: 1,
        w: 3,
        h: 2,
        noCollideWith: {cover.id},
      );
      world.pin(behind, const Vec2(1.5, 1.5));
      world.pin(behind, const Vec2(3.5, 1.5));
      world.pin(cover, const Vec2(1.5, 1.5));
      world.pin(cover, const Vec2(3.5, 1.5));
      // remove the cover plate's screws: it must fall through the plate
      // it was covering (it is in front of it)
      world.release(cover);
      run(world, 600);
      expect(cover.center.y, greaterThan(behind.center.y + 0.5));
    });

    test('heavy plates fall faster', () {
      final world = PhysicsWorld(cols: 8, rows: 8);
      final light = world.addBody(x: 1, y: 1, w: 2, h: 1);
      final heavy = world.addBody(x: 4, y: 1, w: 2, h: 1, gravityScale: 1.8);
      run(world, 60);
      expect(heavy.center.y, greaterThan(light.center.y));
    });

    test('impact events fire when a plate hits the board lip', () {
      final world = PhysicsWorld(cols: 8, rows: 8);
      var hits = 0;
      var maxSpeed = 0.0;
      world.onImpact = (body, speed) {
        hits++;
        maxSpeed = max(maxSpeed, speed);
      };
      final plate = world.addBody(x: 1, y: 1, w: 2, h: 1);
      run(world, 600);
      expect(hits, greaterThan(0));
      expect(maxSpeed, greaterThan(0));
    });

    test('tilt angle math: flat plate has zero tilt', () {
      final world = PhysicsWorld(cols: 8, rows: 8);
      final plate = world.addBody(x: 0, y: 0, w: 2, h: 1);
      expect(world.tiltAngle(plate), closeTo(0, 1e-9));
    });
  });
}
