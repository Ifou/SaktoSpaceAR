import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'local_ar_viewer.dart';

class ModelInfoScreen extends StatefulWidget {
  final String modelPath;
  final String modelName;

  const ModelInfoScreen({
    super.key,
    required this.modelPath,
    required this.modelName,
  });

  @override
  State<ModelInfoScreen> createState() => _ModelInfoScreenState();
}

class _ModelInfoScreenState extends State<ModelInfoScreen> {
  bool _isModelLoading = true;

  @override
  void initState() {
    super.initState();
    // Quick loading for 3D model
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _isModelLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.modelName),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 3D Model Viewer
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Flutter3DViewer(src: widget.modelPath),
                    if (_isModelLoading)
                      Container(
                        color: Colors.white,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Loading 3D Model...'),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Model Info Section
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.modelName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getModelDescription(),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Model Details
                  Row(
                    children: [
                      _buildDetailChip('Format', _getFileFormat()),
                      const SizedBox(width: 12),
                      _buildDetailChip('AR Ready', 'Yes'),
                    ],
                  ),

                  const Spacer(),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Back'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _launchAR,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.view_in_ar),
                              SizedBox(width: 8),
                              Text('Launch AR'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          color: Colors.blue[800],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getFileFormat() {
    if (widget.modelPath.toLowerCase().endsWith('.glb')) {
      return 'GLB';
    } else if (widget.modelPath.toLowerCase().endsWith('.gltf')) {
      return 'GLTF';
    } else {
      return '3D Model';
    }
  }

  String _getModelDescription() {
    final name = widget.modelName.toLowerCase();
    if (name.contains('chair')) {
      return 'A comfortable and stylish chair perfect for your space.';
    } else if (name.contains('miyako')) {
      return 'An anime character model from Blue Archive.';
    } else if (name.contains('takodachi')) {
      return 'A cute Hololive mascot character.';
    } else {
      return 'A high-quality 3D model perfect for AR visualization.';
    }
  }

  void _launchAR() {
    HapticFeedback.mediumImpact();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LocalARViewer(
          modelPath: widget.modelPath,
          modelName: widget.modelName,
        ),
      ),
    );
  }
}
