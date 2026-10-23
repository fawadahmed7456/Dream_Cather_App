import 'package:flutter/material.dart';

import '../extensions/extensions.dart';

/// This file is used to create a responsive design for the app.
///
/// It uses the figma design width and height to calculate the size of the widgets.
/// [figmaDesignWidth] is used to set the width of the design.
const double figmaDesignWidth = 390.0;

///[figmaDesignWidth] is used to set the width of the design
const double figmaDesignHeight = 844.0;

///[figmaDesignStatusBar] is used to set the status bar height to 0.0
const double figmaDesignStatusBar = 0.0;

///[ResponsiveBuild] is a function that takes a [BuildContext] and an [Orientation]
typedef ResponsiveBuild = Widget Function(
    BuildContext context, Orientation orientation);

///[SizerUtils] is a widget that takes a [ResponsiveBuild] and returns a widget
class SizerUtils extends StatelessWidget {
  ///[SizerUtils] Constructor
  const SizerUtils({super.key, required this.builder});

  ///[ResponsiveBuild] is a function that takes a [BuildContext] and an [Orientation]
  final ResponsiveBuild builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return OrientationBuilder(
          builder: (BuildContext context, Orientation orientation) {
            SizeUtils.setScreenSize(constraints, orientation);
            return builder(context, orientation);
          },
        );
      },
    );
  }
}

///[SizeUtils] is a class that contains the screen size and orientation
class SizeUtils {
  ///[boxConstraints] is used to get the screen size
  static BoxConstraints boxConstraints = const BoxConstraints(
    maxWidth: figmaDesignWidth,
    maxHeight: figmaDesignHeight,
  );

  ///[orientation] is used to get the screen orientation
  static Orientation orientation = Orientation.portrait;

  /// Screen height. Defaults to the Figma design height so the `.h` / `.fSize`
  /// extensions resolve to a safe 1:1 base scale even when evaluated before
  /// [SizerUtils] is mounted (e.g. while building the [ThemeData] text theme,
  /// which happens outside the responsive subtree). Once [SizerUtils] mounts,
  /// [setScreenSize] overwrites this with the real device height.
  static double height = figmaDesignHeight;

  /// Screen width. Defaults to the Figma design width (see [height]).
  static double width = figmaDesignWidth;

  ///[setScreenSize] is used to set the screen size

  static void setScreenSize(
    BoxConstraints constraints,
    Orientation currentOrientation,
  ) {
    boxConstraints = constraints;
    orientation = currentOrientation;

    // Adjust for desktop or larger screens
    final double maxHeight = boxConstraints.maxHeight > figmaDesignHeight
        ? boxConstraints.maxHeight
        : figmaDesignHeight;
    final double maxWidth = boxConstraints.maxWidth > figmaDesignWidth
        ? boxConstraints.maxWidth
        : figmaDesignWidth;

    if (orientation == Orientation.portrait) {
      width = maxWidth.isNonZero(defaultValue: figmaDesignWidth);
      height = maxHeight.isNonZero(defaultValue: figmaDesignHeight);
    } else {
      width = maxWidth.isNonZero(defaultValue: figmaDesignWidth);
      height = maxHeight.isNonZero(defaultValue: figmaDesignHeight);
    }
  }
}

///[ResponsiveExtension] is an extension on [num] that provides
extension ResponsiveExtension on num {
  double get _width => SizeUtils.width;
  double get _height => SizeUtils.height;

  ///[w] is used to get the screen width
  double get w => ((toDouble() * _width) / figmaDesignWidth);

  ///[h] is used to get the screen height
  double get h =>
      (toDouble() * _height) / (figmaDesignHeight - figmaDesignStatusBar);

  ///[adaptSize] is used to get the screen size
  double get adaptSize {
    final double height = h;
    final double width = w;
    return height < width ? height.toDoubleValue() : width.toDoubleValue();
  }

  ///[r] is used to get the screen radius
  double get r => adaptSize / 2;

  ///[fSize] is used to get the screen size
  double get fSize {
    final double size = adaptSize;
    return size.clamp(8.0, 100.0);
  }
}

///[FormatExtension] is an extension on [double] that provides
extension FormatExtension on double {
  ///[toDoubleValue] is used to convert the double to a string
  double toDoubleValue({int fractionDigits = 2}) {
    return double.parse(toStringAsFixed(fractionDigits));
  }

  ///[isNonZero] is used to check if the double is non zero
  double isNonZero({double defaultValue = 0.0}) {
    return this > 0 ? this : defaultValue;
  }
}

///[calculateCrossAxisCount] is a function that takes a [BuildContext] and returns an [int]

int calculateCrossAxisCount(
  BuildContext context, {
  double minTileWidth = 500, // default for most cases
}) {
  final double screenWidth = context.width;

  final int count = (screenWidth / minTileWidth).floor();
  return count > 0 ? count : 1;
}

///[calculateCrossAxisCountStates] is a function that takes a [BuildContext] and returns an [int]
int calculateCrossAxisCountStates(BuildContext context) {
  final double screenWidth = context.width;

  const double minTileWidth = 300;

  int count = (screenWidth / minTileWidth).floor();
  if (count < 2) return 2;
  if (count < 5) return 2;
  return 6;
}
