import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:universal_html/html.dart' as html;

import '../../theme/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/glassmorphic_card.dart';
import '../../utils/formatters.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  XFile? _profileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final budgetProvider = context.watch<BudgetProvider>();
    final transactionProvider = context.watch<TransactionProvider>();
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate total savings
    final totalSavings = budgetProvider.goals.fold<double>(
      0, (sum, goal) => sum + goal.currentAmount,
    );

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: screenWidth > 600 ? 40 : 20,
          right: screenWidth > 600 ? 40 : 20,
          top: 20,
          bottom: 120, // Clear space for floating nav
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                // Profile Header with Badges
                _buildProfileHeader(context, authProvider, totalSavings)
                    .animate().fadeIn(duration: 300.ms),
                
                const SizedBox(height: 20),
                
                // Achievement Badges
                _buildBadgesSection(context, totalSavings, transactionProvider)
                    .animate(delay: 100.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1),
                
                const SizedBox(height: 20),
                
                // API Key Settings
                _buildApiKeySection(context, authProvider)
                    .animate(delay: 150.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1),
                
                const SizedBox(height: 16),
                
                // Settings List
                _buildSettingsList(context)
                    .animate(delay: 200.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1),
                
                const SizedBox(height: 24),
                
                // Logout Button
                _buildLogoutButton(context, authProvider)
                    .animate(delay: 250.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1),
                
                const SizedBox(height: 120), // Extra space for nav bar
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, AuthProvider authProvider, double totalSavings) {
    // Determine user tier based on savings
    final tier = _getUserTier(totalSavings);
    final avatarUrl = authProvider.avatarUrl;
    
    return GlassmorphicCard(
      child: Column(
        children: [
          // Avatar with Tier Badge and Edit Button
          Stack(
            children: [
              GestureDetector(
                onTap: () => _showImagePickerOptions(context),
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: avatarUrl == null ? tier.gradient : null,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: tier.color.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 3,
                      ),
                    ],
                    image: avatarUrl != null
                        ? DecorationImage(
                            image: NetworkImage(avatarUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: avatarUrl == null
                      ? Center(
                          child: Text(
                            (authProvider.userName ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
              // Camera Button
              Positioned(
                bottom: 0,
                left: 0,
                child: GestureDetector(
                  onTap: () => _showImagePickerOptions(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 14,
                      color: AppColors.primaryStart,
                    ),
                  ),
                ),
              ),
              // Tier Badge
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: tier.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                  child: Icon(
                    tier.icon,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Tier Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              gradient: tier.gradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(tier.icon, size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  tier.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Name
          Text(
            authProvider.userName ?? 'User',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          
          // Email with verified badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                authProvider.userEmail ?? 'email@example.com',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.info,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 10,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Total Savings
          Text(
            'Total Tabungan: ${Formatters.formatCompactCurrency(totalSavings)}',
            style: TextStyle(
              color: AppColors.income,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          
          // Edit Profile Button
          OutlinedButton.icon(
            onPressed: () => _showEditProfileDialog(context, authProvider),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit Profil'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryStart,
              side: const BorderSide(color: AppColors.primaryStart),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection(BuildContext context, double totalSavings, TransactionProvider transactionProvider) {
    final badges = _getEarnedBadges(totalSavings, transactionProvider);
    final earnedCount = badges.where((b) => b.earned).length;
    
    // Sort: earned badges first, then locked
    badges.sort((a, b) {
      if (a.earned == b.earned) return 0;
      return a.earned ? -1 : 1;
    });
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GlassmorphicCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.warning, Colors.orange.shade700],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.military_tech, color: Colors.white, size: 20),
          ),
          title: Text(
            'Achievement Badges',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            '$earnedCount/${badges.length} Terbuka',
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 12,
            ),
          ),
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.85,
              ),
              itemCount: badges.length,
              itemBuilder: (context, index) => _BadgeItem(badge: badges[index]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiKeySection(BuildContext context, AuthProvider authProvider) {
    return GlassmorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.secondaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.smart_toy_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gemini AI API Key',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.titleMedium?.color,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      authProvider.geminiApiKey != null
                          ? 'API key tersimpan ✓'
                          : 'Belum diatur',
                      style: TextStyle(
                        color: authProvider.geminiApiKey != null
                            ? AppColors.income
                            : AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showApiKeyDialog(context, authProvider),
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _launchUrl('https://aistudio.google.com/app/apikey'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.info,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'API key dibutuhkan untuk fitur scan struk. Dapatkan gratis di aistudio.google.com',
                      style: TextStyle(
                        color: AppColors.info.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.open_in_new,
                    color: AppColors.info,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context) {
    return GlassmorphicCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.download_outlined,
            label: 'Export Data',
            subtitle: 'CSV, PDF',
            onTap: () => _showExportDialog(context),
          ),
          const Divider(color: AppColors.border, height: 1),
          _SettingsTile(
            icon: Icons.security_outlined,
            label: 'Keamanan',
            subtitle: 'Biometrik, PIN',
            onTap: () => _showSecurityDialog(context),
          ),
          const Divider(color: AppColors.border, height: 1),
          _SettingsTile(
            icon: Icons.help_outline,
            label: 'Bantuan',
            onTap: () => _showHelpDialog(context),
          ),
          const Divider(color: AppColors.border, height: 1),
          _SettingsTile(
            icon: Icons.info_outline,
            label: 'Tentang Aplikasi',
            subtitle: 'v1.0.0-beta.7',
            onTap: () => _showAboutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthProvider authProvider) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showLogoutConfirmation(context, authProvider),
        icon: const Icon(Icons.logout, size: 18),
        label: const Text('Logout'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.expense,
          side: const BorderSide(color: AppColors.expense),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  // ========== DIALOGS ==========

  void _showEditProfileDialog(BuildContext context, AuthProvider authProvider) {
    final nameController = TextEditingController(text: authProvider.userName ?? '');
    final emailController = TextEditingController(text: authProvider.userEmail ?? '');
    
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
              'Edit Profil',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                prefixIcon: Icon(Icons.person_outline, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted),
                helperText: 'Link konfirmasi dikirim jika email diubah',
                helperMaxLines: 2,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final newName = nameController.text.trim();
                      final newEmail = emailController.text.trim();
                      
                      // Validation
                      if (newName.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Nama tidak boleh kosong'),
                            backgroundColor: AppColors.expense,
                          ),
                        );
                        return;
                      }
                      
                      if (newEmail.isEmpty || !newEmail.contains('@')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Email tidak valid'),
                            backgroundColor: AppColors.expense,
                          ),
                        );
                        return;
                      }
                      
                      Navigator.pop(context);
                      
                      // Update name if changed
                      bool nameSuccess = true;
                      if (newName != authProvider.userName) {
                        nameSuccess = await authProvider.updateUserName(newName);
                      }
                      
                      // Update email if changed
                      bool emailSuccess = true;
                      bool emailChanged = false;
                      if (newEmail != authProvider.userEmail) {
                        emailSuccess = await authProvider.updateUserEmail(newEmail);
                        emailChanged = true;
                      }
                      
                      // Show feedback
                      if (context.mounted) {
                        String message;
                        Color bgColor;
                        
                        if (nameSuccess && emailSuccess) {
                          if (emailChanged) {
                            message = 'Profil diupdate! Cek email untuk konfirmasi';
                          } else {
                            message = 'Profil berhasil diperbarui!';
                          }
                          bgColor = AppColors.income;
                        } else {
                          message = 'Gagal mengupdate profil';
                          bgColor = AppColors.expense;
                        }
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(message),
                            backgroundColor: bgColor,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryStart,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Simpan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showApiKeyDialog(BuildContext context, AuthProvider authProvider) {
    final controller = TextEditingController(text: authProvider.geminiApiKey ?? '');
    
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppColors.secondaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Gemini API Key',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Dapatkan API key gratis di aistudio.google.com/app/apikey',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: controller,
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'Masukkan Gemini API key...',
                prefixIcon: Icon(Icons.key_outlined, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      authProvider.setGeminiApiKey(controller.text);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('API key berhasil disimpan!'),
                          backgroundColor: AppColors.income,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryStart,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Simpan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    String selectedFilter = 'all';  // 'all', '7d', '30d', '90d'
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                  'Export Data',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                
                // Time range filter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedFilter,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Semua Waktu')),
                        DropdownMenuItem(value: '7d', child: Text('7 Hari Terakhir')),
                        DropdownMenuItem(value: '30d', child: Text('30 Hari Terakhir')),
                        DropdownMenuItem(value: '90d', child: Text('90 Hari Terakhir')),
                      ],
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() {
                            selectedFilter = value;
                          });
                        }
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _ExportOptionCard(
                        icon: Icons.table_chart_outlined,
                        label: 'CSV',
                        description: 'Spreadsheet',
                        onTap: () async {
                          Navigator.pop(context);
                          await _exportToCSV(context, selectedFilter);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ExportOptionCard(
                        icon: Icons.picture_as_pdf_outlined,
                        label: 'PDF',
                        description: 'Laporan',
                        onTap: () async {
                          Navigator.pop(context);
                          await _exportToPDF(context, selectedFilter);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _exportToCSV(BuildContext context, [String filter = 'all']) async {
    try {
      final transactionProvider = context.read<TransactionProvider>();
      var transactions = transactionProvider.transactions;
      
      // Apply time filter
      final now = DateTime.now();
      if (filter == '7d') {
        transactions = transactions.where((t) => t.date.isAfter(now.subtract(const Duration(days: 7)))).toList();
      } else if (filter == '30d') {
        transactions = transactions.where((t) => t.date.isAfter(now.subtract(const Duration(days: 30)))).toList();
      } else if (filter == '90d') {
        transactions = transactions.where((t) => t.date.isAfter(now.subtract(const Duration(days: 90)))).toList();
      }
      
      // Prepare CSV data
      List<List<dynamic>> rows = [
        ['Tanggal', 'Kategori', 'Deskripsi', 'Jumlah', 'Tipe'],
      ];
      
      for (var transaction in transactions) {
        rows.add([
          Formatters.formatDate(transaction.date),
          transaction.category,
          transaction.description,
          transaction.amount,
          transaction.type.toUpperCase(),
        ]);
      }
      
      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(rows);
      
      if (kIsWeb) {
        // Web: trigger download
        final bytes = utf8.encode(csv);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'mydompet_transactions.csv')
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // Mobile: save to downloads
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/mydompet_transactions.csv');
        await file.writeAsString(csv);
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data berhasil diekspor ke CSV!'),
            backgroundColor: AppColors.income,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error exporting CSV: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengekspor CSV'),
            backgroundColor: AppColors.expense,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _exportToPDF(BuildContext context, [String filter = 'all']) async {
    try {
      final transactionProvider = context.read<TransactionProvider>();
      var transactions = transactionProvider.transactions;
      final authProvider = context.read<AuthProvider>();
      
      // Apply time filter
      final now = DateTime.now();
      String filterLabel = 'Semua Waktu';
      if (filter == '7d') {
        transactions = transactions.where((t) => t.date.isAfter(now.subtract(const Duration(days: 7)))).toList();
        filterLabel = '7 Hari Terakhir';
      } else if (filter == '30d') {
        transactions = transactions.where((t) => t.date.isAfter(now.subtract(const Duration(days: 30)))).toList();
        filterLabel = '30 Hari Terakhir';
      } else if (filter == '90d') {
        transactions = transactions.where((t) => t.date.isAfter(now.subtract(const Duration(days: 90)))).toList();
        filterLabel = '90 Hari Terakhir';
      }
      
      final pdf = pw.Document();
      
      // Calculate totals
      double totalIncome = transactions
          .where((t) => t.type == 'income')
          .fold(0, (sum, t) => sum + t.amount);
      double totalExpense = transactions
          .where((t) => t.type == 'expense')
          .fold(0, (sum, t) => sum + t.amount);
      
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'MyDompet - Laporan Transaksi',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text('User: ${authProvider.userName ?? "Anonymous"}'),
                pw.Text('Tanggal: ${Formatters.formatDate(DateTime.now())}'),
                pw.Text('Periode: $filterLabel', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 16),
                
                // Summary
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Ringkasan', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 8),
                      pw.Text('Total Pemasukan: ${Formatters.formatCurrency(totalIncome)}'),
                      pw.Text('Total Pengeluaran: ${Formatters.formatCurrency(totalExpense)}'),
                      pw.Text('Saldo: ${Formatters.formatCurrency(totalIncome - totalExpense)}'),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 16),
                pw.Text('Detail Transaksi', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                pw.SizedBox(height: 8),
                
                // Transactions table
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('Tanggal', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('Kategori', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('Deskripsi', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('Jumlah', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    ...transactions.map((t) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(Formatters.formatDate(t.date), style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(t.category, style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(t.description, style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            Formatters.formatCurrency(t.amount),
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    )),
                  ],
                ),
              ],
            );
          },
        ),
      );
      
      final bytes = await pdf.save();
      
      if (kIsWeb) {
        // Web: trigger download
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'mydompet_report.pdf')
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // Mobile: save to downloads
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/mydompet_report.pdf');
        await file.writeAsBytes(bytes);
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Laporan PDF berhasil diekspor!'),
            backgroundColor: AppColors.income,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error exporting PDF: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengekspor PDF'),
            backgroundColor: AppColors.expense,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showSecurityDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.security, color: AppColors.warning),
                ),
                const SizedBox(width: 12),
                Text(
                  'Keamanan',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SecurityOption(
              icon: Icons.fingerprint,
              label: 'Biometrik',
              description: 'Gunakan sidik jari atau Face ID',
              isEnabled: false,
            ),
            const SizedBox(height: 12),
            _SecurityOption(
              icon: Icons.pin,
              label: 'PIN',
              description: 'Tambahkan PIN untuk keamanan ekstra',
              isEnabled: false,
            ),
            const SizedBox(height: 12),
            _SecurityOption(
              icon: Icons.lock_reset,
              label: 'Ganti Password',
              description: 'Ubah password akun Anda',
              isEnabled: true,
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Email reset password telah dikirim!'),
                    backgroundColor: AppColors.info,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              'Bantuan',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.email_outlined, color: AppColors.info),
              title: const Text('Email Support'),
              subtitle: const Text('support@mydompet.app'),
              onTap: () => _launchUrl('mailto:support@mydompet.app'),
            ),
            ListTile(
              leading: const Icon(Icons.book_outlined, color: AppColors.info),
              title: const Text('Panduan Pengguna'),
              subtitle: const Text('Pelajari cara menggunakan MyDompet'),
              trailing: const Icon(Icons.open_in_new, size: 18, color: AppColors.textMuted),
              onTap: () {
                Navigator.pop(context);
                _launchUrl('https://mydompet-site.vercel.app/#guide');
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline, color: AppColors.info),
              title: const Text('FAQ'),
              subtitle: const Text('Pertanyaan yang sering diajukan'),
              trailing: const Icon(Icons.open_in_new, size: 18, color: AppColors.textMuted),
              onTap: () {
                Navigator.pop(context);
                _launchUrl('https://mydompet-site.vercel.app/#faq');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'MyDompet',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'v1.0.0',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Text(
              'Aplikasi pengelola keuangan pribadi dengan fitur AI untuk scan struk otomatis.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              '© 2026 MyDompet',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Logout'),
        content: const Text('Yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              await authProvider.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.expense),
            ),
          ),
        ],
      ),
    );
  }

  // ========== HELPERS ==========

  void _showImagePickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              'Ubah Foto Profil',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                // Camera option - hide on web
                if (!kIsWeb) 
                  Expanded(
                    child: _ImagePickerOption(
                      icon: Icons.camera_alt,
                      label: 'Kamera',
                      onTap: () async {
                        try {
                          // Get AuthProvider BEFORE closing modal
                          debugPrint('📸 Camera: Getting AuthProvider...');
                          final authProvider = context.read<AuthProvider>();
                          
                          Navigator.pop(context);
                          debugPrint('📸 Camera: Picking image...');
                          final XFile? image = await _picker.pickImage(
                            source: ImageSource.camera,
                            maxWidth: 512,
                            maxHeight: 512,
                            imageQuality: 85,
                          );
                          
                          if (image == null) {
                            debugPrint('📸 Camera: No image picked');
                            return;
                          }
                          
                          debugPrint('📸 Camera: Image picked: ${image.path}');
                          setState(() => _profileImage = image);
                          
                          if (!mounted) {
                            debugPrint('📸 Camera: Widget not mounted!');
                            return;
                          }
                          
                          // Upload to Supabase
                          debugPrint('📸 Camera: Starting upload...');
                          final success = await authProvider.uploadProfilePhoto(image);
                          debugPrint('📸 Camera: Upload result = $success');
                          
                          if (!mounted) {
                            debugPrint('📸 Camera: Widget not mounted after upload!');
                            return;
                          }
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success
                                  ? 'Foto profil berhasil diperbarui!'
                                  : 'Gagal mengupload foto. Coba lagi.'),
                              backgroundColor: success ? AppColors.income : AppColors.expense,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } catch (e, stackTrace) {
                          debugPrint('📸 Camera: EXCEPTION!');
                          debugPrint('📸 Error: $e');
                          debugPrint('📸 Stack trace: $stackTrace');
                          
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Error! Cek console untuk detail'),
                                backgroundColor: AppColors.expense,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                if (!kIsWeb) const SizedBox(width: 16),
                Expanded(
                  child: _ImagePickerOption(
                    icon: Icons.photo_library,
                    label: 'Galeri',
                    onTap: () async {
                      try {
                        // Get references BEFORE closing modal
                        debugPrint('🖼️ Gallery: Getting providers...');
                        final authProvider = context.read<AuthProvider>();
                        final messenger = ScaffoldMessenger.of(context);
                        
                        Navigator.pop(context);
                        debugPrint('🖼️ Gallery: Picking image...');
                        final XFile? image = await _picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 512,
                          maxHeight: 512,
                          imageQuality: 85,
                        );
                        
                        if (image == null) {
                          debugPrint('🖼️ Gallery: No image picked');
                          return;
                        }
                        
                        debugPrint('🖼️ Gallery: Image picked: ${image.path}');
                        setState(() => _profileImage = image);
                        
                        // Upload to Supabase
                        debugPrint('🖼️ Gallery: Starting upload...');
                        final success = await authProvider.uploadProfilePhoto(image);
                        debugPrint('🖼️ Gallery: Upload result = $success');
                        
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? 'Foto profil berhasil diperbarui!'
                                : 'Gagal mengupload foto. Coba lagi.'),
                            backgroundColor: success ? AppColors.income : AppColors.expense,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } catch (e, stackTrace) {
                        debugPrint('🖼️ Gallery: EXCEPTION!');
                        debugPrint('🖼️ Error: $e');
                        debugPrint('🖼️ Stack trace: $stackTrace');
                      }
                    },
                  ),
                ),
              ],
            ),
            if (_profileImage != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _profileImage = null);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Foto profil dihapus'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.delete_outline, color: AppColors.expense),
                label: const Text(
                  'Hapus Foto',
                  style: TextStyle(color: AppColors.expense),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  UserTier _getUserTier(double totalSavings) {
    if (totalSavings >= 100000000) {
      return UserTier(
        name: 'Diamond Saver',
        icon: Icons.diamond,
        color: Colors.cyan,
        gradient: const LinearGradient(
          colors: [Colors.cyan, Colors.blue],
        ),
      );
    } else if (totalSavings >= 50000000) {
      return UserTier(
        name: 'Gold Saver',
        icon: Icons.workspace_premium,
        color: Colors.amber,
        gradient: const LinearGradient(
          colors: [Colors.amber, Colors.orange],
        ),
      );
    } else if (totalSavings >= 10000000) {
      return UserTier(
        name: 'Silver Saver',
        icon: Icons.verified,
        color: Colors.grey,
        gradient: LinearGradient(
          colors: [Colors.grey.shade400, Colors.grey.shade600],
        ),
      );
    } else if (totalSavings >= 1000000) {
      return UserTier(
        name: 'Bronze Saver',
        icon: Icons.star,
        color: Colors.brown,
        gradient: LinearGradient(
          colors: [Colors.brown.shade300, Colors.brown.shade500],
        ),
      );
    } else {
      return UserTier(
        name: 'Starter',
        icon: Icons.person,
        color: AppColors.primaryStart,
        gradient: AppColors.primaryGradient,
      );
    }
  }

  List<Badge> _getEarnedBadges(double totalSavings, TransactionProvider transactionProvider) {
    List<Badge> badges = [];
    final transactions = transactionProvider.transactions;
    final goals = context.read<BudgetProvider>().goals;
    
    // Calculate streak
    int streak = _calculateStreak(transactions);
    
    // Calculate unique categories used
    Set<String> usedCategories = transactions.map((t) => t.category).toSet();
    
    // Savings Milestone Badges
    badges.add(Badge(
      icon: Icons.savings,
      name: 'First Million',
      color: AppColors.income,
      earned: totalSavings >= 1000000,
    ));
    
    badges.add(Badge(
      icon: Icons.emoji_events,
      name: '10 Juta Club',
      color: Colors.amber,
      earned: totalSavings >= 10000000,
    ));
    
    badges.add(Badge(
      icon: Icons.workspace_premium,
      name: 'Gold Status',
      color: Colors.orange,
      earned: totalSavings >= 50000000,
    ));
    
    badges.add(Badge(
      icon: Icons.diamond,
      name: '100M Club',
      color: Colors.cyan,
      earned: totalSavings >= 100000000,
    ));
    
    // Transaction Count Badges
    badges.add(Badge(
      icon: Icons.receipt_long,
      name: 'Active User',
      color: AppColors.info,
      earned: transactions.length >= 10,
    ));
    
    badges.add(Badge(
      icon: Icons.auto_awesome,
      name: 'Power User',
      color: Colors.purple,
      earned: transactions.length >= 50,
    ));
    
    badges.add(Badge(
      icon: Icons.star_rounded,
      name: 'Century Club',
      color: Colors.deepPurple,
      earned: transactions.length >= 100,
    ));
    
    badges.add(Badge(
      icon: Icons.military_tech,
      name: 'Elite Tracker',
      color: Colors.indigo,
      earned: transactions.length >= 500,
    ));
    
    // Streak Badges
    badges.add(Badge(
      icon: Icons.local_fire_department,
      name: '7-Day Streak',
      color: Colors.orange,
      earned: streak >= 7,
    ));
    
    badges.add(Badge(
      icon: Icons.whatshot,
      name: '30-Day Streak',
      color: Colors.deepOrange,
      earned: streak >= 30,
    ));
    
    badges.add(Badge(
      icon: Icons.celebration,
      name: '100-Day Streak',
      color: Colors.red,
      earned: streak >= 100,
    ));
    
    // Goal Badges
    final completedGoals = goals.where((g) => g.isCompleted).length;
    
    badges.add(Badge(
      icon: Icons.flag_rounded,
      name: 'First Goal',
      color: AppColors.income,
      earned: completedGoals >= 1,
    ));
    
    badges.add(Badge(
      icon: Icons.emoji_events_outlined,
      name: 'Goal Master',
      color: Colors.teal,
      earned: completedGoals >= 5,
    ));
    
    badges.add(Badge(
      icon: Icons.stars,
      name: 'Dream Achiever',
      color: Colors.amber.shade700,
      earned: goals.isNotEmpty && completedGoals == goals.length,
    ));
    
    // Budget & Spending Badges
    badges.add(Badge(
      icon: Icons.account_balance_wallet,
      name: 'Budget Master',
      color: AppColors.primaryStart,
      earned: goals.any((g) => g.targetAmount > 0),
    ));
    
    // Calculate if user stayed under budget this month
    final thisMonth = DateTime.now();
    final monthTransactions = transactions.where((t) => 
      t.date.year == thisMonth.year && t.date.month == thisMonth.month
    );
    final monthExpenses = monthTransactions
      .where((t) => t.type == 'expense')
      .fold<double>(0, (sum, t) => sum + t.amount);
    final budget = context.read<BudgetProvider>().monthlyBudget;
    
    badges.add(Badge(
      icon: Icons.trending_down,
      name: 'Frugal Saver',
      color: AppColors.income,
      earned: budget > 0 && monthExpenses < budget,
    ));
    
    // Category Explorer Badge
    badges.add(Badge(
      icon: Icons.explore,
      name: 'Category Explorer',
      color: Colors.blue,
      earned: usedCategories.length >= 5,
    ));
    
    // OCR Scanner Badge
    badges.add(Badge(
      icon: Icons.document_scanner,
      name: 'Scanner Pro',
      color: AppColors.secondaryStart,
      earned: transactions.any((t) => t.description.contains('Scan')),
    ));
    
    // Sort: earned badges first, then by name
    badges.sort((a, b) {
      if (a.earned != b.earned) return a.earned ? -1 : 1;
      return a.name.compareTo(b.name);
    });
    
    return badges;
  }
  
  int _calculateStreak(List transactions) {
    if (transactions.isEmpty) return 0;
    
    // Get unique dates
    final dates = transactions
      .map((t) => DateTime(t.date.year, t.date.month, t.date.day))
      .toSet()
      .toList()
      ..sort((a, b) => b.compareTo(a)); // Sort descending
    
    int streak = 0;
    DateTime current = DateTime.now();
    DateTime checkDate = DateTime(current.year, current.month, current.day);
    
    for (var date in dates) {
      if (date == checkDate || date == checkDate.subtract(const Duration(days: 1))) {
        streak++;
        checkDate = date.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    
    return streak;
  }
}

// ========== MODELS & WIDGETS ==========

class UserTier {
  final String name;
  final IconData icon;
  final Color color;
  final Gradient gradient;

  UserTier({
    required this.name,
    required this.icon,
    required this.color,
    required this.gradient,
  });
}

class Badge {
  final IconData icon;
  final String name;
  final Color color;
  final bool earned;

  Badge({
    required this.icon,
    required this.name,
    required this.color,
    required this.earned,
  });
}

class _BadgeItem extends StatelessWidget {
  final Badge badge;

  const _BadgeItem({required this.badge});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Tooltip(
      message: badge.name,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          gradient: badge.earned
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    badge.color.withOpacity(0.2),
                    badge.color.withOpacity(0.1),
                  ],
                )
              : null,
          color: !badge.earned
              ? (isDark ? Colors.grey.withOpacity(0.08) : Colors.grey.withOpacity(0.04))
              : null,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: badge.earned
                ? badge.color.withOpacity(0.4)
                : Colors.grey.withOpacity(0.15),
            width: 1.5,
          ),
          boxShadow: badge.earned ? [
            BoxShadow(
              color: badge.color.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: badge.earned
                    ? badge.color.withOpacity(0.15)
                    : Colors.grey.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                badge.icon,
                color: badge.earned ? badge.color : Colors.grey.shade600,
                size: 22,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              badge.name,
              style: TextStyle(
                color: badge.earned
                    ? theme.textTheme.bodyMedium?.color
                    : Colors.grey.shade600,
                fontSize: 9.5,
                fontWeight: badge.earned ? FontWeight.w600 : FontWeight.w500,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: theme.textTheme.bodyMedium?.color,
          size: 22, // Consistent icon size
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: theme.textTheme.titleMedium?.color,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 12,
              ),
            )
          : null,
      trailing: trailing ?? Icon(
        Icons.chevron_right,
        color: theme.textTheme.bodySmall?.color,
        size: 20,
      ),
      onTap: onTap,
    );
  }
}

class _ExportOptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  const _ExportOptionCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceLight : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.border : AppColors.borderLightGray,
          ),
          boxShadow: isDark ? null : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: AppColors.primaryStart),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: theme.textTheme.titleLarge?.color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              description,
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool isEnabled;
  final VoidCallback? onTap;

  const _SecurityOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.isEnabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceLight : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.border : AppColors.borderLightGray
          ),
          boxShadow: isDark ? null : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: isEnabled ? AppColors.warning : Colors.grey),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isEnabled ? theme.textTheme.titleMedium?.color : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      color: isEnabled ? theme.textTheme.bodySmall?.color : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (!isEnabled)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Coming Soon',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
              ),
            if (isEnabled)
              Icon(
                Icons.chevron_right, 
                color: theme.textTheme.bodySmall?.color,
              ),
          ],
        ),
      ),
    );
  }
}

class _ImagePickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImagePickerOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceLight : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.border : AppColors.borderLightGray
          ),
          boxShadow: isDark ? null : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: theme.textTheme.titleMedium?.color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
