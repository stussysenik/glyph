import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glyph/core/gestures/rotation_snap_engine.dart';

void main() {
  group('RotationSnapEngine Tests', () {
    test('normalizeAngle handles negative angles correctly', () {
      expect(RotationSnapEngine._normalizeAngle(-90), equals(270));
      expect(RotationSnapEngine._normalizeAngle(-180), equals(180));
      expect(RotationSnapEngine._normalizeAngle(-360), equals(0));
      expect(RotationSnapEngine._normalizeAngle(-450), equals(270));
    });

    test('normalizeAngle handles positive angles correctly', () {
      expect(RotationSnapEngine._normalizeAngle(0), equals(0));
      expect(RotationSnapEngine._normalizeAngle(90), equals(90));
      expect(RotationSnapEngine._normalizeAngle(180), equals(180));
      expect(RotationSnapEngine._normalizeAngle(270), equals(270));
      expect(RotationSnapEngine._normalizeAngle(360), equals(0));
      expect(RotationSnapEngine._normalizeAngle(450), equals(90));
    });

    test('findNearestCardinalAngle returns correct nearest angle', () {
      expect(RotationSnapEngine._findNearestCardinalAngle(0), equals(0));
      expect(RotationSnapEngine._findNearestCardinalAngle(45), equals(0));
      expect(RotationSnapEngine._findNearestCardinalAngle(89), equals(90));
      expect(RotationSnapEngine._findNearestCardinalAngle(90), equals(90));
      expect(RotationSnapEngine._findNearestCardinalAngle(135), equals(90));
      expect(RotationSnapEngine._findNearestCardinalAngle(180), equals(180));
      expect(RotationSnapEngine._findNearestCardinalAngle(270), equals(270));
      expect(RotationSnapEngine._findNearestCardinalAngle(315), equals(270));
      expect(RotationSnapEngine._findNearestCardinalAngle(360), equals(0));
    });

    test('shouldSnap returns true when within threshold', () {
      expect(RotationSnapEngine.shouldSnap(0, 3), isTrue);
      expect(RotationSnapEngine.shouldSnap(90, 87), isTrue);
      expect(RotationSnapEngine.shouldSnap(180, 185), isTrue);
      expect(RotationSnapEngine.shouldSnap(270, 265), isTrue);
      expect(RotationSnapEngine.shouldSnap(0, 5), isTrue);
    });

    test('shouldSnap returns false when outside threshold', () {
      expect(RotationSnapEngine.shouldSnap(0, 6), isFalse);
      expect(RotationSnapEngine.shouldSnap(90, 86), isFalse);
      expect(RotationSnapEngine.shouldSnap(180, 186), isFalse);
      expect(RotationSnapEngine.shouldSnap(270, 264), isFalse);
    });

    test('snapAngle returns correct snapped angle', () {
      expect(RotationSnapEngine.snapAngle(0), equals(0));
      expect(RotationSnapEngine.snapAngle(45), equals(0));
      expect(RotationSnapEngine.snapAngle(89), equals(90));
      expect(RotationSnapEngine.snapAngle(90), equals(90));
      expect(RotationSnapEngine.snapAngle(135), equals(90));
      expect(RotationSnapEngine.snapAngle(180), equals(180));
      expect(RotationSnapEngine.snapAngle(270), equals(270));
      expect(RotationSnapEngine.snapAngle(315), equals(270));
      expect(RotationSnapEngine.snapAngle(360), equals(0));
    });

    test('getDegreeBadge formats angle correctly', () {
      expect(RotationSnapEngine.getDegreeBadge(0), equals('0°'));
      expect(RotationSnapEngine.getDegreeBadge(45), equals('45°'));
      expect(RotationSnapEngine.getDegreeBadge(90), equals('90°'));
      expect(RotationSnapEngine.getDegreeBadge(180), equals('180°'));
      expect(RotationSnapEngine.getDegreeBadge(270), equals('270°'));
      expect(RotationSnapEngine.getDegreeBadge(360), equals('0°'));
    });

    test('isAtCardinalAngle detects cardinal angles correctly', () {
      expect(RotationSnapEngine.isAtCardinalAngle(0), isTrue);
      expect(RotationSnapEngine.isAtCardinalAngle(90), isTrue);
      expect(RotationSnapEngine.isAtCardinalAngle(180), isTrue);
      expect(RotationSnapEngine.isAtCardinalAngle(270), isTrue);
      expect(RotationSnapEngine.isAtCardinalAngle(45), isFalse);
      expect(RotationSnapEngine.isAtCardinalAngle(135), isFalse);
      expect(RotationSnapEngine.isAtCardinalAngle(225), isFalse);
      expect(RotationSnapEngine.isAtCardinalAngle(315), isFalse);
    });

    test('provideHapticFeedback is called', () {
      // Mock HapticFeedback to test if it's called
      final mockHaptic = MockHapticFeedback();
      HapticFeedback.mediumImpact = mockHaptic.mediumImpact;

      RotationSnapEngine.provideHapticFeedback();

      expect(mockHaptic.mediumImpactCalled, isTrue);
    });
  });
}

// Mock class for testing haptic feedback
class MockHapticFeedback {
  bool mediumImpactCalled = false;

  void mediumImpact() {
    mediumImpactCalled = true;
  }
}
