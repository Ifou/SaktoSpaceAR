import 'package:flutter/material.dart';
import '../widgets/model_card.dart';
import 'model_info_screen.dart';

class ModelSelectionScreen extends StatelessWidget {
  const ModelSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR Model Gallery'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: ModelCard(
        onModelSelected: (String modelPath) {
          // Handle model selection - you can navigate to AR view here
          _navigateToARView(context, modelPath);
        },
      ),
    );
  }

  void _navigateToARView(BuildContext context, String modelPath) {
    // Extract model name from path
    String modelName = modelPath
        .split('/')
        .last
        .replaceAll('.glb', '')
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : '',
        )
        .join(' '); // Navigate to model info screen with the selected model
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ModelInfoScreen(modelPath: modelPath, modelName: modelName),
      ),
    );
  }
}
