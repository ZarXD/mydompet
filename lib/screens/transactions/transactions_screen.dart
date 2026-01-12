import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../theme/colors.dart';
import '../../models/transaction.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/glassmorphic_card.dart';
import '../../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          _buildHeader(context).animate().fadeIn(duration: 300.ms),
          
          // Filters
          _buildFilters(context).animate(delay: 100.ms).fadeIn(duration: 300.ms),
          
          // Transaction List
          Expanded(
            child: _buildTransactionList(context).animate(delay: 200.ms).fadeIn(duration: 300.ms),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final transactionProvider = context.watch<TransactionProvider>();
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Riwayat Transaksi',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            '${transactionProvider.transactions.length} transaksi tercatat',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    final transactionProvider = context.watch<TransactionProvider>();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Search Bar
          TextField(
            onChanged: (value) => transactionProvider.setSearchQuery(value),
            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            decoration: InputDecoration(
              hintText: 'Cari transaksi...',
              prefixIcon: Icon(Icons.search, color: Theme.of(context).textTheme.bodySmall?.color),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Semua',
                  isSelected: transactionProvider.typeFilter == 'all',
                  onTap: () => transactionProvider.setTypeFilter('all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Pemasukan',
                  isSelected: transactionProvider.typeFilter == 'income',
                  color: AppColors.income,
                  onTap: () => transactionProvider.setTypeFilter('income'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Pengeluaran',
                  isSelected: transactionProvider.typeFilter == 'expense',
                  color: AppColors.expense,
                  onTap: () => transactionProvider.setTypeFilter('expense'),
                ),
                const SizedBox(width: 8),
                
                // Category Dropdown
                PopupMenuButton<String>(
                  initialValue: transactionProvider.categoryFilter,
                  onSelected: (value) => transactionProvider.setCategoryFilter(value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'all', child: Text('Semua Kategori')),
                    ...transactionCategories.map((cat) => PopupMenuItem(
                      value: cat,
                      child: Row(
                        children: [
                          Text(categoryIcons[cat] ?? '📦'),
                          const SizedBox(width: 8),
                          Text(cat),
                        ],
                      ),
                    )),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: transactionProvider.categoryFilter != 'all'
                          ? AppColors.info.withOpacity(0.2)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: transactionProvider.categoryFilter != 'all'
                            ? AppColors.info
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          transactionProvider.categoryFilter == 'all'
                              ? 'Kategori'
                              : transactionProvider.categoryFilter,
                          style: TextStyle(
                            color: transactionProvider.categoryFilter != 'all'
                                ? AppColors.info
                                : AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down,
                          color: transactionProvider.categoryFilter != 'all'
                              ? AppColors.info
                              : AppColors.textMuted,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(BuildContext context) {
    final transactionProvider = context.watch<TransactionProvider>();
    final transactions = transactionProvider.filteredTransactions;

    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada transaksi',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Transaksi yang kamu tambahkan\nakan muncul di sini',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Group transactions by date
    final groupedTransactions = <String, List<Transaction>>{};
    for (final t in transactions) {
      final dateKey = '${t.date.year}-${t.date.month}-${t.date.day}';
      groupedTransactions.putIfAbsent(dateKey, () => []).add(t);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: groupedTransactions.length,
      itemBuilder: (context, index) {
        final dateKey = groupedTransactions.keys.elementAt(index);
        final dayTransactions = groupedTransactions[dateKey]!;
        final date = dayTransactions.first.date;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            Padding(
              padding: EdgeInsets.only(bottom: 8, top: index > 0 ? 16 : 0),
              child: Text(
                _formatDateHeader(date),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            // Transactions for this date
            GlassmorphicCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: dayTransactions.map((t) => TransactionTileWithActions(
                  transaction: t,
                  onEdit: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddTransactionScreen(editTransaction: t),
                      ),
                    );
                  },
                  onDelete: () {
                    transactionProvider.deleteTransaction(t.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Transaksi dihapus'),
                        backgroundColor: AppColors.expense,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                )).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return 'Hari ini';
    } else if (transactionDate == yesterday) {
      return 'Kemarin';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primaryStart;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withOpacity(0.2) : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? chipColor : Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
