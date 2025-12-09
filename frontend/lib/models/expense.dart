class Expense {
  final int id;
  final double amount;
  final String category;
  final String description;
  final String timestamp; 

  Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.description,
    required this.timestamp,
  });

  // JSON(Map)을 Expense 객체로 변환하는 팩토리 생성자
  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      amount: (json['amount'] as num).toDouble(), // 숫자 타입 변환
      category: json['category'],
      description: json['description'] ?? '', // null일 경우 빈 문자열
      timestamp: json['timestamp'],
    );
  }
}
