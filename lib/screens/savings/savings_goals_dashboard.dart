import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:expense_sage/bloc/cubit/app_cubit.dart';
import 'package:expense_sage/dao/savings_goal_dao.dart';
import 'package:expense_sage/model/savings_goal.model.dart';
import 'package:expense_sage/helpers/responsive_helper.dart';
import 'package:expense_sage/helpers/currency.helper.dart';
import 'package:intl/intl.dart';

class SavingsGoalsDashboard extends StatefulWidget {
  const SavingsGoalsDashboard({super.key});

  @override
  State<SavingsGoalsDashboard> createState() => _SavingsGoalsDashboardState();
}

class _SavingsGoalsDashboardState extends State<SavingsGoalsDashboard>
    with TickerProviderStateMixin {
  final SavingsGoalDao _savingsGoalDao = SavingsGoalDao();

  late TabController _tabController;
  List<SavingsGoal> _allGoals = [];
  List<SavingsGoal> _activeGoals = [];
  List<SavingsGoal> _completedGoals = [];
  Map<String, dynamic> _savingsSummary = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final allGoals = await _savingsGoalDao.find();
      final activeGoals = await _savingsGoalDao.getActiveGoals();
      final completedGoals = await _savingsGoalDao.getCompletedGoals();
      final savingsSummary = await _savingsGoalDao.getSavingsSummary();

      setState(() {
        _allGoals = allGoals;
        _activeGoals = activeGoals;
        _completedGoals = completedGoals;
        _savingsSummary = savingsSummary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileLayout(),
      tablet: _buildTabletLayout(),
      desktop: _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Overview', icon: Icon(Symbols.dashboard)),
            Tab(
                text: 'Active (${_activeGoals.length})',
                icon: Icon(Symbols.flag)),
            Tab(
                text: 'Completed (${_completedGoals.length})',
                icon: Icon(Symbols.check_circle)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Symbols.add),
            onPressed: _addSavingsGoal,
          ),
          IconButton(
            icon: const Icon(Symbols.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _buildTabContent(),
    );
  }

  Widget _buildTabletLayout() {
    return _buildMobileLayout(); // Same layout for tablet
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: ResponsiveHelper.getResponsivePadding(context),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Savings Goals',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _addSavingsGoal,
                  icon: const Icon(Symbols.add),
                  label: const Text('Add Goal'),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Symbols.refresh),
                  onPressed: _loadData,
                ),
              ],
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Overview', icon: Icon(Symbols.dashboard)),
              Tab(
                  text: 'Active (${_activeGoals.length})',
                  icon: Icon(Symbols.flag)),
              Tab(
                  text: 'Completed (${_completedGoals.length})',
                  icon: Icon(Symbols.check_circle)),
            ],
          ),

          // Tab Content
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(),
        _buildActiveGoalsTab(),
        _buildCompletedGoalsTab(),
      ],
    );
  }

  Widget _buildOverviewTab() {
    final currency = context.read<AppCubit>().state.currency ?? 'USD';
    final totalTargetAmount = _savingsSummary['totalTargetAmount'] ?? 0.0;
    final totalCurrentAmount = _savingsSummary['totalCurrentAmount'] ?? 0.0;
    final totalRemaining = _savingsSummary['totalRemaining'] ?? 0.0;
    final overallProgress = _savingsSummary['overallProgress'] ?? 0.0;

    return SingleChildScrollView(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Target',
                  CurrencyHelper.format(totalTargetAmount, name: currency),
                  Symbols.flag,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Total Saved',
                  CurrencyHelper.format(totalCurrentAmount, name: currency),
                  Symbols.savings,
                  Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Remaining',
                  CurrencyHelper.format(totalRemaining, name: currency),
                  Symbols.trending_up,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Progress',
                  '${(overallProgress * 100).toStringAsFixed(1)}%',
                  Symbols.percent,
                  Colors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Overall Progress Bar
          Text(
            'Overall Progress',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Progress',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      Text(
                        '${(overallProgress * 100).toStringAsFixed(1)}%',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: overallProgress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        CurrencyHelper.format(totalCurrentAmount,
                            name: currency),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        CurrencyHelper.format(totalTargetAmount,
                            name: currency),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Quick Stats
          Text(
            'Quick Statistics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 16),

          _buildQuickStats(),

          const SizedBox(height: 24),

          // Recent Goals
          Text(
            'Recent Goals',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 16),

          _buildRecentGoals(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: ResponsiveHelper.getResponsiveCardElevation(context),
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Column(
          children: [
            Icon(icon,
                color: color,
                size: ResponsiveHelper.getResponsiveIconSize(context, 32)),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 16),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    final totalGoals = _savingsSummary['totalGoals'] ?? 0;
    final activeGoals = _savingsSummary['activeGoals'] ?? 0;
    final completedGoals = _savingsSummary['completedGoals'] ?? 0;

    return Column(
      children: [
        _buildStatRow('Total Goals', '$totalGoals'),
        _buildStatRow('Active Goals', '$activeGoals'),
        _buildStatRow('Completed Goals', '$completedGoals'),
        if (_activeGoals.isNotEmpty)
          _buildStatRow('Avg Progress',
              '${(_activeGoals.map((g) => g.progressPercentage).reduce((a, b) => a + b) / _activeGoals.length * 100).toStringAsFixed(1)}%'),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentGoals() {
    if (_allGoals.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Symbols.savings,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No savings goals yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your first savings goal to start building your future',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _addSavingsGoal,
                icon: const Icon(Symbols.add),
                label: const Text('Add Savings Goal'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _allGoals.take(5).map((goal) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: goal.color.withValues(alpha: 0.1),
              child: Icon(
                goal.icon,
                color: goal.color,
                size: 20,
              ),
            ),
            title: Text(goal.name),
            subtitle: Text(
                '${(goal.progressPercentage * 100).toStringAsFixed(1)}% complete'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyHelper.format(goal.currentAmount, name: 'USD'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'of ${CurrencyHelper.format(goal.targetAmount, name: 'USD')}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            onTap: () => _viewGoalDetails(goal),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActiveGoalsTab() {
    if (_activeGoals.isEmpty) {
      return _buildEmptyState(
          'No active goals', 'Create a new savings goal to get started');
    }

    return ListView.builder(
      padding: ResponsiveHelper.getResponsivePadding(context),
      itemCount: _activeGoals.length,
      itemBuilder: (context, index) {
        final goal = _activeGoals[index];
        return _buildGoalCard(goal);
      },
    );
  }

  Widget _buildCompletedGoalsTab() {
    if (_completedGoals.isEmpty) {
      return _buildEmptyState('No completed goals',
          'Complete your first savings goal to see it here');
    }

    return ListView.builder(
      padding: ResponsiveHelper.getResponsivePadding(context),
      itemCount: _completedGoals.length,
      itemBuilder: (context, index) {
        final goal = _completedGoals[index];
        return _buildGoalCard(goal);
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Symbols.savings,
            size: ResponsiveHelper.getResponsiveIconSize(context, 64),
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addSavingsGoal,
            icon: const Icon(Symbols.add),
            label: const Text('Add Savings Goal'),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(SavingsGoal goal) {
    final currency = context.read<AppCubit>().state.currency ?? 'USD';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: ResponsiveHelper.getResponsiveCardElevation(context),
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Goal Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: goal.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    goal.icon,
                    color: goal.color,
                    size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                  ),
                ),

                const SizedBox(width: 12),

                // Goal Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      if (goal.description.isNotEmpty)
                        Text(
                          goal.description,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),

                // Priority Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: goal.priorityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    goal.priorityDescription,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: goal.priorityColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  '${(goal.progressPercentage * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: goal.color,
                      ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            LinearProgressIndicator(
              value: goal.progressPercentage,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(goal.color),
              minHeight: 6,
            ),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  CurrencyHelper.format(goal.currentAmount, name: currency),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  CurrencyHelper.format(goal.targetAmount, name: currency),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Goal Details
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Target Date: ${DateFormat('MMM dd, yyyy').format(goal.targetDate)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Days Remaining: ${goal.daysRemaining}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (goal.isAutoSave)
                        Text(
                          'Auto-save: ${CurrencyHelper.format(goal.autoSaveAmount, name: currency)} ${goal.autoSaveFrequency}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.green,
                                  ),
                        ),
                    ],
                  ),
                ),

                // Action Buttons
                PopupMenuButton<String>(
                  onSelected: (value) => _handleGoalAction(value, goal),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Symbols.visibility),
                          SizedBox(width: 8),
                          Text('View Details'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'add_money',
                      child: Row(
                        children: [
                          Icon(Symbols.add_circle),
                          SizedBox(width: 8),
                          Text('Add Money'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Symbols.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    if (goal.status == GoalStatus.active)
                      const PopupMenuItem(
                        value: 'pause',
                        child: Row(
                          children: [
                            Icon(Symbols.pause),
                            SizedBox(width: 8),
                            Text('Pause'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Symbols.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addSavingsGoal() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add savings goal coming soon')),
    );
  }

  void _viewGoalDetails(SavingsGoal goal) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing ${goal.name} details')),
    );
  }

  Future<void> _handleGoalAction(String action, SavingsGoal goal) async {
    try {
      switch (action) {
        case 'view':
          _viewGoalDetails(goal);
          break;
        case 'add_money':
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Add money to ${goal.name} coming soon')),
          );
          break;
        case 'edit':
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Edit ${goal.name} coming soon')),
          );
          break;
        case 'pause':
          await _savingsGoalDao.pauseGoal(goal.id!);
          await _loadData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${goal.name} paused')),
            );
          }
          break;
        case 'delete':
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Savings Goal'),
              content: Text('Are you sure you want to delete "${goal.name}"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            await _savingsGoalDao.delete(goal.id!);
            await _loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${goal.name} deleted')),
              );
            }
          }
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
