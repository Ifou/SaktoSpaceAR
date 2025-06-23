import 'package:flutter/material.dart';

/// A reusable settings panel widget for AR model configuration.
///
/// This widget provides a modal overlay with controls for adjusting
/// AR model properties like scale, and can be extended for additional
/// settings in the future.
class ARSettingsPanel extends StatelessWidget {
  /// Current scale value of the AR model (0.0 to 1.0)
  final double currentScale;

  /// Minimum allowed scale value
  final double minScale;

  /// Maximum allowed scale value
  final double maxScale;

  /// Callback function called when scale value changes
  final Function(double) onScaleChanged;

  /// Callback function called when panel should be closed
  final VoidCallback onClose;

  const ARSettingsPanel({
    super.key,
    required this.currentScale,
    required this.minScale,
    required this.maxScale,
    required this.onScaleChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: onClose,
        child: Container(
          color: Colors.black.withOpacity(0.3),
          child: Stack(
            children: [
              Positioned(
                bottom: 100,
                right: 20,
                child: GestureDetector(
                  onTap: () {}, // Prevent closing when tapping the panel
                  child: Container(
                    width: 300,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Icon(
                              Icons.tune,
                              color: Theme.of(context).primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Model Settings',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Scale slider
                        const Text(
                          'Scale',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              '${(minScale * 100).round()}%',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Expanded(
                              child: Slider(
                                value: currentScale,
                                min: minScale,
                                max: maxScale,
                                divisions:
                                    19, // 5% increments (95% range / 5% = 19)
                                activeColor: Theme.of(context).primaryColor,
                                onChanged: onScaleChanged,
                              ),
                            ),
                            Text(
                              '${(maxScale * 100).round()}%',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Current: ${(currentScale * 100).round()}%',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Future settings placeholder
                        const Divider(),
                        const SizedBox(height: 8),
                        const Text(
                          'More settings coming soon...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
