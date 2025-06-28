# Scale Tracker Widget

This document describes the new Scale Tracker feature added to the AR Viewer.

## Overview

The Scale Tracker provides real-time dimension information for AR models, showing width and height (and depth in detailed view) based on the current scale factor.

## Features

### Simple Scale Tracker

- Displays current scale percentage
- Shows width and height in real-time
- Color-coded scale indicator bar
- Supports both metric (meters/centimeters) and imperial (feet/inches) units
- Compact overlay design

### Detailed Scale Tracker

- Includes all simple tracker features
- Adds depth dimension
- Shows model name
- Built-in unit toggle button
- More comprehensive information panel

## Usage

### In Local AR Viewer

1. **Place a model** in AR space
2. **Scale Tracker Toggle** - Use the straighten icon (📏) floating button to show/hide the scale tracker
3. **View Mode Toggle** - Use the view toggle button to switch between simple and detailed tracker
4. **Units Toggle** - Use the "M"/"FT" button to switch between metric and imperial units (simple view only)

### Controls

- **📏 Button**: Toggle scale tracker visibility
- **⚫ Button**: Toggle between simple and detailed view
- **M/FT Button**: Toggle measurement units (simple view)
- **⚙️ Button**: Open model settings panel for scale adjustment

## Model Dimensions

The tracker automatically configures appropriate base dimensions based on the model:

- **Chairs**: 60cm × 90cm × 60cm (W×H×D)
- **Characters** (Takodachi, Miyako): 30cm × 160cm × 20cm
- **Default objects**: 100cm × 100cm × 100cm

## Implementation Details

### Files

- `lib/widgets/scale_tracker.dart` - Main scale tracker widgets
- `lib/screens/local_ar_viewer.dart` - Integration and UI controls

### Key Components

- `ScaleTracker` - Simple overlay tracker
- `DetailedScaleTracker` - Comprehensive information panel
- Auto-configuration based on model names
- Real-time scale updates
- Dynamic unit conversion

## Customization

### Base Dimensions

Modify the `_configureModelDimensions()` method in `local_ar_viewer.dart` to add custom dimensions for specific models.

### Positioning

Adjust tracker position using the `top`, `left`, `right`, `bottom` parameters in the `ScaleTracker` widget.

### Styling

Customize colors, fonts, and layout in the respective tracker widget files.

## Future Enhancements

- Model metadata loading for accurate dimensions
- Volume calculations
- Export dimension data
- Custom dimension input
- AR measurement tools
