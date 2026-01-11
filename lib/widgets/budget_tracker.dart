import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/colors.dart';
import '../providers/transaction_provider.dart';
import '../providers/budget_provider.dart';
import '../utils/formatters.dart';
import 'glassmorphic_card.dart';

class BudgetTrackerWidget extends StatefulWidget {
  const BudgetTrackerWidget({super.key});

  @override
  State<BudgetTrackerWidget> createState() => _BudgetTrackerWidgetState();
}

class _BudgetTrackerWidgetState extends State<BudgetTrackerWidget> {
  final _budgetController = TextEditingController();
  bool _isEditing = false;

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  void _saveBudget() {
    final budget = double.tryParse(_budgetController.text.replaceAll('.', '')) ?? 0;
    context.read<BudgetProvider>().setMonthlyBudget(budget);
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final budgetProvider = context.watch<BudgetProvider>();
    final transactionProvider = context.watch<TransactionProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final monthlyBudget = budgetProvider.monthlyBudget;
    final spent = transactionProvider.thisMonthExpense;
    final remaining = monthlyBudget - spent;
    final percentage = monthlyBudget > 0 ? (spent / monthlyBudget).clamp(0.0, 1.0) : 0.0;
    
    Color progressColor;
    if (percentage < 0.5) {
      progressColor = AppColors.income;
    } else if (percentage < 0.8) {
      progressColor = AppColors.warning;
    } else {
      progressColor = AppColors.expense;
    }

    return GlassmorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Budget Bulanan',
                    style: TextStyle(
                      color: theme.textTheme.titleMedium?.color,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {
                  _budgetController.text = monthlyBudget.toStringAsFixed(0);
                  setState(() => _isEditing = true);
                },
                icon: Icon(
                  Icons.edit_outlined,
                  color: theme.textTheme.bodySmall?.color,
                  size: 20,
                ),
              ),
            ],
          ),
          
          if (_isEditing) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _budgetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Masukkan budget',
                      prefixText: 'Rp ',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saveBudget,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Simpan'),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 16),
            
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 10,
                backgroundColor: isDark 
                    ? AppColors.surfaceLight 
                    : AppColors.borderLightGray,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Terpakai',
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.formatCompactCurrency(spent),
                      style: TextStyle(
                        color: progressColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Budget',
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.formatCompactCurrency(monthlyBudget),
                      style: TextStyle(
                        color: theme.textTheme.titleMedium?.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Sisa',
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.formatCompactCurrency(remaining > 0 ? remaining : 0),
                      style: TextStyle(
                        color: remaining > 0 ? AppColors.income : AppColors.expense,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            if (percentage >= 0.8) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.expense.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.expense.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.expense,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      percentage >= 1.0 
                          ? 'Budget sudah habis!' 
                          : 'Hampir mencapai limit!',
                      style: const TextStyle(
                        color: AppColors.expense,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
