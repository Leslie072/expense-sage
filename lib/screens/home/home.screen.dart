import 'package:events_emitter/events_emitter.dart';
import 'package:expense_sage/bloc/cubit/app_cubit.dart';
import 'package:expense_sage/dao/account_dao.dart';
import 'package:expense_sage/dao/payment_dao.dart';
import 'package:expense_sage/events.dart';
import 'package:expense_sage/model/account.model.dart';
import 'package:expense_sage/model/category.model.dart';
import 'package:expense_sage/model/payment.model.dart';
import 'package:expense_sage/screens/home/widgets/account_slider.dart';
import 'package:expense_sage/screens/payment_form.screen.dart';
import 'package:expense_sage/widgets/cards/dashboard_card.dart';
import 'package:expense_sage/widgets/cards/transaction_card.dart';
import 'package:expense_sage/widgets/quick_actions_widget.dart';
import 'package:expense_sage/widgets/theme_toggle_widget.dart';
import 'package:expense_sage/theme/app_theme.dart';
import 'package:expense_sage/helpers/currency.helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

String greeting() {
  var hour = DateTime.now().hour;
  if (hour < 12) {
    return 'Morning';
  }
  if (hour < 17) {
    return 'Afternoon';
  }
  return 'Evening';
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PaymentDao _paymentDao = PaymentDao();
  final AccountDao _accountDao = AccountDao();
  EventListener? _accountEventListener;
  EventListener? _categoryEventListener;
  EventListener? _paymentEventListener;
  List<Payment> _payments = [];
  List<Account> _accounts = [];
  double _income = 0;
  double _expense = 0;
  //double _savings = 0;
  DateTimeRange _range = DateTimeRange(
      start: DateTime.now().subtract(Duration(days: DateTime.now().day - 1)),
      end: DateTime.now());
  Account? _account;
  Category? _category;

  void openAddPaymentPage(PaymentType type) async {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (builder) => PaymentForm(type: type)));
  }

  void _handleQuickAction(String action, double? amount) {
    switch (action) {
      case 'add_income':
        // Create quick income transaction
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (builder) => PaymentForm(
              type: PaymentType.debit,
            ),
          ),
        );
        break;
      case 'add_expense':
        // Create quick expense transaction
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (builder) => PaymentForm(
              type: PaymentType.credit,
            ),
          ),
        );
        break;
      case 'save_money':
        // Navigate to savings goals
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Savings feature coming soon!'),
            backgroundColor: Colors.blue,
          ),
        );
        break;
      case 'view_reports':
        // Navigate to reports
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check the Reports tab for detailed analytics!'),
            backgroundColor: Colors.purple,
          ),
        );
        break;
    }
  }

  void handleChooseDateRange() async {
    final selected = await showDateRangePicker(
      context: context,
      initialDateRange: _range,
      firstDate: DateTime(2019),
      lastDate: DateTime.now(),
    );
    if (selected != null) {
      setState(() {
        _range = selected;
        _fetchTransactions();
      });
    }
  }

  void _fetchTransactions() async {
    List<Payment> trans = await _paymentDao.find(
        range: _range, category: _category, account: _account);
    double income = 0;
    double expense = 0;
    for (var payment in trans) {
      if (payment.type == PaymentType.credit) income += payment.amount;
      if (payment.type == PaymentType.debit) expense += payment.amount;
    }

    //fetch accounts
    List<Account> accounts = await _accountDao.find(withSummery: true);

    setState(() {
      _payments = trans;
      _income = income;
      _expense = expense;
      _accounts = accounts;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchTransactions();

    _accountEventListener = globalEvent.on("account_update", (data) {
      debugPrint("accounts are changed");
      _fetchTransactions();
    });

    _categoryEventListener = globalEvent.on("category_update", (data) {
      debugPrint("categories are changed");
      _fetchTransactions();
    });

    _paymentEventListener = globalEvent.on("payment_update", (data) {
      debugPrint("payments are changed");
      _fetchTransactions();
    });
  }

  @override
  void dispose() {
    _accountEventListener?.cancel();
    _categoryEventListener?.cancel();
    _paymentEventListener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header Section
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spacing20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting
                    Text(
                      "Hi! Good ${greeting()}",
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.textPrimary,
                      ),
                    ),

                    const SizedBox(height: AppTheme.spacing8),

                    BlocConsumer<AppCubit, AppState>(
                      listener: (context, state) {},
                      builder: (context, state) => Text(
                        state.username ?? "Guest",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Financial Overview Cards
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Balance Overview
                  DashboardCard(
                    title: 'Total Balance',
                    value: CurrencyHelper.format(
                      _accounts.fold(0.0,
                          (sum, account) => sum + (account.balance ?? 0.0)),
                      name: context.read<AppCubit>().state.currency ?? 'USD',
                      symbol: context.read<AppCubit>().state.currency ?? 'USD',
                    ),
                    subtitle: '${_accounts.length} accounts',
                    icon: Icons.account_balance_wallet,
                    iconColor: AppTheme.primaryColor,
                  ),

                  // Income/Expense Row
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing8),
                    child: Row(
                      children: [
                        Expanded(
                          child: DashboardCard(
                            title: 'Income',
                            value: CurrencyHelper.format(
                              _income,
                              name: context.read<AppCubit>().state.currency ??
                                  'USD',
                              symbol: context.read<AppCubit>().state.currency ??
                                  'USD',
                            ),
                            subtitle: 'This month',
                            icon: Icons.trending_up,
                            iconColor: AppTheme.successColor,
                            backgroundColor: AppTheme.successColor,
                          ),
                        ),
                        Expanded(
                          child: DashboardCard(
                            title: 'Expenses',
                            value: CurrencyHelper.format(
                              _expense,
                              name: context.read<AppCubit>().state.currency ??
                                  'USD',
                              symbol: context.read<AppCubit>().state.currency ??
                                  'USD',
                            ),
                            subtitle: 'This month',
                            icon: Icons.trending_down,
                            iconColor: AppTheme.errorColor,
                            backgroundColor: AppTheme.errorColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Accounts Section
            SliverToBoxAdapter(
              child: Column(
                children: [
                  AccountsSlider(accounts: _accounts),
                  const SizedBox(height: AppTheme.spacing16),
                ],
              ),
            ),

            // Quick Actions Section
            SliverToBoxAdapter(
              child: QuickActionsWidget(
                onActionTap: (action, amount) {
                  _handleQuickAction(action, amount);
                },
              ),
            ),
            // Transactions Header
            SliverToBoxAdapter(
              child: TransactionListHeader(
                title: 'Recent Transactions',
                subtitle:
                    "${DateFormat("dd MMM").format(_range.start)} - ${DateFormat("dd MMM").format(_range.end)}",
                trailing: TextButton.icon(
                  onPressed: handleChooseDateRange,
                  icon: const Icon(Icons.date_range, size: 18),
                  label: const Text('Filter'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing12,
                      vertical: AppTheme.spacing8,
                    ),
                  ),
                ),
              ),
            ),

            // Transactions List
            _payments.isNotEmpty
                ? SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return TransactionCard(
                          payment: _payments[index],
                          currency:
                              context.read<AppCubit>().state.currency ?? 'USD',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (builder) => PaymentForm(
                                  type: _payments[index].type,
                                  payment: _payments[index],
                                ),
                              ),
                            );
                          },
                          showActions: true,
                          onEdit: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (builder) => PaymentForm(
                                  type: _payments[index].type,
                                  payment: _payments[index],
                                ),
                              ),
                            );
                          },
                          onDelete: () {
                            // Handle delete
                          },
                        );
                      },
                      childCount: _payments.length,
                    ),
                  )
                : SliverToBoxAdapter(
                    child: TransactionEmptyState(
                      title: 'No Transactions Yet',
                      subtitle:
                          'Start tracking your expenses by adding your first transaction',
                      icon: Icons.receipt_long,
                      actionText: 'Add Transaction',
                      onAction: () => openAddPaymentPage(PaymentType.credit),
                    ),
                  ),

            // Bottom spacing
            const SliverToBoxAdapter(
              child: SizedBox(height: AppTheme.spacing64),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openAddPaymentPage(PaymentType.credit),
        child: const Icon(Icons.add),
      ),
    );
  }
}
