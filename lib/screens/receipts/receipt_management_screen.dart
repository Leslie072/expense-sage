import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:expense_sage/bloc/cubit/app_cubit.dart';
import 'package:expense_sage/dao/receipt_dao.dart';
import 'package:expense_sage/model/receipt.model.dart';
import 'package:expense_sage/helpers/responsive_helper.dart';
import 'package:expense_sage/helpers/currency.helper.dart';
import 'package:intl/intl.dart';

class ReceiptManagementScreen extends StatefulWidget {
  const ReceiptManagementScreen({super.key});

  @override
  State<ReceiptManagementScreen> createState() =>
      _ReceiptManagementScreenState();
}

class _ReceiptManagementScreenState extends State<ReceiptManagementScreen>
    with TickerProviderStateMixin {
  final ReceiptDao _receiptDao = ReceiptDao();
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;
  List<Receipt> _allReceipts = [];
  List<Receipt> _pendingReceipts = [];
  List<Receipt> _processedReceipts = [];
  List<Receipt> _verifiedReceipts = [];
  List<Receipt> _filteredReceipts = [];
  Map<String, dynamic> _receiptsSummary = {};
  bool _isLoading = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final allReceipts = await _receiptDao.find();
      final pendingReceipts = await _receiptDao.getPendingReceipts();
      final processedReceipts = await _receiptDao.getProcessedReceipts();
      final verifiedReceipts = await _receiptDao.getVerifiedReceipts();
      final receiptsSummary = await _receiptDao.getReceiptsSummary();

      setState(() {
        _allReceipts = allReceipts;
        _pendingReceipts = pendingReceipts;
        _processedReceipts = processedReceipts;
        _verifiedReceipts = verifiedReceipts;
        _filteredReceipts = allReceipts;
        _receiptsSummary = receiptsSummary;
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

  Future<void> _searchReceipts(String query) async {
    if (query.isEmpty) {
      setState(() {
        _filteredReceipts = _allReceipts;
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await _receiptDao.searchReceipts(query);
      setState(() {
        _filteredReceipts = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search error: $e')),
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
        title: const Text('Receipt Management'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search receipts...',
                    prefixIcon: const Icon(Symbols.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Symbols.clear),
                            onPressed: () {
                              _searchController.clear();
                              _searchReceipts('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: _searchReceipts,
                ),
              ),

              // Tab Bar
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: [
                  Tab(text: 'All (${_allReceipts.length})'),
                  Tab(text: 'Pending (${_pendingReceipts.length})'),
                  Tab(text: 'Processed (${_processedReceipts.length})'),
                  Tab(text: 'Verified (${_verifiedReceipts.length})'),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Symbols.camera_alt),
            onPressed: _captureReceipt,
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
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'Receipt Management',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 300,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search receipts...',
                          prefixIcon: const Icon(Symbols.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Symbols.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _searchReceipts('');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: _searchReceipts,
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _captureReceipt,
                      icon: const Icon(Symbols.camera_alt),
                      label: const Text('Capture Receipt'),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Symbols.refresh),
                      onPressed: _loadData,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Summary Cards
                _buildSummaryCards(),
              ],
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'All (${_allReceipts.length})'),
              Tab(text: 'Pending (${_pendingReceipts.length})'),
              Tab(text: 'Processed (${_processedReceipts.length})'),
              Tab(text: 'Verified (${_verifiedReceipts.length})'),
            ],
          ),

          // Tab Content
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final currency = context.read<AppCubit>().state.currency ?? 'USD';
    final totalReceipts = _receiptsSummary['totalReceipts'] ?? 0;
    final totalAmount = _receiptsSummary['totalAmount'] ?? 0.0;
    final totalTax = _receiptsSummary['totalTax'] ?? 0.0;
    final pendingCount = _receiptsSummary['pendingCount'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Receipts',
            '$totalReceipts',
            Symbols.receipt_long,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Total Amount',
            CurrencyHelper.format(totalAmount, name: currency),
            Symbols.payments,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Total Tax',
            CurrencyHelper.format(totalTax, name: currency),
            Symbols.receipt,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Pending Review',
            '$pendingCount',
            Symbols.pending,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: ResponsiveHelper.getResponsiveCardElevation(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
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

  Widget _buildTabContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildReceiptsList(_filteredReceipts),
        _buildReceiptsList(_pendingReceipts),
        _buildReceiptsList(_processedReceipts),
        _buildReceiptsList(_verifiedReceipts),
      ],
    );
  }

  Widget _buildReceiptsList(List<Receipt> receipts) {
    if (receipts.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: ResponsiveHelper.getResponsivePadding(context),
      itemCount: receipts.length,
      itemBuilder: (context, index) {
        final receipt = receipts[index];
        return _buildReceiptCard(receipt);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Symbols.receipt_long,
            size: ResponsiveHelper.getResponsiveIconSize(context, 64),
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No receipts found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Capture your first receipt to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _captureReceipt,
            icon: const Icon(Symbols.camera_alt),
            label: const Text('Capture Receipt'),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptCard(Receipt receipt) {
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
                // Receipt Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: receipt.statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Symbols.receipt_long,
                    color: receipt.statusColor,
                    size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                  ),
                ),

                const SizedBox(width: 12),

                // Receipt Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        receipt.merchantName,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      if (receipt.merchantAddress.isNotEmpty)
                        Text(
                          receipt.merchantAddress,
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

                // Amount and Status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyHelper.format(receipt.totalAmount,
                          name: currency),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: receipt.statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        receipt.statusDescription,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: receipt.statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Receipt Details
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date: ${DateFormat('MMM dd, yyyy').format(receipt.transactionDate)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (receipt.receiptNumber.isNotEmpty)
                        Text(
                          'Receipt #: ${receipt.receiptNumber}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      if (receipt.taxAmount > 0)
                        Text(
                          'Tax: ${CurrencyHelper.format(receipt.taxAmount, name: currency)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),

                // Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Symbols.visibility),
                      onPressed: () => _viewReceiptDetails(receipt),
                      tooltip: 'View Details',
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) =>
                          _handleReceiptAction(value, receipt),
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
                        if (receipt.paymentId == null)
                          const PopupMenuItem(
                            value: 'link',
                            child: Row(
                              children: [
                                Icon(Symbols.link),
                                SizedBox(width: 8),
                                Text('Link to Payment'),
                              ],
                            ),
                          ),
                        if (receipt.paymentId != null)
                          const PopupMenuItem(
                            value: 'unlink',
                            child: Row(
                              children: [
                                Icon(Symbols.link_off),
                                SizedBox(width: 8),
                                Text('Unlink Payment'),
                              ],
                            ),
                          ),
                        if (receipt.status != ReceiptStatus.verified)
                          const PopupMenuItem(
                            value: 'verify',
                            child: Row(
                              children: [
                                Icon(Symbols.verified),
                                SizedBox(width: 8),
                                Text('Mark Verified'),
                              ],
                            ),
                          ),
                        if (receipt.status != ReceiptStatus.archived)
                          const PopupMenuItem(
                            value: 'archive',
                            child: Row(
                              children: [
                                Icon(Symbols.archive),
                                SizedBox(width: 8),
                                Text('Archive'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Symbols.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
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

  void _captureReceipt() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Receipt capture coming soon')),
    );
  }

  void _viewReceiptDetails(Receipt receipt) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing ${receipt.merchantName} receipt')),
    );
  }

  Future<void> _handleReceiptAction(String action, Receipt receipt) async {
    try {
      switch (action) {
        case 'edit':
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Edit ${receipt.merchantName} receipt coming soon')),
          );
          break;
        case 'link':
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Link ${receipt.merchantName} receipt coming soon')),
          );
          break;
        case 'unlink':
          await _receiptDao.unlinkFromPayment(receipt.id!);
          await _loadData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('${receipt.merchantName} receipt unlinked')),
            );
          }
          break;
        case 'verify':
          await _receiptDao.updateStatus(receipt.id!, ReceiptStatus.verified);
          await _loadData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('${receipt.merchantName} receipt verified')),
            );
          }
          break;
        case 'archive':
          await _receiptDao.archiveReceipt(receipt.id!);
          await _loadData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('${receipt.merchantName} receipt archived')),
            );
          }
          break;
        case 'delete':
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Receipt'),
              content: Text(
                  'Are you sure you want to delete the receipt from ${receipt.merchantName}?'),
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
            await _receiptDao.delete(receipt.id!);
            await _loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('${receipt.merchantName} receipt deleted')),
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
