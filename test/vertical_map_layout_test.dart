import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_quest/ui/map/map_terrain_painter.dart';

void main() {
  test('adventure map anchors rise continuously from the start to later levels', () {
    const count = 163;
    const width = 390.0;
    final anchors = MapLayout.anchors(count, width);

    expect(anchors, hasLength(count));
    expect(anchors.first.dy, greaterThan(anchors.last.dy));
    for (var i = 0; i < anchors.length - 1; i++) {
      expect(
        anchors[i].dy - anchors[i + 1].dy,
        MapLayout.verticalStep,
        reason: 'route should advance by a consistent vertical step at $i',
      );
    }

    final xs = anchors.map((point) => point.dx);
    expect(xs.reduce((a, b) => a < b ? a : b), greaterThan(MapLayout.nodeRadius));
    expect(xs.reduce((a, b) => a > b ? a : b), lessThan(width - MapLayout.nodeRadius));
    expect(xs.reduce((a, b) => a < b ? a : b), lessThan(width * 0.30));
    expect(xs.reduce((a, b) => a > b ? a : b), greaterThan(width * 0.70));
    expect(MapLayout.heightFor(count), greaterThan(anchors.first.dy + MapLayout.bottomPadding - 1));
  });
}
