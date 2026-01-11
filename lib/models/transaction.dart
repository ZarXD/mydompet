class Transaction {
  final String id;
  final String type; // 'income' or 'expense'
  final double amount;
  final String description;
  final String category;
  final String? notes;
  final DateTime date;
  final DateTime? createdAt;
  
  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.category,
    this.notes,
    required this.date,
    this.createdAt,
  });
  
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      type: json['type'],
      amount: (json['amount'] as num).toDouble(),
      description: json['description'],
      category: json['category'],
      notes: json['notes'],
      date: DateTime.parse(json['date']),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'description': description,
      'category': category,
      'notes': notes,
      'date': date.toIso8601String().split('T')[0],
    };
  }
  
  Transaction copyWith({
    String? id,
    String? type,
    double? amount,
    String? description,
    String? category,
    String? notes,
    DateTime? date,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      date: date ?? this.date,
      createdAt: createdAt,
    );
  }
}

// Available categories
const List<String> transactionCategories = [
  'Makanan',
  'Transport',
  'Belanja',
  'Hiburan',
  'Tagihan',
  'Kesehatan',
  'Pendidikan',
  'Lainnya',
];

// Category icons
const Map<String, String> categoryIcons = {
  'Makanan': '🍔',
  'Transport': '🚗',
  'Belanja': '🛒',
  'Hiburan': '🎬',
  'Tagihan': '📄',
  'Kesehatan': '💊',
  'Pendidikan': '📚',
  'Lainnya': '📦',
};
