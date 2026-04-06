import 'package:flutter/material.dart';

/// Represents a custom horizontal or vertical guide that can be dragged from canvas edges.
class CustomGuide {
  final double position;
  final bool isHorizontal;
  final bool isVisible;

  const CustomGuide({
    required this.position,
    required this.isHorizontal,
    this.isVisible = true,
  });

  CustomGuide copyWith({
    double? position,
    bool? isHorizontal,
    bool? isVisible,
  }) {
    return CustomGuide(
      position: position ?? this.position,
      isHorizontal: isHorizontal ?? this.isHorizontal,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}

/// Manages custom guides including creation, persistence, and snapping support.
class GuideManager {
  static const String _prefsKey = 'glyph_guides';
  final List<CustomGuide> _guides = [];

  GuideManager() {
    _loadGuides();
  }

  /// Load persisted guides from storage
  void _loadGuides() {
    // In a real implementation, this would load from SharedPreferences
    // For now, we'll use default guides
    _guides.addAll([
      const CustomGuide(position: 100, isHorizontal: true),
      const CustomGuide(position: 200, isHorizontal: true),
      const CustomGuide(position: 150, isHorizontal: false),
    ]);
  }

  /// Save guides to persistent storage
  void saveGuides() {
    // In a real implementation, this would save to SharedPreferences
  }

  /// Add a new guide
  void addGuide(CustomGuide guide) {
    _guides.add(guide);
    saveGuides();
  }

  /// Remove a guide
  void removeGuide(CustomGuide guide) {
    _guides.remove(guide);
    saveGuides();
  }

  /// Get all visible guides
  List<CustomGuide> get visibleGuides =>
      _guides.where((g) => g.isVisible).toList();

  /// Check if a position should snap to any guide
  bool shouldSnapToGuide(double position, bool isHorizontal) {
    final guides = visibleGuides.where((g) => g.isHorizontal == isHorizontal);
    return guides.any((guide) {
      final diff = (position - guide.position).abs();
      return diff < 10; // 10px snap threshold
    });
  }

  /// Get the snapped position for a given position
  double getSnappedPosition(double position, bool isHorizontal) {
    final guides = visibleGuides.where((g) => g.isHorizontal == isHorizontal);
    CustomGuide? nearestGuide;
    double minDiff = double.infinity;

    for (final guide in guides) {
      final diff = (position - guide.position).abs();
      if (diff < minDiff) {
        minDiff = diff;
        nearestGuide = guide;
      }
    }

    return nearestGuide?.position ?? position;
  }

  /// Clear all guides
  void clearGuides() {
    _guides.clear();
    saveGuides();
  }
}

/// Riverpod provider for guide manager
final guideManagerProvider = Provider<GuideManager>((ref) => GuideManager());
