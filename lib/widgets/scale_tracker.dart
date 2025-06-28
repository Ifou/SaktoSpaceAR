import 'package:flutter/material.dart';

/// A widget that displays width and height scale information for AR models.
///
/// This tracker shows the current dimensions based on the model's scale factor,
/// providing real-time feedback about the model's size in the AR environment.
class ScaleTracker extends StatelessWidget {
  /// Current scale factor of the AR model (0.0 to 1.0)
  final double currentScale;

  /// Base width of the model in meters (when scale = 1.0)
  final double baseWidthMeters;

  /// Base height of the model in meters (when scale = 1.0)
  final double baseHeightMeters;

  /// Whether to show metric units (meters/centimeters)
  final bool useMetricUnits;

  /// Position from the top of the screen
  final double? top;

  /// Position from the left of the screen
  final double? left;

  /// Position from the right of the screen
  final double? right;

  /// Position from the bottom of the screen
  final double? bottom;

  /// Whether the tracker is currently visible
  final bool isVisible;

  const ScaleTracker({
    super.key,
    required this.currentScale,
    this.baseWidthMeters = 1.0,
    this.baseHeightMeters = 1.0,
    this.useMetricUnits = true,
    this.top,
    this.left,
    this.right,
    this.bottom,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    // Pre-calculate dimensions to avoid repeated calculations
    final currentWidth = baseWidthMeters * currentScale;
    final currentHeight = baseHeightMeters * currentScale;
    
    // Cache theme data for performance
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: AnimatedOpacity(
        opacity: isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: RepaintBoundary(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.75),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: primaryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.straighten,
                      color: primaryColor,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Scale Tracker',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Scale percentage with optimized text
                _buildInfoRow(
                  icon: Icons.zoom_in,
                  text: 'Scale: ${(currentScale * 100).round()}%',
                ),
                const SizedBox(height: 4),

                // Width measurement
                _buildInfoRow(
                  icon: Icons.width_normal,
                  text: 'Width: ${_formatDimension(currentWidth)}',
                ),
                const SizedBox(height: 2),

                // Height measurement
                _buildInfoRow(
                  icon: Icons.height,
                  text: 'Height: ${_formatDimension(currentHeight)}',
                ),

                // Scale factor indicator with optimized rendering
                const SizedBox(height: 4),
                Container(
                  width: 120,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: Colors.white24,
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: currentScale,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: _getScaleColor(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Optimized info row builder to reduce widget creation
  Widget _buildInfoRow({required IconData icon, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Formats dimension value based on unit preference (optimized)
  String _formatDimension(double meters) {
    if (useMetricUnits) {
      if (meters >= 1.0) {
        return '${meters.toStringAsFixed(2)}m';
      } else {
        final centimeters = meters * 100;
        return '${centimeters.toStringAsFixed(1)}cm';
      }
    } else {
      // Convert to feet and inches
      final feet = meters * 3.28084;
      if (feet >= 1.0) {
        final wholeFeet = feet.floor();
        final inches = (feet - wholeFeet) * 12;
        if (inches < 0.5) {
          return '${wholeFeet}ft';
        } else {
          return '${wholeFeet}ft ${inches.toStringAsFixed(1)}in';
        }
      } else {
        final inches = feet * 12;
        return '${inches.toStringAsFixed(1)}in';
      }
    }
  }

  /// Returns color based on current scale for visual feedback
  Color _getScaleColor() {
    if (currentScale < 0.2) {
      return Colors.red.withOpacity(0.8); // Very small
    } else if (currentScale < 0.5) {
      return Colors.orange.withOpacity(0.8); // Small
    } else if (currentScale < 0.8) {
      return Colors.green.withOpacity(0.8); // Good size
    } else {
      return Colors.blue.withOpacity(0.8); // Large
    }
  }
}

/// A more detailed scale tracker with additional information
class DetailedScaleTracker extends StatelessWidget {
  /// Current scale factor of the AR model (0.0 to 1.0)
  final double currentScale;

  /// Base dimensions of the model when scale = 1.0
  final double baseWidthMeters;
  final double baseHeightMeters;
  final double baseDepthMeters;

  /// Model name for display
  final String modelName;

  /// Whether to show metric units
  final bool useMetricUnits;

  /// Callback when unit system is toggled
  final VoidCallback? onToggleUnits;

  /// Whether the tracker is currently visible
  final bool isVisible;

  const DetailedScaleTracker({
    super.key,
    required this.currentScale,
    required this.modelName,
    this.baseWidthMeters = 1.0,
    this.baseHeightMeters = 1.0,
    this.baseDepthMeters = 1.0,
    this.useMetricUnits = true,
    this.onToggleUnits,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    // Calculate current dimensions
    final currentWidth = baseWidthMeters * currentScale;
    final currentHeight = baseHeightMeters * currentScale;
    final currentDepth = baseDepthMeters * currentScale;

    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
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
                Icons.aspect_ratio,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dimensions - $modelName',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onToggleUnits != null)
                InkWell(
                  onTap: onToggleUnits,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      useMetricUnits ? 'M' : 'FT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Scale info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Text(
                  'Scale:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '${(currentScale * 100).round()}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Dimensions
          _buildDimensionRow('Width', currentWidth, Icons.width_normal),
          const SizedBox(height: 8),
          _buildDimensionRow('Height', currentHeight, Icons.height),
          const SizedBox(height: 8),
          _buildDimensionRow('Depth', currentDepth, Icons.straighten),
        ],
      ),
    );
  }

  Widget _buildDimensionRow(String label, double value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Text(
          _formatDimension(value),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  String _formatDimension(double meters) {
    if (useMetricUnits) {
      if (meters >= 1.0) {
        return '${meters.toStringAsFixed(2)}m';
      } else {
        final centimeters = meters * 100;
        return '${centimeters.toStringAsFixed(1)}cm';
      }
    } else {
      final feet = meters * 3.28084;
      if (feet >= 1.0) {
        final wholeFeet = feet.floor();
        final inches = (feet - wholeFeet) * 12;
        if (inches < 0.5) {
          return '${wholeFeet}ft';
        } else {
          return '${wholeFeet}ft ${inches.toStringAsFixed(1)}in';
        }
      } else {
        final inches = feet * 12;
        return '${inches.toStringAsFixed(1)}in';
      }
    }
  }
}
