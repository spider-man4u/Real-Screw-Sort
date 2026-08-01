import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../engine/board.dart';
import '../engine/models.dart';
import '../physics/world.dart';
import 'themes.dart';

/// A screw that is animating out (rotation + pop), driven by GameController.
class ScrewFx {
  ScrewFx({required this.cell, required this.color});

  final Cell cell;
  final Color color;
  double progress = 0;
  double angle = 0;
}

/// A spark particle for impacts and pops.
class Spark {
  Spark({
    required this.pos,
    required this.vel,
    required this.life,
    required this.maxLife,
    required this.color,
  });

  Offset pos;
  Offset vel;
  double life;
  final double maxLife;
  final Color color;
}

/// Everything the board painter needs to draw one frame.
class BoardPaintData {
  BoardPaintData({
    required this.level,
    required this.board,
    required this.world,
    required this.cell,
    required this.origin,
    this.fx = const [],
    this.sparks = const [],
    this.highlightScrew,
    this.shake = Offset.zero,
    this.themeKey = 'workshop',
    this.skinKey = 'classic',
  });

  final LevelDef level;
  final BoardState board;
  final PhysicsWorld world;
  final double cell;
  final Offset origin;
  final List<ScrewFx> fx;
  final List<Spark> sparks;
  final int? highlightScrew;
  final Offset shake;
  final String themeKey;
  final String skinKey;

  Offset cellCenter(Cell c) =>
      Offset(origin.dx + (c.x + 0.5) * cell, origin.dy + (c.y + 0.5) * cell);
}

class BoardPainter extends CustomPainter {
  BoardPainter(this.data);

  final BoardPaintData data;

  late final BoardTheme theme = themeForKey(data.themeKey);
  late final ScrewSkin skin = skinForKey(data.skinKey);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(data.shake.dx * data.cell, data.shake.dy * data.cell);
    _drawPegboard(canvas, size);
    _drawSlots(canvas);
    _drawPlates(canvas);
    _drawScrews(canvas);
    _drawFx(canvas);
    _drawSparks(canvas);
    canvas.restore();
  }

  // ---------------------------------------------------------------- board
  void _drawPegboard(Canvas canvas, Size size) {
    final cell = data.cell;
    final cols = data.level.cols;
    final rows = data.level.rows;
    final boardRect = Rect.fromLTWH(
      data.origin.dx - cell * 0.3,
      data.origin.dy - cell * 0.3,
      cols * cell + cell * 0.6,
      rows * cell + cell * 0.6,
    );

    final peg = RRect.fromRectAndRadius(
      boardRect,
      Radius.circular(cell * 0.35),
    );
    canvas.drawRRect(peg, Paint()..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: theme.pegGradient,
    ).createShader(boardRect));
    canvas.drawRRect(
      peg,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.18),
    );

    // screw holes
    final holePaint = Paint()..color = theme.hole;
    for (var x = 0; x < cols; x++) {
      for (var y = 0; y < rows; y++) {
        canvas.drawCircle(
          data.cellCenter(Cell(x, y)),
          cell * 0.16,
          holePaint,
        );
      }
    }

    // bottom lip (where fallen plates rest)
    final lip = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        data.origin.dx - cell * 0.3,
        data.origin.dy + rows * cell + cell * 0.05,
        cols * cell + cell * 0.6,
        cell * 0.45,
      ),
      Radius.circular(cell * 0.22),
    );
    canvas.drawRRect(lip, Paint()..color = theme.frame);
  }

  // ------------------------------------------------------------------ slots
  void _drawSlots(Canvas canvas) {
    final cell = data.cell;
    final slotCount = data.level.maxColorSlots;
    if (slotCount == 0) return;
    // slots live on the left edge, one per row (up to maxColorSlots)
    for (var color = 0; color < data.level.slots.length; color++) {
      final count = data.level.slotCountFor(color);
      for (var i = 0; i < count; i++) {
        final used = data.board.usedSlotCountFor(color) > i;
        final cx = data.origin.dx - cell * 0.85;
        final cy = data.origin.dy + (i + 1.5) * cell;
        final c = screwColors[color % screwColors.length];
        final rect = Rect.fromCenter(center: Offset(cx, cy), width: cell * 0.7, height: cell * 0.7);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.18)),
          Paint()..color = used ? c : c.withValues(alpha: 0.25),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.18)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = c.withValues(alpha: 0.9),
        );
        if (used) {
          canvas.drawLine(
            Offset(cx - cell * 0.15, cy),
            Offset(cx + cell * 0.15, cy),
            Paint()
              ..color = Colors.white
              ..strokeWidth = cell * 0.08
              ..strokeCap = StrokeCap.round,
          );
        }
      }
    }
  }

  // ------------------------------------------------------------------ plates
  void _drawPlates(Canvas canvas) {
    // back to front by depth
    final plates = [...data.level.plates]
      ..sort((a, b) => a.depth.compareTo(b.depth));
    for (final plate in plates) {
      final body = data.world.bodyById(plate.id);
      if (body == null) continue;
      final p = body.particles;
      final path = Path()
        ..moveTo(p[0].pos.x * data.cell + data.origin.dx, p[0].pos.y * data.cell + data.origin.dy)
        ..lineTo(p[2].pos.x * data.cell + data.origin.dx, p[2].pos.y * data.cell + data.origin.dy)
        ..lineTo(p[8].pos.x * data.cell + data.origin.dx, p[8].pos.y * data.cell + data.origin.dy)
        ..lineTo(p[6].pos.x * data.cell + data.origin.dx, p[6].pos.y * data.cell + data.origin.dy)
        ..close();

      final rect = path.getBounds();
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: plate.heavy
              ? [const Color(0xFF9AA3B8), const Color(0xFF67718C)]
              : theme.plateGradient,
        ).createShader(rect);

      canvas.drawPath(path, paint);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(2, data.cell * 0.06)
          ..color = plate.heavy ? const Color(0xFF414B63) : theme.plateEdge
          ..strokeJoin = StrokeJoin.round,
      );

      if (plate.fragile && !plate.heavy) {
        // crack marks
        final crackPaint = Paint()
          ..color = Palette.ink.withValues(alpha: 0.35)
          ..strokeWidth = max(1.5, data.cell * 0.04);
        final c = rect.center;
        canvas.drawLine(c + const Offset(-8, 4), c + const Offset(6, -6), crackPaint);
        canvas.drawLine(c + const Offset(6, -6), c + const Offset(10, 2), crackPaint);
      }
    }
  }

  // ------------------------------------------------------------------ screws
  void _drawScrews(Canvas canvas) {
    for (final s in data.level.screws) {
      if (data.board.screwGone(s.id)) continue;
      if (data.board.isHidden(s)) continue;
      final center = data.cellCenter(s.cell);
      final r = data.cell * 0.27;
      final highlight = s.id == data.highlightScrew;

      if (highlight) {
        canvas.drawCircle(
          center,
          r * 1.9,
          Paint()..color = theme.accent.withValues(alpha: 0.35),
        );
        canvas.drawCircle(
          center,
          r * 2.3,
          Paint()..color = theme.accent.withValues(alpha: 0.12),
        );
      }

      // head
      final head = Paint()
        ..shader = RadialGradient(
          colors: s.isColor
              ? [screwColors[s.color! % screwColors.length], skin.headB]
              : [skin.headA, skin.headB],
        ).createShader(Rect.fromCircle(center: center, radius: r));
      canvas.drawCircle(center, r, head);
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1.5, r * 0.12)
          ..color = skin.edge,
      );
      // slot
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(pi / 4);
      canvas.drawLine(
        Offset(-r * 0.5, 0),
        Offset(r * 0.5, 0),
        Paint()
          ..color = skin.slot
          ..strokeWidth = max(1.2, r * 0.14)
          ..strokeCap = StrokeCap.round,
      );
      canvas.restore();

      _drawScrewBadges(canvas, s, center, r);
    }
  }

  void _drawScrewBadges(Canvas canvas, Screw s, Offset center, double r) {
    switch (s.type) {
      case ScrewType.locked:
        _badge(canvas, center, r, Icons.lock_rounded, Palette.orange, Colors.white);
      case ScrewType.frozen:
        _badge(canvas, center, r, Icons.ac_unit_rounded, const Color(0xFF4FC3F7), Palette.ink);
      case ScrewType.color:
        canvas.drawCircle(
          center,
          r * 0.55,
          Paint()..color = screwColors[s.color! % screwColors.length],
        );
      case ScrewType.oneWay:
        _badge(canvas, center, r, Icons.arrow_forward_rounded, Palette.purple, Colors.white);
      case ScrewType.heavy:
      case ScrewType.hidden:
      case ScrewType.basic:
        break;
    }
  }

  void _badge(Canvas canvas, Offset center, double r, IconData icon, Color bg, Color fg) {
    canvas.drawCircle(center, r * 0.8, Paint()..color = bg);
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: r * 0.9,
          color: fg,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  // ------------------------------------------------------------ fx & sparks
  void _drawFx(Canvas canvas) {
    for (final fx in data.fx) {
      final center = data.cellCenter(fx.cell);
      final t = fx.progress;
      final r = data.cell * 0.25 * (1 - t * 0.4);
      canvas.save();
      canvas.translate(center.dx - t * data.cell * 0.4, center.dy - t * data.cell * 1.2);
      canvas.rotate(fx.angle);
      canvas.drawCircle(
        Offset.zero,
        r * (1 - t * 0.5),
        Paint()
          ..color = fx.color.withValues(alpha: 1 - t),
      );
      canvas.drawCircle(
        Offset.zero,
        r * (1 - t * 0.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: 1 - t),
      );
      canvas.restore();
    }
  }

  void _drawSparks(Canvas canvas) {
    for (final spark in data.sparks) {
      final a = (spark.life / spark.maxLife).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(
          spark.pos.dx * data.cell + data.origin.dx,
          spark.pos.dy * data.cell + data.origin.dy,
        ),
        data.cell * 0.08 * a,
        Paint()..color = spark.color.withValues(alpha: a),
      );
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) => true;
}
