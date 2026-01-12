import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../theme/colors.dart';
import '../../models/transaction.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/glassmorphic_card.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? editTransaction;
  
  const AddTransactionScreen({super.key, this.editTransaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _type = 'expense';
  String _category = 'Lainnya';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  bool get isEditing => widget.editTransaction != null;

  @override
  void initState() {
    super.initState();
    if (widget.editTransaction != null) {
      final t = widget.editTransaction!;
      _amountController.text = t.amount.toStringAsFixed(0);
      _descController.text = t.description;
      _notesController.text = t.notes ?? '';
      _type = t.type;
      _category = t.category;
      _selectedDate = t.date;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final transactionProvider = context.read<TransactionProvider>();
    
    final transaction = Transaction(
      id: widget.editTransaction?.id ?? const Uuid().v4(),
      type: _type,
      amount: double.parse(_amountController.text.replaceAll('.', '')),
      description: _descController.text,
      category: _category,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      date: _selectedDate,
    );

    if (isEditing) {
      transactionProvider.updateTransaction(transaction);
    } else {
      transactionProvider.addTransaction(transaction);
    }

    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    Navigator.of(context).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isEditing ? 'Transaksi diperbarui!' : 'Transaksi ditambahkan!'),
        backgroundColor: AppColors.income,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryStart,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader().animate().fadeIn(duration: 300.ms),
              
              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Type Selector
                        _buildTypeSelector().animate(delay: 100.ms).fadeIn().slideY(begin: 0.1),
                        
                        const SizedBox(height: 24),
                        
                        // Amount Input
                        _buildAmountInput().animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),
                        
                        const SizedBox(height: 20),
                        
                        // Description & Notes
                        _buildDescriptionForm().animate(delay: 300.ms).fadeIn().slideY(begin: 0.1),
                        
                        const SizedBox(height: 20),
                        
                        // Category Selector
                        _buildCategorySelector().animate(delay: 400.ms).fadeIn().slideY(begin: 0.1),
                        
                        const SizedBox(height: 20),
                        
                        // Date Selector
                        _buildDateSelector().animate(delay: 500.ms).fadeIn().slideY(begin: 0.1),
                        
                        const SizedBox(height: 32),
                        
                        // Save Button
                        _buildSaveButton().animate(delay: 600.ms).fadeIn().slideY(begin: 0.1),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          ),
          Text(
            isEditing ? 'Edit Transaksi' : 'Tambah Transaksi',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: _TypeButton(
              label: 'Pengeluaran',
              icon: Icons.arrow_upward_rounded,
              isSelected: _type == 'expense',
              color: AppColors.expense,
              onTap: () => setState(() => _type = 'expense'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TypeButton(
              label: 'Pemasukan',
              icon: Icons.arrow_downward_rounded,
              isSelected: _type == 'income',
              color: AppColors.income,
              onTap: () => setState(() => _type = 'income'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput() {
    return GlassmorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nominal',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Rp',
                style: TextStyle(
                  color: _type == 'income' ? AppColors.income : AppColors.expense,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: _type == 'income' ? AppColors.income : AppColors.expense,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Masukkan nominal';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionForm() {
    return GlassmorphicCard(
      child: Column(
        children: [
          TextFormField(
            controller: _descController,
            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            decoration: InputDecoration(
              labelText: 'Keterangan',
              hintText: 'Contoh: Makan siang',
              prefixIcon: Icon(Icons.description_outlined, color: Theme.of(context).textTheme.bodySmall?.color),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Masukkan keterangan';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            decoration: InputDecoration(
              labelText: 'Catatan (opsional)',
              hintText: 'Tambahkan catatan...',
              prefixIcon: Icon(Icons.note_outlined, color: Theme.of(context).textTheme.bodySmall?.color),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return GlassmorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kategori',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: transactionCategories.map((cat) {
              final isSelected = _category == cat;
              final icon = categoryIcons[cat] ?? '📦';
              
              return GestureDetector(
                onTap: () => setState(() => _category = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppColors.primaryStart.withOpacity(0.2) 
                        : AppColors.surfaceLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryStart : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        cat,
                        style: TextStyle(
                          color: isSelected ? AppColors.primaryStart : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return GlassmorphicCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.calendar_today_rounded,
            color: AppColors.info,
            size: 20,
          ),
        ),
        title: const Text(
          'Tanggal',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        subtitle: Text(
          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textMuted,
        ),
        onTap: _selectDate,
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: _type == 'income' ? AppColors.incomeGradient : AppColors.expenseGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_type == 'income' ? AppColors.income : AppColors.expense).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveTransaction,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isEditing ? Icons.check : Icons.add, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    isEditing ? 'Simpan Perubahan' : 'Tambah Transaksi',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? color : AppColors.textMuted,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppColors.textMuted,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
