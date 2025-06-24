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
import 'package:permission_handler/permission_handler.dart';
import '../widgets/ar_settings_panel.dart';

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
  bool _isModelPlaced = false; // Track if model is permanently placed
  bool _hasPermissions = false; // Track camera permission status
  bool _showPermissionError = false; // Show permission error state

  double _currentScale = 0.15; // Track current model scale
  final double _minScale = 0.05; // Minimum scale (5%)
  final double _maxScale = 1.0; // Maximum scale (100%)
  bool _showSettings = false; // Track settings panel visibility
  bool _isScaling = false; // Prevent concurrent scaling operations
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Observe app lifecycle
    _checkPermissions(); // Check camera permissions before AR initialization
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
          // Only show reset button if model hasn't been placed yet
          if (!_isModelPlaced)
            IconButton(
              onPressed: _resetView,
              icon: const Icon(Icons.refresh),
              tooltip: 'Reset View',
            ),
        ],
      ),
      body: Stack(
        children: [
          // AR View - only show when permissions are granted
          if (_hasPermissions)
            ARView(
              onARViewCreated: onARViewCreated,
              planeDetectionConfig: PlaneDetectionConfig
                  .horizontal, // Use only horizontal for better performance
            ),

          // Permission error screen
          if (_showPermissionError)
            Positioned.fill(
              child: Container(
                color: Colors.black87,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.white,
                          size: 64,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Camera Permission Required',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'This app needs camera access to provide AR functionality. Please grant camera permission to continue.',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: _checkPermissions,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Try Again'),
                            ),
                            ElevatedButton(
                              onPressed: _openAppSettings,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Open Settings'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ), // Loading indicator while AR initializes
          if (_isLoading && _hasPermissions && !_showPermissionError)
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
            ), // Instructions overlay - only show when model hasn't been placed yet
          if (!isARInitialized || (nodes.isEmpty && !_isModelPlaced))
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: AnimatedOpacity(
                opacity:
                    (!isARInitialized || (nodes.isEmpty && !_isModelPlaced))
                    ? 1.0
                    : 0.0,
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
            ), // Model info and controls - hide controls after model is placed
          if (!_isModelPlaced)
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
                                    ? 'Ready to place'
                                    : 'Object placed successfully!',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: nodes.isEmpty
                                      ? Colors.grey[600]
                                      : Colors.green[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Success message after model is placed
          if (_isModelPlaced)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.9),
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
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${widget.modelName} Placed!',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'Model successfully placed in AR space',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ), // Settings Panel
          if (_showSettings && _isModelPlaced)
            ARSettingsPanel(
              currentScale: _currentScale,
              minScale: _minScale,
              maxScale: _maxScale,
              onScaleChanged: (value) {
                setState(() {
                  _currentScale = value;
                });
                _updateModelScale();
              },
              onClose: () {
                setState(() {
                  _showSettings = false;
                });
              },
            ),
        ],
      ),
      floatingActionButton: _isModelPlaced
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _showSettings = !_showSettings;
                });
              },
              backgroundColor: Theme.of(context).primaryColor,
              child: Icon(
                _showSettings ? Icons.close : Icons.settings,
                color: Colors.white,
              ),
              tooltip: _showSettings ? 'Close Settings' : 'Model Settings',
            )
          : null,
    );
  }

  void onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager,
  ) {
    // Only proceed if we have camera permissions
    if (!_hasPermissions) {
      print('AR View created but no camera permissions');
      return;
    }

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
      if (mounted && this.arObjectManager != null && _hasPermissions) {
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
    // Don't allow removal if model is permanently placed
    if (_isModelPlaced) return;

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
    // Don't allow placement if model is already permanently placed
    if (_isModelPlaced) return;

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
      // Since we want permanent placement, don't remove existing models
      // Just place the new one (though this shouldn't happen with _isModelPlaced check)

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
        anchors.add(
          newAnchor,
        ); // Create node with optimized settings for better performance
        var newNode = ARNode(
          type: NodeType.localGLTF2,
          uri: widget.modelPath,
          scale: Vector3(
            _currentScale,
            _currentScale,
            _currentScale,
          ), // Use current scale variable
          position: Vector3(0.0, 0.0, 0.0),
        );

        // Add the node to the anchor with timeout to prevent hanging
        bool? didAddNodeToAnchor = await _addNodeWithTimeout(
          newNode,
          newAnchor,
        );
        if (didAddNodeToAnchor == true) {
          nodes.add(newNode);

          // Disable plane detection and finalize placement
          await _finalizeModelPlacement();

          // Defer UI update to prevent blocking
          if (mounted) {
            Future.microtask(() {
              if (mounted) {
                setState(() {
                  _isModelPlaced = true;
                });
              }
            });
          }

          _showSnackBar(
            '${widget.modelName} placed successfully!',
            Colors.green,
          );
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

  // Finalize model placement by disabling plane detection and interactions
  Future<void> _finalizeModelPlacement() async {
    try {
      // Disable plane detection
      if (arSessionManager != null) {
        await arSessionManager!.onInitialize(
          showFeaturePoints: false,
          showPlanes: false, // Disable plane detection
          showWorldOrigin: false,
          handleTaps: false, // Disable tap handling
        );

        // Replace tap handlers with no-op functions to prevent further interactions
        arSessionManager!.onPlaneOrPointTap =
            (List<ARHitTestResult> hits) async {
              // No-op: do nothing when tapped
            };
        if (arObjectManager != null) {
          arObjectManager!.onNodeTap = (List<String> nodeIds) async {
            // No-op: do nothing when node is tapped
          };
        }
      }
    } catch (e) {
      print('Error finalizing placement: $e');
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
    // Prevent reset if model is permanently placed
    if (_isModelPlaced) return;

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
  } // Model scaling method

  void _updateModelScale() async {
    if (nodes.isEmpty ||
        arObjectManager == null ||
        anchors.isEmpty ||
        _isScaling)
      return;

    _isScaling = true; // Prevent concurrent scaling operations

    try {
      // Since updateNode might not be available, we'll recreate the node with new scale
      final oldNode = nodes.first;
      final anchor = anchors.first;

      // Remove the old node and wait for completion
      await arObjectManager!.removeNode(oldNode);

      // Small delay to ensure removal is processed
      await Future.delayed(
        const Duration(milliseconds: 100),
      ); // Create a new node with updated scale
      final newNode = ARNode(
        type: NodeType.localGLTF2,
        uri: widget.modelPath,
        scale: Vector3(_currentScale, _currentScale, _currentScale),
        position: Vector3(0.0, 0.0, 0.0),
      ); // Add the new node to the existing anchor
      bool? success = await arObjectManager!.addNode(
        newNode,
        planeAnchor: anchor as ARPlaneAnchor,
      );

      if (success == true) {
        // Update the nodes list only after successful addition
        nodes[0] = newNode;
      } else {
        // If failed to add new node, add the old one back
        await arObjectManager!.addNode(oldNode, planeAnchor: anchor);
        _showSnackBar('Failed to scale model', Colors.red);
      }
    } catch (e) {
      print('Error updating model scale: $e');
      _showSnackBar('Failed to scale model', Colors.red);
    } finally {
      _isScaling = false; // Reset the flag
    }
  }

  // Check camera permissions before initializing AR
  Future<void> _checkPermissions() async {
    try {
      final status = await Permission.camera.status;

      if (status.isGranted) {
        setState(() {
          _hasPermissions = true;
          _showPermissionError = false;
        });
      } else if (status.isDenied) {
        // Request permission
        final result = await Permission.camera.request();
        setState(() {
          _hasPermissions = result.isGranted;
          _showPermissionError = !result.isGranted;
        });
      } else {
        // Permission permanently denied
        setState(() {
          _hasPermissions = false;
          _showPermissionError = true;
        });
      }
    } catch (e) {
      print('Error checking permissions: $e');
      setState(() {
        _hasPermissions = false;
        _showPermissionError = true;
      });
    }
  }

  // Open app settings for permission management
  Future<void> _openAppSettings() async {
    await openAppSettings();
  }
}
