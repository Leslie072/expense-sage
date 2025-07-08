import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:expense_sage/bloc/cubit/app_cubit.dart';
import 'package:expense_sage/dao/investment_dao.dart';
import 'package:expense_sage/model/investment.model.dart';
import 'package:expense_sage/helpers/responsive_helper.dart';
import 'package:expense_sage/helpers/currency.helper.dart';
import 'package:intl/intl.dart';

class InvestmentPortfolioScreen extends StatefulWidget {
  const InvestmentPortfolioScreen({super.key});

  @override
  State<InvestmentPortfolioScreen> createState() =>
      _InvestmentPortfolioScreenState();
}

class _InvestmentPortfolioScreenState extends State<InvestmentPortfolioScreen>
    with TickerProviderStateMixin {
  final InvestmentDao _investmentDao = InvestmentDao();

  late TabController _tabController;
  List<Investment> _investments = [];
  Map<String, dynamic> _portfolioSummary = {};
  Map<String, dynamic> _performanceMetrics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      final investments = await _investmentDao.getActiveInvestments();
      final portfolioSummary = await _investmentDao.getPortfolioSummary();
      final performanceMetrics = await _investmentDao.getPerformanceMetrics();

      setState(() {
        _investments = investments;
        _portfolioSummary = portfolioSummary;
        _performanceMetrics = performanceMetrics;
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
        title: const Text('Investment Portfolio'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Symbols.dashboard)),
            Tab(text: 'Holdings', icon: Icon(Symbols.trending_up)),
            Tab(text: 'Performance', icon: Icon(Symbols.analytics)),
            Tab(text: 'Allocation', icon: Icon(Symbols.pie_chart)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Symbols.add),
            onPressed: _addInvestment,
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
                  'Investment Portfolio',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _addInvestment,
                  icon: const Icon(Symbols.add),
                  label: const Text('Add Investment'),
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
            tabs: const [
              Tab(text: 'Overview', icon: Icon(Symbols.dashboard)),
              Tab(text: 'Holdings', icon: Icon(Symbols.trending_up)),
              Tab(text: 'Performance', icon: Icon(Symbols.analytics)),
              Tab(text: 'Allocation', icon: Icon(Symbols.pie_chart)),
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
        _buildHoldingsTab(),
        _buildPerformanceTab(),
        _buildAllocationTab(),
      ],
    );
  }

  Widget _buildOverviewTab() {
    final currency = context.read<AppCubit>().state.currency ?? 'USD';
    final totalValue = _portfolioSummary['totalValue'] ?? 0.0;
    final totalCost = _portfolioSummary['totalCost'] ?? 0.0;
    final totalGainLoss = _portfolioSummary['totalGainLoss'] ?? 0.0;
    final gainLossPercentage =
        _portfolioSummary['totalGainLossPercentage'] ?? 0.0;

    return SingleChildScrollView(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Portfolio Value Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Portfolio Value',
                  CurrencyHelper.format(totalValue, name: currency),
                  Symbols.account_balance_wallet,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Total Cost',
                  CurrencyHelper.format(totalCost, name: currency),
                  Symbols.payments,
                  Colors.grey,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Gain/Loss',
                  CurrencyHelper.format(totalGainLoss, name: currency),
                  totalGainLoss >= 0
                      ? Symbols.trending_up
                      : Symbols.trending_down,
                  totalGainLoss >= 0 ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Return %',
                  '${gainLossPercentage.toStringAsFixed(2)}%',
                  gainLossPercentage >= 0
                      ? Symbols.arrow_upward
                      : Symbols.arrow_downward,
                  gainLossPercentage >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
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

          _buildQuickStats(currency),

          const SizedBox(height: 24),

          // Recent Activity
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 16),

          _buildRecentActivity(),
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

  Widget _buildQuickStats(String currency) {
    final investmentCount = _portfolioSummary['investmentCount'] ?? 0;
    final bestPerformer = _performanceMetrics['bestPerformer'] as Investment?;
    final worstPerformer = _performanceMetrics['worstPerformer'] as Investment?;
    final averageReturn = _performanceMetrics['averageReturn'] ?? 0.0;

    return Column(
      children: [
        _buildStatRow('Total Investments', '$investmentCount'),
        if (bestPerformer != null)
          _buildStatRow('Best Performer',
              '${bestPerformer.symbol} (+${bestPerformer.gainLossPercentage.toStringAsFixed(2)}%)'),
        if (worstPerformer != null)
          _buildStatRow('Worst Performer',
              '${worstPerformer.symbol} (${worstPerformer.gainLossPercentage.toStringAsFixed(2)}%)'),
        _buildStatRow('Average Return', '${averageReturn.toStringAsFixed(2)}%'),
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

  Widget _buildRecentActivity() {
    if (_investments.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Symbols.trending_up,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No investments yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your first investment to start tracking your portfolio',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _addInvestment,
                icon: const Icon(Symbols.add),
                label: const Text('Add Investment'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _investments.take(5).map((investment) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: investment.gainLossColor.withValues(alpha: 0.1),
              child: Icon(
                investment.typeIcon,
                color: investment.gainLossColor,
                size: 20,
              ),
            ),
            title: Text(investment.symbol),
            subtitle: Text(investment.name),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyHelper.format(investment.currentMarketValue,
                      name: 'USD'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${investment.gainLossPercentage >= 0 ? '+' : ''}${investment.gainLossPercentage.toStringAsFixed(2)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: investment.gainLossColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            onTap: () => _viewInvestmentDetails(investment),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHoldingsTab() {
    if (_investments.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: ResponsiveHelper.getResponsivePadding(context),
      itemCount: _investments.length,
      itemBuilder: (context, index) {
        final investment = _investments[index];
        return _buildInvestmentCard(investment);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Symbols.trending_up,
            size: ResponsiveHelper.getResponsiveIconSize(context, 64),
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No investments yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start building your investment portfolio',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addInvestment,
            icon: const Icon(Symbols.add),
            label: const Text('Add Investment'),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentCard(Investment investment) {
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
                // Investment Type Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: investment.gainLossColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    investment.typeIcon,
                    color: investment.gainLossColor,
                    size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                  ),
                ),

                const SizedBox(width: 12),

                // Investment Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        investment.symbol,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Text(
                        investment.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

                // Current Value
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyHelper.format(investment.currentMarketValue,
                          name: currency),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '${investment.gainLossPercentage >= 0 ? '+' : ''}${investment.gainLossPercentage.toStringAsFixed(2)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: investment.gainLossColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Details Row
            Row(
              children: [
                _buildDetailChip(
                  icon: Symbols.trending_up,
                  label: investment.typeDescription,
                ),
                const SizedBox(width: 8),
                _buildDetailChip(
                  icon: Symbols.info,
                  label: investment.statusDescription,
                  color: investment.statusColor,
                ),
                if (investment.sector.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _buildDetailChip(
                    icon: Symbols.business,
                    label: investment.sector,
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // Investment Details
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quantity: ${investment.quantity.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Avg Cost: ${CurrencyHelper.format(investment.purchasePrice, name: currency)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Current: ${CurrencyHelper.format(investment.currentPrice, name: currency)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

                // Action Buttons
                PopupMenuButton<String>(
                  onSelected: (value) =>
                      _handleInvestmentAction(value, investment),
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
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Symbols.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    if (investment.status == InvestmentStatus.active)
                      const PopupMenuItem(
                        value: 'sell',
                        child: Row(
                          children: [
                            Icon(Symbols.sell),
                            SizedBox(width: 8),
                            Text('Sell'),
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

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Theme.of(context).colorScheme.primary)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color ?? Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color ?? Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return Center(
      child: Text(
        'Performance charts coming soon',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  Widget _buildAllocationTab() {
    return Center(
      child: Text(
        'Allocation charts coming soon',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  void _addInvestment() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add investment coming soon')),
    );
  }

  void _viewInvestmentDetails(Investment investment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing ${investment.symbol} details')),
    );
  }

  Future<void> _handleInvestmentAction(
      String action, Investment investment) async {
    try {
      switch (action) {
        case 'view':
          _viewInvestmentDetails(investment);
          break;
        case 'edit':
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Edit ${investment.symbol} coming soon')),
          );
          break;
        case 'sell':
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sell ${investment.symbol} coming soon')),
          );
          break;
        case 'delete':
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Investment'),
              content:
                  Text('Are you sure you want to delete ${investment.symbol}?'),
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
            await _investmentDao.delete(investment.id!);
            await _loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${investment.symbol} deleted')),
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
