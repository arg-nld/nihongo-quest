import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_quest/ui/map/map_terrain_painter.dart';

void main() {
  group('MapLayout', () {
    test('keeps curriculum order while the route climbs from bottom to top', () {
      const count = 5;
      const width = 400.0;
      final anchors = MapLayout.anchors(count, width);

      expect(anchors, hasLength(count));
      expect(anchors.first.dy, greaterThan(anchors.last.dy));
      expect(anchors.last.dy, MapLayout.topPadding);
      expect(
        anchors.first.dy,
        MapLayout.heightFor(count) - MapLayout.bottomPadding,
      );

      for (var i = 0; i < anchors.length - 1; i++) {
        expect(anchors[i].dy - anchors[i + 1].dy, MapLayout.verticalStep);
      }
    });

    test('keeps the route inside the horizontal map bounds', () {
      final anchors = MapLayout.anchors(40, 390);
      for (final anchor in anchors) {
        expect(anchor.dx, greaterThanOrEqualTo(0));
        expect(anchor.dx, lessThanOrEqualTo(390));
      }
    });
  });
}
