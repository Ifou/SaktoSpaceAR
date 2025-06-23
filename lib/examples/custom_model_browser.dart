import 'package:flutter/material.dart';
import '../widgets/model_card.dart';

/// Example showing how to use ModelCard in a custom screen
class CustomModelBrowser extends StatelessWidget {
  const CustomModelBrowser({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Model Browser'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.teal.withOpacity(0.1),
            child: Column(
              children: [
                const Icon(
                  Icons.collections_outlined,
                  size: 48,
                  color: Colors.teal,
                ),
                const SizedBox(height: 8),
                Text(
                  'Browse 3D Models',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Select a model to view in AR',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          // Model cards section
          Expanded(
            child: ModelCard(
              onModelSelected: (String modelPath) {
                // Custom handling for model selection
                _showCustomDialog(context, modelPath);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomDialog(BuildContext context, String modelPath) {
    String modelName = modelPath.split('/').last.replaceAll('.glb', '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.model_training, color: Colors.teal),
            const SizedBox(width: 8),
            const Text('Model Selected'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    modelName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Path: $modelPath',
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Loading $modelName...'),
                  backgroundColor: Colors.teal,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Load in AR'),
          ),
        ],
      ),
    );
  }
}
