import 'package:flutter/material.dart';
import '../pages/home_page.dart';
import '../pages/statistics_page.dart';
import '../pages/settings_page.dart';
import '../widgets/bottom_navigation.dart';

/// Responsive layout yang automatically switch antara mobile & desktop
class ResponsiveLayout extends StatefulWidget {
  const ResponsiveLayout({Key? key}) : super(key: key);

  @override
  State<ResponsiveLayout> createState() => _ResponsiveLayoutState();
}

class _ResponsiveLayoutState extends State<ResponsiveLayout> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const StatisticsPage(),
    const SettingsPage(),
  ];

  final List<NavigationItem> _navItems = [
    NavigationItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Journal',
    ),
    NavigationItem(
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart,
      label: 'Progress',
    ),
    NavigationItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Breakpoint: 600px untuk tablet/desktop
        final isDesktop = constraints.maxWidth > 600;

        if (isDesktop) {
          return _DesktopLayout(
            currentIndex: _currentIndex,
            pages: _pages,
            navItems: _navItems,
            onNavigate: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          );
        } else {
          return _MobileLayout(
            currentIndex: _currentIndex,
            pages: _pages,
            onNavigate: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          );
        }
      },
    );
  }
}

// ============================================================================
// MOBILE LAYOUT (Original dengan Bottom Navigation)
// ============================================================================
class _MobileLayout extends StatelessWidget {
  final int currentIndex;
  final List<Widget> pages;
  final Function(int) onNavigate;

  const _MobileLayout({
    required this.currentIndex,
    required this.pages,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: currentIndex,
        onTap: onNavigate,
      ),
    );
  }
}

// ============================================================================
// DESKTOP LAYOUT (Sidebar Navigation)
// ============================================================================
class _DesktopLayout extends StatelessWidget {
  final int currentIndex;
  final List<Widget> pages;
  final List<NavigationItem> navItems;
  final Function(int) onNavigate;

  const _DesktopLayout({
    required this.currentIndex,
    required this.pages,
    required this.navItems,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar Navigation
          _buildSidebar(context),

          // Main Content Area
          Expanded(
            child: Container(
              color: Colors.grey[50],
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: IndexedStack(
                    index: currentIndex,
                    children: pages,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildNavigationItems(),
          const Spacer(),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF64B5F6), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  color: Color(0xFF42A5F5),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'StreakUp',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Build Better Habits',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItems() {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: navItems.length,
        itemBuilder: (context, index) {
          final item = navItems[index];
          final isSelected = index == currentIndex;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onNavigate(index),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF42A5F5).withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF42A5F5)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? item.activeIcon : item.icon,
                        color: isSelected
                            ? const Color(0xFF42A5F5)
                            : Colors.grey[600],
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? const Color(0xFF42A5F5)
                              : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.code,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                'v0.3 • Made with Flutter',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.favorite,
                size: 14,
                color: Colors.red[300],
              ),
              const SizedBox(width: 6),
              Text(
                'github.com/17frn',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// NAVIGATION ITEM MODEL
// ============================================================================
class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}