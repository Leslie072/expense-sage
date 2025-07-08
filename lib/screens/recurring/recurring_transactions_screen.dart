import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:expense_sage/bloc/cubit/app_cubit.dart';
import 'package:expense_sage/dao/recurring_transaction_dao.dart';
import 'package:expense_sage/dao/payment_dao.dart';
import 'package:expense_sage/model/recurring_transaction.model.dart';
import 'package:expense_sage/model/payment.model.dart';
import 'package:expense_sage/helpers/responsive_helper.dart';
import 'package:expense_sage/helpers/currency.helper.dart';

import 'package:intl/intl.dart';

class RecurringTransactionsScreen extends StatefulWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  State<RecurringTransactionsScreen> createState() =>
      _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState
    extends State<RecurringTransactionsScreen> with TickerProviderStateMixin {
  final RecurringTransactionDao _recurringDao = RecurringTransactionDao();
  final PaymentDao _paymentDao = PaymentDao();

  late TabController _tabController;
  List<RecurringTransaction> _allTransactions = [];
  List<RecurringTransaction> _dueTransactions = [];
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
      final allTransactions = await _recurringDao.find();
      final dueTransactions = await _recurringDao.getDueTransactions();

      setState(() {
        _allTransactions = allTransactions;
        _dueTransactions = dueTransactions;
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
        title: const Text('Recurring Transactions'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Due (${_dueTransactions.length})'),
            Tab(text: 'All (${_allTransactions.length})'),
            const Tab(text: 'Statistics'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Symbols.add),
            onPressed: _addRecurringTransaction,
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
                  'Recurring Transactions',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _addRecurringTransaction,
                  icon: const Icon(Symbols.add),
                  label: const Text('Add Recurring'),
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
              Tab(text: 'Due (${_dueTransactions.length})'),
              Tab(text: 'All (${_allTransactions.length})'),
              const Tab(text: 'Statistics'),
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
        _buildDueTransactionsList(),
        _buildAllTransactionsList(),
        _buildStatistics(),
      ],
    );
  }

  Widget _buildDueTransactionsList() {
    if (_dueTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Symbols.schedule,
              size: ResponsiveHelper.getResponsiveIconSize(context, 64),
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No due transactions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'All your recurring transactions are up to date!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: ResponsiveHelper.getResponsivePadding(context),
      itemCount: _dueTransactions.length,
      itemBuilder: (context, index) {
        final transaction = _dueTransactions[index];
        return _buildTransactionCard(transaction, isDue: true);
      },
    );
  }

  Widget _buildAllTransactionsList() {
    if (_allTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Symbols.repeat,
              size: ResponsiveHelper.getResponsiveIconSize(context, 64),
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No recurring transactions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first recurring transaction to automate your finances',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _addRecurringTransaction,
              icon: const Icon(Symbols.add),
              label: const Text('Add Recurring Transaction'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: ResponsiveHelper.getResponsivePadding(context),
      itemCount: _allTransactions.length,
      itemBuilder: (context, index) {
        final transaction = _allTransactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  Widget _buildTransactionCard(RecurringTransaction transaction,
      {bool isDue = false}) {
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
                // Transaction Type Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: transaction.type == PaymentType.credit
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    transaction.type == PaymentType.credit
                        ? Symbols.trending_up
                        : Symbols.trending_down,
                    color: transaction.type == PaymentType.credit
                        ? Colors.green
                        : Colors.red,
                    size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                  ),
                ),

                const SizedBox(width: 12),

                // Transaction Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      if (transaction.description.isNotEmpty)
                        Text(
                          transaction.description,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                    ],
                  ),
                ),

                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyHelper.format(transaction.amount, name: currency),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: transaction.type == PaymentType.credit
                                ? Colors.green
                                : Colors.red,
                          ),
                    ),
                    Text(
                      transaction.getRecurrenceDescription(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
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
                  icon: Symbols.account_balance,
                  label: transaction.account.name,
                ),
                const SizedBox(width: 8),
                _buildDetailChip(
                  icon: Symbols.category,
                  label: transaction.category.name,
                ),
                const SizedBox(width: 8),
                _buildDetailChip(
                  icon: Symbols.info,
                  label: transaction.getStatusDescription(),
                  color: _getStatusColor(transaction.status),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Next Due & Actions
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next Due: ${transaction.nextDue != null ? DateFormat('MMM dd, yyyy').format(transaction.nextDue!) : 'N/A'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      Text(
                        'Executed: ${transaction.executedCount} times',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),

                // Action Buttons
                if (isDue) ...[
                  ElevatedButton.icon(
                    onPressed: () => _executeTransaction(transaction),
                    icon: const Icon(Symbols.play_arrow, size: 16),
                    label: const Text('Execute'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(value, transaction),
                  itemBuilder: (context) => [
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
                    if (transaction.status == RecurrenceStatus.active)
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
                    if (transaction.status == RecurrenceStatus.paused)
                      const PopupMenuItem(
                        value: 'resume',
                        child: Row(
                          children: [
                            Icon(Symbols.play_arrow),
                            SizedBox(width: 8),
                            Text('Resume'),
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

  Color _getStatusColor(RecurrenceStatus status) {
    switch (status) {
      case RecurrenceStatus.active:
        return Colors.green;
      case RecurrenceStatus.paused:
        return Colors.orange;
      case RecurrenceStatus.completed:
        return Colors.blue;
      case RecurrenceStatus.cancelled:
        return Colors.red;
    }
  }

  Widget _buildStatistics() {
    return SingleChildScrollView(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 16),

          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Active',
                  _allTransactions
                      .where((t) => t.status == RecurrenceStatus.active)
                      .length
                      .toString(),
                  Symbols.repeat,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Due Now',
                  _dueTransactions.length.toString(),
                  Symbols.schedule,
                  Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Paused',
                  _allTransactions
                      .where((t) => t.status == RecurrenceStatus.paused)
                      .length
                      .toString(),
                  Symbols.pause,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Completed',
                  _allTransactions
                      .where((t) => t.status == RecurrenceStatus.completed)
                      .length
                      .toString(),
                  Symbols.check_circle,
                  Colors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Monthly Projection
          Text(
            'Monthly Projection',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 16),

          _buildMonthlyProjection(),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyProjection() {
    final currency = context.read<AppCubit>().state.currency ?? 'USD';
    double monthlyIncome = 0;
    double monthlyExpense = 0;

    for (final transaction in _allTransactions) {
      if (transaction.status != RecurrenceStatus.active) continue;

      double monthlyAmount = 0;
      switch (transaction.recurrenceType) {
        case RecurrenceType.daily:
          monthlyAmount = transaction.amount * 30;
          break;
        case RecurrenceType.weekly:
          monthlyAmount = transaction.amount * 4.33;
          break;
        case RecurrenceType.biweekly:
          monthlyAmount = transaction.amount * 2.17;
          break;
        case RecurrenceType.monthly:
          monthlyAmount = transaction.amount;
          break;
        case RecurrenceType.quarterly:
          monthlyAmount = transaction.amount / 3;
          break;
        case RecurrenceType.yearly:
          monthlyAmount = transaction.amount / 12;
          break;
      }

      if (transaction.type == PaymentType.credit) {
        monthlyIncome += monthlyAmount;
      } else {
        monthlyExpense += monthlyAmount;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Monthly Income:',
                    style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  CurrencyHelper.format(monthlyIncome, name: currency),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Monthly Expenses:',
                    style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  CurrencyHelper.format(monthlyExpense, name: currency),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Net Monthly:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  CurrencyHelper.format(monthlyIncome - monthlyExpense,
                      name: currency),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: monthlyIncome - monthlyExpense >= 0
                            ? Colors.green
                            : Colors.red,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addRecurringTransaction() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add recurring transaction coming soon')),
    );
  }

  Future<void> _executeTransaction(RecurringTransaction transaction) async {
    try {
      final payment = transaction.createPayment();
      await _paymentDao.create(payment);
      await _recurringDao.markAsExecuted(transaction.id!);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${transaction.title} executed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error executing transaction: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleMenuAction(
      String action, RecurringTransaction transaction) async {
    try {
      switch (action) {
        case 'edit':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Edit recurring transaction coming soon')),
          );
          break;
        case 'pause':
          await _recurringDao.pauseTransaction(transaction.id!);
          await _loadData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${transaction.title} paused')),
            );
          }
          break;
        case 'resume':
          await _recurringDao.resumeTransaction(transaction.id!);
          await _loadData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${transaction.title} resumed')),
            );
          }
          break;
        case 'delete':
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Recurring Transaction'),
              content: Text(
                  'Are you sure you want to delete "${transaction.title}"?'),
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
            await _recurringDao.delete(transaction.id!);
            await _loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${transaction.title} deleted')),
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
