import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Layout for the illustrated adventure map.
///
/// Node anchors and spacing live here so the terrain painter and the tappable
/// node overlay always agree on geometry.
class MapLayout {
  const MapLayout._();

  // Keep stage labels readable while the artwork scrolls as one tall world.
  // The first lesson is at the bottom and later chapters climb toward the top,
  // following the upward progression used by classic mobile puzzle maps.
  static const double nodeRadius = 22;
  static const double verticalStep = 112;
  static const double topPadding = 72;
  static const double bottomPadding = 118;
  static const double amplitudeFactor = 0.25;

  /// Total map height needed for [count] nodes.
  static double heightFor(int count) =>
      topPadding + (count <= 1 ? 0 : count - 1) * verticalStep + bottomPadding;

  /// Anchor point for node [index] on a map [width] wide. The chapter order is
  /// preserved in the list, but its y-coordinate rises as [index] increases.
  /// A deterministic curve keeps the trail stable across rebuilds.
  static Offset anchor(int index, double width, {required int count}) {
    final y = topPadding + (count - 1 - index) * verticalStep;
    final amplitude = width * amplitudeFactor;
    final secondary = width * 0.02 * math.sin(index * 1.77);
    return Offset(width / 2 + amplitude * math.sin(index * 0.70) + secondary, y);
  }

  /// All anchors, in curriculum order (first stage at the bottom).
  static List<Offset> anchors(int count, double width) =>
      [for (var i = 0; i < count; i++) anchor(i, width, count: count)];
}

/// A color sample at the vertical center of one chapter's terrain section.
/// Samples are interpolated over the full map; they never create chapter cards.
class MapBiomeStop {
  const MapBiomeStop({required this.y, required this.color});

  final double y;
  final Color color;
}

/// Paints the continuous, vertical Japanese fantasy world beneath the scene
/// vignettes: terrain, mountains, river, fields, forests and the single route.
/// The chapter colors form one continuous gradient through this canvas rather
/// than 17 stacked rectangular backgrounds.
class MapTerrainPainter extends CustomPainter {
  const MapTerrainPainter({
    required this.anchors,
    required this.nodeCount,
    this.biomeStops = const [],
    this.drawRoute = true,
  });

  final List<Offset> anchors;
  final int nodeCount;
  final List<MapBiomeStop> biomeStops;
  final bool drawRoute;

  @override
  void paint(Canvas canvas, Size size) {
    _drawSky(canvas, size);
    _drawMountains(canvas, size);
    _drawClouds(canvas, size);
    _drawRiver(canvas, size);
    _drawFields(canvas, size);
    // Scenery between nodes, on the side of the route the path is not using.
    for (var i = 0; i < nodeCount - 1; i++) {
      final here = anchors[i];
      final there = anchors[i + 1];
      final mid = Offset((here.dx + there.dx) / 2, (here.dy + there.dy) / 2);
      final onLeft = mid.dx > size.width / 2;
      final x = onLeft ? size.width * 0.16 : size.width * 0.84;
      switch (i % 4) {
        case 0:
          _drawForest(canvas, Offset(x, mid.dy), size.width);
        case 1:
          _drawSakura(canvas, Offset(x, mid.dy), size.width);
        case 2:
          _drawBamboo(canvas, Offset(x, mid.dy), size.width);
        default:
          _drawFieldPatch(canvas, Offset(x, mid.dy), size.width);
      }
    }
    _drawVillage(canvas, Offset(size.width * 0.2, size.height * 0.62), size.width);
    _drawTorii(canvas, Offset(size.width * 0.82, size.height * 0.24), size.width);
    if (drawRoute) _drawRoute(canvas, size);
  }

  // ---- Layers ----------------------------------------------------------

  void _drawSky(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final samples = [...biomeStops]..sort((a, b) => a.y.compareTo(b.y));

    if (samples.isEmpty) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.paper, AppTheme.paper, AppTheme.paperAlt],
            stops: [0.0, 0.55, 1.0],
          ).createShader(rect),
      );
      return;
    }

    // Build a strictly ascending gradient from the chapter center points. A
    // subdued wash of each biome dissolves gradually into the next instead of
    // changing color at an image or section boundary.
    final colors = <Color>[];
    final stops = <double>[];
    void addSample(double y, Color color) {
      final t = (y / math.max(size.height, 1)).clamp(0.0, 1.0).toDouble();
      if (stops.isNotEmpty && t <= stops.last + 0.00001) {
        if ((t - stops.last).abs() < 0.00001) {
          colors[colors.length - 1] = color;
          return;
        }
        return;
      }
      stops.add(t);
      colors.add(color);
    }

    final firstWash = Color.lerp(AppTheme.paper, samples.first.color, 0.17)!;
    final lastWash = Color.lerp(AppTheme.paperAlt, samples.last.color, 0.14)!;
    addSample(0, firstWash);
    for (final sample in samples) {
      addSample(sample.y, Color.lerp(AppTheme.paper, sample.color, 0.23)!);
    }
    addSample(size.height, lastWash);

    // LinearGradient requires at least two colors; the one-sample map case is
    // still useful for tests and empty/small curriculum fixtures.
    if (colors.length == 1) {
      colors.add(colors.single);
      stops.add(1.0);
    }
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: stops,
        ).createShader(rect),
    );
  }

  void _drawMountains(Canvas canvas, Size size) {
    void peak(double cx, double halfWidth, double baseY, double height, Color body) {
      final path = Path()
        ..moveTo(cx - halfWidth, baseY)
        ..lineTo(cx, baseY - height)
        ..lineTo(cx + halfWidth, baseY)
        ..close();
      canvas.drawPath(path, Paint()..color = body);
      final cap = Path()
        ..moveTo(cx - halfWidth * 0.32, baseY - height * 0.68)
        ..lineTo(cx, baseY - height)
        ..lineTo(cx + halfWidth * 0.32, baseY - height * 0.68)
        ..close();
      canvas.drawPath(cap, Paint()..color = AppTheme.terrainSnow);
    }

    // A dramatic range at the entrance, then softer ranges along the route so
    // the long map feels like several connected regions instead of one canvas.
    peak(size.width * 0.17, size.width * 0.23, 154, 118, AppTheme.terrainMountain);
    peak(size.width * 0.57, size.width * 0.28, 156, 142, AppTheme.terrainMountain);
    peak(size.width * 0.91, size.width * 0.17, 150, 91,
        AppTheme.terrainMountain.withValues(alpha: 0.88));

    for (var region = 1; region * 2240.0 < size.height; region++) {
      final y = region * 2240.0 + 430;
      final smallHeight = 46.0 + (region % 3) * 12.0;
      peak(size.width * (region.isEven ? 0.18 : 0.82), size.width * 0.20,
          y, smallHeight, AppTheme.terrainMountain.withValues(alpha: 0.20));
      peak(size.width * (region.isEven ? 0.42 : 0.61), size.width * 0.15,
          y + 9, smallHeight * 0.72,
          AppTheme.terrainForest.withValues(alpha: 0.16));
    }
  }

  void _drawClouds(Canvas canvas, Size size) {
    for (var region = 0; region * 720.0 < size.height; region++) {
      final y = region * 720.0 + 100;
      for (final item in [
        (size.width * (region.isEven ? 0.76 : 0.24), y.toDouble(), 0.78),
        (size.width * (region.isEven ? 0.27 : 0.74), y + 265.0, 0.54),
      ]) {
        final center = Offset(item.$1, item.$2);
        final scale = item.$3 * size.width / 390;
        final cloudPaint = Paint()..color = Colors.white.withValues(alpha: 0.36);
        canvas.drawOval(Rect.fromCenter(center: center, width: 56 * scale, height: 19 * scale), cloudPaint);
        canvas.drawCircle(center.translate(-15 * scale, -3 * scale), 10 * scale, cloudPaint);
        canvas.drawCircle(center.translate(0, -7 * scale), 14 * scale, cloudPaint);
        canvas.drawCircle(center.translate(15 * scale, -2 * scale), 10 * scale, cloudPaint);
      }
    }
  }

  void _drawRiver(Canvas canvas, Size size) {
    // One continuous, narrow stream meanders down the left side of the world.
    // The old implementation repeated horizontal rivers at fixed intervals,
    // producing artificial cyan bands at chapter boundaries. Chapter-specific
    // SVGs add their own ponds, crossings and wider rivers where appropriate.
    final scale = size.width / 390.0;
    final step = (size.width * 1.85).clamp(520.0, 900.0).toDouble();
    double streamX(double y) {
      final progress = y / math.max(size.height, 1.0);
      final broadBend = math.sin(progress * math.pi * 4.8 + 0.55) * 0.045;
      final localBend = math.sin(y / 710.0 + 0.75) * 0.015;
      return size.width * (0.15 + broadBend + localBend);
    }

    var y = -step;
    var x = streamX(y);
    final path = Path()..moveTo(x, y);
    while (y < size.height + step) {
      final nextY = y + step;
      final nextX = streamX(nextY);
      path.cubicTo(
        x,
        y + step * 0.34,
        nextX,
        y + step * 0.66,
        nextX,
        nextY,
      );
      x = nextX;
      y = nextY;
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = AppTheme.terrainWaterDeep.withValues(alpha: 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24 * scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppTheme.terrainWater.withValues(alpha: 0.62)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 17 * scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.34)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * scale
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawFields(Canvas canvas, Size size) {
    final scale = size.width / 390.0;
    const spacing = 1180.0;
    for (var region = 0; region * spacing < size.height; region++) {
      final side = region.isEven ? 0.035 : 0.675;
      final top = region * spacing + 520.0 + (region % 3) * 43.0;
      final w = size.width * 0.285;
      final h = (72.0 + (region % 3) * 16.0) * scale;
      final left = size.width * side;
      final shape = Path()
        ..moveTo(left + w * 0.08, top + h * 0.12)
        ..cubicTo(
          left + w * 0.34, top - h * 0.05,
          left + w * 0.75, top + h * 0.02,
          left + w * 0.96, top + h * 0.19,
        )
        ..cubicTo(
          left + w * 1.04, top + h * 0.43,
          left + w * 0.92, top + h * 0.81,
          left + w * 0.72, top + h * 0.88,
        )
        ..cubicTo(
          left + w * 0.43, top + h * 1.02,
          left + w * 0.15, top + h * 0.86,
          left + w * 0.04, top + h * 0.61,
        )
        ..cubicTo(
          left - w * 0.01, top + h * 0.40,
          left - w * 0.02, top + h * 0.22,
          left + w * 0.08, top + h * 0.12,
        )
        ..close();
      canvas.drawPath(
        shape,
        Paint()..color = AppTheme.terrainField.withValues(alpha: 0.44),
      );
      canvas.drawPath(
        shape,
        Paint()
          ..color = AppTheme.matchaDark.withValues(alpha: 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0 * scale,
      );
      // Curved crop rows follow the uneven field boundary instead of forming
      // rigid horizontal stripes across the map.
      for (var row = 1; row <= 4; row++) {
        final y = top + h * row / 5;
        final rowPath = Path()
          ..moveTo(left + w * 0.13, y)
          ..quadraticBezierTo(
            left + w * 0.48,
            y + (row.isEven ? -4 : 4) * scale,
            left + w * 0.86,
            y - 1.5 * scale,
          );
        canvas.drawPath(
          rowPath,
          Paint()
            ..color = AppTheme.matchaDark.withValues(alpha: 0.24)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.1 * scale,
        );
      }
    }
  }

  void _drawForest(Canvas canvas, Offset at, double width) {
    final scale = width / 360;
    void tree(double dx, double dy, double h, Color c) {
      final trunk = Rect.fromLTWH(at.dx + dx - 2 * scale, at.dy + dy - 6 * scale,
          4 * scale, 10 * scale);
      canvas.drawRect(trunk, Paint()..color = AppTheme.terrainWood);
      final p = Path()
        ..moveTo(at.dx + dx, at.dy + dy - h)
        ..lineTo(at.dx + dx - 11 * scale, at.dy + dy)
        ..lineTo(at.dx + dx + 11 * scale, at.dy + dy)
        ..close();
      canvas.drawPath(p, Paint()..color = c);
    }

    tree(-16, 6, 34, AppTheme.terrainForestDeep);
    tree(2, 0, 44, AppTheme.terrainForest);
    tree(20, 8, 30, AppTheme.terrainForestDeep);
  }

  void _drawFieldPatch(Canvas canvas, Offset at, double width) {
    final scale = width / 360;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: at, width: 56 * scale, height: 34 * scale),
      const Radius.circular(8),
    );
    canvas.drawRRect(rect, Paint()..color = AppTheme.terrainField);
    canvas.drawRRect(
      rect,
      Paint()
        ..color = AppTheme.matchaDark.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawVillage(Canvas canvas, Offset at, double width) {
    final scale = width / 360;
    void house(double dx, double dy, double w, double h, Color roof) {
      final body = Rect.fromLTWH(at.dx + dx, at.dy + dy, w, h);
      canvas.drawRect(body, Paint()..color = Colors.white);
      canvas.drawRect(
        body,
        Paint()
          ..color = AppTheme.terrainWood.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      final r = Path()
        ..moveTo(at.dx + dx - w * 0.12, at.dy + dy)
        ..lineTo(at.dx + dx + w / 2, at.dy + dy - h * 0.55)
        ..lineTo(at.dx + dx + w * 1.12, at.dy + dy)
        ..close();
      canvas.drawPath(r, Paint()..color = roof);
    }

    house(-24 * scale, -6 * scale, 30 * scale, 22 * scale, AppTheme.terrainRoof);
    house(10 * scale, 0, 34 * scale, 26 * scale, AppTheme.terrainRoof);
    // A small path marker between the houses.
    canvas.drawCircle(
        Offset(at.dx + 8 * scale, at.dy + 32 * scale), 3 * scale,
        Paint()..color = AppTheme.terrainPath);
  }

  void _drawTorii(Canvas canvas, Offset at, double width) {
    final scale = width / 360;
    final p = Paint()..color = AppTheme.shu;
    // Posts.
    canvas.drawRect(
        Rect.fromLTWH(at.dx - 22 * scale, at.dy, 6 * scale, 46 * scale), p);
    canvas.drawRect(
        Rect.fromLTWH(at.dx + 16 * scale, at.dy, 6 * scale, 46 * scale), p);
    // Lower beam.
    canvas.drawRect(
        Rect.fromLTWH(at.dx - 28 * scale, at.dy + 16 * scale, 56 * scale, 5 * scale), p);
    // Upper beam, slightly wider and with a small upward curve.
    final top = Path()
      ..moveTo(at.dx - 34 * scale, at.dy + 2 * scale)
      ..lineTo(at.dx + 34 * scale, at.dy + 2 * scale)
      ..lineTo(at.dx + 30 * scale, at.dy + 9 * scale)
      ..lineTo(at.dx - 30 * scale, at.dy + 9 * scale)
      ..close();
    canvas.drawPath(top, p);
  }

  void _drawSakura(Canvas canvas, Offset at, double width) {
    final scale = width / 360;
    canvas.drawRect(
        Rect.fromLTWH(at.dx - 2 * scale, at.dy, 4 * scale, 26 * scale),
        Paint()..color = AppTheme.terrainWood);
    final canopy = Paint()..color = AppTheme.sakura;
    for (final (dx, dy, r) in [
      (-13.0, -14.0, 11.0),
      (0.0, -20.0, 13.0),
      (13.0, -13.0, 10.0),
      (0.0, -6.0, 11.0),
    ]) {
      canvas.drawCircle(
          Offset(at.dx + dx * scale, at.dy + dy * scale), r * scale, canopy);
    }
    // Falling petals.
    final petal = Paint()..color = AppTheme.sakuraDeep.withValues(alpha: 0.8);
    for (final (dx, dy) in [(-26.0, 18.0), (-34.0, 30.0), (26.0, 24.0)]) {
      canvas.drawCircle(
          Offset(at.dx + dx * scale, at.dy + dy * scale), 2.4 * scale, petal);
    }
  }

  void _drawBamboo(Canvas canvas, Offset at, double width) {
    final scale = width / 360;
    final stalk = Paint()..color = AppTheme.terrainBamboo;
    for (final dx in [-12.0, -2.0, 9.0]) {
      final x = at.dx + dx * scale;
      canvas.drawLine(Offset(x, at.dy), Offset(x, at.dy - 52 * scale), stalk);
      // Segments.
      final node = Paint()
        ..color = AppTheme.terrainForestDeep
        ..strokeWidth = 1.2;
      for (var i = 1; i < 5; i++) {
        final y = at.dy - (52 * i / 5) * scale;
        canvas.drawLine(Offset(x - 4 * scale, y), Offset(x + 4 * scale, y), node);
      }
      // Leaves.
      final leaf = Paint()..color = AppTheme.terrainBamboo;
      for (final (lx, ly) in [(-8.0, -44.0), (8.0, -38.0)]) {
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(x + lx * scale, at.dy + ly * scale),
                width: 14 * scale,
                height: 4 * scale),
            leaf);
      }
    }
  }

  // ---- Route -----------------------------------------------------------

  void _drawRoute(Canvas canvas, Size size) {
    if (anchors.length < 2) return;
    final path = _smoothPath(anchors);
    // Dirt trail.
    canvas.drawPath(
      path,
      Paint()
        ..color = AppTheme.terrainPath
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    // Dashed guide line down the middle of the trail.
    _strokeDashed(
      canvas,
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.66)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
      9,
      9,
    );
  }

  /// Catmull-Rom through the anchors, emitted as cubic segments.
  Path _smoothPath(List<Offset> pts) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = pts[i];
      final p1 = pts[i + 1];
      final prev = i > 0 ? pts[i - 1] : p0;
      final next = i + 2 < pts.length ? pts[i + 2] : p1;
      final c1 = Offset(p0.dx + (p1.dx - prev.dx) / 6, p0.dy + (p1.dy - prev.dy) / 6);
      final c2 = Offset(p1.dx - (next.dx - p0.dx) / 6, p1.dy - (next.dy - p0.dy) / 6);
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p1.dx, p1.dy);
    }
    return path;
  }

  void _strokeDashed(Canvas canvas, Path path, Paint paint, double dash, double gap) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant MapTerrainPainter oldDelegate) =>
      oldDelegate.nodeCount != nodeCount ||
      oldDelegate.drawRoute != drawRoute ||
      oldDelegate.anchors.length != anchors.length ||
      oldDelegate.anchors != anchors ||
      oldDelegate.biomeStops != biomeStops;
}

/// Draws the trail above chapter panoramas so the route remains one connected,
/// tappable journey even where the illustrated regions blend into one another.
class MapRoutePainter extends CustomPainter {
  const MapRoutePainter({required this.anchors});

  final List<Offset> anchors;

  @override
  void paint(Canvas canvas, Size size) {
    if (anchors.length < 2) return;
    final path = _smoothPath(anchors);

    // A soft dark rim keeps the trail legible over both pale terrain and richly
    // colored SVG scenes without adding a heavy outline to the illustrations.
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x55332926)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 26
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppTheme.terrainPath
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    _strokeDashed(
      canvas,
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.78)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
      9,
      9,
    );
  }

  Path _smoothPath(List<Offset> pts) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = pts[i];
      final p1 = pts[i + 1];
      final prev = i > 0 ? pts[i - 1] : p0;
      final next = i + 2 < pts.length ? pts[i + 2] : p1;
      final c1 = Offset(
        p0.dx + (p1.dx - prev.dx) / 6,
        p0.dy + (p1.dy - prev.dy) / 6,
      );
      final c2 = Offset(
        p1.dx - (next.dx - p0.dx) / 6,
        p1.dy - (next.dy - p0.dy) / 6,
      );
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p1.dx, p1.dy);
    }
    return path;
  }

  void _strokeDashed(
    Canvas canvas,
    Path path,
    Paint paint,
    double dash,
    double gap,
  ) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant MapRoutePainter oldDelegate) =>
      oldDelegate.anchors.length != anchors.length ||
      oldDelegate.anchors != anchors;
}
