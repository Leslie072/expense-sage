import 'package:flutter/material.dart';
import 'package:expense_sage/dao/category_dao.dart';
import 'package:expense_sage/model/category.model.dart';

import 'package:expense_sage/helpers/currency.helper.dart';
import 'package:expense_sage/bloc/cubit/app_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final CategoryDao _categoryDao = CategoryDao();
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryDao.find(withSummery: true);
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading categories: $e')),
        );
      }
    }
  }

  Future<void> _setBudget(Category category) async {
    final TextEditingController controller = TextEditingController(
      text: category.budget?.toString() ?? '',
    );

    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Budget for ${category.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Current spending this month: ${CurrencyHelper.format(category.expense ?? 0, name: context.read<AppCubit>().state.currency, symbol: context.read<AppCubit>().state.currency)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Budget Amount',
                hintText: 'Enter budget amount',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final budget = double.tryParse(controller.text);
              Navigator.of(context).pop(budget);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        category.budget = result;
        await _categoryDao.update(category);
        _loadCategories(); // Refresh the list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Budget updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating budget: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Management'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? const Center(
                  child: Text(
                    'No categories found.\nAdd some categories first.',
                    textAlign: TextAlign.center,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCategories,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final budget = category.budget ?? 0;
                      final spent = category.expense ?? 0;
                      final remaining = budget - spent;
                      final progress =
                          budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor:
                                        category.color.withValues(alpha: 0.2),
                                    child: Icon(
                                      category.icon,
                                      color: category.color,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          category.name,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (budget > 0) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Budget: ${CurrencyHelper.format(budget, name: context.read<AppCubit>().state.currency, symbol: context.read<AppCubit>().state.currency)}',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _setBudget(category),
                                    icon: Icon(
                                      budget > 0 ? Icons.edit : Icons.add,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              if (budget > 0) ...[
                                const SizedBox(height: 16),

                                // Progress bar
                                LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    progress > 1.0
                                        ? Colors.red
                                        : progress > 0.8
                                            ? Colors.orange
                                            : Colors.green,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // Budget details
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Spent',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          CurrencyHelper.format(spent,
                                              name: context
                                                  .read<AppCubit>()
                                                  .state
                                                  .currency,
                                              symbol: context
                                                  .read<AppCubit>()
                                                  .state
                                                  .currency),
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: progress > 1.0
                                                ? Colors.red
                                                : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          remaining >= 0
                                              ? 'Remaining'
                                              : 'Over Budget',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          CurrencyHelper.format(remaining.abs(),
                                              name: context
                                                  .read<AppCubit>()
                                                  .state
                                                  .currency,
                                              symbol: context
                                                  .read<AppCubit>()
                                                  .state
                                                  .currency),
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: remaining < 0
                                                ? Colors.red
                                                : Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                if (progress > 0.8) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (progress > 1.0
                                              ? Colors.red
                                              : Colors.orange)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          progress > 1.0
                                              ? Icons.warning
                                              : Icons.info,
                                          size: 16,
                                          color: progress > 1.0
                                              ? Colors.red
                                              : Colors.orange,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          progress > 1.0
                                              ? 'Budget exceeded!'
                                              : 'Approaching budget limit',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: progress > 1.0
                                                ? Colors.red
                                                : Colors.orange,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ] else ...[
                                const SizedBox(height: 8),
                                Text(
                                  'No budget set. Tap + to set a budget.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
