import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../theme/colors.dart';
import '../../models/transaction.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/glassmorphic_card.dart';

class ReceiptScannerScreen extends StatefulWidget {
  const ReceiptScannerScreen({super.key});

  @override
  State<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen> {
  XFile? _imageFile;
  Uint8List? _imageBytes;
  String? _imageBase64;
  bool _isProcessing = false;
  Map<String, dynamic>? _extractedData;
  String? _errorMessage;

  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  String _category = 'Lainnya';

  final _picker = ImagePicker();

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Read bytes (works on both web and mobile)
        final bytes = await pickedFile.readAsBytes();
        final base64Image = base64Encode(bytes);

        setState(() {
          _imageFile = pickedFile;
          _imageBytes = bytes;
          _imageBase64 = base64Image;
          _extractedData = null;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memilih gambar: $e';
      });
    }
  }

  Future<void> _processImage() async {
    final authProvider = context.read<AuthProvider>();
    final apiKey = authProvider.geminiApiKey;

    if (apiKey == null || apiKey.isEmpty) {
      setState(() {
        _errorMessage = 'API key belum diatur. Silakan atur di halaman Profil.';
      });
      return;
    }

    if (_imageBase64 == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Initialize Gemini model with SDK
      final model = GenerativeModel(
        model: 'gemini-2.0-flash-lite',
        apiKey: apiKey,
      );

      // Create prompt
      final prompt = '''Analyze this receipt image and extract the following information in JSON format:
{
  "merchant": "name of the store/merchant",
  "amount": "total amount (numbers only, no currency symbol)",
  "category": "one of: Makanan, Transport, Belanja, Hiburan, Tagihan, Kesehatan, Pendidikan, or Lainnya",
  "items": ["list of items purchased if visible"]
}

Guidelines:
- Extract the total amount (grand total/total bayar)
- Determine the most appropriate category based on the merchant and items
- Use Indonesian language for merchant name if it's Indonesian
- If you can't find specific information, use reasonable defaults

Return ONLY the JSON object, no additional text.''';

      // Generate content with image using SDK
      final imageBytes = base64Decode(_imageBase64!);
      final content = [
        Content.multi([
          DataPart('image/jpeg', imageBytes),
          TextPart(prompt),
        ])
      ];

      final response = await model.generateContent(content);
      final text = response.text ?? '';

      // Parse JSON from response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch != null) {
        final extractedJson = jsonDecode(jsonMatch.group(0)!);
        
        setState(() {
          _extractedData = extractedJson;
          _amountController.text = extractedJson['amount']?.toString().replaceAll(RegExp(r'[.,]'), '') ?? '';
          _descController.text = extractedJson['merchant'] ?? '';
          _category = extractedJson['category'] ?? 'Lainnya';
        });
      } else {
        setState(() {
          _errorMessage = 'Gagal mengekstrak data dari respons AI';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _saveTransaction() {
    if (_amountController.text.isEmpty || _descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nominal dan keterangan harus diisi'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    final transaction = Transaction(
      id: const Uuid().v4(),
      type: 'expense',
      amount: double.parse(_amountController.text.replaceAll('.', '')),
      description: _descController.text,
      category: _category,
      date: DateTime.now(),
    );

    context.read<TransactionProvider>().addTransaction(transaction);

    Navigator.of(context).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Transaksi berhasil ditambahkan!'),
        backgroundColor: AppColors.income,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _clearImage() {
    setState(() {
      _imageFile = null;
      _imageBytes = null;
      _imageBase64 = null;
      _extractedData = null;
      _errorMessage = null;
      _amountController.clear();
      _descController.clear();
      _category = 'Lainnya';
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final hasApiKey = authProvider.geminiApiKey != null && authProvider.geminiApiKey!.isNotEmpty;

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
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // API Key Warning
                      if (!hasApiKey)
                        _buildApiKeyWarning().animate(delay: 100.ms).fadeIn().slideY(begin: 0.1),
                      
                      // Image Picker
                      if (_imageFile == null)
                        _buildImagePicker().animate(delay: 100.ms).fadeIn().slideY(begin: 0.1)
                      else
                        Column(
                          children: [
                            _buildImagePreview().animate(delay: 100.ms).fadeIn(),
                            const SizedBox(height: 16),
                            
                            // Process Button
                            if (_extractedData == null && !_isProcessing)
                              _buildProcessButton(hasApiKey).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),
                            
                            // Loading
                            if (_isProcessing)
                              _buildLoadingIndicator().animate().fadeIn(),
                            
                            // Error
                            if (_errorMessage != null)
                              _buildErrorMessage().animate().fadeIn().shake(),
                            
                            // Extracted Data Form
                            if (_extractedData != null)
                              _buildExtractedDataForm().animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),
                          ],
                        ),
                    ],
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
          const SizedBox(width: 8),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Receipt Scanner',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                'Powered by Gemini',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeyWarning() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'API Key Belum Diatur',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Atur Gemini API key di halaman Profil untuk menggunakan fitur ini',
                  style: TextStyle(
                    color: AppColors.warning.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return GlassmorphicCard(
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          const Text(
            'Scan Struk Belanja',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ambil foto atau pilih dari galeri',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (!kIsWeb) ...[
                Expanded(
                  child: _PickerButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Kamera',
                    gradient: AppColors.primaryGradient,
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: _PickerButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Galeri',
                  gradient: AppColors.secondaryGradient,
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: AppColors.info, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    kIsWeb 
                        ? 'Tips: Upload gambar struk dari komputer Anda'
                        : 'Tips: Pastikan struk terlihat jelas dan tidak blur',
                    style: TextStyle(
                      color: AppColors.info.withOpacity(0.9),
                      fontSize: 12,
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

  Widget _buildImagePreview() {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _imageBytes != null
                ? Image.memory(
                    _imageBytes!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: double.infinity,
                    height: 200,
                    color: AppColors.surfaceLight,
                    child: const Icon(Icons.image, size: 48, color: AppColors.textMuted),
                  ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: _clearImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.expense,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessButton(bool hasApiKey) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: hasApiKey ? AppColors.primaryGradient : null,
        color: hasApiKey ? null : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ElevatedButton.icon(
        onPressed: hasApiKey ? _processImage : null,
        icon: const Icon(Icons.auto_awesome, size: 20),
        label: const Text('Scan dengan AI'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return GlassmorphicCard(
      child: Column(
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryStart),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Menganalisis struk...',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI sedang membaca data dari gambar',
            style: TextStyle(
              color: AppColors.textMuted.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.expense.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.expense.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.expense),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: AppColors.expense,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtractedDataForm() {
    return Column(
      children: [
        const SizedBox(height: 16),
        
        // Success message
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.income.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.income.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.income),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Data berhasil diekstrak! Silakan review dan edit jika perlu.',
                  style: TextStyle(
                    color: AppColors.income,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Form
        GlassmorphicCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Data Transaksi',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              
              // Amount
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  labelText: 'Nominal',
                  prefixText: 'Rp ',
                  prefixIcon: Icon(Icons.attach_money, color: Theme.of(context).textTheme.bodySmall?.color),
                ),
              ),
              const SizedBox(height: 16),
              
              // Description
              TextField(
                controller: _descController,
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  labelText: 'Keterangan',
                  prefixIcon: Icon(Icons.description_outlined, color: Theme.of(context).textTheme.bodySmall?.color),
                ),
              ),
              const SizedBox(height: 16),
              
              // Category
              DropdownButtonFormField<String>(
                value: _category,
                dropdownColor: AppColors.surface,
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: Icon(Icons.category_outlined, color: Theme.of(context).textTheme.bodySmall?.color),
                ),
                items: transactionCategories.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Row(
                      children: [
                        Text(categoryIcons[cat] ?? '📦'),
                        const SizedBox(width: 8),
                        Text(cat),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _category = value);
                  }
                },
              ),
              
              // Items if available
              if (_extractedData?['items'] != null && (_extractedData!['items'] as List).isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Item yang terdeteksi:',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: (_extractedData!['items'] as List).map((item) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.toString(),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Save Button
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppColors.incomeGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.income.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: _saveTransaction,
            icon: const Icon(Icons.check, size: 20),
            label: const Text('Simpan Transaksi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Scan Another Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _clearImage,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Scan Struk Lain'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  const _PickerButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
