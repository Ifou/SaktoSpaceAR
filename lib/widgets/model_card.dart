import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ModelCard extends StatefulWidget {
  final Function(String)? onModelSelected;

  const ModelCard({Key? key, this.onModelSelected}) : super(key: key);

  @override
  State<ModelCard> createState() => _ModelCardState();
}

class _ModelCardState extends State<ModelCard> {
  List<String> modelFiles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadModelFiles();
  }

  Future<void> _loadModelFiles() async {
    try {
      // Get all assets from the asset manifest
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = Map<String, dynamic>.from(
        json.decode(manifestContent),
      );

      // Filter for GLB files
      final glbFiles = manifestMap.keys
          .where((String key) => key.toLowerCase().endsWith('.glb'))
          .toList();

      setState(() {
        modelFiles = glbFiles;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading model files: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String _getModelName(String filePath) {
    String fileName = filePath.split('/').last.replaceAll('.glb', '');
    // Convert snake_case or camelCase to readable format
    return fileName
        .replaceAll('_', ' ')
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : '',
        )
        .join(' ');
  }

  String _getFileSize(String filePath) {
    // This is a placeholder - in a real app you might want to get actual file sizes
    return '~${(filePath.length * 0.1).toStringAsFixed(1)}MB';
  }

  Future<void> _refreshModels() async {
    setState(() {
      isLoading = true;
    });
    await _loadModelFiles();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(onRefresh: _refreshModels, child: _buildContent());
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading 3D models...'),
          ],
        ),
      );
    }

    if (modelFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.view_in_ar_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No 3D models found',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Add GLB files to your assets/models folder\nand restart the app',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshModels,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                Icons.view_in_ar,
                color: Theme.of(context).primaryColor,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                '3D Models (${modelFiles.length})',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _refreshModels,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh models',
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: modelFiles.length,
            itemBuilder: (context, index) {
              final modelPath = modelFiles[index];
              final modelName = _getModelName(modelPath);
              final fileSize = _getFileSize(modelPath);

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: () {
                    _onModelSelected(modelPath, modelName);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).primaryColor.withOpacity(0.1),
                                Theme.of(context).primaryColor.withOpacity(0.2),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(35),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.view_in_ar,
                            size: 35,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          modelName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '.glb',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          fileSize,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _onModelSelected(String modelPath, String modelName) {
    if (widget.onModelSelected != null) {
      widget.onModelSelected!(modelPath);
      return;
    }

    // Show a dialog if no callback is provided
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.view_in_ar, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              const Text('Load Model'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Do you want to load "$modelName" in AR view?'),
              const SizedBox(height: 8),
              Text(
                'Path: $modelPath',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _loadModelInAR(modelPath);
              },
              child: const Text('Load'),
            ),
          ],
        );
      },
    );
  }

  void _loadModelInAR(String modelPath) {
    // Implement navigation to AR view with the selected model
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loading model: ${_getModelName(modelPath)}'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
    print('Loading model: $modelPath');
  }
}
