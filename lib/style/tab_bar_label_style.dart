import 'package:flutter/widgets.dart';

/// Visual styling for tab bar item labels in [CNTabBar].
///
/// Controls font size, weight, color, and spacing of the text labels
/// displayed beneath tab bar icons.
///
/// Example:
/// ```dart
/// CNTabBar(
///   items: [...],
///   labelStyle: CNTabBarLabelStyle(
///     fontSize: 11,
///     fontWeight: FontWeight.w500,
///     activeColor: CupertinoColors.activeBlue,
///     color: CupertinoColors.inactiveGray,
///   ),
/// )
/// ```
@immutable
class CNTabBarLabelStyle {
  /// Creates a tab bar label style configuration.
  const CNTabBarLabelStyle({
    this.fontSize,
    this.fontWeight,
    this.color,
    this.activeColor,
    this.fontFamily,
    this.letterSpacing,
  });

  /// Font size for the tab label text.
  ///
  /// On iOS, defaults to the system tab bar font size (~10pt).
  /// On macOS, defaults to the system segmented control font size.
  final double? fontSize;

  /// Font weight for the tab label text.
  ///
  /// Maps to system font weights on native platforms.
  /// Defaults to the platform's standard tab bar label weight.
  final FontWeight? fontWeight;

  /// Text color for unselected/inactive tab labels.
  ///
  /// If not provided, uses the platform default inactive color.
  final Color? color;

  /// Text color for the selected/active tab label.
  ///
  /// If not provided, uses the tab bar's tint color.
  final Color? activeColor;

  /// Custom font family name.
  ///
  /// On iOS/macOS, this must be a font family name registered with the system.
  /// If not provided, uses the platform's default system font.
  final String? fontFamily;

  /// Letter spacing (tracking) for the tab label text.
  ///
  /// Positive values spread characters apart, negative values bring them closer.
  final double? letterSpacing;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CNTabBarLabelStyle &&
        other.fontSize == fontSize &&
        other.fontWeight == fontWeight &&
        other.color == color &&
        other.activeColor == activeColor &&
        other.fontFamily == fontFamily &&
        other.letterSpacing == letterSpacing;
  }

  @override
  int get hashCode => Object.hash(
        fontSize,
        fontWeight,
        color,
        activeColor,
        fontFamily,
        letterSpacing,
      );
}
