import 'package:flutter/material.dart';

import '../config/supabase_config.dart';
import '../models/transaction.dart';
import '../services/cache_service.dart';

class TransactionProvider extends ChangeNotifier {
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLocalMode = false;
  
  // Pagination
  static const int _pageSize = 50;
  int _currentPage = 1;
  bool _hasMore = true;
  
  // Filters
  String _searchQuery = '';
  String _typeFilter = 'all'; // all, income, expense
  String _categoryFilter = 'all';

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  String get searchQuery => _searchQuery;
  String get typeFilter => _typeFilter;
  String get categoryFilter => _categoryFilter;

  // Filtered transactions
  List<Transaction> get filteredTransactions {
    return _transactions.where((t) {
      final matchesSearch = _searchQuery.isEmpty ||
          t.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.category.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesType = _typeFilter == 'all' || t.type == _typeFilter;
      final matchesCategory = _categoryFilter == 'all' || t.category == _categoryFilter;
      return matchesSearch && matchesType && matchesCategory;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // Calculations
  double get totalIncome => _transactions
      .where((t) => t.type == 'income')
      .fold(0, (sum, t) => sum + t.amount);

  double get totalExpense => _transactions
      .where((t) => t.type == 'expense')
      .fold(0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpense;

  double get thisMonthExpense {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == 'expense' &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold(0, (sum, t) => sum + t.amount);
  }

  // Load demo data
  void loadDemoData() {
    _transactions = [
      Transaction(
        id: '1',
        type: 'income',
        amount: 8500000,
        description: 'Gaji Januari',
        category: 'Pendapatan',
        date: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Transaction(
        id: '2',
        type: 'expense',
        amount: 250000,
        description: 'Makan Siang',
        category: 'Makanan',
        date: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Transaction(
        id: '3',
        type: 'expense',
        amount: 150000,
        description: 'Grab ke Kantor',
        category: 'Transport',
        date: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Transaction(
        id: '4',
        type: 'expense',
        amount: 500000,
        description: 'Belanja Mingguan',
        category: 'Belanja',
        date: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Transaction(
        id: '5',
        type: 'expense',
        amount: 75000,
        description: 'Netflix',
        category: 'Hiburan',
        date: DateTime.now().subtract(const Duration(days: 7)),
      ),
      Transaction(
        id: '6',
        type: 'expense',
        amount: 1200000,
        description: 'Listrik & Internet',
        category: 'Tagihan',
        date: DateTime.now().subtract(const Duration(days: 10)),
      ),
      Transaction(
        id: '7',
        type: 'income',
        amount: 2000000,
        description: 'Freelance Project',
        category: 'Pendapatan',
        date: DateTime.now().subtract(const Duration(days: 15)),
      ),
    ];
    _isLocalMode = true;
    notifyListeners();
  }

  // Fetch transactions from Supabase with caching
  Future<void> fetchTransactions({bool forceRefresh = false}) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) {
      loadDemoData();
      return;
    }

    // Check cache first (unless force refresh)
    if (!forceRefresh) {
      final cached = CacheService.get<List<Transaction>>('transactions_${user.id}');
      if (cached != null) {
        _transactions = cached;
        _isLocalMode = false;
        notifyListeners();
        return;
      }
    }

    _isLoading = true;
    _errorMessage = null;
    _currentPage = 1;
    notifyListeners();

    try {
      final response = await SupabaseConfig.client
          .from('transactions')
          .select()
          .eq('user_id', user.id)
          .order('date', ascending: false)
          .limit(_pageSize);

      _transactions = (response as List)
          .map((json) => Transaction.fromJson(json))
          .toList();
      
      // Cache the result
      CacheService.set('transactions_${user.id}', _transactions, 
        duration: const Duration(minutes: 3));
      
      _hasMore = _transactions.length >= _pageSize;
      _isLocalMode = false;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Supabase error, using local mode: $e');
      loadDemoData();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Load more transactions (pagination)
  Future<void> loadMore() async {
    if (_isLoading || !_hasMore || _isLocalMode) return;
    
    final user = SupabaseConfig.currentUser;
    if (user == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      _currentPage++;
      final response = await SupabaseConfig.client
          .from('transactions')
          .select()
          .eq('user_id', user.id)
          .order('date', ascending: false)
          .range((_currentPage - 1) * _pageSize, _currentPage * _pageSize - 1);
      
      final newTransactions = (response as List)
          .map((json) => Transaction.fromJson(json))
          .toList();
      
      _transactions.addAll(newTransactions);
      _hasMore = newTransactions.length >= _pageSize;
      
      // Update cache
      CacheService.set('transactions_${user.id}', _transactions);
    } catch (e) {
      debugPrint('Error loading more transactions: $e');
      _currentPage--; // Rollback page increment
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add transaction
  Future<bool> addTransaction(Transaction transaction) async {
    // Always add locally first
    _transactions.insert(0, transaction);
    notifyListeners();
    
    final user = SupabaseConfig.currentUser;
    if (user == null || _isLocalMode) return true;

    try {
      final data = transaction.toJson();
      data['user_id'] = user.id;
      await SupabaseConfig.client.from('transactions').insert(data);
      
      // Clear cache to force refresh
      CacheService.clear('transactions_${user.id}');
      return true;
    } catch (e) {
      debugPrint('Failed to add transaction in Supabase: $e');
      return true; // Transaction was added locally
    }
  }

  // Update transaction
  Future<bool> updateTransaction(Transaction transaction) async {
    // Always update locally first
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      _transactions[index] = transaction;
      notifyListeners();
    }
    
    final user = SupabaseConfig.currentUser;
    if (user == null || _isLocalMode) return true;

    try {
      await SupabaseConfig.client
          .from('transactions')
          .update(transaction.toJson())
          .eq('id', transaction.id)
          .eq('user_id', user.id);
      
      // Clear cache to force refresh
      CacheService.clear('transactions_${user.id}');
      return true;
    } catch (e) {
      debugPrint('Failed to update transaction in Supabase: $e');
      return true; // Transaction was updated locally
    }
  }

  // Delete transaction
  Future<bool> deleteTransaction(String id) async {
    // Always delete locally first
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
    
    final user = SupabaseConfig.currentUser;
    if (user == null || _isLocalMode) return true;

    try {
      await SupabaseConfig.client
          .from('transactions')
          .delete()
          .eq('id', id)
          .eq('user_id', user.id);
      
      // Clear cache to force refresh
      CacheService.clear('transactions_${user.id}');
      return true;
    } catch (e) {
      debugPrint('Failed to delete transaction in Supabase: $e');
      return true; // Transaction was deleted locally
    }
  }

  // Filter methods
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setTypeFilter(String type) {
    _typeFilter = type;
    notifyListeners();
  }

  void setCategoryFilter(String category) {
    _categoryFilter = category;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _typeFilter = 'all';
    _categoryFilter = 'all';
    notifyListeners();
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
