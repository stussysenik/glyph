import 'package:flutter_test/flutter_test.dart';
import 'package:glyph/core/guides.dart';

void main() {
  group('GuideManager Tests', () {
    late GuideManager guideManager;
    late CustomGuide horizontalGuide;
    late CustomGuide verticalGuide;

    setUp(() {
      guideManager = GuideManager();
      horizontalGuide = const CustomGuide(position: 100, isHorizontal: true);
      verticalGuide = const CustomGuide(position: 150, isHorizontal: false);
    });

    test('addGuide adds guide to list', () {
      guideManager.addGuide(horizontalGuide);
      expect(guideManager.visibleGuides.contains(horizontalGuide), isTrue);
    });

    test('removeGuide removes guide from list', () {
      guideManager.addGuide(horizontalGuide);
      guideManager.removeGuide(horizontalGuide);
      expect(guideManager.visibleGuides.contains(horizontalGuide), isFalse);
    });

    test('visibleGuides returns only visible guides', () {
      final visibleGuide = const CustomGuide(position: 100, isHorizontal: true, isVisible: true);
      final hiddenGuide = const CustomGuide(position: 200, isHorizontal: true, isVisible: false);

      guideManager.addGuide(visibleGuide);
      guideManager.addGuide(hiddenGuide);

      final visibleGuides = guideManager.visibleGuides;
      expect(visibleGuides.length, equals(1));
      expect(visibleGuides.contains(visibleGuide), isTrue);
      expect(visibleGuides.contains(hiddenGuide), isFalse);
    });

    test('shouldSnapToGuide returns true when near guide', () {
      guideManager.addGuide(horizontalGuide);

      expect(guideManager.shouldSnapToGuide(95, true), isTrue);
      expect(guideManager.shouldSnapToGuide(105, true), isTrue);
      expect(guideManager.shouldSnapToGuide(110, true), isFalse);
    });

    test('shouldSnapToGuide returns false when far from guide', () {
      guideManager.addGuide(horizontalGuide);

      expect(guideManager.shouldSnapToGuide(115, true), isFalse);
      expect(guideManager.shouldSnapToGuide(85, true), isFalse);
    });

    test('shouldSnapToGuide works with vertical guides', () {
      guideManager.addGuide(verticalGuide);

      expect(guideManager.shouldSnapToGuide(145, false), isTrue);
      expect(guideManager.shouldSnapToGuide(155, false), isTrue);
      expect(guideManager.shouldSnapToGuide(165, false), isFalse);
    });

    test('getSnappedPosition returns guide position when near', () {
      guideManager.addGuide(horizontalGuide);

      expect(guideManager.getSnappedPosition(95, true), equals(100));
      expect(guideManager.getSnappedPosition(105, true), equals(100));
    });

    test('getSnappedPosition returns original position when far', () {
      guideManager.addGuide(horizontalGuide);

      expect(guideManager.getSnappedPosition(115, true), equals(115));
      expect(guideManager.getSnappedPosition(85, true), equals(85));
    });

    test('getSnappedPosition works with multiple guides', () {
      final guide1 = const CustomGuide(position: 100, isHorizontal: true);
      final guide2 = const CustomGuide(position: 200, isHorizontal: true);

      guideManager.addGuide(guide1);
      guideManager.addGuide(guide2);

      expect(guideManager.getSnappedPosition(105, true), equals(100));
      expect(guideManager.getSnappedPosition(195, true), equals(200));
      expect(guideManager.getSnappedPosition(150, true), equals(150));
    });

    test('getSnappedPosition works with vertical guides', () {
      final guide1 = const CustomGuide(position: 100, isHorizontal: false);
      final guide2 = const CustomGuide(position: 200, isHorizontal: false);

      guideManager.addGuide(guide1);
      guideManager.addGuide(guide2);

      expect(guideManager.getSnappedPosition(105, false), equals(100));
      expect(guideManager.getSnappedPosition(195, false), equals(200));
      expect(guideManager.getSnappedPosition(150, false), equals(150));
    });

    test('clearGuides removes all guides', () {
      guideManager.addGuide(horizontalGuide);
      guideManager.addGuide(verticalGuide);

      expect(guideManager.visibleGuides.length, equals(2));

      guideManager.clearGuides();
      expect(guideManager.visibleGuides.length, equals(0));
    });

    test('guide properties are preserved', () {
      final guide = CustomGuide(
        position: 100,
        isHorizontal: true,
        isVisible: false,
      );

      guideManager.addGuide(guide);
      final retrievedGuides = guideManager.visibleGuides;

      expect(retrievedGuides.length, equals(1));
      final retrievedGuide = retrievedGuides.first;
      expect(retrievedGuide.position, equals(100));
      expect(retrievedGuide.isHorizontal, isTrue);
      expect(retrievedGuide.isVisible, isFalse);
    });

    test('copyWith creates new guide with modified properties', () {
      final guide = CustomGuide(
        position: 100,
        isHorizontal: true,
        isVisible: true,
      );

      final modifiedGuide = guide.copyWith(
        position: 200,
        isHorizontal: false,
        isVisible: false,
      );

      expect(modifiedGuide.position, equals(200));
      expect(modifiedGuide.isHorizontal, isFalse);
      expect(modifiedGuide.isVisible, isFalse);

      // Original guide should remain unchanged
      expect(guide.position, equals(100));
      expect(guide.isHorizontal, isTrue);
      expect(guide.isVisible, isTrue);
    });

    test('shouldSnapToGuide works with multiple guides of same type', () {
      final guide1 = const CustomGuide(position: 100, isHorizontal: true);
      final guide2 = const CustomGuide(position: 200, isHorizontal: true);

      guideManager.addGuide(guide1);
      guideManager.addGuide(guide2);

      expect(guideManager.shouldSnapToGuide(95, true), isTrue);
      expect(guideManager.shouldSnapToGuide(105, true), isTrue);
      expect(guideManager.shouldSnapToGuide(195, true), isTrue);
      expect(guideManager.shouldSnapToGuide(205, true), isTrue);
      expect(guideManager.shouldSnapToGuide(150, true), isFalse);
    });

    test('shouldSnapToGuide ignores guides of different type', () {
      guideManager.addGuide(horizontalGuide);
      guideManager.addGuide(verticalGuide);

      expect(guideManager.shouldSnapToGuide(95, true), isTrue);
      expect(guideManager.shouldSnapToGuide(95, false), isFalse);

      expect(guideManager.shouldSnapToGuide(145, false), isTrue);
      expect(guideManager.shouldSnapToGuide(145, true), isFalse);
    });

    test('getSnappedPosition returns nearest guide position', () {
      final guide1 = const CustomGuide(position: 100, isHorizontal: true);
      final guide2 = const CustomGuide(position: 200, isHorizontal: true);

      guideManager.addGuide(guide1);
      guideManager.addGuide(guide2);

      expect(guideManager.getSnappedPosition(95, true), equals(100));
      expect(guideManager.getSnappedPosition(105, true), equals(100));
      expect(guideManager.getSnappedPosition(195, true), equals(200));
      expect(guideManager.getSnappedPosition(205, true), equals(200));
      expect(guideManager.getSnappedPosition(150, true), equals(150));
    });
  });
}
