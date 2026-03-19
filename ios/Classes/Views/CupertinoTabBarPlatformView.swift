import Flutter
import UIKit
import SVGKit

class CupertinoTabBarPlatformView: NSObject, FlutterPlatformView, UITabBarDelegate, UITabBarControllerDelegate {
  private let channel: FlutterMethodChannel
  private let container: UIView
  private var tabBar: UITabBar?
  private var splitTabBarController: UITabBarController?
  private static let actionButtonTag = 9999

  // MARK: - State Properties
  private var isSplit: Bool = false
  private var rightCountVal: Int = 1
  private var currentLabels: [String] = []
  private var currentSymbols: [String] = []
  private var currentActiveSymbols: [String] = []
  private var currentBadges: [String] = []
  private var currentCustomIconBytes: [Data?] = []
  private var currentActiveCustomIconBytes: [Data?] = []
  private var currentImageAssetPaths: [String] = []
  private var currentActiveImageAssetPaths: [String] = []
  private var currentImageAssetData: [Data?] = []
  private var currentActiveImageAssetData: [Data?] = []
  private var currentImageAssetFormats: [String] = []
  private var currentActiveImageAssetFormats: [String] = []
  private var iconScale: CGFloat = UIScreen.main.scale
  private var leftInsetVal: CGFloat = 0
  private var rightInsetVal: CGFloat = 0
  private var splitSpacingVal: CGFloat = 12
  private var currentIconSizes: [CGFloat] = []
  private var currentLabelStyle: [String: Any]? = nil
  private var currentItemPaddings: [[Double]]? = nil
  private var forceCompactLayout: Bool = true
  private var currentColors: [NSNumber?] = []
  private var currentActiveColors: [NSNumber?] = []
  private var currentBadgeColors: [NSNumber?] = []
  private var currentBadgeTextColors: [NSNumber?] = []
  private var currentBadgeDotSizes: [NSNumber?] = []
  private var currentBadgeFontSizes: [NSNumber?] = []
  private var activeSingleConstraints: [NSLayoutConstraint] = []

  init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
    self.channel = FlutterMethodChannel(name: "CupertinoNativeTabBar_\(viewId)", binaryMessenger: messenger)
    self.container = UIView(frame: frame)

    var labels: [String] = []
    var symbols: [String] = []
    var activeSymbols: [String] = []
    var badges: [String] = []
    var customIconBytes: [Data?] = []
    var activeCustomIconBytes: [Data?] = []
    var imageAssetPaths: [String] = []
    var activeImageAssetPaths: [String] = []
    var imageAssetData: [Data?] = []
    var activeImageAssetData: [Data?] = []
    var imageAssetFormats: [String] = []
    var activeImageAssetFormats: [String] = []
    var iconScale: CGFloat = UIScreen.main.scale
    var sizes: [NSNumber?] = []
    var colors: [NSNumber?] = []
    var activeColors: [NSNumber?] = []
    var selectedIndex: Int = 0
    var isDark: Bool = false
    var tint: UIColor? = nil
    var bg: UIColor? = nil
    var split: Bool = false
    var rightCount: Int = 1
    var leftInset: CGFloat = 0
    var rightInset: CGFloat = 0

    if let dict = args as? [String: Any] {
      labels = (dict["labels"] as? [String]) ?? []
      symbols = (dict["sfSymbols"] as? [String]) ?? []
      activeSymbols = (dict["activeSfSymbols"] as? [String]) ?? []
      badges = (dict["badges"] as? [String]) ?? []
      if let bytesArray = dict["customIconBytes"] as? [FlutterStandardTypedData?] {
        customIconBytes = bytesArray.map { $0?.data }
      }
      if let bytesArray = dict["activeCustomIconBytes"] as? [FlutterStandardTypedData?] {
        activeCustomIconBytes = bytesArray.map { $0?.data }
      }
      imageAssetPaths = (dict["imageAssetPaths"] as? [String]) ?? []
      activeImageAssetPaths = (dict["activeImageAssetPaths"] as? [String]) ?? []
      if let bytesArray = dict["imageAssetData"] as? [FlutterStandardTypedData?] {
        imageAssetData = bytesArray.map { $0?.data }
      }
      if let bytesArray = dict["activeImageAssetData"] as? [FlutterStandardTypedData?] {
        activeImageAssetData = bytesArray.map { $0?.data }
      }
      imageAssetFormats = (dict["imageAssetFormats"] as? [String]) ?? []
      activeImageAssetFormats = (dict["activeImageAssetFormats"] as? [String]) ?? []
      if let scale = dict["iconScale"] as? NSNumber {
        iconScale = CGFloat(truncating: scale)
      }
      sizes = (dict["sfSymbolSizes"] as? [NSNumber?]) ?? []
      colors = (dict["sfSymbolColors"] as? [NSNumber?]) ?? []
      activeColors = (dict["sfSymbolActiveColors"] as? [NSNumber?]) ?? []
      if let v = dict["selectedIndex"] as? NSNumber { selectedIndex = v.intValue }
      if let v = dict["isDark"] as? NSNumber { isDark = v.boolValue }
      if let style = dict["style"] as? [String: Any] {
        if let n = style["tint"] as? NSNumber { tint = Self.colorFromARGB(n.intValue) }
      }
      if let s = dict["split"] as? NSNumber { split = s.boolValue }
      if let rc = dict["rightCount"] as? NSNumber { rightCount = rc.intValue }
      if let sp = dict["splitSpacing"] as? NSNumber { splitSpacingVal = CGFloat(truncating: sp) }
      if let ls = dict["labelStyle"] as? [String: Any] { currentLabelStyle = ls }
      if let ial = dict["forceCompactLayout"] as? NSNumber { self.forceCompactLayout = ial.boolValue }
      if let rawPaddings = dict["itemPaddings"] as? [Any] {
        currentItemPaddings = rawPaddings.map { element in
          if let arr = element as? [NSNumber] {
            return arr.map { $0.doubleValue }
          }
          return []
        }
      }
      currentBadgeColors = Self.extractNullableNumbers(dict["badgeColors"])
      currentBadgeTextColors = Self.extractNullableNumbers(dict["badgeTextColors"])
      currentBadgeDotSizes = Self.extractNullableNumbers(dict["badgeDotSizes"])
      currentBadgeFontSizes = Self.extractNullableNumbers(dict["badgeFontSizes"])
    }

    // Preload SVG assets dynamically based on what's actually being used
    let allAssetPaths = Set(imageAssetPaths + activeImageAssetPaths).filter { !$0.isEmpty }
    if !allAssetPaths.isEmpty {
      SVGImageLoader.shared.preloadAssetsFromPaths(Array(allAssetPaths))
    }

    super.init()

    container.backgroundColor = .clear
    // On iOS 26+, the Liquid Glass tab bar needs to overflow slightly for the pill effect
    // On older iOS, keep clipsToBounds to prevent visual artifacts
    if #available(iOS 26.0, *) {
      container.clipsToBounds = false
    } else {
      container.clipsToBounds = true // Prevent shadow leakage on older iOS
    }
    container.layer.shadowOpacity = 0 // Explicitly disable layer shadow
    if #available(iOS 13.0, *) { container.overrideUserInterfaceStyle = isDark ? .dark : .light }

    let appearance: UITabBarAppearance? = {
    if #available(iOS 13.0, *) {
      let ap = UITabBarAppearance()
      ap.configureWithDefaultBackground()
      ap.backgroundColor = .clear
      ap.shadowColor = .clear
      ap.shadowImage = UIImage()
      Self.applyLabelStyle(to: ap, labelStyle: self.currentLabelStyle, tint: tint)
      let hasCustomBadgeSizing =
        Self.hasAnyPositive(values: self.currentBadgeDotSizes) ||
        Self.hasAnyPositive(values: self.currentBadgeFontSizes)
      let badgeBackground = Self.firstNonNilColor(colors: self.currentBadgeColors)
      let badgeText = Self.firstNonNilColor(colors: self.currentBadgeTextColors)
      let badgeFontSize = hasCustomBadgeSizing
        ? nil
        : Self.firstNonNilCGFloat(values: self.currentBadgeFontSizes)
      Self.applyBadgeStyle(to: ap, badgeBackground: badgeBackground, badgeText: badgeText, badgeFontSize: badgeFontSize)
      return ap
    }
    return nil
  }()
    func buildItems(_ range: Range<Int>) -> [UITabBarItem] {
      var items: [UITabBarItem] = []
      for i in range {
        var image: UIImage? = nil
        var selectedImage: UIImage? = nil

        // Extract size for this item from sizes array
        let imgSize: CGSize? = (i < sizes.count) ? sizes[i].flatMap { $0.doubleValue > 0 ? CGSize(width: $0.doubleValue, height: $0.doubleValue) : nil } : nil

        // Priority: imageAsset > customIconBytes > SF Symbol
        // Unselected image
        if i < imageAssetData.count, let data = imageAssetData[i] {
          image = Self.createImageFromData(data, format: (i < imageAssetFormats.count) ? imageAssetFormats[i] : nil, scale: iconScale, size: imgSize)
        } else if i < imageAssetPaths.count && !imageAssetPaths[i].isEmpty {
          image = Self.loadFlutterAsset(imageAssetPaths[i], size: imgSize)
        } else if i < customIconBytes.count, let data = customIconBytes[i] {
          image = UIImage(data: data, scale: self.iconScale)?.withRenderingMode(.alwaysTemplate)
        } else if i < symbols.count && !symbols[i].isEmpty {
          // Apply size configuration if specified
          if i < sizes.count, let sizeNum = sizes[i], sizeNum.doubleValue > 0 {
            let config = UIImage.SymbolConfiguration(pointSize: CGFloat(sizeNum.doubleValue))
            image = UIImage(systemName: symbols[i], withConfiguration: config)
          } else {
            image = UIImage(systemName: symbols[i])
          }
        }

        // Selected image: Use active versions if available
        if i < activeImageAssetData.count, let data = activeImageAssetData[i] {
          selectedImage = Self.createImageFromData(data, format: (i < activeImageAssetFormats.count) ? activeImageAssetFormats[i] : nil, scale: iconScale, size: imgSize)
        } else if i < activeImageAssetPaths.count && !activeImageAssetPaths[i].isEmpty {
          selectedImage = Self.loadFlutterAsset(activeImageAssetPaths[i], size: imgSize)
        } else if i < activeCustomIconBytes.count, let data = activeCustomIconBytes[i] {
          selectedImage = UIImage(data: data, scale: self.iconScale)?.withRenderingMode(.alwaysTemplate)
        } else if i < activeSymbols.count && !activeSymbols[i].isEmpty {
          // Apply size configuration if specified
          if i < sizes.count, let sizeNum = sizes[i], sizeNum.doubleValue > 0 {
            let config = UIImage.SymbolConfiguration(pointSize: CGFloat(sizeNum.doubleValue))
            selectedImage = UIImage(systemName: activeSymbols[i], withConfiguration: config)
          } else {
            selectedImage = UIImage(systemName: activeSymbols[i])
          }
        } else {
          selectedImage = image // Fallback to same image
        }

        let itemColor = Self.colorForItem(index: i, colors: colors)
        let activeItemColor = Self.colorForItem(index: i, colors: activeColors)
        if itemColor != nil {
          image = Self.applyItemColor(image, color: itemColor)
        }
        if activeItemColor != nil {
          selectedImage = Self.applyItemColor(selectedImage, color: activeItemColor)
        } else if itemColor != nil {
          selectedImage = Self.applyItemColor(selectedImage, color: itemColor)
        }
        let title = (i < labels.count && !labels[i].isEmpty) ? labels[i] : nil
        let item = UITabBarItem(title: title, image: image, selectedImage: selectedImage)
        let badge = i < badges.count ? badges[i] : ""
        Self.applyBadge(
          to: item,
          index: i,
          badge: badge,
          badgeColors: self.currentBadgeColors,
          badgeTextColors: self.currentBadgeTextColors,
          badgeDotSizes: self.currentBadgeDotSizes,
          badgeFontSizes: self.currentBadgeFontSizes
        )
        if i < sizes.count, let sizeNum = sizes[i], sizeNum.doubleValue > 25 {
          let offset = CGFloat(sizeNum.doubleValue - 25)
          item.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: offset)
        }
        Self.applyItemPadding(item, index: i, paddings: self.currentItemPaddings)
        items.append(item)
      }
      return items
    }
    let count = max(labels.count, symbols.count)
    if split && count > rightCount {
      NSLog("🧭 [CN_TABBAR_INIT_SPLIT] count=\(count) rightCount=\(rightCount) using UITabBarController")
      // Use UITabBarController so UIKit handles the Liquid Glass split layout natively.
      // The action button is added as a regular tab bar item; its tap is intercepted via the delegate.
      let tbc = UITabBarController()
      tbc.delegate = self
      self.splitTabBarController = tbc
      let items = buildItems(0..<count)
      var controllers: [UIViewController] = []
      for (i, item) in items.enumerated() {
        let vc = UIViewController()
        vc.view.backgroundColor = .clear
        // Use tabBarSystemItem: .search for the action button item so iOS 26
        // renders it as a separate Liquid Glass pill (the split effect).
        if i >= count - rightCount {
          let actionItem = UITabBarItem(tabBarSystemItem: .search, tag: Self.actionButtonTag + i)
          actionItem.image = item.image
          actionItem.selectedImage = item.selectedImage
          actionItem.title = item.title
          actionItem.badgeValue = item.badgeValue
          actionItem.badgeColor = item.badgeColor
          vc.tabBarItem = actionItem
        } else {
          item.tag = i
          vc.tabBarItem = item
        }
        controllers.append(vc)
      }
      // Apply trait overrides before setViewControllers so UIKit uses
      // the correct size class from the start (affects split layout spacing).
      if self.forceCompactLayout { Self.forceCompactTraits(on: tbc) } else { Self.clearTraitOverrides(on: tbc) }
      tbc.setViewControllers(controllers, animated: false)
      tbc.view.backgroundColor = .clear
      tbc.view.isOpaque = false
      let bar = tbc.tabBar
      bar.isTranslucent = true
      if self.forceCompactLayout { Self.forceCompactTraits(on: bar) } else { Self.clearTraitOverrides(on: bar) }
      // Resolve effective tint: label style activeColor takes priority over theme tint
      let labelActiveColor = (self.currentLabelStyle?["activeColor"] as? NSNumber).map { Self.colorFromARGB($0.intValue) }
      let labelColor = (self.currentLabelStyle?["color"] as? NSNumber).map { Self.colorFromARGB($0.intValue) }
      let effectiveTint = labelActiveColor ?? tint
      NSLog("🧭 [CN_TABBAR_INIT_SPLIT_COLORS] labelActiveColor=\(String(describing: labelActiveColor)) labelColor=\(String(describing: labelColor)) effectiveTint=\(String(describing: effectiveTint)) tint=\(String(describing: tint))")
      // Set tintColor at every level — iOS 26 Liquid Glass may read it from
      // different places depending on device/mode.
      if let t = effectiveTint {
        bar.tintColor = t
        tbc.view.tintColor = t
        container.tintColor = t
      }
      if let c = labelColor { bar.unselectedItemTintColor = c }
      if let ap = appearance { if #available(iOS 13.0, *) { bar.standardAppearance = ap; if #available(iOS 15.0, *) { bar.scrollEdgeAppearance = ap } } }
      // Apply label style to items synchronously
      if let vcs = tbc.viewControllers {
        Self.applyLabelStyleToItems(vcs.map { $0.tabBarItem }, tabBar: bar, labelStyle: self.currentLabelStyle, tint: effectiveTint)
      }
      // Set selection (skip action button indices)
      if selectedIndex >= 0 && selectedIndex < count - rightCount {
        tbc.selectedIndex = selectedIndex
      }
      // Add controller's view to container with edge-to-edge constraints
      tbc.view.translatesAutoresizingMaskIntoConstraints = false
      container.addSubview(tbc.view)
      NSLayoutConstraint.activate([
        tbc.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
        tbc.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        tbc.view.topAnchor.constraint(equalTo: container.topAnchor),
        tbc.view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
      ])
    } else {
      let bar = UITabBar(frame: .zero)
      tabBar = bar
      bar.delegate = self
      bar.translatesAutoresizingMaskIntoConstraints = false
      // On iOS 26+, allow overflow for Liquid Glass pill effect
      if #available(iOS 26.0, *) {
        bar.clipsToBounds = false
      } else {
        bar.clipsToBounds = true // Prevent shadow leakage on older iOS
      }
      bar.layer.shadowOpacity = 0
      // Resolve effective tint: label style activeColor takes priority over theme tint.
      let labelActiveColor = (self.currentLabelStyle?["activeColor"] as? NSNumber).map { Self.colorFromARGB($0.intValue) }
      let labelColor = (self.currentLabelStyle?["color"] as? NSNumber).map { Self.colorFromARGB($0.intValue) }
      let effectiveTint = labelActiveColor ?? tint
      if #available(iOS 10.0, *), let t = effectiveTint {
        bar.tintColor = t
        container.tintColor = t
      }
      if let c = labelColor { bar.unselectedItemTintColor = c }
      if let ap = appearance { if #available(iOS 13.0, *) { bar.standardAppearance = ap; if #available(iOS 15.0, *) { bar.scrollEdgeAppearance = ap } } }
      if self.forceCompactLayout { Self.forceCompactTraits(on: bar) } else { Self.clearTraitOverrides(on: bar) }
      bar.items = buildItems(0..<count)
      if let items = bar.items {
        Self.applyLabelStyleToItems(items, tabBar: bar, labelStyle: self.currentLabelStyle, tint: effectiveTint)
      }
      if selectedIndex >= 0, let items = bar.items, selectedIndex < items.count { bar.selectedItem = items[selectedIndex] }
      container.addSubview(bar)
      self.activeSingleConstraints = [
        bar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
        bar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        bar.topAnchor.constraint(equalTo: container.topAnchor),
        bar.bottomAnchor.constraint(equalTo: container.bottomAnchor),
      ]
      NSLayoutConstraint.activate(self.activeSingleConstraints)
      // Force layout update for background and text rendering on iOS < 16
      // Re-assign items after layout to ensure labels render properly
      DispatchQueue.main.async { [weak self, weak bar] in
        guard let self = self, let bar = bar else { return }
        self.container.setNeedsLayout()
        self.container.layoutIfNeeded()
        bar.setNeedsLayout()
        bar.layoutIfNeeded()
        // Re-assign items to force label rendering
        let items = bar.items
        bar.items = items
        // Force another update cycle for text rendering
        DispatchQueue.main.async { [weak bar] in
          guard let bar = bar else { return }
          bar.setNeedsDisplay()
          bar.setNeedsLayout()
          bar.layoutIfNeeded()
        }
      }
    }
    // Store split settings for future updates
    self.isSplit = split
    self.rightCountVal = rightCount
    self.currentLabels = labels
    self.currentSymbols = symbols
    self.currentActiveSymbols = activeSymbols
    self.currentBadges = badges
    self.currentCustomIconBytes = customIconBytes
    self.currentActiveCustomIconBytes = activeCustomIconBytes
    self.currentImageAssetPaths = imageAssetPaths
    self.currentActiveImageAssetPaths = activeImageAssetPaths
    self.currentImageAssetData = imageAssetData
    self.currentActiveImageAssetData = activeImageAssetData
    self.currentImageAssetFormats = imageAssetFormats
    self.currentActiveImageAssetFormats = activeImageAssetFormats
    self.iconScale = iconScale
    self.leftInsetVal = leftInset
    self.rightInsetVal = rightInset
    self.currentIconSizes = sizes.compactMap { $0 }.map { CGFloat(truncating: $0) }
    self.currentColors = colors
    self.currentActiveColors = activeColors
    // UIKit may normalize badge styling during initial layout. Re-apply badges
    // on the live items to ensure per-item badgeColor/dot settings stick.
    DispatchQueue.main.async { [weak self] in
      self?.applyCurrentBadgesToVisibleItems()
    }
channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { result(nil); return }
      switch call.method {
      case "getIntrinsicSize":
        if let bar = self.tabBar ?? self.splitTabBarController?.tabBar {
          let size = bar.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
          // Adjust height for larger icons - default icon is ~25pt, default height is ~49pt
          let defaultIconSize: CGFloat = 25.0
          let maxIconSize = self.currentIconSizes.max() ?? defaultIconSize
          let extraHeight = max(0, maxIconSize - defaultIconSize)
          let dynamicHeight = size.height + extraHeight
          result(["width": Double(size.width), "height": Double(dynamicHeight)])
        } else {
          result(["width": Double(self.container.bounds.width), "height": 50.0])
        }
      case "setItems":
        if let args = call.arguments as? [String: Any] {
          let labels = (args["labels"] as? [String]) ?? []
          let symbols = (args["sfSymbols"] as? [String]) ?? []
          let activeSymbols = (args["activeSfSymbols"] as? [String]) ?? []
          let badges = (args["badges"] as? [String]) ?? []
          let sizes = (args["sfSymbolSizes"] as? [NSNumber?]) ?? []
          var customIconBytes: [Data?] = []
          var activeCustomIconBytes: [Data?] = []
          var imageAssetPaths: [String] = []
          var activeImageAssetPaths: [String] = []
          var imageAssetData: [Data?] = []
          var activeImageAssetData: [Data?] = []
          var imageAssetFormats: [String] = []
          var activeImageAssetFormats: [String] = []
          if let bytesArray = args["customIconBytes"] as? [FlutterStandardTypedData?] {
            customIconBytes = bytesArray.map { $0?.data }
          }
          if let bytesArray = args["activeCustomIconBytes"] as? [FlutterStandardTypedData?] {
            activeCustomIconBytes = bytesArray.map { $0?.data }
          }
          imageAssetPaths = (args["imageAssetPaths"] as? [String]) ?? []
          activeImageAssetPaths = (args["activeImageAssetPaths"] as? [String]) ?? []
          if let bytesArray = args["imageAssetData"] as? [FlutterStandardTypedData?] {
            imageAssetData = bytesArray.map { $0?.data }
          }
          if let bytesArray = args["activeImageAssetData"] as? [FlutterStandardTypedData?] {
            activeImageAssetData = bytesArray.map { $0?.data }
          }
          imageAssetFormats = (args["imageAssetFormats"] as? [String]) ?? []
          activeImageAssetFormats = (args["activeImageAssetFormats"] as? [String]) ?? []
          if let scale = args["iconScale"] as? NSNumber {
            self.iconScale = CGFloat(truncating: scale)
          }
          let selectedIndex = (args["selectedIndex"] as? NSNumber)?.intValue ?? 0
          self.currentLabels = labels
          self.currentSymbols = symbols
          self.currentActiveSymbols = activeSymbols
          self.currentBadges = badges
          self.currentCustomIconBytes = customIconBytes
          self.currentActiveCustomIconBytes = activeCustomIconBytes
          self.currentImageAssetPaths = imageAssetPaths
          self.currentActiveImageAssetPaths = activeImageAssetPaths
          self.currentImageAssetData = imageAssetData
          self.currentActiveImageAssetData = activeImageAssetData
          self.currentImageAssetFormats = imageAssetFormats
          self.currentActiveImageAssetFormats = activeImageAssetFormats
          self.currentIconSizes = sizes.compactMap { $0?.doubleValue }.map { CGFloat($0) }
          let colors = (args["sfSymbolColors"] as? [NSNumber?]) ?? self.currentColors
          self.currentColors = colors
          let activeColors = (args["sfSymbolActiveColors"] as? [NSNumber?]) ?? self.currentActiveColors
          self.currentActiveColors = activeColors
          let badgeColors = args["badgeColors"] != nil ? Self.extractNullableNumbers(args["badgeColors"]) : self.currentBadgeColors
          self.currentBadgeColors = badgeColors
          let badgeTextColors = args["badgeTextColors"] != nil ? Self.extractNullableNumbers(args["badgeTextColors"]) : self.currentBadgeTextColors
          self.currentBadgeTextColors = badgeTextColors
          let badgeDotSizes = args["badgeDotSizes"] != nil ? Self.extractNullableNumbers(args["badgeDotSizes"]) : self.currentBadgeDotSizes
          self.currentBadgeDotSizes = badgeDotSizes
          let badgeFontSizes = args["badgeFontSizes"] != nil ? Self.extractNullableNumbers(args["badgeFontSizes"]) : self.currentBadgeFontSizes
          self.currentBadgeFontSizes = badgeFontSizes
          func buildItems(_ range: Range<Int>) -> [UITabBarItem] {
            var items: [UITabBarItem] = []
            for i in range {
              var image: UIImage? = nil
              var selectedImage: UIImage? = nil

              let imgSize: CGSize? = (i < sizes.count) ? sizes[i].flatMap { $0.doubleValue > 0 ? CGSize(width: $0.doubleValue, height: $0.doubleValue) : nil } : nil

              if i < imageAssetData.count, let data = imageAssetData[i] {
                image = Self.createImageFromData(data, format: (i < imageAssetFormats.count) ? imageAssetFormats[i] : nil, scale: self.iconScale, size: imgSize)
              } else if i < imageAssetPaths.count && !imageAssetPaths[i].isEmpty {
                image = Self.loadFlutterAsset(imageAssetPaths[i], size: imgSize)
              } else if i < customIconBytes.count, let data = customIconBytes[i] {
                image = UIImage(data: data, scale: self.iconScale)?.withRenderingMode(.alwaysTemplate)
              } else if i < symbols.count && !symbols[i].isEmpty {
                if i < sizes.count, let sizeNum = sizes[i], sizeNum.doubleValue > 0 {
                  let config = UIImage.SymbolConfiguration(pointSize: CGFloat(sizeNum.doubleValue))
                  image = UIImage(systemName: symbols[i], withConfiguration: config)
                } else {
                  image = UIImage(systemName: symbols[i])
                }
              }

              if i < activeImageAssetData.count, let data = activeImageAssetData[i] {
                selectedImage = Self.createImageFromData(data, format: (i < activeImageAssetFormats.count) ? activeImageAssetFormats[i] : nil, scale: self.iconScale, size: imgSize)
              } else if i < activeImageAssetPaths.count && !activeImageAssetPaths[i].isEmpty {
                selectedImage = Self.loadFlutterAsset(activeImageAssetPaths[i], size: imgSize)
              } else if i < activeCustomIconBytes.count, let data = activeCustomIconBytes[i] {
                selectedImage = UIImage(data: data, scale: self.iconScale)?.withRenderingMode(.alwaysTemplate)
              } else if i < activeSymbols.count && !activeSymbols[i].isEmpty {
                if i < sizes.count, let sizeNum = sizes[i], sizeNum.doubleValue > 0 {
                  let config = UIImage.SymbolConfiguration(pointSize: CGFloat(sizeNum.doubleValue))
                  selectedImage = UIImage(systemName: activeSymbols[i], withConfiguration: config)
                } else {
                  selectedImage = UIImage(systemName: activeSymbols[i])
                }
              } else {
                selectedImage = image
              }

              let itemColor = Self.colorForItem(index: i, colors: colors)
              let activeItemColor = Self.colorForItem(index: i, colors: activeColors)
              if itemColor != nil {
                image = Self.applyItemColor(image, color: itemColor)
              }
              if activeItemColor != nil {
                selectedImage = Self.applyItemColor(selectedImage, color: activeItemColor)
              } else if itemColor != nil {
                selectedImage = Self.applyItemColor(selectedImage, color: itemColor)
              }
              let title = (i < labels.count && !labels[i].isEmpty) ? labels[i] : nil
              let item = UITabBarItem(title: title, image: image, selectedImage: selectedImage)
              let badge = i < badges.count ? badges[i] : ""
              Self.applyBadge(
                to: item,
                index: i,
                badge: badge,
                badgeColors: badgeColors,
                badgeTextColors: badgeTextColors,
                badgeDotSizes: badgeDotSizes,
                badgeFontSizes: badgeFontSizes
              )
              if i < sizes.count, let sizeNum = sizes[i] {
                let pointSize = sizeNum.doubleValue
                if pointSize > 25 {
                  let offset = CGFloat(pointSize - 25)
                  item.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: offset)
                }
              }
              Self.applyItemPadding(item, index: i, paddings: self.currentItemPaddings)
              items.append(item)
            }
            return items
          }
          let count = max(labels.count, symbols.count)
          if self.isSplit && count > self.rightCountVal, let tbc = self.splitTabBarController, let vcs = tbc.viewControllers {
            let items = buildItems(0..<count)
            for (i, item) in items.enumerated() {
              guard i < vcs.count else { break }
              let vc = vcs[i]
              if vc.tabBarItem.tag >= Self.actionButtonTag {
                // Preserve the system item tag; update icon/title/badge
                vc.tabBarItem.image = item.image
                vc.tabBarItem.selectedImage = item.selectedImage
                vc.tabBarItem.title = item.title
                vc.tabBarItem.badgeValue = item.badgeValue
                vc.tabBarItem.badgeColor = item.badgeColor
              } else {
                item.tag = i
                vc.tabBarItem = item
              }
            }
            if selectedIndex >= 0 && selectedIndex < count - self.rightCountVal {
              tbc.selectedIndex = selectedIndex
            }
            // Apply label style directly to items for iPad inline layout
            Self.applyLabelStyleToItems(vcs.map { $0.tabBarItem }, tabBar: tbc.tabBar, labelStyle: self.currentLabelStyle, tint: tbc.tabBar.tintColor)
            self.applyCurrentBadgesToVisibleItems()
            result(nil)
          } else if let bar = self.tabBar {
            bar.items = buildItems(0..<count)
            if let items = bar.items, selectedIndex >= 0, selectedIndex < items.count { bar.selectedItem = items[selectedIndex] }
            if let items = bar.items {
              Self.applyLabelStyleToItems(items, tabBar: bar, labelStyle: self.currentLabelStyle, tint: bar.tintColor)
            }
            self.applyCurrentBadgesToVisibleItems()
            result(nil)
          } else {
            result(FlutterError(code: "state_error", message: "Tab bars not initialized", details: nil))
          }
        } else { result(FlutterError(code: "bad_args", message: "Missing items", details: nil)) }
      case "setLayout":
        if let args = call.arguments as? [String: Any] {
          let split = (args["split"] as? NSNumber)?.boolValue ?? false
          let rightCount = (args["rightCount"] as? NSNumber)?.intValue ?? 1
          // Insets are controlled by Flutter padding; keep stored zeros here
          let leftInset = self.leftInsetVal
          let rightInset = self.rightInsetVal
          if let sp = args["splitSpacing"] as? NSNumber { self.splitSpacingVal = CGFloat(truncating: sp) }
          if let ial = args["forceCompactLayout"] as? NSNumber { self.forceCompactLayout = ial.boolValue }
          let dartAvailableWidth = (args["availableWidth"] as? NSNumber).map { CGFloat($0.doubleValue) }
          let selectedIndex = (args["selectedIndex"] as? NSNumber)?.intValue ?? 0
          // Remove existing bars and controllers
          NSLayoutConstraint.deactivate(self.activeSingleConstraints)
          self.activeSingleConstraints = []
          self.tabBar?.removeFromSuperview(); self.tabBar = nil
          self.splitTabBarController?.view.removeFromSuperview(); self.splitTabBarController = nil
          let labels = self.currentLabels
          let symbols = self.currentSymbols
          let activeSymbols = self.currentActiveSymbols
          let badges = self.currentBadges
          let customIconBytes = self.currentCustomIconBytes
          let activeCustomIconBytes = self.currentActiveCustomIconBytes
          let imageAssetPaths = self.currentImageAssetPaths
          let activeImageAssetPaths = self.currentActiveImageAssetPaths
          let imageAssetData = self.currentImageAssetData
          let activeImageAssetData = self.currentActiveImageAssetData
          let imageAssetFormats = self.currentImageAssetFormats
          let activeImageAssetFormats = self.currentActiveImageAssetFormats
          let labelStyle = self.currentLabelStyle
          let appearance: UITabBarAppearance? = {
            if #available(iOS 13.0, *) {
              let ap = UITabBarAppearance()
              ap.configureWithDefaultBackground()
      ap.backgroundColor = .clear
              ap.shadowColor = .clear
              ap.shadowImage = UIImage()
              Self.applyLabelStyle(to: ap, labelStyle: labelStyle, tint: nil)
              let hasCustomBadgeSizing =
                Self.hasAnyPositive(values: self.currentBadgeDotSizes) ||
                Self.hasAnyPositive(values: self.currentBadgeFontSizes)
              let badgeBackground = Self.firstNonNilColor(colors: self.currentBadgeColors)
              let badgeText = Self.firstNonNilColor(colors: self.currentBadgeTextColors)
              let badgeFontSize = hasCustomBadgeSizing
                ? nil
                : Self.firstNonNilCGFloat(values: self.currentBadgeFontSizes)
              Self.applyBadgeStyle(to: ap, badgeBackground: badgeBackground, badgeText: badgeText, badgeFontSize: badgeFontSize)
              return ap
            }
            return nil
          }()
          let iconSizes = self.currentIconSizes
          let colors = self.currentColors
          let activeColors = self.currentActiveColors
          let badgeColors = self.currentBadgeColors
          let badgeTextColors = self.currentBadgeTextColors
          let badgeDotSizes = self.currentBadgeDotSizes
          let badgeFontSizes = self.currentBadgeFontSizes
          func buildItems(_ range: Range<Int>) -> [UITabBarItem] {
            var items: [UITabBarItem] = []
            for i in range {
              var image: UIImage? = nil
              var selectedImage: UIImage? = nil
              let imgSize: CGSize? = (i < iconSizes.count && iconSizes[i] > 0) ? CGSize(width: iconSizes[i], height: iconSizes[i]) : nil

              if i < imageAssetData.count, let data = imageAssetData[i] {
                image = Self.createImageFromData(data, format: (i < imageAssetFormats.count) ? imageAssetFormats[i] : nil, scale: self.iconScale, size: imgSize)
              } else if i < imageAssetPaths.count && !imageAssetPaths[i].isEmpty {
                image = Self.loadFlutterAsset(imageAssetPaths[i], size: imgSize)
              } else if i < customIconBytes.count, let data = customIconBytes[i] {
                image = UIImage(data: data, scale: self.iconScale)?.withRenderingMode(.alwaysTemplate)
              } else if i < symbols.count && !symbols[i].isEmpty {
                if i < iconSizes.count && iconSizes[i] > 0 {
                  let config = UIImage.SymbolConfiguration(pointSize: iconSizes[i])
                  image = UIImage(systemName: symbols[i], withConfiguration: config)
                } else {
                  image = UIImage(systemName: symbols[i])
                }
              }

              if i < activeImageAssetData.count, let data = activeImageAssetData[i] {
                selectedImage = Self.createImageFromData(data, format: (i < activeImageAssetFormats.count) ? activeImageAssetFormats[i] : nil, scale: self.iconScale, size: imgSize)
              } else if i < activeImageAssetPaths.count && !activeImageAssetPaths[i].isEmpty {
                selectedImage = Self.loadFlutterAsset(activeImageAssetPaths[i], size: imgSize)
              } else if i < activeCustomIconBytes.count, let data = activeCustomIconBytes[i] {
                selectedImage = UIImage(data: data, scale: self.iconScale)?.withRenderingMode(.alwaysTemplate)
              } else if i < activeSymbols.count && !activeSymbols[i].isEmpty {
                if i < iconSizes.count && iconSizes[i] > 0 {
                  let config = UIImage.SymbolConfiguration(pointSize: iconSizes[i])
                  selectedImage = UIImage(systemName: activeSymbols[i], withConfiguration: config)
                } else {
                  selectedImage = UIImage(systemName: activeSymbols[i])
                }
              } else {
                selectedImage = image
              }

              let itemColor = Self.colorForItem(index: i, colors: colors)
              let activeItemColor = Self.colorForItem(index: i, colors: activeColors)
              if itemColor != nil {
                image = Self.applyItemColor(image, color: itemColor)
              }
              if activeItemColor != nil {
                selectedImage = Self.applyItemColor(selectedImage, color: activeItemColor)
              } else if itemColor != nil {
                selectedImage = Self.applyItemColor(selectedImage, color: itemColor)
              }
              let title = (i < labels.count && !labels[i].isEmpty) ? labels[i] : nil
              let item = UITabBarItem(title: title, image: image, selectedImage: selectedImage)
              let badge = i < badges.count ? badges[i] : ""
              Self.applyBadge(
                to: item,
                index: i,
                badge: badge,
                badgeColors: badgeColors,
                badgeTextColors: badgeTextColors,
                badgeDotSizes: badgeDotSizes,
                badgeFontSizes: badgeFontSizes
              )
              Self.applyItemPadding(item, index: i, paddings: self.currentItemPaddings)
              items.append(item)
            }
            return items
          }
          let count = max(labels.count, symbols.count)
          if split && count > rightCount {
            NSLog("🧭 [CN_TABBAR_SETLAYOUT_SPLIT] count=\(count) rightCount=\(rightCount) using UITabBarController")
            let tbc = UITabBarController()
            tbc.delegate = self
            self.splitTabBarController = tbc
            let items = buildItems(0..<count)
            var controllers: [UIViewController] = []
            for (i, item) in items.enumerated() {
              let vc = UIViewController()
              vc.view.backgroundColor = .clear
              if i >= count - rightCount {
                let actionItem = UITabBarItem(tabBarSystemItem: .search, tag: Self.actionButtonTag + i)
                actionItem.image = item.image
                actionItem.selectedImage = item.selectedImage
                actionItem.title = item.title
                actionItem.badgeValue = item.badgeValue
                actionItem.badgeColor = item.badgeColor
                vc.tabBarItem = actionItem
              } else {
                item.tag = i
                vc.tabBarItem = item
              }
              controllers.append(vc)
            }
            if self.forceCompactLayout { Self.forceCompactTraits(on: tbc) } else { Self.clearTraitOverrides(on: tbc) }
            tbc.setViewControllers(controllers, animated: false)
            tbc.view.backgroundColor = .clear
            tbc.view.isOpaque = false
            let bar = tbc.tabBar
            bar.isTranslucent = true
            if self.forceCompactLayout { Self.forceCompactTraits(on: bar) } else { Self.clearTraitOverrides(on: bar) }
            let labelActiveColor = (self.currentLabelStyle?["activeColor"] as? NSNumber).map { Self.colorFromARGB($0.intValue) }
            let labelColor = (self.currentLabelStyle?["color"] as? NSNumber).map { Self.colorFromARGB($0.intValue) }
            let argsTint = (args["tint"] as? NSNumber).map { Self.colorFromARGB($0.intValue) }
            let effectiveTint = labelActiveColor ?? argsTint ?? bar.tintColor
            bar.tintColor = effectiveTint
            tbc.view.tintColor = effectiveTint
            self.container.tintColor = effectiveTint
            if let c = labelColor { bar.unselectedItemTintColor = c }
            if let ap = appearance { if #available(iOS 13.0, *) { bar.standardAppearance = ap; if #available(iOS 15.0, *) { bar.scrollEdgeAppearance = ap } } }
            if let vcs = tbc.viewControllers {
              Self.applyLabelStyleToItems(vcs.map { $0.tabBarItem }, tabBar: bar, labelStyle: self.currentLabelStyle, tint: effectiveTint)
            }
            if selectedIndex >= 0 && selectedIndex < count - rightCount {
              tbc.selectedIndex = selectedIndex
            }
            tbc.view.translatesAutoresizingMaskIntoConstraints = false
            self.container.addSubview(tbc.view)
            NSLayoutConstraint.activate([
              tbc.view.leadingAnchor.constraint(equalTo: self.container.leadingAnchor),
              tbc.view.trailingAnchor.constraint(equalTo: self.container.trailingAnchor),
              tbc.view.topAnchor.constraint(equalTo: self.container.topAnchor),
              tbc.view.bottomAnchor.constraint(equalTo: self.container.bottomAnchor),
            ])
          } else {
            let bar = UITabBar(frame: .zero)
            self.tabBar = bar
            bar.delegate = self
            bar.translatesAutoresizingMaskIntoConstraints = false
            // On iOS 26+, allow overflow for Liquid Glass pill effect
            if #available(iOS 26.0, *) {
              bar.clipsToBounds = false
            } else {
              bar.clipsToBounds = true
            }
            bar.layer.shadowOpacity = 0
            let labelActiveColor = (self.currentLabelStyle?["activeColor"] as? NSNumber).map { Self.colorFromARGB($0.intValue) }
            let labelColor = (self.currentLabelStyle?["color"] as? NSNumber).map { Self.colorFromARGB($0.intValue) }
            let argsTint = (args["tint"] as? NSNumber).map { Self.colorFromARGB($0.intValue) }
            let effectiveTint = labelActiveColor ?? argsTint ?? bar.tintColor
            bar.tintColor = effectiveTint
            self.container.tintColor = effectiveTint
            if let c = labelColor { bar.unselectedItemTintColor = c }
            if let ap = appearance { if #available(iOS 13.0, *) { bar.standardAppearance = ap; if #available(iOS 15.0, *) { bar.scrollEdgeAppearance = ap } } }
            if self.forceCompactLayout { Self.forceCompactTraits(on: bar) } else { Self.clearTraitOverrides(on: bar) }
            bar.items = buildItems(0..<count)
            if let items = bar.items {
              Self.applyLabelStyleToItems(items, tabBar: bar, labelStyle: self.currentLabelStyle, tint: effectiveTint)
            }
            if let items = bar.items, selectedIndex >= 0, selectedIndex < items.count { bar.selectedItem = items[selectedIndex] }
            self.container.addSubview(bar)
            self.activeSingleConstraints = [
              bar.leadingAnchor.constraint(equalTo: self.container.leadingAnchor),
              bar.trailingAnchor.constraint(equalTo: self.container.trailingAnchor),
              bar.topAnchor.constraint(equalTo: self.container.topAnchor),
              bar.bottomAnchor.constraint(equalTo: self.container.bottomAnchor),
            ]
            NSLayoutConstraint.activate(self.activeSingleConstraints)
            // Force layout update for background and text rendering on iOS < 16
            // Re-assign items after layout to ensure labels render properly
            DispatchQueue.main.async { [weak self, weak bar] in
              guard let self = self, let bar = bar else { return }
              self.container.setNeedsLayout()
              self.container.layoutIfNeeded()
              bar.setNeedsLayout()
              bar.layoutIfNeeded()
              // Re-assign items to force label rendering
              let items = bar.items
              bar.items = items
              // Force another update cycle for text rendering
              DispatchQueue.main.async { [weak bar] in
                guard let bar = bar else { return }
                bar.setNeedsDisplay()
                bar.setNeedsLayout()
                bar.layoutIfNeeded()
              }
            }
          }
          self.isSplit = split; self.rightCountVal = rightCount; self.leftInsetVal = leftInset; self.rightInsetVal = rightInset
          self.applyCurrentBadgesToVisibleItems()
          result(nil)
        } else { result(FlutterError(code: "bad_args", message: "Missing layout", details: nil)) }
      case "setSelectedIndex":
        if let args = call.arguments as? [String: Any], let idx = (args["index"] as? NSNumber)?.intValue {
          // Single bar
          if let bar = self.tabBar, let items = bar.items, idx >= 0, idx < items.count {
            bar.selectedItem = items[idx]
            result(nil)
            return
          }
          // Split (UITabBarController)
          if let tbc = self.splitTabBarController, let vcs = tbc.viewControllers {
            let regularCount = vcs.filter { $0.tabBarItem.tag < Self.actionButtonTag }.count
            if idx >= 0 && idx < regularCount {
              tbc.selectedIndex = idx
              result(nil)
              return
            }
          }
          result(FlutterError(code: "bad_args", message: "Index out of range", details: nil))
        } else { result(FlutterError(code: "bad_args", message: "Missing index", details: nil)) }
      case "setStyle":
        if let args = call.arguments as? [String: Any] {
          NSLog("🧭 [CN_TABBAR_SET_STYLE] args=\(args) currentLabelStyle=\(String(describing: self.currentLabelStyle))")
          var tintColor: UIColor? = nil
          if let n = args["tint"] as? NSNumber {
            let c = Self.colorFromARGB(n.intValue)
            tintColor = c
            // Only set tintColor if the label style doesn't define activeColor,
            // since activeColor should take priority for the selected tab color.
            let labelActiveColor = (self.currentLabelStyle?["activeColor"] as? NSNumber).map { Self.colorFromARGB($0.intValue) }
            let effectiveTint = labelActiveColor ?? c
            if let bar = self.tabBar { bar.tintColor = effectiveTint }
            if let tbc = self.splitTabBarController {
              tbc.tabBar.tintColor = effectiveTint
              tbc.view.tintColor = effectiveTint
              self.container.tintColor = effectiveTint
            }
            // Also set unselectedItemTintColor if label style defines color
            if let labelColor = (self.currentLabelStyle?["color"] as? NSNumber).map({ Self.colorFromARGB($0.intValue) }) {
              self.tabBar?.unselectedItemTintColor = labelColor
              self.splitTabBarController?.tabBar.unselectedItemTintColor = labelColor
            }
          }
          let hasClearLabelStyle = (args["clearLabelStyle"] as? NSNumber)?.boolValue == true
          if let ls = args["labelStyle"] as? [String: Any] {
            self.currentLabelStyle = ls
          } else if hasClearLabelStyle {
            self.currentLabelStyle = nil
          }
          if args["labelStyle"] is [String: Any] || hasClearLabelStyle {
            if #available(iOS 13.0, *) {
              let allBars: [UITabBar] = [self.tabBar, self.splitTabBarController?.tabBar].compactMap { $0 }
              for bar in allBars {
                let ap = UITabBarAppearance()
                ap.configureWithDefaultBackground()
      ap.backgroundColor = .clear
                ap.shadowColor = .clear
                ap.shadowImage = UIImage()
                Self.applyLabelStyle(to: ap, labelStyle: self.currentLabelStyle, tint: tintColor ?? bar.tintColor)
                let hasCustomBadgeSizing =
                  Self.hasAnyPositive(values: self.currentBadgeDotSizes) ||
                  Self.hasAnyPositive(values: self.currentBadgeFontSizes)
                let badgeBackground = Self.firstNonNilColor(colors: self.currentBadgeColors)
                let badgeText = Self.firstNonNilColor(colors: self.currentBadgeTextColors)
                let badgeFontSize = hasCustomBadgeSizing
                  ? nil
                  : Self.firstNonNilCGFloat(values: self.currentBadgeFontSizes)
                Self.applyBadgeStyle(to: ap, badgeBackground: badgeBackground, badgeText: badgeText, badgeFontSize: badgeFontSize)
                bar.standardAppearance = ap
                if #available(iOS 15.0, *) { bar.scrollEdgeAppearance = ap }
              }
              // Re-apply per-item badges after appearance updates, since
              // UITabBarAppearance assignment can reset badge styling.
              self.applyCurrentBadgesToVisibleItems()
            }
          }
          // Apply label style directly to items for iPad inline layout compatibility
          if let vcs = self.splitTabBarController?.viewControllers {
            Self.applyLabelStyleToItems(vcs.map { $0.tabBarItem }, tabBar: self.splitTabBarController?.tabBar, labelStyle: self.currentLabelStyle, tint: tintColor ?? self.splitTabBarController?.tabBar.tintColor)
          }
          if let bar = self.tabBar, let items = bar.items {
            Self.applyLabelStyleToItems(items, tabBar: bar, labelStyle: self.currentLabelStyle, tint: tintColor ?? bar.tintColor)
          }
          result(nil)
        } else { result(FlutterError(code: "bad_args", message: "Missing style", details: nil)) }
      case "setBrightness":
        if let args = call.arguments as? [String: Any], let isDark = (args["isDark"] as? NSNumber)?.boolValue {
          if #available(iOS 13.0, *) { self.container.overrideUserInterfaceStyle = isDark ? .dark : .light }
          result(nil)
        } else { result(FlutterError(code: "bad_args", message: "Missing isDark", details: nil)) }
      case "setBadges":
        // Lightweight badge-only update without rebuilding items
        if let args = call.arguments as? [String: Any], let badges = args["badges"] as? [String] {
          self.currentBadges = badges
          let badgeColors = args["badgeColors"] != nil ? Self.extractNullableNumbers(args["badgeColors"]) : self.currentBadgeColors
          self.currentBadgeColors = badgeColors
          let badgeTextColors = args["badgeTextColors"] != nil ? Self.extractNullableNumbers(args["badgeTextColors"]) : self.currentBadgeTextColors
          self.currentBadgeTextColors = badgeTextColors
          let badgeDotSizes = args["badgeDotSizes"] != nil ? Self.extractNullableNumbers(args["badgeDotSizes"]) : self.currentBadgeDotSizes
          self.currentBadgeDotSizes = badgeDotSizes
          let badgeFontSizes = args["badgeFontSizes"] != nil ? Self.extractNullableNumbers(args["badgeFontSizes"]) : self.currentBadgeFontSizes
          self.currentBadgeFontSizes = badgeFontSizes
          if #available(iOS 13.0, *) {
            let allBars: [UITabBar] = [self.tabBar, self.splitTabBarController?.tabBar].compactMap { $0 }
            for bar in allBars {
              let ap = UITabBarAppearance()
              ap.configureWithDefaultBackground()
      ap.backgroundColor = .clear
              ap.shadowColor = .clear
              ap.shadowImage = UIImage()
              Self.applyLabelStyle(to: ap, labelStyle: self.currentLabelStyle, tint: bar.tintColor)
              let hasCustomBadgeSizing =
                Self.hasAnyPositive(values: badgeDotSizes) ||
                Self.hasAnyPositive(values: badgeFontSizes)
              let badgeBackground = Self.firstNonNilColor(colors: badgeColors)
              let badgeText = Self.firstNonNilColor(colors: badgeTextColors)
              let badgeFontSize = hasCustomBadgeSizing
                ? nil
                : Self.firstNonNilCGFloat(values: badgeFontSizes)
              Self.applyBadgeStyle(to: ap, badgeBackground: badgeBackground, badgeText: badgeText, badgeFontSize: badgeFontSize)
              bar.standardAppearance = ap
              if #available(iOS 15.0, *) { bar.scrollEdgeAppearance = ap }
            }
          }
          func applyBadge(to item: UITabBarItem, index i: Int) {
            let badge = i < badges.count ? badges[i] : ""
            Self.applyBadge(
              to: item,
              index: i,
              badge: badge,
              badgeColors: badgeColors,
              badgeTextColors: badgeTextColors,
              badgeDotSizes: badgeDotSizes,
              badgeFontSizes: badgeFontSizes
            )
          }
          // Update single bar
          if let bar = self.tabBar, let items = bar.items {
            for (i, item) in items.enumerated() { applyBadge(to: item, index: i) }
          }
          // Update split (UITabBarController)
          if let vcs = self.splitTabBarController?.viewControllers {
            for (i, vc) in vcs.enumerated() { applyBadge(to: vc.tabBarItem, index: i) }
          }
          result(nil)
        } else { result(FlutterError(code: "bad_args", message: "Missing badges", details: nil)) }
      case "refresh":
        // Force refresh for label rendering on iOS < 16
        // UITabBar only fully layouts labels when items are selected
        // So we need to temporarily select each item to force layout
        if let bar = self.tabBar, let items = bar.items, !items.isEmpty {
          let originalSelected = bar.selectedItem
          // Temporarily remove delegate to prevent callbacks during refresh
          bar.delegate = nil
          DispatchQueue.main.async { [weak self, weak bar, weak originalSelected] in
            guard let self = self, let bar = bar, let items = bar.items, !items.isEmpty else { return }
            // Cycle through each item to force label layout
            var index = 0
            func selectNext() {
              guard index < items.count else {
                // Restore original selection
                if let original = originalSelected {
                  bar.selectedItem = original
                } else {
                  bar.selectedItem = items.first
                }
                bar.setNeedsLayout()
                bar.layoutIfNeeded()
                // Restore delegate
                bar.delegate = self
                return
              }
              bar.selectedItem = items[index]
              bar.setNeedsLayout()
              bar.layoutIfNeeded()
              index += 1
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                selectNext()
              }
            }
            selectNext()
          }
        } else if let tbc = self.splitTabBarController {
          // UITabBarController handles its own layout; just force a refresh
          tbc.tabBar.setNeedsLayout()
          tbc.tabBar.layoutIfNeeded()
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  func view() -> UIView { container }

  func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
    // Single bar case only (split is handled by UITabBarControllerDelegate)
    if let single = self.tabBar, single === tabBar, let items = single.items, let idx = items.firstIndex(of: item) {
      channel.invokeMethod("valueChanged", arguments: ["index": idx])
      return
    }
  }

  // MARK: - UITabBarControllerDelegate (split layout with action button)

  func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
    if viewController.tabBarItem.tag >= Self.actionButtonTag {
      // Action button tapped — fire callback at the action item's flat index, don't change selection
      let actionIndex = viewController.tabBarItem.tag - Self.actionButtonTag
      channel.invokeMethod("valueChanged", arguments: ["index": actionIndex])
      return false
    }
    return true
  }

  func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
    let tag = viewController.tabBarItem.tag
    if tag < Self.actionButtonTag {
      channel.invokeMethod("valueChanged", arguments: ["index": tag])
    }
  }

  /// Safely extracts a [NSNumber?] array from a value received via Flutter's StandardMessageCodec.
  /// Dart null values arrive as NSNull objects, which break `as? [NSNumber?]` casts.
  /// This method maps NSNull → nil and Any → NSNumber? correctly.
  private static func extractNullableNumbers(_ value: Any?) -> [NSNumber?] {
    guard let array = value as? [Any] else { return [] }
    return array.map { element in
      if element is NSNull { return nil }
      if let number = element as? NSNumber { return number }
      if let intValue = element as? Int { return NSNumber(value: intValue) }
      if let doubleValue = element as? Double { return NSNumber(value: doubleValue) }
      if let floatValue = element as? Float { return NSNumber(value: floatValue) }
      return nil
    }
  }

  private static func forceCompactTraits(on tabBar: UITabBar) {
    if #available(iOS 17.0, *) {
      tabBar.traitOverrides.horizontalSizeClass = .compact
      tabBar.traitOverrides.verticalSizeClass = .regular
    }
  }

  private static func forceCompactTraits(on controller: UITabBarController) {
    if #available(iOS 17.0, *) {
      controller.traitOverrides.horizontalSizeClass = .compact
      controller.traitOverrides.verticalSizeClass = .regular
    }
  }

  private static func clearTraitOverrides(on tabBar: UITabBar) {
    if #available(iOS 17.0, *) {
      tabBar.traitOverrides.remove(UITraitHorizontalSizeClass.self)
      tabBar.traitOverrides.remove(UITraitVerticalSizeClass.self)
    }
  }

  private static func clearTraitOverrides(on controller: UITabBarController) {
    if #available(iOS 17.0, *) {
      controller.traitOverrides.remove(UITraitHorizontalSizeClass.self)
      controller.traitOverrides.remove(UITraitVerticalSizeClass.self)
    }
  }

  private static func applyItemColor(_ image: UIImage?, color: UIColor?) -> UIImage? {
    guard let image = image, let color = color else { return image }
    if #available(iOS 13.0, *) {
      return image.withTintColor(color, renderingMode: .alwaysOriginal)
    }
    return image
  }

  private static func colorForItem(index: Int, colors: [NSNumber?]) -> UIColor? {
    guard index < colors.count, let argb = colors[index] else { return nil }
    return colorFromARGB(argb.intValue)
  }

  private static func applyItemPadding(_ item: UITabBarItem, index: Int, paddings: [[Double]]?) {
    guard let paddings = paddings, index < paddings.count else { return }
    let p = paddings[index]
    guard p.count == 4 else { return }
    let top = CGFloat(p[0])
    let left = CGFloat(p[1])
    let bottom = CGFloat(p[2])
    let right = CGFloat(p[3])
    item.imageInsets = UIEdgeInsets(top: top, left: left, bottom: -bottom, right: -right)
    item.titlePositionAdjustment = UIOffset(horizontal: (left - right) / 2, vertical: bottom)
  }

  private static func firstNonNilColor(colors: [NSNumber?]) -> UIColor? {
    for value in colors {
      if let value = value { return colorFromARGB(value.intValue) }
    }
    return nil
  }

  private static func firstNonNilCGFloat(values: [NSNumber?]) -> CGFloat? {
    for value in values {
      if let value = value {
        let v = CGFloat(truncating: value)
        if v > 0 { return v }
      }
    }
    return nil
  }

  private static func hasAnyPositive(values: [NSNumber?]) -> Bool {
    for value in values {
      if let value = value, CGFloat(truncating: value) > 0 {
        return true
      }
    }
    return false
  }

  @available(iOS 13.0, *)
  private static func applyBadgeStyle(
    to appearance: UITabBarAppearance,
    badgeBackground: UIColor?,
    badgeText: UIColor?,
    badgeFontSize: CGFloat?
  ) {
    guard badgeBackground != nil || badgeText != nil || badgeFontSize != nil else { return }

    let states = [
      appearance.stackedLayoutAppearance.normal,
      appearance.stackedLayoutAppearance.selected,
      appearance.inlineLayoutAppearance.normal,
      appearance.inlineLayoutAppearance.selected,
      appearance.compactInlineLayoutAppearance.normal,
      appearance.compactInlineLayoutAppearance.selected,
    ]

    for state in states {
      if let badgeBackground = badgeBackground {
        state.badgeBackgroundColor = badgeBackground
      }
      var attrs: [NSAttributedString.Key: Any] = [:]
      if let badgeText = badgeText {
        attrs[.foregroundColor] = badgeText
      }
      if let badgeFontSize = badgeFontSize {
        attrs[.font] = UIFont.systemFont(ofSize: badgeFontSize, weight: .semibold)
      }
      if !attrs.isEmpty {
        state.badgeTextAttributes = attrs
      }
    }
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
    if badge.isEmpty {
      item.badgeValue = nil
      return
    }

    let isDot = badge == "\u{200B}"
    let badgeBackgroundColor = colorForItem(index: index, colors: badgeColors)
    let badgeTextColor = colorForItem(index: index, colors: badgeTextColors)
    let badgeDotSize = numberForItem(index: index, numbers: badgeDotSizes)
    let badgeFontSize = numberForItem(index: index, numbers: badgeFontSizes)

    if isDot {
      if #available(iOS 10.0, *) {
        let dotColor = badgeBackgroundColor ?? UIColor.systemRed
        item.badgeColor = dotColor
        if let dotSize = badgeDotSize {
          // Custom-sized dot: render a glyph and tint it to match background.
          item.badgeValue = "●"
          var attrs: [NSAttributedString.Key: Any] = [.foregroundColor: dotColor]
          attrs[.font] = UIFont.systemFont(ofSize: dotSize, weight: .semibold)
          item.setBadgeTextAttributes(attrs, for: .normal)
          item.setBadgeTextAttributes(attrs, for: .selected)
        } else {
          // Default dot: use textless bubble to avoid inner white glyph artifacts.
          item.badgeValue = " "
          let hiddenAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.clear,
            .font: UIFont.systemFont(ofSize: 1, weight: .regular)
          ]
          item.setBadgeTextAttributes(hiddenAttrs, for: .normal)
          item.setBadgeTextAttributes(hiddenAttrs, for: .selected)
        }
      }
      return
    }

    item.badgeValue = badge
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

  /// Re-applies current badge values and per-item badge colors to all live items.
  /// Needed after appearance/style updates, which can reset badge rendering.
  private func applyCurrentBadgesToVisibleItems() {
    let badges = self.currentBadges
    let badgeColors = self.currentBadgeColors
    let badgeTextColors = self.currentBadgeTextColors
    let badgeDotSizes = self.currentBadgeDotSizes
    let badgeFontSizes = self.currentBadgeFontSizes

    func applyBadge(to item: UITabBarItem, index i: Int) {
      let badge = i < badges.count ? badges[i] : ""
      Self.applyBadge(
        to: item,
        index: i,
        badge: badge,
        badgeColors: badgeColors,
        badgeTextColors: badgeTextColors,
        badgeDotSizes: badgeDotSizes,
        badgeFontSizes: badgeFontSizes
      )
    }

    if let bar = self.tabBar, let items = bar.items {
      for (i, item) in items.enumerated() {
        applyBadge(to: item, index: i)
      }
    }

    if let vcs = self.splitTabBarController?.viewControllers {
      for (i, vc) in vcs.enumerated() {
        applyBadge(to: vc.tabBarItem, index: i)
      }
    }
  }

  /// Apply label style directly to each UITabBarItem and the tab bar itself.
  /// On iPad in regular size class, UITabBarController ignores per-item text
  /// attributes for colors — it uses tabBar.tintColor and
  /// tabBar.unselectedItemTintColor instead. So we set both.
  private static func applyLabelStyleToItems(_ items: [UITabBarItem], tabBar: UITabBar?, labelStyle: [String: Any]?, tint: UIColor?) {
    NSLog("🧭 [CN_TABBAR_APPLY_LABEL_STYLE] labelStyle=\(String(describing: labelStyle)) tint=\(String(describing: tint)) tabBar.tintColor=\(String(describing: tabBar?.tintColor)) items=\(items.count)")
    guard let ls = labelStyle else { return }
    var normalAttrs: [NSAttributedString.Key: Any] = [:]
    var selectedAttrs: [NSAttributedString.Key: Any] = [:]
    let font = buildFont(from: ls)
    if let font = font {
      normalAttrs[.font] = font
      selectedAttrs[.font] = font
    }
    if let colorVal = ls["color"] as? NSNumber {
      let color = colorFromARGB(colorVal.intValue)
      normalAttrs[.foregroundColor] = color
      tabBar?.unselectedItemTintColor = color
    }
    if let activeColorVal = ls["activeColor"] as? NSNumber {
      let color = colorFromARGB(activeColorVal.intValue)
      selectedAttrs[.foregroundColor] = color
      tabBar?.tintColor = color
    } else if let tint = tint {
      selectedAttrs[.foregroundColor] = tint
    }
    if let kern = ls["letterSpacing"] as? NSNumber {
      normalAttrs[.kern] = CGFloat(truncating: kern)
      selectedAttrs[.kern] = CGFloat(truncating: kern)
    }
    // On iPad with Liquid Glass, unselectedItemTintColor is ignored.
    // Bake colors into item images using .alwaysOriginal so the system
    // can't override them. Skip action button items (they have their own colors).
    let normalColor = normalAttrs[.foregroundColor] as? UIColor
    let selectedColor = selectedAttrs[.foregroundColor] as? UIColor
    for item in items {
      // Skip action button items — they use their own color property
      if item.tag >= actionButtonTag { continue }
      if let color = normalColor {
        if let img = item.image {
          item.image = img.withTintColor(color, renderingMode: .alwaysOriginal)
        }
        // Also set normal title color via attributed string for label
        item.setTitleTextAttributes(normalAttrs, for: .normal)
      } else if !normalAttrs.isEmpty {
        item.setTitleTextAttributes(normalAttrs, for: .normal)
      }
      if let color = selectedColor {
        if let img = item.selectedImage ?? item.image {
          item.selectedImage = img.withTintColor(color, renderingMode: .alwaysOriginal)
        }
        item.setTitleTextAttributes(selectedAttrs, for: .selected)
      } else if !selectedAttrs.isEmpty {
        item.setTitleTextAttributes(selectedAttrs, for: .selected)
      }
    }
    // Re-apply via UITabBarAppearance with fresh item appearances.
    if #available(iOS 13.0, *), let tabBar = tabBar {
      let ap = tabBar.standardAppearance.copy() as! UITabBarAppearance
      let itemAppearance = UITabBarItemAppearance()
      if let c = normalColor { itemAppearance.normal.iconColor = c }
      if let c = selectedColor { itemAppearance.selected.iconColor = c }
      if !normalAttrs.isEmpty { itemAppearance.normal.titleTextAttributes = normalAttrs }
      if !selectedAttrs.isEmpty { itemAppearance.selected.titleTextAttributes = selectedAttrs }
      ap.stackedLayoutAppearance = itemAppearance
      ap.inlineLayoutAppearance = itemAppearance
      ap.compactInlineLayoutAppearance = itemAppearance
      tabBar.standardAppearance = ap
      if #available(iOS 15.0, *) { tabBar.scrollEdgeAppearance = ap }
    }
    // On iPad Liquid Glass, label colors are only settable by directly
    // modifying UILabel subviews inside the tab bar after layout.
    if normalColor != nil || selectedColor != nil, let tabBar = tabBar {
      DispatchQueue.main.async {
        Self.applyColorsToTabBarSubviews(tabBar, normalColor: normalColor, selectedColor: selectedColor)
      }
    }
  }

  /// Walk the tab bar's view hierarchy and set colors directly on UILabel subviews.
  /// This is the nuclear option for iPad Liquid Glass which ignores all standard APIs.
  private static func applyColorsToTabBarSubviews(_ tabBar: UITabBar, normalColor: UIColor?, selectedColor: UIColor?) {
    tabBar.layoutIfNeeded()
    guard let items = tabBar.items else { return }
    // Find tab bar button subviews (UITabBarButton or similar internal classes)
    let buttons = tabBar.subviews.filter {
      let cls = String(describing: type(of: $0))
      return cls.contains("Button") || cls.contains("ItemView")
    }.sorted { $0.frame.minX < $1.frame.minX }

    for (i, button) in buttons.enumerated() {
      let isSelected = i < items.count && items[i] === tabBar.selectedItem
      // Skip action button items
      if i < items.count && items[i].tag >= actionButtonTag { continue }
      let color = isSelected ? selectedColor : normalColor
      guard let color = color else { continue }
      applyColorRecursively(to: button, color: color)
    }
  }

  private static func applyColorRecursively(to view: UIView, color: UIColor) {
    if let label = view as? UILabel {
      label.textColor = color
    }
    for subview in view.subviews {
      applyColorRecursively(to: subview, color: color)
    }
  }

  @available(iOS 13.0, *)
  private static func applyLabelStyle(to appearance: UITabBarAppearance, labelStyle: [String: Any]?, tint: UIColor?) {
    guard let ls = labelStyle else { return }
    var normalAttrs: [NSAttributedString.Key: Any] = [:]
    var selectedAttrs: [NSAttributedString.Key: Any] = [:]
    let font = buildFont(from: ls)
    if let font = font {
      normalAttrs[.font] = font
      selectedAttrs[.font] = font
    }
    let normalColor: UIColor? = (ls["color"] as? NSNumber).map { colorFromARGB($0.intValue) }
    let selectedColor: UIColor? = (ls["activeColor"] as? NSNumber).map { colorFromARGB($0.intValue) } ?? tint
    if let c = normalColor { normalAttrs[.foregroundColor] = c }
    if let c = selectedColor { selectedAttrs[.foregroundColor] = c }
    if let kern = ls["letterSpacing"] as? NSNumber {
      normalAttrs[.kern] = CGFloat(truncating: kern)
      selectedAttrs[.kern] = CGFloat(truncating: kern)
    }
    // Create a fresh UITabBarItemAppearance and assign it to all layout modes.
    // This is how native_glass_navbar does it — replacing the entire item
    // appearance ensures iPad respects the colors in all rendering modes.
    let itemAppearance = UITabBarItemAppearance()
    if let c = normalColor { itemAppearance.normal.iconColor = c }
    if let c = selectedColor { itemAppearance.selected.iconColor = c }
    if !normalAttrs.isEmpty { itemAppearance.normal.titleTextAttributes = normalAttrs }
    if !selectedAttrs.isEmpty { itemAppearance.selected.titleTextAttributes = selectedAttrs }
    appearance.stackedLayoutAppearance = itemAppearance
    appearance.inlineLayoutAppearance = itemAppearance
    appearance.compactInlineLayoutAppearance = itemAppearance
  }

  private static func buildFont(from labelStyle: [String: Any]) -> UIFont? {
    let size = (labelStyle["fontSize"] as? NSNumber).map { CGFloat(truncating: $0) }
    let weightVal = labelStyle["fontWeight"] as? NSNumber
    let family = labelStyle["fontFamily"] as? String
    let weight: UIFont.Weight? = weightVal.map { Self.mapFontWeight($0.intValue) }
    if let family = family, let size = size ?? Optional(10) {
      if let descriptor = UIFontDescriptor(name: family, size: size).withSymbolicTraits(weight.flatMap { Self.symbolicTraits(for: $0) } ?? []) {
        return UIFont(descriptor: descriptor, size: size)
      }
      return UIFont(name: family, size: size) ?? UIFont.systemFont(ofSize: size, weight: weight ?? .regular)
    }
    if let size = size {
      return UIFont.systemFont(ofSize: size, weight: weight ?? .regular)
    }
    if let weight = weight {
      return UIFont.systemFont(ofSize: 10, weight: weight)
    }
    return nil
  }

  private static func mapFontWeight(_ value: Int) -> UIFont.Weight {
    switch value {
    case ...100: return .ultraLight
    case ...200: return .thin
    case ...300: return .light
    case ...400: return .regular
    case ...500: return .medium
    case ...600: return .semibold
    case ...700: return .bold
    case ...800: return .heavy
    default: return .black
    }
  }

  private static func symbolicTraits(for weight: UIFont.Weight) -> UIFontDescriptor.SymbolicTraits? {
    if weight.rawValue >= UIFont.Weight.bold.rawValue { return .traitBold }
    return nil
  }

  // Use shared utility functions
  private static func colorFromARGB(_ argb: Int) -> UIColor {
    return ImageUtils.colorFromARGB(argb)
  }

  private static func loadFlutterAsset(_ assetPath: String, size: CGSize? = nil) -> UIImage? {
    return ImageUtils.loadFlutterAsset(assetPath, size: size)
  }

  private static func createImageFromData(_ data: Data, format: String?, scale: CGFloat, size: CGSize? = nil) -> UIImage? {
    return ImageUtils.createImageFromData(data, format: format, size: size, scale: scale)
  }

}

