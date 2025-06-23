import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_2/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:ar_flutter_plugin_2/models/ar_hittest_result.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

class LocalARViewer extends StatefulWidget {
  final String modelPath;
  final String modelName;

  const LocalARViewer({
    super.key,
    required this.modelPath,
    required this.modelName,
  });

  @override
  State<LocalARViewer> createState() => _LocalARViewerState();
}

class _LocalARViewerState extends State<LocalARViewer>
    with WidgetsBindingObserver {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;
  List<ARNode> nodes = [];
  List<ARAnchor> anchors = [];
  bool isARInitialized = false;
  bool _isPlacingModel = false; // Add flag to prevent rapid taps
  bool _isLoading = true; // Add loading state
  bool _isModelLoading = false; // Track model loading state

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Observe app lifecycle
  }

  @override
  void dispose() {
    super.dispose();
    arSessionManager?.dispose();
    WidgetsBinding.instance.removeObserver(this); // Remove observer
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Simple lifecycle management for memory optimization
    switch (state) {
      case AppLifecycleState.paused:
        // App goes to background - AR processing will be paused automatically
        break;
      case AppLifecycleState.resumed:
        // App comes back to foreground - AR will resume automatically
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AR View - ${widget.modelName}'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _resetView,
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset View',
          ),
        ],
      ),
      body: Stack(
        children: [
          // AR View
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig
                .horizontal, // Use only horizontal for better performance
          ), // Loading indicator while AR initializes
          if (_isLoading)
            const Positioned.fill(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Initializing AR...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // Model placement loading indicator
          if (_isModelLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Placing model...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Instructions overlay - optimized with AnimatedOpacity
          if (!isARInitialized || nodes.isEmpty)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: AnimatedOpacity(
                opacity: (!isARInitialized || nodes.isEmpty) ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.touch_app,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        nodes.isEmpty
                            ? 'Tap on a plane to place ${widget.modelName}'
                            : 'Tap on a plane to move ${widget.modelName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nodes.isEmpty
                            ? 'Point camera at a flat surface and tap'
                            : 'Tap another location to reposition',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Model info and controls
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Model info card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.view_in_ar,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.modelName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              nodes.isEmpty
                                  ? 'No object placed'
                                  : 'Object placed',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Control button
                if (nodes.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: _removeAllObjects,
                    icon: const Icon(Icons.delete, size: 20),
                    label: const Text(
                      'Remove Object',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager,
  ) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;

    // Initialize AR session with optimized settings for reduced lag
    this.arSessionManager!.onInitialize(
      showFeaturePoints: false, // Disabled for better performance
      showPlanes: true, // Essential for model placement
      showWorldOrigin: false, // Disabled for better performance
      handleTaps: true,
    );

    // Initialize object manager asynchronously to reduce blocking
    Future.microtask(() async {
      if (mounted && this.arObjectManager != null) {
        await this.arObjectManager!.onInitialize();

        // Set up tap handlers after initialization
        this.arSessionManager!.onPlaneOrPointTap = onPlaneOrPointTapped;
        this.arObjectManager!.onNodeTap = onNodeTapped;

        if (mounted) {
          setState(() {
            isARInitialized = true;
            _isLoading = false;
          });
        }
      }
    });
  }

  Future<void> _removeAllObjects() async {
    // Use optimized quiet removal and then show feedback
    await _removeAllObjectsQuietly();

    if (mounted) {
      setState(() {}); // Single setState call
    }

    _showSnackBar('Object removed', Colors.red);
  }

  Future<void> onNodeTapped(List<String> nodeIds) async {
    // Optional: Handle individual node taps
    _showSnackBar('Tapped ${nodeIds.length} object(s)', Colors.blue);
  }

  Future<void> onPlaneOrPointTapped(
    List<ARHitTestResult> hitTestResults,
  ) async {
    // Prevent rapid tapping and multiple model placements
    if (_isPlacingModel || _isModelLoading) return;

    _isPlacingModel = true;

    // Show loading state immediately for better UX
    if (mounted) {
      setState(() {
        _isModelLoading = true;
      });
    }

    // Find the first plane hit result
    ARHitTestResult? planeHit;
    try {
      planeHit = hitTestResults.firstWhere(
        (hitTestResult) => hitTestResult.type == ARHitTestResultType.plane,
      );
    } catch (e) {
      // No plane hit found
      _resetPlacementFlags();
      _showSnackBar('Please tap on a detected plane', Colors.orange);
      return;
    }

    try {
      // Remove existing model efficiently if one is already placed
      if (anchors.isNotEmpty) {
        await _removeAllObjectsQuietly(); // Use quiet removal to avoid extra UI updates
      }

      // Create anchor in background to reduce main thread blocking
      await _createModelWithAnchor(planeHit);
    } catch (e) {
      print('Error placing model: $e');
      _showSnackBar('Error: ${e.toString()}', Colors.red);
    } finally {
      _resetPlacementFlags();
    }
  }

  // Optimized method to create model with anchor
  Future<void> _createModelWithAnchor(ARHitTestResult planeHit) async {
    try {
      // Create an anchor at the tapped location
      var newAnchor = ARPlaneAnchor(transformation: planeHit.worldTransform);

      bool? didAddAnchor = await arAnchorManager!.addAnchor(newAnchor);

      if (didAddAnchor == true) {
        anchors.add(newAnchor);

        // Create node with optimized settings for better performance
        var newNode = ARNode(
          type: NodeType.localGLTF2,
          uri: widget.modelPath,
          scale: Vector3(
            0.15,
            0.15,
            0.15,
          ), // Slightly smaller for better performance
          position: Vector3(0.0, 0.0, 0.0),
          rotation: Vector4(1.0, 0.0, 0.0, 0.0),
        );

        // Add the node to the anchor with timeout to prevent hanging
        bool? didAddNodeToAnchor = await _addNodeWithTimeout(
          newNode,
          newAnchor,
        );

        if (didAddNodeToAnchor == true) {
          nodes.add(newNode);

          // Defer UI update to prevent blocking
          if (mounted) {
            Future.microtask(() {
              if (mounted) {
                setState(() {});
              }
            });
          }

          _showSnackBar('${widget.modelName} placed!', Colors.green);
        } else {
          // Clean up failed anchor
          await arAnchorManager!.removeAnchor(newAnchor);
          anchors.remove(newAnchor);
          _showSnackBar('Failed to place model', Colors.red);
        }
      } else {
        _showSnackBar('Failed to create anchor', Colors.red);
      }
    } catch (e) {
      print('Error in _createModelWithAnchor: $e');
      _showSnackBar('Placement failed', Colors.red);
      rethrow;
    }
  }

  // Add node with timeout to prevent hanging
  Future<bool?> _addNodeWithTimeout(ARNode node, ARAnchor anchor) async {
    try {
      return await Future.any([
        arObjectManager!.addNode(node, planeAnchor: anchor as ARPlaneAnchor),
        Future.delayed(
          const Duration(seconds: 5),
          () => false,
        ), // 5 second timeout
      ]);
    } catch (e) {
      print('Error adding node: $e');
      return false;
    }
  }

  // Reset placement flags efficiently
  void _resetPlacementFlags() {
    _isPlacingModel = false;
    if (mounted) {
      setState(() {
        _isModelLoading = false;
      });
    }
  }

  // Quiet removal without UI feedback for better performance
  Future<void> _removeAllObjectsQuietly() async {
    try {
      // Remove anchors in parallel for better performance
      if (anchors.isNotEmpty) {
        await Future.wait(
          anchors.map((anchor) => arAnchorManager!.removeAnchor(anchor)),
        );
        anchors.clear();
        nodes.clear();
      }
    } catch (e) {
      print('Error removing objects: $e');
    }
  }

  void _resetView() {
    // Prevent multiple rapid resets
    if (_isPlacingModel || _isModelLoading) return;

    // Remove all objects by calling optimized _removeAllObjects
    _removeAllObjects();
    _showSnackBar('View reset', Colors.grey);
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return; // Don't show snackbar if widget is disposed

    // Use postFrameCallback to defer snackbar creation to prevent blocking
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).clearSnackBars(); // Clear existing to prevent queue buildup
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 14,
            ), // Smaller text for better performance
          ),
          backgroundColor: color,
          duration: const Duration(milliseconds: 1200), // Reduced duration
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(8), // Smaller margin
          elevation: 2, // Reduced elevation for better performance
        ),
      );
    });
  }
}
