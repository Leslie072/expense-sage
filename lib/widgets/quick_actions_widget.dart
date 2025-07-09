import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuickActionsWidget extends StatefulWidget {
  final Function(String action, double? amount)? onActionTap;

  const QuickActionsWidget({
    super.key,
    this.onActionTap,
  });

  @override
  State<QuickActionsWidget> createState() => _QuickActionsWidgetState();
}

class _QuickActionsWidgetState extends State<QuickActionsWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _animations;

  final List<QuickAction> _actions = [
    QuickAction(
      icon: Icons.add_circle,
      label: 'Add Income',
      color: Colors.green,
      action: 'add_income',
    ),
    QuickAction(
      icon: Icons.remove_circle,
      label: 'Add Expense',
      color: Colors.red,
      action: 'add_expense',
    ),
    QuickAction(
      icon: Icons.savings,
      label: 'Save Money',
      color: Colors.blue,
      action: 'save_money',
    ),
    QuickAction(
      icon: Icons.analytics,
      label: 'View Reports',
      color: Colors.purple,
      action: 'view_reports',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _animations = List.generate(
      _actions.length,
      (index) => Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            index * 0.2,
            0.8 + index * 0.2,
            curve: Curves.elasticOut,
          ),
        ),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleActionTap(QuickAction action) {
    HapticFeedback.lightImpact();
    
    if (action.action == 'add_income' || action.action == 'add_expense') {
      _showQuickAmountDialog(action);
    } else {
      widget.onActionTap?.call(action.action, null);
    }
  }

  void _showQuickAmountDialog(QuickAction action) {
    final TextEditingController amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(action.icon, color: action.color),
            const SizedBox(width: 8),
            Text(action.label),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '\$',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ...[10, 25, 50, 100].map((amount) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: ElevatedButton(
                      onPressed: () {
                        amountController.text = amount.toString();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: action.color.withOpacity(0.1),
                        foregroundColor: action.color,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text('\$$amount'),
                    ),
                  ),
                )),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                Navigator.pop(context);
                widget.onActionTap?.call(action.action, amount);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: action.color,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: _actions.length,
            itemBuilder: (context, index) {
              final action = _actions[index];
              return AnimatedBuilder(
                animation: _animations[index],
                builder: (context, child) {
                  return Transform.scale(
                    scale: _animations[index].value,
                    child: GestureDetector(
                      onTap: () => _handleActionTap(action),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              action.color.withOpacity(0.1),
                              action.color.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: action.color.withOpacity(0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: action.color.withOpacity(0.1),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              action.icon,
                              size: 32,
                              color: action.color,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              action.label,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: action.color,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final String action;

  QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.action,
  });
}
