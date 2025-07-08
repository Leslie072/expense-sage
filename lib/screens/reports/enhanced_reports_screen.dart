import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:expense_sage/bloc/cubit/app_cubit.dart';
import 'package:expense_sage/dao/payment_dao.dart';
import 'package:expense_sage/dao/category_dao.dart';
import 'package:expense_sage/dao/account_dao.dart';
import 'package:expense_sage/model/payment.model.dart';
import 'package:expense_sage/model/category.model.dart';
import 'package:expense_sage/model/account.model.dart';
import 'package:expense_sage/helpers/currency.helper.dart';
import 'package:expense_sage/theme/app_theme.dart';
import 'package:intl/intl.dart';

class EnhancedReportsScreen extends StatefulWidget {
  const EnhancedReportsScreen({super.key});

  @override
  State<EnhancedReportsScreen> createState() => _EnhancedReportsScreenState();
}

class _EnhancedReportsScreenState extends State<EnhancedReportsScreen>
    with TickerProviderStateMixin {
  final PaymentDao _paymentDao = PaymentDao();
  final CategoryDao _categoryDao = CategoryDao();
  final AccountDao _accountDao = AccountDao();

  late TabController _tabController;
  DateTimeRange _selectedRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  List<Payment> _payments = [];
  List<Category> _categories = [];
  List<Account> _accounts = [];
  bool _isLoading = true;

  // Analytics data
  double _totalIncome = 0;
  double _totalExpense = 0;
  Map<String, double> _categoryExpenses = {};
  Map<String, double> _monthlyTrends = {};
  Map<String, double> _accountBalances = {};

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
      // Load payments for selected range
      final payments = await _paymentDao.find(range: _selectedRange);
      final categories = await _categoryDao.find(withSummery: true);
      final accounts = await _accountDao.find(withSummery: true);

      // Calculate totals
      double income = 0;
      double expense = 0;
      Map<String, double> categoryExpenses = {};
      Map<String, double> monthlyTrends = {};
      Map<String, double> accountBalances = {};

      for (final payment in payments) {
        if (payment.type == PaymentType.credit) {
          income += payment.amount;
        } else {
          expense += payment.amount;
          // Category expenses
          final categoryName = payment.category.name;
          categoryExpenses[categoryName] =
              (categoryExpenses[categoryName] ?? 0) + payment.amount;
        }

        // Monthly trends
        final monthKey = DateFormat('MMM yyyy').format(payment.datetime);
        if (payment.type == PaymentType.debit) {
          monthlyTrends[monthKey] =
              (monthlyTrends[monthKey] ?? 0) + payment.amount;
        }
      }

      // Account balances
      for (final account in accounts) {
        accountBalances[account.name] = account.balance ?? 0;
      }

      setState(() {
        _payments = payments;
        _categories = categories;
        _accounts = accounts;
        _totalIncome = income;
        _totalExpense = expense;
        _categoryExpenses = categoryExpenses;
        _monthlyTrends = monthlyTrends;
        _accountBalances = accountBalances;
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

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedRange,
    );

    if (picked != null && picked != _selectedRange) {
      setState(() {
        _selectedRange = picked;
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = context.read<AppCubit>().state.currency ?? 'USD';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Reports'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Categories', icon: Icon(Icons.pie_chart)),
            Tab(text: 'Trends', icon: Icon(Icons.trending_up)),
            Tab(text: 'Accounts', icon: Icon(Icons.account_balance)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Date Range Display
                Container(
                  padding: const EdgeInsets.all(16),
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today,
                          color: theme.colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${DateFormat('MMM dd, yyyy').format(_selectedRange.start)} - ${DateFormat('MMM dd, yyyy').format(_selectedRange.end)}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_payments.length} transactions',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(currency),
                      _buildCategoriesTab(currency),
                      _buildTrendsTab(currency),
                      _buildAccountsTab(currency),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildOverviewTab(String currency) {
    final netIncome = _totalIncome - _totalExpense;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Income',
                  CurrencyHelper.format(_totalIncome, name: currency),
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Total Expenses',
                  CurrencyHelper.format(_totalExpense, name: currency),
                  Icons.trending_down,
                  Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _buildSummaryCard(
            'Net Income',
            CurrencyHelper.format(netIncome, name: currency),
            netIncome >= 0 ? Icons.savings : Icons.warning,
            netIncome >= 0 ? Colors.blue : Colors.orange,
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
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
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
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(String currency) {
    final avgDailyExpense = _payments.isNotEmpty
        ? _totalExpense / _selectedRange.duration.inDays
        : 0.0;
    final topCategory = _categoryExpenses.isNotEmpty
        ? _categoryExpenses.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key
        : 'None';
    final topCategoryAmount = _categoryExpenses.isNotEmpty
        ? _categoryExpenses.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .value
        : 0.0;

    return Column(
      children: [
        _buildStatRow('Average Daily Expense',
            CurrencyHelper.format(avgDailyExpense, name: currency)),
        _buildStatRow('Top Spending Category', topCategory),
        _buildStatRow('Top Category Amount',
            CurrencyHelper.format(topCategoryAmount, name: currency)),
        _buildStatRow('Total Transactions', '${_payments.length}'),
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

  Widget _buildCategoriesTab(String currency) {
    if (_categoryExpenses.isEmpty) {
      return const Center(
        child: Text('No expense data available for the selected period.'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending by Category',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 16),

          // Pie Chart
          SizedBox(
            height: 300,
            child: PieChart(
              PieChartData(
                sections: _buildPieChartSections(),
                centerSpaceRadius: 60,
                sectionsSpace: 2,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Category List
          Text(
            'Category Breakdown',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 16),

          ..._categoryExpenses.entries.map((entry) {
            final percentage =
                (_totalExpense > 0) ? (entry.value / _totalExpense * 100) : 0.0;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getCategoryColor(entry.key),
                  child: Text(
                    entry.key.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(entry.key),
                subtitle:
                    Text('${percentage.toStringAsFixed(1)}% of total expenses'),
                trailing: Text(
                  CurrencyHelper.format(entry.value, name: currency),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];

    int colorIndex = 0;
    return _categoryExpenses.entries.map((entry) {
      final percentage =
          (_totalExpense > 0) ? (entry.value / _totalExpense * 100) : 0.0;

      final color = colors[colorIndex % colors.length];
      colorIndex++;

      return PieChartSectionData(
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        color: color,
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Color _getCategoryColor(String categoryName) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[categoryName.hashCode % colors.length];
  }

  Widget _buildTrendsTab(String currency) {
    if (_monthlyTrends.isEmpty) {
      return const Center(
        child: Text('No trend data available for the selected period.'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Spending Trends',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 16),

          // Line Chart
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          CurrencyHelper.format(value, name: currency),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final months = _monthlyTrends.keys.toList();
                        if (value.toInt() < months.length) {
                          return Text(
                            months[value.toInt()],
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: _buildLineChartSpots(),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Monthly breakdown
          Text(
            'Monthly Breakdown',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 16),

          ..._monthlyTrends.entries.map((entry) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.calendar_month),
                title: Text(entry.key),
                trailing: Text(
                  CurrencyHelper.format(entry.value, name: currency),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  List<FlSpot> _buildLineChartSpots() {
    final months = _monthlyTrends.keys.toList();
    return months.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        _monthlyTrends[entry.value] ?? 0,
      );
    }).toList();
  }

  Widget _buildAccountsTab(String currency) {
    if (_accounts.isEmpty) {
      return const Center(
        child: Text('No account data available.'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Balances',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 16),

          // Bar Chart
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _accountBalances.values.isNotEmpty
                    ? _accountBalances.values.reduce((a, b) => a > b ? a : b) *
                        1.2
                    : 100,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          CurrencyHelper.format(value, name: currency),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final accounts = _accountBalances.keys.toList();
                        if (value.toInt() < accounts.length) {
                          return Text(
                            accounts[value.toInt()],
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                barGroups: _buildBarChartGroups(),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Account List
          Text(
            'Account Details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 16),

          ..._accounts.map((account) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: account.color,
                  child: Icon(account.icon, color: Colors.white),
                ),
                title: Text(account.name),
                subtitle: Text(account.holderName.isNotEmpty
                    ? account.holderName
                    : 'No holder name'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyHelper.format(account.balance ?? 0,
                          name: currency),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (account.isDefault == true)
                      Text(
                        'Default',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.blue,
                            ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  List<BarChartGroupData> _buildBarChartGroups() {
    final accounts = _accountBalances.keys.toList();
    return accounts.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: _accountBalances[entry.value] ?? 0,
            color: Colors.blue,
            width: 20,
          ),
        ],
      );
    }).toList();
  }
}
