import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:expense_sage/helpers/responsive_helper.dart';
import 'package:expense_sage/screens/budget/budget_screen.dart';
import 'package:expense_sage/screens/recurring/recurring_transactions_screen.dart';
import 'package:expense_sage/screens/reports/enhanced_reports_screen.dart';

class AdvancedScreen extends StatefulWidget {
  const AdvancedScreen({super.key});

  @override
  State<AdvancedScreen> createState() => _AdvancedScreenState();
}

class _AdvancedScreenState extends State<AdvancedScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  final List<AdvancedTab> _tabs = [
    AdvancedTab(
      icon: Symbols.trending_up,
      label: 'Budget',
      screen: const BudgetScreen(),
    ),
    AdvancedTab(
      icon: Symbols.repeat,
      label: 'Recurring',
      screen: const RecurringTransactionsScreen(),
    ),
    AdvancedTab(
      icon: Symbols.analytics,
      label: 'Reports',
      screen: const EnhancedReportsScreen(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context)) {
      return _buildDesktopLayout();
    } else if (ResponsiveHelper.isTablet(context)) {
      return _buildTabletLayout();
    } else {
      return _buildMobileLayout();
    }
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Features'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs
              .map((tab) => Tab(
                    icon: Icon(tab.icon),
                    text: tab.label,
                  ))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((tab) => tab.screen).toList(),
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Features'),
        centerTitle: true,
      ),
      body: Row(
        children: [
          // Side navigation
          Container(
            width: 200,
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
                const SizedBox(height: 16),
                ..._tabs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final tab = entry.value;
                  final isSelected = index == _selectedIndex;

                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: Icon(
                        tab.icon,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      title: Text(
                        tab.label,
                        style: TextStyle(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      selectedTileColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                        });
                        _tabController.animateTo(index);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: _tabs[_selectedIndex].screen,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          // Side navigation
          Container(
            width: 250,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Advanced Features',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),

                const Divider(),

                // Navigation items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: _tabs.asMap().entries.map((entry) {
                      final index = entry.key;
                      final tab = entry.value;
                      final isSelected = index == _selectedIndex;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            tab.icon,
                            size: 24,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          title: Text(
                            tab.label,
                            style: TextStyle(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontSize: 16,
                            ),
                          ),
                          selected: isSelected,
                          selectedTileColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedIndex = index;
                            });
                            _tabController.animateTo(index);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: _tabs[_selectedIndex].screen,
          ),
        ],
      ),
    );
  }
}

class AdvancedTab {
  final IconData icon;
  final String label;
  final Widget screen;

  const AdvancedTab({
    required this.icon,
    required this.label,
    required this.screen,
  });
}
