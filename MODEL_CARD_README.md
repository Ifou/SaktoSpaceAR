# Dynamic 3D Model Card System

This Flutter app automatically detects and displays all GLB (3D model) files in your assets folder using dynamic cards.

## Features

✅ **Automatic Detection**: Scans your assets folder for GLB files  
✅ **Dynamic Updates**: New models appear immediately after restart  
✅ **Beautiful UI**: Modern card-based interface with gradients  
✅ **Pull to Refresh**: Swipe down to refresh the model list  
✅ **Responsive Design**: Adapts to different screen sizes  
✅ **AR Integration Ready**: Built with ar_flutter_plugin_2 support

## How to Add New Models

1. **Add GLB files** to the `assets/models/` folder
2. **Run** `flutter pub get` (if needed)
3. **Restart** the app (hot restart)
4. **New models will appear automatically!**

## File Structure

```
assets/
└── models/
    ├── arm_chair.glb
    ├── blue_archive_miyako.glb
    ├── home_chair.glb
    ├── takodachi_rigged_hololive.glb
    └── [your-new-model].glb  ← Add here!
```

## Widget Usage

### Basic Usage

```dart
import 'package:flutter/material.dart';
import 'widgets/model_card.dart';

class YourScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ModelCard(), // That's it!
    );
  }
}
```

### With Custom Model Selection

```dart
ModelCard(
  onModelSelected: (String modelPath) {
    // Handle model selection
    print('Selected: $modelPath');
    Navigator.push(context,
      MaterialPageRoute(
        builder: (context) => ARViewScreen(modelPath: modelPath)
      )
    );
  },
)
```

## Implementation Details

### How It Works

1. **Asset Discovery**: Uses Flutter's `AssetManifest.json` to find GLB files
2. **Dynamic Loading**: Filters assets by `.glb` extension
3. **Auto-Refresh**: Supports pull-to-refresh for manual updates
4. **Smart Naming**: Converts file names to readable titles

### Model Name Conversion

- `blue_archive_miyako.glb` → "Blue Archive Miyako"
- `home_chair.glb` → "Home Chair"
- `takodachi_rigged_hololive.glb` → "Takodachi Rigged Hololive"

### Key Files

- `lib/widgets/model_card.dart` - Main widget implementation
- `lib/screens/model_selection_screen.dart` - Complete screen example
- `lib/examples/custom_model_browser.dart` - Custom usage example

## Customization

### Change Grid Layout

```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3, // Change number of columns
    childAspectRatio: 0.75, // Adjust card proportions
  ),
  // ...
)
```

### Custom Card Styling

Modify the card design in `model_card.dart`:

- Colors and gradients
- Card size and spacing
- Icon and text styles
- Animation effects

## AR Integration

The system is designed to work with `ar_flutter_plugin_2`. Replace the placeholder AR view with your actual AR implementation:

```dart
void _loadModelInAR(String modelPath) {
  // Your AR implementation here
  Navigator.push(context,
    MaterialPageRoute(
      builder: (context) => ARViewWithModel(
        modelAsset: modelPath,
      )
    )
  );
}
```

## Dependencies

- `flutter/material.dart` - UI framework
- `flutter/services.dart` - Asset loading
- `dart:convert` - JSON parsing
- `ar_flutter_plugin_2` - AR functionality (already included)

## Performance Notes

- Model detection runs once on widget initialization
- Asset manifest is cached by Flutter
- Large model collections load efficiently
- Pull-to-refresh allows manual updates

---

**Ready to use!** Just add your GLB files and they'll appear automatically! 🚀
