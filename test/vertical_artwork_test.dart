import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all 17 map region SVGs are portrait-native and vector-only', () async {
    for (var i = 1; i <= 17; i++) {
      final number = i.toString().padLeft(2, '0');
      final asset = 'assets/artwork/regions/$number.svg';
      final svg = await rootBundle.loadString(asset);

      expect(svg, contains('viewBox="0 0 720 1280"'), reason: asset);
      expect(svg, isNot(contains('<image')), reason: asset);
      expect(
        svg,
        isNot(contains('<rect x="0" y="0" width="720" height="1280"')),
        reason: 'map vignette must not be a full-canvas flat background: $asset',
      );
      expect(svg, isNot(contains('<feGaussianBlur')), reason: asset);
      expect(svg, contains('preserveAspectRatio="xMidYMid meet"'), reason: asset);
    }
  });

  test('combat arena SVGs remain landscape so battle presentation is preserved',
      () async {
    for (var i = 1; i <= 17; i++) {
      final number = i.toString().padLeft(2, '0');
      final asset = 'assets/artwork/arenas/$number.svg';
      final svg = await rootBundle.loadString(asset);

      expect(svg, contains('viewBox="0 0 1280 720"'), reason: asset);
      expect(svg, isNot(contains('<image')), reason: asset);
    }
  });
}
