import 'package:flutter/cupertino.dart';
import 'package:cupertino_native_better/cupertino_native_better.dart';

/// Action Tab Bar Test with SF Symbols
/// Tests action button behavior and tab selection consistency
class SplitTabBarTestPage extends StatefulWidget {
  const SplitTabBarTestPage({super.key});

  @override
  State<SplitTabBarTestPage> createState() => _SplitTabBarTestPageState();
}

class _SplitTabBarTestPageState extends State<SplitTabBarTestPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Action Tab Bar Test'),
        leading: CupertinoButton(padding: EdgeInsets.zero, child: const Icon(CupertinoIcons.back), onPressed: () => Navigator.of(context).pop()),
      ),
      child: Column(
        children: [
          Expanded(child: _buildCurrentScreen()),
          SafeArea(
            top: false,
            child: LiquidTabBar(
              items: [
                LiquidTabBarItem(label: 'Home', icon: CNSymbol('house.fill'), activeIcon: CNSymbol('house.fill')),
                LiquidTabBarItem(label: 'Search', icon: CNSymbol('magnifyingglass'), activeIcon: CNSymbol('magnifyingglass.fill')),
                LiquidTabBarItem(label: 'Chat', icon: CNSymbol('bubble.left'), activeIcon: CNSymbol('bubble.left.fill')),
                LiquidTabBarItem(label: 'Profile', icon: CNSymbol('person'), activeIcon: CNSymbol('person.fill')),
              ],
              actionButton: LiquidTabBarActionButton(
                icon: CNSymbol('plus.circle.fill', size: 22),
                splitSpacing: 12,
                onPressed: () {
                  showCupertinoDialog<void>(
                    context: context,
                    builder: (_) => CupertinoAlertDialog(
                      title: const Text('Create'),
                      content: const Text('Action button pressed'),
                      actions: [CupertinoDialogAction(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
                    ),
                  );
                },
              ),
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildPlaceholder('Home', CupertinoIcons.home, CupertinoColors.systemBlue);
      case 1:
        return _buildPlaceholder('Search', CupertinoIcons.search, CupertinoColors.systemOrange);
      case 2:
        return _buildPlaceholder('Chat', CupertinoIcons.chat_bubble_fill, CupertinoColors.systemGreen);
      case 3:
        return _buildPlaceholder('Profile', CupertinoIcons.person_fill, CupertinoColors.systemPurple);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPlaceholder(String title, IconData icon, Color color) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Check alignment on init vs hot reload', style: TextStyle(color: CupertinoColors.systemGrey)),
          ],
        ),
      ),
    );
  }
}
