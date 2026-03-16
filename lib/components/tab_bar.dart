import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../channel/params.dart';
import '../style/sf_symbol.dart';
import '../style/tab_bar_label_style.dart';
import '../style/tab_bar_search_item.dart';
import '../utils/icon_renderer.dart';
import '../utils/theme_helper.dart';
import '../utils/version_detector.dart';
import 'icon.dart';

/// Immutable data describing a single tab bar item.
class CNTabBarItem {
  /// Creates a tab bar item description.
  const CNTabBarItem({
    this.label,
    this.icon,
    this.activeIcon,
    this.badge,
    this.badgeColor,
    this.badgeTextColor,
    this.badgeDotSize,
    this.badgeFontSize,
    this.customIcon,
    this.activeCustomIcon,
    this.imageAsset,
    this.activeImageAsset,
    this.padding,
  });

  /// Optional tab item label.
  final String? label;

  /// Optional SF Symbol for the item (unselected state).
  /// If both [icon] and [customIcon] are provided, [customIcon] takes precedence.
  final CNSymbol? icon;

  /// Optional SF Symbol for the item when selected.
  /// If not provided, [icon] is used for both states.
  final CNSymbol? activeIcon;

  /// Optional badge to display on the tab bar item.
  ///
  /// - `null` → no badge shown
  /// - `''` (empty string) → small dot indicator (no text)
  /// - Any other string → badge with that text (e.g. `'5'`, `'99+'`)
  ///
  /// On macOS, badges are not supported by NSSegmentedControl.
  final String? badge;

  /// Background color of the badge bubble.
  /// Defaults to the system red when null.
  final Color? badgeColor;

  /// Text color of the badge label.
  /// Defaults to white when null.
  final Color? badgeTextColor;

  /// Custom size (in logical points) for the dot badge when [badge] is `''`.
  ///
  /// On iOS this renders a dot-style badge with the requested size.
  /// If null, the system default dot size is used.
  final double? badgeDotSize;

  /// Custom font size (in logical points) for text badges.
  ///
  /// Applies when [badge] contains non-empty text (e.g. `'3'`, `'New'`).
  /// If null, the system default badge text size is used.
  final double? badgeFontSize;

  /// Optional custom icon for unselected state.
  /// Use icons from CupertinoIcons, Icons, or any custom IconData.
  /// The icon will be rendered to an image at 25pt (iOS standard tab bar icon size)
  /// and sent to the native platform. If provided, this takes precedence over [icon].
  ///
  /// Examples:
  /// ```dart
  /// customIcon: CupertinoIcons.house
  /// customIcon: Icons.home
  /// ```
  final IconData? customIcon;

  /// Optional custom icon for selected state.
  /// If not provided, [customIcon] is used for both states.
  final IconData? activeCustomIcon;

  /// Optional image asset for unselected state.
  /// If provided, this takes precedence over [icon] and [customIcon].
  /// Priority: [imageAsset] > [customIcon] > [icon]
  final CNImageAsset? imageAsset;

  /// Optional image asset for selected state.
  /// If not provided, [imageAsset] is used for both states.
  final CNImageAsset? activeImageAsset;

  /// Optional padding around this tab bar item.
  ///
  /// On iOS, this adjusts the item's image insets and title position.
  /// On macOS and the Flutter fallback, this is applied as widget padding.
  final EdgeInsets? padding;
}

/// A Cupertino-native tab bar. Uses native UITabBar/NSTabView style visuals.
///
/// On iOS 26+, supports a dedicated search tab that follows Apple's native
/// behavior: appearing as a floating circular button that expands into a
/// full search bar when tapped.
///
/// Example with search:
/// ```dart
/// CNTabBar(
///   items: [
///     CNTabBarItem(label: 'Home', icon: CNSymbol('house.fill')),
///     CNTabBarItem(label: 'Profile', icon: CNSymbol('person.fill')),
///   ],
///   currentIndex: _index,
///   onTap: (i) => setState(() => _index = i),
///   searchItem: CNTabBarSearchItem(
///     placeholder: 'Find customer',
///     onSearchChanged: (query) => filterResults(query),
///   ),
/// )
/// ```
class CNTabBar extends StatefulWidget {
  /// Creates a Cupertino-native tab bar.
  ///
  /// According to Apple's Human Interface Guidelines, tab bars should contain
  /// 3-5 tabs for optimal usability. More than 5 tabs can make the interface
  /// cluttered and reduce tappability.
  const CNTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.height,
    this.split = false,
    this.rightCount = 1,
    this.shrinkCentered = true,
    this.splitSpacing = 12.0,
    this.iconAboveLabel = true,
    this.searchItem,
    this.labelStyle,
    this.searchController,
    this.fallback,
  }) : assert(items.length >= 2, 'Tab bar must have at least 2 items'),
       assert(items.length <= 5, 'Tab bar should have 5 or fewer items for optimal usability'),
       assert(rightCount >= 1, 'Right count must be at least 1'),
       assert(rightCount < items.length || searchItem != null, 'Right count must be less than total items');

  /// Items to display in the tab bar.
  final List<CNTabBarItem> items;

  /// The index of the currently selected item.
  final int currentIndex;

  /// Called when the user selects a new item.
  final ValueChanged<int> onTap;

  /// Fixed height; if null uses intrinsic height reported by native view.
  final double? height;

  /// When true, splits items between left and right sections.
  ///
  /// This follows Apple's HIG guidelines for organizing related tab functions
  /// into logical groups with clear visual separation.
  ///
  /// Note: When [searchItem] is provided, split mode is automatically enabled
  /// with the search tab appearing as a floating button on the right.
  final bool split;

  /// How many trailing items to pin right when [split] is true.
  ///
  /// Must be less than the total number of items. Follows Apple's HIG
  /// recommendation for maintaining balanced visual hierarchy.
  ///
  /// Note: When [searchItem] is provided, this value is ignored as the
  /// search tab automatically becomes the right-side floating element.
  final int rightCount; // how many trailing items to pin right when split

  /// When true, centers the split groups more tightly.
  final bool shrinkCentered;

  /// Gap between left/right halves when split.
  ///
  /// Defaults to 12pt following Apple's HIG recommendations for visual separation.
  final double splitSpacing;

  /// Whether to force icon-above-label layout on iPad.
  ///
  /// On iPad, UITabBar defaults to inline (side-by-side) icon and label layout.
  /// When `true` (default), forces the stacked (icon above label) layout
  /// that matches the standard iPhone tab bar appearance.
  ///
  /// On iPhone this has no effect since stacked layout is already the default.
  final bool iconAboveLabel;

  /// Custom styling for tab bar item labels.
  ///
  /// Controls font size, weight, color, and spacing of the text labels
  /// displayed beneath tab bar icons.
  final CNTabBarLabelStyle? labelStyle;

  /// Optional search tab configuration.
  ///
  /// When provided, adds a dedicated search tab that follows iOS 26's native
  /// behavior:
  /// - Appears as a separate floating circular button on the right
  /// - Expands into a full search bar when tapped
  /// - Collapses other tabs during search
  ///
  /// On iOS < 26, the search behavior is simulated using Flutter widgets.
  final CNTabBarSearchItem? searchItem;

  /// Optional controller for programmatic search management.
  ///
  /// Use this to:
  /// - Activate/deactivate search programmatically
  /// - Set or clear the search text
  /// - Listen to search state changes
  final CNTabBarSearchController? searchController;

  /// Custom widget to show instead of the default Flutter fallback.
  ///
  /// Used when:
  /// - Platform is not iOS/macOS
  /// - iOS/macOS version does not support native tab bar (e.g. iOS < 26)
  /// - Custom icons are loading or native view is being built
  ///
  /// If null, the built-in Cupertino-style fallback is used.
  final Widget? fallback;

  @override
  State<CNTabBar> createState() => _CNTabBarState();
}

class _CNTabBarState extends State<CNTabBar> {
  MethodChannel? _channel;
  int? _lastIndex;
  bool? _lastIsDark;
  double? _intrinsicHeight;
  double? _intrinsicWidth;
  // Comprehensive fingerprint covering ALL item properties (colors, assets, icons, etc.)
  String? _lastItemsFingerprint;
  // Separate fingerprint for the fast badges-only lightweight path
  String? _lastBadgesFingerprint;
  bool? _lastSplit;
  int? _lastRightCount;
  double? _lastSplitSpacing;

  // Search state
  bool _isSearchActive = false;
  String _searchText = '';
  FocusNode? _searchFocusNode;

  bool get _isDark => ThemeHelper.isDark(context);
  Color? get _themeTint => ThemeHelper.getPrimaryColor(context);

  // Whether search mode is enabled
  bool get _hasSearch => widget.searchItem != null;

  Future<Map<String, dynamic>?>? _creationParamsFuture;
  bool _didLogFallbackBadgeWarning = false;

  @override
  void initState() {
    super.initState();
    widget.searchController?.addListener(_onSearchControllerChanged);
    if (_hasSearch) {
      _searchFocusNode = FocusNode();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_creationParamsFuture == null) {
      final isIOSOrMacOS = defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;
      if (isIOSOrMacOS && PlatformVersion.shouldUseNativeGlass) {
        _creationParamsFuture = _buildCreationParams();
      }
    }
    _syncBrightnessIfNeeded();
    _syncPropsToNativeIfNeeded();
  }

  @override
  void didUpdateWidget(covariant CNTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Handle controller changes
    if (oldWidget.searchController != widget.searchController) {
      oldWidget.searchController?.removeListener(_onSearchControllerChanged);
      widget.searchController?.addListener(_onSearchControllerChanged);
    }
    // Handle search item changes
    if (_hasSearch && _searchFocusNode == null) {
      _searchFocusNode = FocusNode();
    }
    _syncPropsToNativeIfNeeded();
  }

  @override
  void dispose() {
    widget.searchController?.removeListener(_onSearchControllerChanged);
    _searchFocusNode?.dispose();
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    // Hot reload keeps State but may skip didUpdateWidget/didChangeDependencies
    // paths that normally trigger native sync. Invalidate caches and force a
    // post-frame sync so updated Dart params (badge colors, label style, etc.)
    // are pushed to the native tab bar without requiring hot restart.
    _lastItemsFingerprint = null;
    _lastBadgesFingerprint = null;
    _lastSplit = null;
    _lastRightCount = null;
    _lastSplitSpacing = null;
    _lastIsDark = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncPropsToNativeIfNeeded();
      _syncBrightnessIfNeeded();
    });
  }

  void _onSearchControllerChanged() {
    final controller = widget.searchController;
    if (controller == null) return;

    // Sync controller state to native
    final ch = _channel;
    if (ch == null) return;

    try {
      if (controller.isActive != _isSearchActive) {
        if (controller.isActive) {
          ch.invokeMethod('activateSearch');
        } else {
          ch.invokeMethod('deactivateSearch');
        }
        _isSearchActive = controller.isActive;
      }

      if (controller.text != _searchText) {
        ch.invokeMethod('setSearchText', {'text': controller.text});
        _searchText = controller.text;
      }
    } catch (e) {
      // Ignore MissingPluginException during hot reload or view recreation
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if we should use native platform view
    final isIOSOrMacOS = defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;
    final shouldUseNative = isIOSOrMacOS && PlatformVersion.shouldUseNativeGlass;

    // Fallback to Flutter widgets for non-iOS/macOS or iOS/macOS < 26
    if (!shouldUseNative || _creationParamsFuture == null) {
      _logFallbackBadgeWarningIfNeeded(shouldUseNative: shouldUseNative);
      return _resolveFallback(context);
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: _creationParamsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return _resolveFallback(context);
        }
        return _buildNativeTabBarPlatformView(snapshot.data!);
      },
    );
  }

  void _logFallbackBadgeWarningIfNeeded({required bool shouldUseNative}) {
    if (!kDebugMode || _didLogFallbackBadgeWarning) return;
    if (widget.fallback == null) return;
    final hasBadgeStyling = widget.items.any((e) => e.badge != null || e.badgeColor != null || e.badgeTextColor != null);
    if (!hasBadgeStyling) return;
    _didLogFallbackBadgeWarning = true;
    debugPrint(
      '⚠️ [cupertino_native_better] CNTabBar is rendering custom fallback '
      '(shouldUseNativeGlass=$shouldUseNative, creationParamsReady=${_creationParamsFuture != null}). '
      'CNTabBarItem badgeColor/badgeTextColor are native-only and will not '
      'affect your custom fallback widget.',
    );
  }

  Future<List<List<Uint8List?>>> _renderCustomIcons() async {
    final customIconBytes = <Uint8List?>[];
    final activeCustomIconBytes = <Uint8List?>[];

    for (final item in widget.items) {
      // Priority: imageAsset > customIcon > icon
      if (item.imageAsset != null) {
        // For imageAsset, we don't need to render to bytes - native code will handle it
        customIconBytes.add(null);
      } else if (item.customIcon != null) {
        final bytes = await iconDataToImageBytes(item.customIcon!, size: 25.0);
        customIconBytes.add(bytes);
      } else {
        customIconBytes.add(null);
      }

      // Render active custom icon
      if (item.activeImageAsset != null) {
        // For activeImageAsset, we don't need to render to bytes - native code will handle it
        activeCustomIconBytes.add(null);
      } else if (item.activeCustomIcon != null) {
        final bytes = await iconDataToImageBytes(item.activeCustomIcon!, size: 25.0);
        activeCustomIconBytes.add(bytes);
      } else if (item.customIcon != null) {
        activeCustomIconBytes.add(customIconBytes.last); // Use same as normal
      } else {
        activeCustomIconBytes.add(null);
      }
    }

    return [customIconBytes, activeCustomIconBytes];
  }

  Future<Map<String, dynamic>?> _buildCreationParams() async {
    final iconBytes = await _renderCustomIcons();
    if (!mounted) return null;
    final customIconBytes = iconBytes[0];
    final activeCustomIconBytes = iconBytes[1];

    // Capture all context-derived values before any async operations
    final capturedDevicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final capturedIsDark = _isDark;
    final capturedStyle = encodeStyle(context, tint: _themeTint);
    // Capture search style params before async operations
    final capturedSearchStyle = _hasSearch ? _buildSearchStyleParams(context) : null;
    final capturedLabelStyle = _buildLabelStyleParams(context);

    final labels = widget.items.map((e) => e.label ?? '').toList();
    final symbols = widget.items.map((e) => e.icon?.name ?? '').toList();
    final activeSymbols = widget.items.map((e) => e.activeIcon?.name ?? e.icon?.name ?? '').toList();
    final badges = widget.items.map((e) => _encodeBadge(e.badge)).toList();
    final badgeColors = widget.items.map((e) => resolveColorToArgb(e.badgeColor, context)).toList();
    final badgeTextColors = widget.items.map((e) => resolveColorToArgb(e.badgeTextColor, context)).toList();
    final badgeDotSizes = widget.items.map((e) => e.badgeDotSize).toList();
    final badgeFontSizes = widget.items.map((e) => e.badgeFontSize).toList();

    // Extract imageAsset data and resolve asset paths based on device pixel ratio
    final imageAssetPaths = await Future.wait(
      widget.items.map((e) async => e.imageAsset != null ? await resolveAssetPathForPixelRatio(e.imageAsset!.assetPath) : ''),
    );
    final activeImageAssetPaths = await Future.wait(
      widget.items.map((e) async => e.activeImageAsset != null ? await resolveAssetPathForPixelRatio(e.activeImageAsset!.assetPath) : ''),
    );

    if (!mounted) return null;

    final sizes = widget.items.map((e) => e.icon?.size ?? e.imageAsset?.size).toList();
    final colors = widget.items.map((e) => resolveColorToArgb(e.icon?.color ?? e.imageAsset?.color, context)).toList();
    final activeColors = widget.items
        .map((e) => resolveColorToArgb(e.activeIcon?.color ?? e.activeImageAsset?.color ?? e.icon?.color ?? e.imageAsset?.color, context))
        .toList();
    final itemPaddings = widget.items.map((e) {
      final p = e.padding;
      if (p == null) return null;
      return [p.top, p.left, p.bottom, p.right];
    }).toList();

    final imageAssetData = widget.items.map((e) => e.imageAsset?.imageData).toList();
    final activeImageAssetData = widget.items.map((e) => e.activeImageAsset?.imageData).toList();
    // Auto-detect format if not provided (use resolved paths)
    final imageAssetFormats = await Future.wait(
      widget.items.asMap().entries.map((entry) async {
        final e = entry.value;
        if (e.imageAsset == null) return '';
        final resolvedPath = imageAssetPaths[entry.key];
        return e.imageAsset!.imageFormat ?? detectImageFormat(resolvedPath, e.imageAsset!.imageData) ?? '';
      }),
    );
    final activeImageAssetFormats = await Future.wait(
      widget.items.asMap().entries.map((entry) async {
        final e = entry.value;
        if (e.activeImageAsset == null) return '';
        final resolvedPath = activeImageAssetPaths[entry.key];
        return e.activeImageAsset!.imageFormat ?? detectImageFormat(resolvedPath, e.activeImageAsset!.imageData) ?? '';
      }),
    );

    if (!mounted) return null;

    final creationParams = <String, dynamic>{
      'labels': labels,
      'sfSymbols': symbols,
      'activeSfSymbols': activeSymbols,
      'badges': badges,
      'badgeColors': badgeColors,
      'badgeTextColors': badgeTextColors,
      'badgeDotSizes': badgeDotSizes,
      'badgeFontSizes': badgeFontSizes,
      'customIconBytes': customIconBytes,
      'activeCustomIconBytes': activeCustomIconBytes,
      'imageAssetPaths': imageAssetPaths,
      'activeImageAssetPaths': activeImageAssetPaths,
      'imageAssetData': imageAssetData,
      'activeImageAssetData': activeImageAssetData,
      'imageAssetFormats': imageAssetFormats,
      'activeImageAssetFormats': activeImageAssetFormats,
      'iconScale': capturedDevicePixelRatio, // Pass the scale!
      'sfSymbolSizes': sizes,
      'sfSymbolColors': colors,
      'sfSymbolActiveColors': activeColors,
      'itemPaddings': itemPaddings,
      'selectedIndex': widget.currentIndex,
      'isDark': capturedIsDark,
      'split': _hasSearch ? true : widget.split,
      'rightCount': widget.rightCount,
      'splitSpacing': widget.splitSpacing,
      'iconAboveLabel': widget.iconAboveLabel,
      'style': capturedStyle,
      // Label style configuration
      if (capturedLabelStyle != null) 'labelStyle': capturedLabelStyle,
      // Search configuration (iOS 26+)
      if (_hasSearch) ...{
        'hasSearch': true,
        'searchPlaceholder': widget.searchItem!.placeholder,
        'searchLabel': widget.searchItem!.label,
        'searchSymbol': widget.searchItem!.icon?.name ?? 'magnifyingglass',
        'searchActiveSymbol': widget.searchItem!.activeIcon?.name ?? widget.searchItem!.icon?.name ?? 'magnifyingglass',
        'automaticallyActivatesSearch': widget.searchItem!.automaticallyActivatesSearch,
        // Style configuration (captured before async operations)
        if (capturedSearchStyle != null) 'searchStyle': capturedSearchStyle,
      },
    };

    return creationParams;
  }

  Map<String, dynamic> _buildSearchStyleParams(BuildContext context) {
    final style = widget.searchItem?.style ?? const CNTabBarSearchStyle();
    return {
      if (style.iconSize != null) 'iconSize': style.iconSize,
      if (style.iconColor != null) 'iconColor': resolveColorToArgb(style.iconColor, context),
      if (style.activeIconColor != null) 'activeIconColor': resolveColorToArgb(style.activeIconColor, context),
      if (style.searchBarBackgroundColor != null) 'searchBarBackgroundColor': resolveColorToArgb(style.searchBarBackgroundColor, context),
      if (style.searchBarTextColor != null) 'searchBarTextColor': resolveColorToArgb(style.searchBarTextColor, context),
      if (style.searchBarPlaceholderColor != null) 'searchBarPlaceholderColor': resolveColorToArgb(style.searchBarPlaceholderColor, context),
      if (style.clearButtonColor != null) 'clearButtonColor': resolveColorToArgb(style.clearButtonColor, context),
      if (style.buttonSize != null) 'buttonSize': style.buttonSize,
      if (style.searchBarHeight != null) 'searchBarHeight': style.searchBarHeight,
      if (style.searchBarBorderRadius != null) 'searchBarBorderRadius': style.searchBarBorderRadius,
      if (style.searchBarPadding != null) ...{
        'searchBarPaddingLeft': style.searchBarPadding!.left,
        'searchBarPaddingRight': style.searchBarPadding!.right,
        'searchBarPaddingTop': style.searchBarPadding!.top,
        'searchBarPaddingBottom': style.searchBarPadding!.bottom,
      },
      if (style.contentPadding != null) ...{
        'contentPaddingLeft': style.contentPadding!.left,
        'contentPaddingRight': style.contentPadding!.right,
        'contentPaddingTop': style.contentPadding!.top,
        'contentPaddingBottom': style.contentPadding!.bottom,
      },
      if (style.spacing != null) 'spacing': style.spacing,
      if (style.animationDuration != null) 'animationDuration': style.animationDuration!.inMilliseconds,
      'showClearButton': style.showClearButton,
      if (style.collapsedTabIcon != null) 'collapsedTabIcon': style.collapsedTabIcon!.name,
    };
  }

  Map<String, dynamic>? _buildLabelStyleParams(BuildContext context) {
    final style = widget.labelStyle;
    if (style == null) return null;
    final params = <String, dynamic>{};
    if (style.fontSize != null) params['fontSize'] = style.fontSize;
    if (style.fontWeight != null) {
      params['fontWeight'] = _encodeFontWeight(style.fontWeight!);
    }
    if (style.color != null) {
      params['color'] = resolveColorToArgb(style.color, context);
    }
    if (style.activeColor != null) {
      params['activeColor'] = resolveColorToArgb(style.activeColor, context);
    }
    if (style.fontFamily != null) params['fontFamily'] = style.fontFamily;
    if (style.letterSpacing != null) {
      params['letterSpacing'] = style.letterSpacing;
    }
    return params.isEmpty ? null : params;
  }

  static int _encodeFontWeight(FontWeight weight) {
    if (weight == FontWeight.w100) return 100;
    if (weight == FontWeight.w200) return 200;
    if (weight == FontWeight.w300) return 300;
    if (weight == FontWeight.w400) return 400;
    if (weight == FontWeight.w500) return 500;
    if (weight == FontWeight.w600) return 600;
    if (weight == FontWeight.w700) return 700;
    if (weight == FontWeight.w800) return 800;
    if (weight == FontWeight.w900) return 900;
    return 400;
  }

  Widget _buildNativeTabBarPlatformView(Map<String, dynamic> creationParams) {
    final viewType = 'CupertinoNativeTabBar';
    final platformView = defaultTargetPlatform == TargetPlatform.iOS
        ? UiKitView(viewType: viewType, creationParams: creationParams, creationParamsCodec: const StandardMessageCodec(), onPlatformViewCreated: _onCreated)
        : AppKitView(viewType: viewType, creationParams: creationParams, creationParamsCodec: const StandardMessageCodec(), onPlatformViewCreated: _onCreated);

    final h = widget.height ?? _intrinsicHeight ?? 50.0;
    if (!widget.split && widget.shrinkCentered) {
      final w = _intrinsicWidth;
      return ClipRect(
        child: SizedBox(height: h, width: w, child: platformView),
      );
    }
    return ClipRect(
      child: SizedBox(height: h, child: platformView),
    );
  }

  void _onCreated(int id) {
    final ch = MethodChannel('CupertinoNativeTabBar_$id');
    _channel = ch;
    ch.setMethodCallHandler(_onMethodCall);
    _lastIndex = widget.currentIndex;
    _lastIsDark = _isDark;
    _requestIntrinsicSize();
    _cacheItems();
    _lastSplit = widget.split;
    _lastRightCount = widget.rightCount;
    _lastSplitSpacing = widget.splitSpacing;

    // Force refresh for label rendering (Issue #6: sporadic missing labels with 5 items).
    // First refresh after 50ms; second after 200ms for slow-to-initialize native view.
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      Future.delayed(const Duration(milliseconds: 50), () async {
        if (mounted && _channel != null) {
          try {
            await _channel?.invokeMethod('refresh');
            await _channel?.invokeMethod('setSelectedIndex', {'index': widget.currentIndex});
          } catch (e) {
            // Ignore MissingPluginException during hot reload or view recreation
          }
        }
      });
      Future.delayed(const Duration(milliseconds: 200), () async {
        if (mounted && _channel != null) {
          try {
            await _channel?.invokeMethod('refresh');
            await _channel?.invokeMethod('setSelectedIndex', {'index': widget.currentIndex});
          } catch (e) {
            // Ignore when platform view is being recreated
          }
        }
      });
    }
  }

  Future<dynamic> _onMethodCall(MethodCall call) async {
    if (call.method == 'valueChanged') {
      final args = call.arguments as Map?;
      final idx = (args?['index'] as num?)?.toInt();
      if (idx != null) {
        // Always fire onTap, even for reselects (Issue #13 fix)
        widget.onTap(idx);
        _lastIndex = idx;
      }
    } else if (call.method == 'searchTextChanged') {
      final args = call.arguments as Map?;
      final text = args?['text'] as String? ?? '';
      _searchText = text;
      widget.searchItem?.onSearchChanged?.call(text);
      widget.searchController?.updateFromNative(text: text);
    } else if (call.method == 'searchActiveChanged') {
      final args = call.arguments as Map?;
      final isActive = args?['isActive'] as bool? ?? false;
      setState(() => _isSearchActive = isActive);
      widget.searchItem?.onSearchActiveChanged?.call(isActive);
      widget.searchController?.updateFromNative(isActive: isActive);
    } else if (call.method == 'searchSubmitted') {
      final args = call.arguments as Map?;
      final text = args?['text'] as String? ?? '';
      widget.searchItem?.onSearchSubmit?.call(text);
    }
    return null;
  }

  Future<void> _syncPropsToNativeIfNeeded() async {
    final ch = _channel;
    if (ch == null) return;
    // Capture theme-dependent values before awaiting
    final idx = widget.currentIndex;
    final iconScale = MediaQuery.of(context).devicePixelRatio;
    final labelStyleParams = _buildLabelStyleParams(context);

    try {
      if (_lastIndex != idx) {
        await ch.invokeMethod('setSelectedIndex', {'index': idx});
        _lastIndex = idx;
      }

      final style = <String, dynamic>{};
      if (labelStyleParams != null) {
        style['labelStyle'] = labelStyleParams;
      }
      if (style.isNotEmpty) {
        await ch.invokeMethod('setStyle', style);
      }

      // Items update (for hot reload or dynamic changes)
      final labels = widget.items.map((e) => e.label ?? '').toList();
      final symbols = widget.items.map((e) => e.icon?.name ?? '').toList();
      final activeSymbols = widget.items.map((e) => e.activeIcon?.name ?? e.icon?.name ?? '').toList();
      final badges = widget.items.map((e) => _encodeBadge(e.badge)).toList();
      final badgeColors = widget.items.map((e) => resolveColorToArgb(e.badgeColor, context)).toList();
      final badgeTextColors = widget.items.map((e) => resolveColorToArgb(e.badgeTextColor, context)).toList();
      final badgeDotSizes = widget.items.map((e) => e.badgeDotSize).toList();
      final badgeFontSizes = widget.items.map((e) => e.badgeFontSize).toList();

      // Compute comprehensive fingerprint covering ALL item properties
      final currentFingerprint = _itemsFingerprint();
      final currentBadgesFingerprint = _badgesFingerprint();
      final itemsChanged = currentFingerprint != _lastItemsFingerprint;
      final onlyBadgesChanged = !itemsChanged
          ? false
          : (currentBadgesFingerprint != _lastBadgesFingerprint &&
                // Verify that only badge-related fields changed by checking the
                // non-badge parts of the fingerprint match
                _nonBadgePart(currentFingerprint) == _nonBadgePart(_lastItemsFingerprint ?? ''));

      if (onlyBadgesChanged) {
        // Only badge values/colors changed — use lightweight update
        await ch.invokeMethod('setBadges', {
          'badges': badges,
          'badgeColors': badgeColors,
          'badgeTextColors': badgeTextColors,
          'badgeDotSizes': badgeDotSizes,
          'badgeFontSizes': badgeFontSizes,
        });
        _lastBadgesFingerprint = currentBadgesFingerprint;
        _lastItemsFingerprint = currentFingerprint;
        return;
      }

      if (itemsChanged) {
        final colors = widget.items.map((e) => resolveColorToArgb(e.icon?.color ?? e.imageAsset?.color, context)).toList();
        final activeColors = widget.items
            .map((e) => resolveColorToArgb(e.activeIcon?.color ?? e.activeImageAsset?.color ?? e.icon?.color ?? e.imageAsset?.color, context))
            .toList();

        // Re-render custom icons if items changed
        final iconBytes = await _renderCustomIcons();
        if (!mounted) return;

        final customIconBytes = iconBytes[0];
        final activeCustomIconBytes = iconBytes[1];

        // Extract imageAsset properties
        final imageAssetPaths = widget.items.map((e) => e.imageAsset?.assetPath ?? '').toList();
        final activeImageAssetPaths = widget.items.map((e) => e.activeImageAsset?.assetPath ?? '').toList();
        final imageAssetData = widget.items.map((e) => e.imageAsset?.imageData).toList();
        final activeImageAssetData = widget.items.map((e) => e.activeImageAsset?.imageData).toList();
        // Auto-detect format if not provided
        final imageAssetFormats = widget.items
            .map((e) => e.imageAsset?.imageFormat ?? detectImageFormat(e.imageAsset?.assetPath, e.imageAsset?.imageData) ?? '')
            .toList();
        final activeImageAssetFormats = widget.items
            .map((e) => e.activeImageAsset?.imageFormat ?? detectImageFormat(e.activeImageAsset?.assetPath, e.activeImageAsset?.imageData) ?? '')
            .toList();

        final sizes = widget.items.map((e) => e.icon?.size ?? e.imageAsset?.size).toList();

        await ch.invokeMethod('setItems', {
          'labels': labels,
          'sfSymbols': symbols,
          'activeSfSymbols': activeSymbols,
          'badges': badges,
          'badgeColors': badgeColors,
          'badgeTextColors': badgeTextColors,
          'badgeDotSizes': badgeDotSizes,
          'badgeFontSizes': badgeFontSizes,
          'customIconBytes': customIconBytes,
          'activeCustomIconBytes': activeCustomIconBytes,
          'imageAssetPaths': imageAssetPaths,
          'activeImageAssetPaths': activeImageAssetPaths,
          'imageAssetData': imageAssetData,
          'activeImageAssetData': activeImageAssetData,
          'imageAssetFormats': imageAssetFormats,
          'activeImageAssetFormats': activeImageAssetFormats,
          'iconScale': iconScale,
          'selectedIndex': widget.currentIndex,
          'sfSymbolSizes': sizes,
          'sfSymbolColors': colors,
          'sfSymbolActiveColors': activeColors,
        });
        _lastItemsFingerprint = currentFingerprint;
        _lastBadgesFingerprint = currentBadgesFingerprint;
        // Re-measure width in case content changed
        _requestIntrinsicSize();
      }

      // Layout updates (split / insets)
      if (_lastSplit != widget.split || _lastRightCount != widget.rightCount || _lastSplitSpacing != widget.splitSpacing) {
        await ch.invokeMethod('setLayout', {
          'split': widget.split,
          'rightCount': widget.rightCount,
          'splitSpacing': widget.splitSpacing,
          'selectedIndex': widget.currentIndex,
        });
        _lastSplit = widget.split;
        _lastRightCount = widget.rightCount;
        _lastSplitSpacing = widget.splitSpacing;
        _requestIntrinsicSize();
      }
    } catch (e) {
      // Ignore MissingPluginException during hot reload or view recreation
    }
  }

  Future<void> _syncBrightnessIfNeeded() async {
    final ch = _channel;
    if (ch == null) return;
    final isDark = _isDark;
    if (_lastIsDark != isDark) {
      try {
        await ch.invokeMethod('setBrightness', {'isDark': isDark});
        _lastIsDark = isDark;
      } catch (e) {
        // Ignore MissingPluginException during hot reload or view recreation
      }
    }
  }

  void _cacheItems() {
    _lastItemsFingerprint = _itemsFingerprint();
    _lastBadgesFingerprint = _badgesFingerprint();
  }

  /// Fingerprint covering ALL item properties that can change at runtime.
  /// This ensures any change — imageAssets, icon colors (theme), badge colors,
  /// custom icons, padding — triggers a native update.
  String _itemsFingerprint() {
    return widget.items
        .map((e) {
          // Context-resolved colors are needed for theme sensitivity
          final iconColor = resolveColorToArgb(e.icon?.color ?? e.imageAsset?.color, context);
          final activeColor = resolveColorToArgb(e.activeIcon?.color ?? e.activeImageAsset?.color ?? e.icon?.color ?? e.imageAsset?.color, context);
          final badgeColor = resolveColorToArgb(e.badgeColor, context);
          final badgeTextColor = resolveColorToArgb(e.badgeTextColor, context);
          return [
            e.label ?? '',
            e.icon?.name ?? '',
            e.icon?.size.toString() ?? '',
            e.activeIcon?.name ?? '',
            _encodeBadge(e.badge),
            iconColor?.toString() ?? '',
            activeColor?.toString() ?? '',
            badgeColor?.toString() ?? '',
            badgeTextColor?.toString() ?? '',
            e.imageAsset?.assetPath ?? '',
            e.imageAsset?.size.toString() ?? '',
            e.activeImageAsset?.assetPath ?? '',
            e.activeImageAsset?.size.toString() ?? '',
            e.customIcon?.hashCode.toString() ?? '',
            e.activeCustomIcon?.hashCode.toString() ?? '',
            e.badgeDotSize?.toString() ?? '',
            e.badgeFontSize?.toString() ?? '',
            e.padding?.toString() ?? '',
          ].join('\x00');
        })
        .join('\x01');
  }

  /// Fingerprint for badges only (used in the fast badges-only update path).
  String _badgesFingerprint() {
    return widget.items
        .map(
          (e) => [
            _encodeBadge(e.badge),
            resolveColorToArgb(e.badgeColor, context)?.toString() ?? '',
            resolveColorToArgb(e.badgeTextColor, context)?.toString() ?? '',
            e.badgeDotSize?.toString() ?? '',
            e.badgeFontSize?.toString() ?? '',
          ].join('\x00'),
        )
        .join('\x01');
  }

  /// Extracts the non-badge parts of a fingerprint.
  String _nonBadgePart(String fingerprint) {
    if (fingerprint.isEmpty) return '';
    return fingerprint
        .split('\x01')
        .map((itemStr) {
          final parts = itemStr.split('\x00');
          if (parts.length >= 18) {
            // Badge-related fields are encoded at indices 4, 7, 8, 16, 17
            parts[4] = '';
            parts[7] = '';
            parts[8] = '';
            parts[16] = '';
            parts[17] = '';
          }
          return parts.join('\x00');
        })
        .join('\x01');
  }

  /// Encodes a badge value for native transfer.
  ///
  /// - `null`  → `''`        → no badge rendered
  /// - `''`    → `'\u200B'`  → dot indicator (empty badge bubble)
  /// - text    → text        → badge with text
  static String _encodeBadge(String? badge) {
    if (badge == null) return '';
    if (badge.isEmpty) return '\u200B'; // zero-width space sentinel → dot
    return badge;
  }

  Future<void> _requestIntrinsicSize() async {
    if (widget.height != null) return;
    final ch = _channel;
    if (ch == null) return;
    try {
      final size = await ch.invokeMethod<Map>('getIntrinsicSize');
      final hNum = size?['height'] as num?;
      final wNum = size?['width'] as num?;
      final h = hNum?.toDouble();
      final w = wNum?.toDouble();
      if (!mounted) return;
      setState(() {
        if (h != null && h > 0) _intrinsicHeight = h;
        if (w != null && w > 0) _intrinsicWidth = w;
      });
    } catch (_) {}
  }

  Widget _resolveFallback(BuildContext context) {
    return widget.fallback ?? _buildFlutterFallback(context);
  }

  /// Builds the Flutter fallback for non-iOS 26+ platforms.
  /// Includes search functionality when searchItem is provided.
  Widget _buildFlutterFallback(BuildContext context) {
    final tintColor = widget.labelStyle?.activeColor ?? ThemeHelper.getPrimaryColor(context);
    final style = widget.searchItem?.style ?? const CNTabBarSearchStyle();

    final labelStyle = widget.labelStyle;

    // If no search item, just return regular CupertinoTabBar
    if (!_hasSearch) {
      return SizedBox(
        height: widget.height,
        child: CupertinoTabBar(
          items: [
            for (final item in widget.items)
              BottomNavigationBarItem(icon: _buildTabIcon(item, isActive: false), activeIcon: _buildTabIcon(item, isActive: true), label: item.label),
          ],
          currentIndex: widget.currentIndex,
          onTap: widget.onTap,
          inactiveColor: labelStyle?.color ?? CupertinoColors.inactiveGray,
          activeColor: labelStyle?.activeColor ?? tintColor,
        ),
      );
    }

    // With search: build a custom layout that mimics iOS 26 behavior
    final buttonSize = style.buttonSize ?? 44.0;
    final iconSize = style.iconSize ?? 20.0;
    final spacing = style.spacing ?? 12.0;
    final contentPadding = style.contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8);

    return Container(
      height: widget.height ?? 50,
      padding: contentPadding,
      child: Row(
        children: [
          // Left side: Tab items or collapsed indicator
          Expanded(
            child: AnimatedSwitcher(
              duration: style.animationDuration ?? const Duration(milliseconds: 400),
              child: _isSearchActive ? _buildCollapsedTabIndicator(context, tintColor, buttonSize, iconSize, style) : _buildTabItems(context, tintColor),
            ),
          ),
          SizedBox(width: spacing),
          // Right side: Search button or expanded search bar
          AnimatedSwitcher(
            duration: style.animationDuration ?? const Duration(milliseconds: 400),
            child: _isSearchActive ? _buildExpandedSearchBar(context, tintColor, style) : _buildSearchButton(context, tintColor, buttonSize, iconSize, style),
          ),
        ],
      ),
    );
  }

  /// Old method kept for Flutter fallback compatibility
  Widget _buildCollapsedTabIndicator(BuildContext context, Color tintColor, double buttonSize, double iconSize, CNTabBarSearchStyle style) {
    final collapsedIcon = style.collapsedTabIcon?.name ?? widget.items.first.icon?.name ?? 'square.grid.2x2';

    return GestureDetector(
      onTap: () {
        // Unfocus and close keyboard first
        _searchFocusNode?.unfocus();
        setState(() => _isSearchActive = false);
        widget.searchItem?.onSearchActiveChanged?.call(false);
        widget.searchController?.updateFromNative(isActive: false);
        // Notify native iOS to deactivate search
        _channel?.invokeMethod('deactivateSearch');
      },
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(color: CupertinoColors.systemGrey6.resolveFrom(context), borderRadius: BorderRadius.circular(buttonSize / 2)),
        child: CNIcon(symbol: CNSymbol(collapsedIcon), size: iconSize, color: style.activeIconColor ?? tintColor),
      ),
    );
  }

  Widget _buildTabItems(BuildContext context, Color tintColor) {
    return Container(
      decoration: BoxDecoration(color: CupertinoColors.systemGrey6.resolveFrom(context), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < widget.items.length; i++)
            GestureDetector(
              onTap: () => widget.onTap(i),
              child: Padding(
                padding: widget.items[i].padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: FittedBox(child: _buildTabIcon(widget.items[i], isActive: widget.currentIndex == i)),
                    ),
                    if (widget.items[i].label != null && widget.items[i].label!.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        widget.items[i].label!,
                        style: _buildLabelTextStyle(isActive: widget.currentIndex == i, tintColor: tintColor),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchButton(BuildContext context, Color tintColor, double buttonSize, double iconSize, CNTabBarSearchStyle style) {
    final searchSymbol = widget.searchItem?.icon?.name ?? 'magnifyingglass';
    final autoActivate = widget.searchItem?.automaticallyActivatesSearch ?? true;

    return GestureDetector(
      onTap: () {
        setState(() => _isSearchActive = true);
        widget.searchItem?.onSearchActiveChanged?.call(true);
        widget.searchController?.updateFromNative(isActive: true);
        // Auto-focus search field if enabled
        if (autoActivate) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _searchFocusNode?.requestFocus();
          });
        }
      },
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(color: CupertinoColors.systemGrey6.resolveFrom(context), borderRadius: BorderRadius.circular(buttonSize / 2)),
        child: CNIcon(symbol: CNSymbol(searchSymbol), size: iconSize, color: style.iconColor ?? CupertinoColors.secondaryLabel),
      ),
    );
  }

  Widget _buildExpandedSearchBar(BuildContext context, Color tintColor, CNTabBarSearchStyle style) {
    final searchSymbol = widget.searchItem?.icon?.name ?? 'magnifyingglass';
    final padding = style.searchBarPadding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8);

    return Expanded(
      child: Container(
        height: style.searchBarHeight ?? 36,
        decoration: BoxDecoration(
          color: style.searchBarBackgroundColor ?? CupertinoColors.systemGrey6.resolveFrom(context),
          borderRadius: BorderRadius.circular(style.searchBarBorderRadius ?? (style.searchBarHeight ?? 36) / 2),
        ),
        padding: padding,
        child: Row(
          children: [
            CNIcon(
              symbol: CNSymbol(searchSymbol),
              size: (style.iconSize ?? 20) * 0.8,
              color: style.searchBarPlaceholderColor ?? CupertinoColors.secondaryLabel,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CupertinoTextField.borderless(
                focusNode: _searchFocusNode,
                autofocus: false, // Never auto-focus - we control this manually
                placeholder: widget.searchItem?.placeholder ?? 'Search',
                placeholderStyle: TextStyle(color: style.searchBarPlaceholderColor ?? CupertinoColors.secondaryLabel),
                style: TextStyle(color: style.searchBarTextColor ?? CupertinoColors.label),
                onChanged: (text) {
                  setState(() => _searchText = text);
                  widget.searchItem?.onSearchChanged?.call(text);
                  widget.searchController?.updateFromNative(text: text);
                },
                onSubmitted: (text) {
                  widget.searchItem?.onSearchSubmit?.call(text);
                },
              ),
            ),
            if (style.showClearButton && _searchText.isNotEmpty)
              GestureDetector(
                onTap: () {
                  setState(() => _searchText = '');
                  widget.searchItem?.onSearchChanged?.call('');
                  widget.searchController?.updateFromNative(text: '');
                },
                child: Icon(
                  CupertinoIcons.xmark_circle_fill,
                  size: (style.iconSize ?? 20) * 0.8,
                  color: style.clearButtonColor ?? CupertinoColors.secondaryLabel,
                ),
              ),
          ],
        ),
      ),
    );
  }

  TextStyle _buildLabelTextStyle({required bool isActive, required Color tintColor}) {
    final ls = widget.labelStyle;
    return TextStyle(
      fontSize: ls?.fontSize ?? 12,
      fontWeight: isActive ? (ls?.fontWeight ?? FontWeight.w600) : (ls?.fontWeight ?? FontWeight.normal),
      color: isActive ? (ls?.activeColor ?? tintColor) : (ls?.color ?? CupertinoColors.inactiveGray),
      fontFamily: ls?.fontFamily,
      letterSpacing: ls?.letterSpacing,
    );
  }

  /// Builds an icon widget for the tab bar fallback.
  /// Priority: imageAsset > customIcon > icon (SF Symbol)
  Widget _buildTabIcon(CNTabBarItem item, {required bool isActive}) {
    const defaultSize = 25.0;

    // Check for image asset (highest priority)
    if (isActive && item.activeImageAsset != null) {
      return CNIcon(imageAsset: item.activeImageAsset, size: item.activeImageAsset!.size);
    }
    if (item.imageAsset != null) {
      return CNIcon(imageAsset: item.imageAsset, size: item.imageAsset!.size);
    }

    // Check for custom icon (medium priority)
    if (isActive && item.activeCustomIcon != null) {
      return Icon(item.activeCustomIcon, size: defaultSize);
    }
    if (item.customIcon != null) {
      return Icon(item.customIcon, size: defaultSize);
    }

    // Check for SF Symbol (lowest priority)
    if (isActive && item.activeIcon != null) {
      return CNIcon(symbol: item.activeIcon, size: item.activeIcon!.size, color: item.activeIcon!.color);
    }
    if (item.icon != null) {
      return CNIcon(symbol: item.icon, size: item.icon!.size, color: item.icon!.color);
    }

    // Fallback to empty circle if nothing provided
    return const Icon(CupertinoIcons.circle, size: defaultSize);
  }
}
