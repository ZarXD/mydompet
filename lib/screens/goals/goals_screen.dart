import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../theme/colors.dart';
import '../../models/savings_goal.dart';
import '../../providers/budget_provider.dart';
import '../../widgets/glassmorphic_card.dart';
import '../../utils/formatters.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // Header
          _buildHeader(context).animate().fadeIn(duration: 300.ms),
          
          // Goals List
          Expanded(
            child: _buildGoalsList(context).animate(delay: 100.ms).fadeIn(duration: 300.ms),
          ),
          
          const SizedBox(height: 100), // Clear space for floating nav
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Savings Goals',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Wujudkan impianmu! 🎯',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              onPressed: () => _showAddGoalDialog(context),
              icon: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsList(BuildContext context) {
    final budgetProvider = context.watch<BudgetProvider>();
    final goals = budgetProvider.goals;

    if (goals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flag_outlined,
              size: 64,
              color: AppColors.textMuted.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada goal',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Buat goal untuk mulai menabung',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddGoalDialog(context),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Buat Goal'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: goals.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: index < goals.length - 1 ? 16 : 80),
          child: _GoalCard(
            goal: goals[index],
            onAddFunds: () => _showAddFundsDialog(context, goals[index]),
            onDelete: () => budgetProvider.deleteGoal(goals[index].id),
          ).animate(delay: (index * 100).ms).fadeIn().slideX(begin: 0.1),
        );
      },
    );
  }

  void _showAddGoalDialog(BuildContext context) {
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    DateTime? deadline;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Buat Goal Baru',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                decoration: const InputDecoration(
                  labelText: 'Nama Goal',
                  hintText: 'Contoh: iPhone 16 Pro',
                  prefixIcon: Icon(Icons.flag_outlined, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: targetController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                decoration: const InputDecoration(
                  labelText: 'Target Nominal',
                  hintText: '10000000',
                  prefixText: 'Rp ',
                  prefixIcon: Icon(Icons.attach_money, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: AppColors.info,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Deadline (opsional)',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                subtitle: Text(
                  deadline != null
                      ? '${deadline!.day}/${deadline!.month}/${deadline!.year}'
                      : 'Pilih tanggal',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppColors.primaryStart,
                          surface: AppColors.surface,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setState(() => deadline = picked);
                  }
                },
              ),
              const SizedBox(height: 24),
              Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isEmpty || targetController.text.isEmpty) {
                      return;
                    }
                    
                    final goal = SavingsGoal(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text,
                      targetAmount: double.parse(targetController.text.replaceAll('.', '')),
                      deadline: deadline,
                    );
                    
                    context.read<BudgetProvider>().addGoal(goal);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  child: const Text('Buat Goal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddFundsDialog(BuildContext context, SavingsGoal goal) {
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Tambah Dana ke "${goal.name}"',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Sisa ${Formatters.formatCurrency(goal.targetAmount - goal.currentAmount)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              decoration: const InputDecoration(
                labelText: 'Nominal',
                hintText: '100000',
                prefixText: 'Rp ',
                prefixIcon: Icon(Icons.add, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.incomeGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton(
                onPressed: () {
                  if (amountController.text.isEmpty) return;
                  
                  final amount = double.parse(amountController.text.replaceAll('.', ''));
                  context.read<BudgetProvider>().addToGoal(goal.id, amount);
                  Navigator.pop(context);
                  
                  if (goal.currentAmount + amount >= goal.targetAmount) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🎉 Goal "${goal.name}" tercapai!'),
                        backgroundColor: AppColors.income,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                child: const Text('Tambah Dana'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final VoidCallback onAddFunds;
  final VoidCallback onDelete;

  const _GoalCard({
    required this.goal,
    required this.onAddFunds,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final progress = goal.progress;
    final isCompleted = goal.isCompleted;

    return GlassmorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.income.withOpacity(0.2)
                      : AppColors.warning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle : Icons.flag,
                  color: isCompleted ? AppColors.income : AppColors.warning,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (goal.daysRemaining != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${goal.daysRemaining} hari lagi',
                        style: TextStyle(
                          color: goal.daysRemaining! < 7
                              ? AppColors.expense
                              : AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: AppColors.expense, size: 20),
                        SizedBox(width: 8),
                        Text('Hapus'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'delete') onDelete();
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted ? AppColors.income : AppColors.primaryStart,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Amount Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Terkumpul',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.formatCompactCurrency(goal.currentAmount),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Target',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.formatCompactCurrency(goal.targetAmount),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Add Funds Button
          if (!isCompleted)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAddFunds,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah Dana'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.income,
                  side: const BorderSide(color: AppColors.income),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.income.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.income.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: AppColors.income, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Goal Tercapai! 🎉',
                    style: TextStyle(
                      color: AppColors.income,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
