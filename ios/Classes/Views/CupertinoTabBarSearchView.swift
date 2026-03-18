import Flutter
import UIKit

/// iOS 26+ native tab bar with search support.
/// Uses UITabBar with UITabBarSystemItem.search for native liquid glass morphing effect.
@available(iOS 26.0, *)
class CupertinoTabBarSearchPlatformView: NSObject, FlutterPlatformView, UITabBarDelegate {
    private let channel: FlutterMethodChannel
    private let container: UIView
    private var tabBar: UITabBar?
    private var glassView: UIView?

    // State
    private var currentLabels: [String] = []
    private var currentSymbols: [String] = []
    private var currentActiveSymbols: [String] = []
    private var currentBadges: [String] = []
    private var currentBadgeCounts: [Int?] = []
    private var currentBadgeColors: [NSNumber?] = []
    private var currentBadgeTextColors: [NSNumber?] = []
    private var currentBadgeDotSizes: [NSNumber?] = []
    private var currentBadgeFontSizes: [NSNumber?] = []
    private var selectedIndex: Int = 0
    private var tintColor: UIColor?
    private var unselectedTintColor: UIColor?
    private var searchPlaceholder: String = "Search"
    private var searchLabel: String = "Search"
    private var iconLabelSpacing: CGFloat = 0

    // Search tab is always the last item
    private var searchItemIndex: Int = -1

    init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
        self.channel = FlutterMethodChannel(name: "CupertinoNativeTabBar_\(viewId)", binaryMessenger: messenger)
        self.container = UIView(frame: frame)

        super.init()

        // Parse creation params
        if let dict = args as? [String: Any] {
            currentLabels = (dict["labels"] as? [String]) ?? []
            currentSymbols = (dict["sfSymbols"] as? [String]) ?? []
            currentActiveSymbols = (dict["activeSfSymbols"] as? [String]) ?? []
            currentBadges = (dict["badges"] as? [String]) ?? []
            if let badgeData = dict["badgeCounts"] as? [NSNumber?] {
                currentBadgeCounts = badgeData.map { $0?.intValue }
            }
            currentBadgeColors = Self.extractNullableNumbers(dict["badgeColors"])
            currentBadgeTextColors = Self.extractNullableNumbers(dict["badgeTextColors"])
            currentBadgeDotSizes = Self.extractNullableNumbers(dict["badgeDotSizes"])
            currentBadgeFontSizes = Self.extractNullableNumbers(dict["badgeFontSizes"])
            if let v = dict["selectedIndex"] as? NSNumber {
                selectedIndex = v.intValue
            }
            if let v = dict["isDark"] as? NSNumber {
                container.overrideUserInterfaceStyle = v.boolValue ? .dark : .light
            }
            if let style = dict["style"] as? [String: Any] {
                if let n = style["tint"] as? NSNumber {
                    tintColor = ImageUtils.colorFromARGB(n.intValue)
                }
                if let n = style["unselectedTint"] as? NSNumber {
                    unselectedTintColor = ImageUtils.colorFromARGB(n.intValue)
                }
            }
            searchPlaceholder = (dict["searchPlaceholder"] as? String) ?? "Search"
            searchLabel = (dict["searchLabel"] as? String) ?? "Search"
            if let v = dict["iconLabelSpacing"] as? NSNumber {
                iconLabelSpacing = CGFloat(v.doubleValue)
            }
        }

        container.backgroundColor = .clear
        container.clipsToBounds = true
        container.layer.shadowOpacity = 0

        setupUI()
        setupMethodChannel()
    }

    private func setupUI() {
        // Create native UITabBar - gets liquid glass morphing effect on iOS 26+
        let bar = UITabBar(frame: .zero)
        tabBar = bar
        bar.delegate = self
        bar.translatesAutoresizingMaskIntoConstraints = false

        // iOS 26+ - use direct properties for liquid glass effect
        // Skip UITabBarAppearance as it interferes with iOS 26 styling
        bar.isTranslucent = true
        bar.backgroundImage = UIImage()
        bar.shadowImage = UIImage()
        bar.backgroundColor = .clear
        bar.clipsToBounds = true
        bar.layer.shadowOpacity = 0

        // Set tint colors
        if let tint = tintColor {
            bar.tintColor = tint
        }
        if let unselTint = unselectedTintColor {
            bar.unselectedItemTintColor = unselTint
        }

        // Build tab items including search
        bar.items = buildTabItems()

        // Set selected item (not the search item)
        if let items = bar.items, selectedIndex >= 0, selectedIndex < items.count {
            if selectedIndex != searchItemIndex {
                bar.selectedItem = items[selectedIndex]
            } else if items.count > 1 {
                bar.selectedItem = items[0]
                selectedIndex = 0
            }
        }

        // Shared glass background — bar has transparent appearance so we own the glass
        let glass = UIVisualEffectView(effect: UIGlassEffect())
        glass.translatesAutoresizingMaskIntoConstraints = false
        glass.layer.cornerRadius = 20
        glass.layer.cornerCurve = .continuous
        glass.clipsToBounds = true
        glassView = glass
        container.addSubview(glass)
        container.addSubview(bar)

        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            bar.topAnchor.constraint(equalTo: container.topAnchor),
            bar.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            glass.leadingAnchor.constraint(equalTo: bar.leadingAnchor),
            glass.trailingAnchor.constraint(equalTo: bar.trailingAnchor),
            glass.topAnchor.constraint(equalTo: bar.topAnchor),
            glass.bottomAnchor.constraint(equalTo: bar.bottomAnchor),
        ])
    }

    private func buildTabItems() -> [UITabBarItem] {
        var items: [UITabBarItem] = []
        let count = max(currentLabels.count, currentSymbols.count)

        for i in 0..<count {
            let title = i < currentLabels.count ? currentLabels[i] : nil
            let symbol = i < currentSymbols.count ? currentSymbols[i] : "circle"
            let activeSymbol = i < currentActiveSymbols.count && !currentActiveSymbols[i].isEmpty
                ? currentActiveSymbols[i] : symbol
            let badge = i < currentBadges.count ? currentBadges[i] : ""
            let badgeCount = i < currentBadgeCounts.count ? currentBadgeCounts[i] : nil

            var image: UIImage? = nil
            var selectedImage: UIImage? = nil

            // iOS 26+: Use different rendering modes for selected/unselected
            if let unselTint = unselectedTintColor {
                // Unselected: Apply custom color
                if let originalImage = UIImage(systemName: symbol) {
                    image = originalImage.withTintColor(unselTint, renderingMode: .alwaysOriginal)
                }
            } else {
                // No custom color - use template mode to respect theme
                image = UIImage(systemName: symbol)?.withRenderingMode(.alwaysTemplate)
            }

            // Selected: Use template rendering so tintColor applies
            selectedImage = UIImage(systemName: activeSymbol)?.withRenderingMode(.alwaysTemplate)

            let item = UITabBarItem(title: title, image: image, selectedImage: selectedImage)
            item.tag = i

            if iconLabelSpacing > 0 {
                let half = iconLabelSpacing / 2
                item.imageInsets = UIEdgeInsets(top: -half, left: 0, bottom: half, right: 0)
                item.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: half)
            }

            if !badge.isEmpty {
                Self.applyBadge(
                    to: item,
                    index: i,
                    badge: badge,
                    badgeColors: currentBadgeColors,
                    badgeTextColors: currentBadgeTextColors,
                    badgeDotSizes: currentBadgeDotSizes,
                    badgeFontSizes: currentBadgeFontSizes
                )
            } else if let count = badgeCount, count > 0 {
                item.badgeValue = count > 99 ? "99+" : String(count)
                Self.applyBadge(
                    to: item,
                    index: i,
                    badge: item.badgeValue ?? "",
                    badgeColors: currentBadgeColors,
                    badgeTextColors: currentBadgeTextColors,
                    badgeDotSizes: currentBadgeDotSizes,
                    badgeFontSizes: currentBadgeFontSizes
                )
            } else {
                item.badgeValue = nil
            }

            items.append(item)
        }

        // Add search tab using UITabBarSystemItem.search for native iOS 26 liquid glass styling
        let searchItem = UITabBarItem(tabBarSystemItem: .search, tag: 9999)
        if !searchLabel.isEmpty {
            searchItem.title = searchLabel
        }
        items.append(searchItem)
        searchItemIndex = items.count - 1

        return items
    }

    private func setupMethodChannel() {
        channel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else { result(nil); return }

            switch call.method {
            case "getIntrinsicSize":
                if let bar = self.tabBar {
                    let size = bar.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
                    result(["width": Double(self.container.bounds.width), "height": Double(size.height)])
                } else {
                    result(["width": Double(self.container.bounds.width), "height": 50.0])
                }

            case "setSelectedIndex":
                if let args = call.arguments as? [String: Any],
                   let idx = (args["index"] as? NSNumber)?.intValue,
                   let bar = self.tabBar,
                   let items = bar.items,
                   idx >= 0, idx < items.count {
                    if idx != self.searchItemIndex {
                        bar.selectedItem = items[idx]
                        self.selectedIndex = idx
                    }
                    result(nil)
                } else {
                    result(FlutterError(code: "bad_args", message: "Missing or invalid index", details: nil))
                }

            case "activateSearch":
                // Notify Flutter to show search UI
                self.channel.invokeMethod("searchActiveChanged", arguments: ["isActive": true])
                result(nil)

            case "deactivateSearch":
                // Restore previous selection
                if let bar = self.tabBar,
                   let items = bar.items,
                   self.selectedIndex >= 0,
                   self.selectedIndex < items.count,
                   self.selectedIndex != self.searchItemIndex {
                    bar.selectedItem = items[self.selectedIndex]
                }
                self.channel.invokeMethod("searchActiveChanged", arguments: ["isActive": false])
                result(nil)

            case "setSearchText":
                // Search text is handled by Flutter
                result(nil)

            case "setBrightness":
                if let args = call.arguments as? [String: Any],
                   let isDark = (args["isDark"] as? NSNumber)?.boolValue {
                    self.container.overrideUserInterfaceStyle = isDark ? .dark : .light
                    result(nil)
                } else {
                    result(FlutterError(code: "bad_args", message: "Missing isDark", details: nil))
                }

            case "setStyle":
                if let args = call.arguments as? [String: Any] {
                    if let n = args["tint"] as? NSNumber {
                        let color = ImageUtils.colorFromARGB(n.intValue)
                        self.tabBar?.tintColor = color
                        self.tintColor = color
                    }
                    if let n = args["unselectedTint"] as? NSNumber {
                        let color = ImageUtils.colorFromARGB(n.intValue)
                        self.tabBar?.unselectedItemTintColor = color
                        self.unselectedTintColor = color
                        // Rebuild items with new unselected color
                        self.rebuildItemsWithCurrentColors()
                    }
                    result(nil)
                } else {
                    result(FlutterError(code: "bad_args", message: "Missing style", details: nil))
                }

            case "setItems":
                if let args = call.arguments as? [String: Any] {
                    self.currentLabels = (args["labels"] as? [String]) ?? []
                    self.currentSymbols = (args["sfSymbols"] as? [String]) ?? []
                    self.currentActiveSymbols = (args["activeSfSymbols"] as? [String]) ?? []
                    self.currentBadges = (args["badges"] as? [String]) ?? self.currentBadges
                    if let badgeData = args["badgeCounts"] as? [NSNumber?] {
                        self.currentBadgeCounts = badgeData.map { $0?.intValue }
                    }
                    self.currentBadgeColors = args["badgeColors"] != nil
                        ? Self.extractNullableNumbers(args["badgeColors"])
                        : self.currentBadgeColors
                    self.currentBadgeTextColors = args["badgeTextColors"] != nil
                        ? Self.extractNullableNumbers(args["badgeTextColors"])
                        : self.currentBadgeTextColors
                    self.currentBadgeDotSizes = args["badgeDotSizes"] != nil
                        ? Self.extractNullableNumbers(args["badgeDotSizes"])
                        : self.currentBadgeDotSizes
                    self.currentBadgeFontSizes = args["badgeFontSizes"] != nil
                        ? Self.extractNullableNumbers(args["badgeFontSizes"])
                        : self.currentBadgeFontSizes

                    self.tabBar?.items = self.buildTabItems()

                    if let idx = (args["selectedIndex"] as? NSNumber)?.intValue,
                       let bar = self.tabBar,
                       let items = bar.items,
                       idx >= 0, idx < items.count, idx != self.searchItemIndex {
                        bar.selectedItem = items[idx]
                        self.selectedIndex = idx
                    }
                    result(nil)
                } else {
                    result(FlutterError(code: "bad_args", message: "Missing items", details: nil))
                }

            case "setBadgeCounts":
                if let args = call.arguments as? [String: Any],
                   let badgeData = args["badgeCounts"] as? [NSNumber?] {
                    let badgeCounts = badgeData.map { $0?.intValue }
                    self.currentBadgeCounts = badgeCounts

                    // Update existing tab bar items
                    if let bar = self.tabBar, let items = bar.items {
                        for (index, item) in items.enumerated() {
                            if index < badgeCounts.count {
                                let count = badgeCounts[index]
                                if let count = count, count > 0 {
                                    item.badgeValue = count > 99 ? "99+" : String(count)
                                } else {
                                    item.badgeValue = nil
                                }
                            }
                        }
                    }
                    result(nil)
                } else {
                    result(FlutterError(code: "bad_args", message: "Missing badge counts", details: nil))
                }

            case "setBadges":
                if let args = call.arguments as? [String: Any],
                   let badges = args["badges"] as? [String] {
                    self.currentBadges = badges
                    self.currentBadgeColors = args["badgeColors"] != nil
                        ? Self.extractNullableNumbers(args["badgeColors"])
                        : self.currentBadgeColors
                    self.currentBadgeTextColors = args["badgeTextColors"] != nil
                        ? Self.extractNullableNumbers(args["badgeTextColors"])
                        : self.currentBadgeTextColors
                    self.currentBadgeDotSizes = args["badgeDotSizes"] != nil
                        ? Self.extractNullableNumbers(args["badgeDotSizes"])
                        : self.currentBadgeDotSizes
                    self.currentBadgeFontSizes = args["badgeFontSizes"] != nil
                        ? Self.extractNullableNumbers(args["badgeFontSizes"])
                        : self.currentBadgeFontSizes

                    if let bar = self.tabBar, let items = bar.items {
                        for (index, item) in items.enumerated() {
                            if index == self.searchItemIndex { continue }

                            if index < badges.count && !badges[index].isEmpty {
                                Self.applyBadge(
                                    to: item,
                                    index: index,
                                    badge: badges[index],
                                    badgeColors: self.currentBadgeColors,
                                    badgeTextColors: self.currentBadgeTextColors,
                                    badgeDotSizes: self.currentBadgeDotSizes,
                                    badgeFontSizes: self.currentBadgeFontSizes
                                )
                            } else {
                                item.badgeValue = nil
                            }
                        }
                    }

                    result(nil)
                } else {
                    result(FlutterError(code: "bad_args", message: "Missing badges", details: nil))
                }

            case "refresh", "setLabels", "setSfSymbols", "setLayout":
                result(nil)

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private static func extractNullableNumbers(_ value: Any?) -> [NSNumber?] {
        guard let array = value as? [Any] else { return [] }
        return array.map { $0 is NSNull ? nil : ($0 as? NSNumber) }
    }

    private static func colorForItem(index: Int, colors: [NSNumber?]) -> UIColor? {
        guard index < colors.count, let argb = colors[index] else { return nil }
        return ImageUtils.colorFromARGB(argb.intValue)
    }

    private static func numberForItem(index: Int, numbers: [NSNumber?]) -> CGFloat? {
        guard index < numbers.count, let value = numbers[index] else { return nil }
        let number = CGFloat(truncating: value)
        return number > 0 ? number : nil
    }

    private static func badgeTextAttributes(textColor: UIColor?, fontSize: CGFloat?) -> [NSAttributedString.Key: Any] {
        var attrs: [NSAttributedString.Key: Any] = [:]
        if let textColor = textColor {
            attrs[.foregroundColor] = textColor
        }
        if let fontSize = fontSize {
            attrs[.font] = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
        }
        return attrs
    }

    private static func applyBadge(
        to item: UITabBarItem,
        index: Int,
        badge: String,
        badgeColors: [NSNumber?],
        badgeTextColors: [NSNumber?],
        badgeDotSizes: [NSNumber?],
        badgeFontSizes: [NSNumber?]
    ) {
        let isDot = badge == "\u{200B}"
        let badgeBackgroundColor = colorForItem(index: index, colors: badgeColors)
        let badgeTextColor = colorForItem(index: index, colors: badgeTextColors)
        let badgeDotSize = numberForItem(index: index, numbers: badgeDotSizes)
        let badgeFontSize = numberForItem(index: index, numbers: badgeFontSizes)

        if isDot, let dotSize = badgeDotSize {
            item.badgeValue = "●"
            if #available(iOS 10.0, *) {
                let dotColor = badgeBackgroundColor ?? badgeTextColor ?? UIColor.systemRed
                item.badgeColor = dotColor
                let attrs = badgeTextAttributes(textColor: dotColor, fontSize: dotSize)
                if !attrs.isEmpty {
                    item.setBadgeTextAttributes(attrs, for: .normal)
                    item.setBadgeTextAttributes(attrs, for: .selected)
                }
            }
            return
        }

        item.badgeValue = isDot ? "" : badge
        if #available(iOS 10.0, *) {
            if let badgeBackgroundColor = badgeBackgroundColor {
                item.badgeColor = badgeBackgroundColor
            }
            let attrs = badgeTextAttributes(textColor: badgeTextColor, fontSize: badgeFontSize)
            if !attrs.isEmpty {
                item.setBadgeTextAttributes(attrs, for: .normal)
                item.setBadgeTextAttributes(attrs, for: .selected)
            }
        }
    }

    // Rebuild tab items with current colors (called when style changes)
    private func rebuildItemsWithCurrentColors() {
        guard let bar = self.tabBar else { return }

        let currentSelectedIndex = bar.items?.firstIndex { $0 == bar.selectedItem } ?? 0

        // Rebuild items with new colors
        bar.items = buildTabItems()

        // Restore selection
        if let items = bar.items, currentSelectedIndex < items.count, currentSelectedIndex != searchItemIndex {
            bar.selectedItem = items[currentSelectedIndex]
        }
    }

    func view() -> UIView {
        return container
    }

    // MARK: - UITabBarDelegate

    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        // Check if search item was tapped
        if item.tag == 9999 {
            // Don't restore previous selection - let search tab stay selected
            // This matches adaptive_platform_ui behavior
            // Notify Flutter search was activated
            channel.invokeMethod("searchActiveChanged", arguments: ["isActive": true])
            return
        }

        // Regular tab item
        if let items = tabBar.items, let index = items.firstIndex(of: item) {
            selectedIndex = index
            channel.invokeMethod("valueChanged", arguments: ["index": index])
        }
    }
}
