import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A 360×640 preview of the final export rendered in the ExportSheet.
/// Shows exactly what the user will get when they share to Instagram Stories.
class ExportPreview extends StatelessWidget {
  final GlobalKey repaintKey;

  const ExportPreview({super.key, required this.repaintKey});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      height: 640,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          // Background gradient for Stories
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1A1A1A),
                    Color(0xFF242424),
                  ],
                ),
              ),
            ),
          ),
          // Preview content
          Center(
            child: RepaintBoundary(
              key: repaintKey,
              child: const Text(
                'Your Story',
                style: TextStyle(
                  fontSize: 48,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Story frame indicator
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Story border
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
