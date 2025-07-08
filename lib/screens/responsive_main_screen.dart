import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:expense_sage/bloc/cubit/app_cubit.dart';
import 'package:expense_sage/helpers/responsive_helper.dart';
import 'package:expense_sage/screens/accounts/accounts.screen.dart';
import 'package:expense_sage/screens/categories/categories.screen.dart';
import 'package:expense_sage/screens/home/home.screen.dart';
import 'package:expense_sage/screens/advanced/advanced_screen.dart';
import 'package:expense_sage/screens/settings/enhanced_settings_screen.dart';
import 'package:expense_sage/screens/admin/admin_dashboard_screen.dart';
import 'package:expense_sage/model/user.model.dart';
import 'package:expense_sage/screens/onboard/onboard_screen.dart';

class ResponsiveMainScreen extends StatefulWidget {
  const ResponsiveMainScreen({super.key});

  @override
  State<ResponsiveMainScreen> createState() => _ResponsiveMainScreenState();
}

class _ResponsiveMainScreenState extends State<ResponsiveMainScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Symbols.home,
      label: 'Home',
      screen: const HomeScreen(),
    ),
    NavigationItem(
      icon: Symbols.wallet,
      label: 'Accounts',
      screen: const AccountsScreen(),
    ),
    NavigationItem(
      icon: Symbols.category,
      label: 'Categories',
      screen: const CategoriesScreen(),
    ),
    NavigationItem(
      icon: Symbols.auto_graph,
      label: 'Advanced',
      screen: const AdvancedScreen(),
    ),
    NavigationItem(
      icon: Symbols.settings,
      label: 'Settings',
      screen: const EnhancedSettingsScreen(),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (ResponsiveHelper.isMobile(context)) {
      _pageController.jumpToPage(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        AppCubit cubit = context.read<AppCubit>();
        if (cubit.state.currency == null || cubit.state.username == null) {
          return OnboardScreen();
        }

        return ResponsiveLayout(
          mobile: _buildMobileLayout(),
          tablet: _buildTabletLayout(),
          desktop: _buildDesktopLayout(),
        );
      },
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _navigationItems.map((item) => item.screen).toList(),
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: _navigationItems
            .map((item) => NavigationDestination(
                  icon: Icon(item.icon),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Scaffold(
      body: Row(
        children: [
          // Navigation Rail
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onDestinationSelected,
            labelType: NavigationRailLabelType.all,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            destinations: _navigationItems
                .map((item) => NavigationRailDestination(
                      icon: Icon(item.icon),
                      label: Text(item.label),
                    ))
                .toList(),
          ),

          // Vertical divider
          const VerticalDivider(thickness: 1, width: 1),

          // Main content
          Expanded(
            child: _navigationItems[_selectedIndex].screen,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar Navigation
          Container(
            width: ResponsiveHelper.getResponsiveSidebarWidth(context),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // App Header
                Container(
                  height: ResponsiveHelper.getResponsiveAppBarHeight(context),
                  padding: ResponsiveHelper.getResponsivePadding(context),
                  child: Row(
                    children: [
                      Icon(
                        Symbols.account_balance_wallet,
                        size:
                            ResponsiveHelper.getResponsiveIconSize(context, 32),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Expense Sage',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                  context, 20),
                            ),
                      ),
                    ],
                  ),
                ),

                const Divider(),

                // Navigation Items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _navigationItems.length,
                    itemBuilder: (context, index) {
                      final item = _navigationItems[index];
                      final isSelected = index == _selectedIndex;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        child: ListTile(
                          selected: isSelected,
                          leading: Icon(
                            item.icon,
                            size: ResponsiveHelper.getResponsiveIconSize(
                                context, 24),
                          ),
                          title: Text(
                            item.label,
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                  context, 16),
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          onTap: () => _onDestinationSelected(index),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getResponsiveBorderRadius(
                                  context, 12),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const Divider(),

                // User Info Section
                Padding(
                  padding: ResponsiveHelper.getResponsivePadding(context),
                  child: BlocBuilder<AppCubit, AppState>(
                    builder: (context, state) {
                      return Row(
                        children: [
                          CircleAvatar(
                            radius: ResponsiveHelper.getResponsiveIconSize(
                                context, 16),
                            child: Text(
                              state.username?.substring(0, 1).toUpperCase() ??
                                  'U',
                              style: TextStyle(
                                fontSize:
                                    ResponsiveHelper.getResponsiveFontSize(
                                        context, 14),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  state.username ?? 'User',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: ResponsiveHelper
                                            .getResponsiveFontSize(context, 14),
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  state.currency ?? 'USD',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                        fontSize: ResponsiveHelper
                                            .getResponsiveFontSize(context, 12),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Main content area
          Expanded(
            child: Column(
              children: [
                // Top app bar for desktop
                Container(
                  height: ResponsiveHelper.getResponsiveAppBarHeight(context),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: ResponsiveHelper.getResponsivePadding(context),
                    child: Row(
                      children: [
                        Text(
                          _navigationItems[_selectedIndex].label,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize:
                                        ResponsiveHelper.getResponsiveFontSize(
                                            context, 24),
                                  ),
                        ),
                        const Spacer(),
                        // Add any action buttons here
                      ],
                    ),
                  ),
                ),

                // Main content
                Expanded(
                  child: _navigationItems[_selectedIndex].screen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final Widget screen;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.screen,
  });
}
