class SavingsGoal {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final DateTime? createdAt;
  
  SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0,
    this.deadline,
    this.createdAt,
  });
  
  double get progress => targetAmount > 0 
      ? (currentAmount / targetAmount).clamp(0, 1) 
      : 0;
  
  bool get isCompleted => currentAmount >= targetAmount;
  
  int? get daysRemaining {
    if (deadline == null) return null;
    final remaining = deadline!.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }
  
  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['id'],
      name: json['name'],
      targetAmount: (json['target_amount'] as num).toDouble(),
      currentAmount: (json['current_amount'] as num?)?.toDouble() ?? 0,
      deadline: json['deadline'] != null 
          ? DateTime.parse(json['deadline']) 
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'deadline': deadline?.toIso8601String().split('T')[0],
    };
  }
}
