import 'package:flutter/material.dart';

import '../config/supabase_config.dart';
import '../models/savings_goal.dart';

class BudgetProvider extends ChangeNotifier {
  double _monthlyBudget = 5000000; // Default budget
  List<SavingsGoal> _goals = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLocalMode = false;

  double get monthlyBudget => _monthlyBudget;
  List<SavingsGoal> get goals => _goals;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Initialize with demo data
  void loadDemoData() {
    _monthlyBudget = 5000000;
    _goals = [
      SavingsGoal(
        id: '1',
        name: 'iPhone 16 Pro',
        targetAmount: 20000000,
        currentAmount: 12500000,
        deadline: DateTime.now().add(const Duration(days: 60)),
      ),
      SavingsGoal(
        id: '2',
        name: 'Liburan Bali',
        targetAmount: 8000000,
        currentAmount: 4000000,
        deadline: DateTime.now().add(const Duration(days: 90)),
      ),
      SavingsGoal(
        id: '3',
        name: 'Emergency Fund',
        targetAmount: 30000000,
        currentAmount: 15000000,
      ),
    ];
    _isLocalMode = true;
    notifyListeners();
  }

  // Fetch budget and goals from Supabase
  Future<void> fetchBudgetAndGoals() async {
    final user = SupabaseConfig.currentUser;
    if (user == null) {
      loadDemoData();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Fetch profile for monthly budget
      final profileResponse = await SupabaseConfig.client
          .from('profiles')
          .select('monthly_budget')
          .eq('id', user.id)
          .maybeSingle();
      
      if (profileResponse != null) {
        _monthlyBudget = (profileResponse['monthly_budget'] ?? 5000000).toDouble();
      }

      // Fetch savings goals
      final goalsResponse = await SupabaseConfig.client
          .from('savings_goals')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      _goals = (goalsResponse as List)
          .map((json) => SavingsGoal.fromJson(json))
          .toList();

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

  // Set monthly budget
  Future<bool> setMonthlyBudget(double budget) async {
    final user = SupabaseConfig.currentUser;
    
    // Always update locally first
    _monthlyBudget = budget;
    notifyListeners();
    
    if (user == null || _isLocalMode) return true;

    try {
      await SupabaseConfig.client
          .from('profiles')
          .update({'monthly_budget': budget})
          .eq('id', user.id);
      return true;
    } catch (e) {
      debugPrint('Failed to update budget in Supabase: $e');
      return true; // Still return true since we updated locally
    }
  }

  // Add savings goal
  Future<bool> addGoal(SavingsGoal goal) async {
    // Always add locally first
    _goals.insert(0, goal);
    notifyListeners();
    
    final user = SupabaseConfig.currentUser;
    if (user == null || _isLocalMode) return true;

    try {
      final data = goal.toJson();
      data['user_id'] = user.id;
      await SupabaseConfig.client.from('savings_goals').insert(data);
      return true;
    } catch (e) {
      debugPrint('Failed to add goal in Supabase: $e');
      return true; // Goal was added locally
    }
  }

  // Update savings goal
  Future<bool> updateGoal(SavingsGoal goal) async {
    // Always update locally first
    final index = _goals.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      _goals[index] = goal;
      notifyListeners();
    }
    
    final user = SupabaseConfig.currentUser;
    if (user == null || _isLocalMode) return true;

    try {
      await SupabaseConfig.client
          .from('savings_goals')
          .update(goal.toJson())
          .eq('id', goal.id)
          .eq('user_id', user.id);
      return true;
    } catch (e) {
      debugPrint('Failed to update goal in Supabase: $e');
      return true; // Goal was updated locally
    }
  }

  // Add funds to goal
  Future<bool> addToGoal(String goalId, double amount) async {
    final index = _goals.indexWhere((g) => g.id == goalId);
    if (index == -1) return false;

    final goal = _goals[index];
    final newAmount = (goal.currentAmount + amount).clamp(0.0, goal.targetAmount).toDouble();
    
    final updatedGoal = SavingsGoal(
      id: goal.id,
      name: goal.name,
      targetAmount: goal.targetAmount,
      currentAmount: newAmount,
      deadline: goal.deadline,
    );
    
    return await updateGoal(updatedGoal);
  }

  // Delete savings goal
  Future<bool> deleteGoal(String id) async {
    // Always delete locally first
    _goals.removeWhere((g) => g.id == id);
    notifyListeners();
    
    final user = SupabaseConfig.currentUser;
    if (user == null || _isLocalMode) return true;

    try {
      await SupabaseConfig.client
          .from('savings_goals')
          .delete()
          .eq('id', id)
          .eq('user_id', user.id);
      return true;
    } catch (e) {
      debugPrint('Failed to delete goal in Supabase: $e');
      return true; // Goal was deleted locally
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
