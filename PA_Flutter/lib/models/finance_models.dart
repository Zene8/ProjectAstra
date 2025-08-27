class Transaction {
  final int id;
  final DateTime date;
  final String vendorName;
  final double amount;
  final String? accountName;
  final int? categoryId;

  Transaction({
    required this.id,
    required this.date,
    required this.vendorName,
    required this.amount,
    this.accountName,
    this.categoryId,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      date: DateTime.parse(json['date']),
      vendorName: json['vendor_name'],
      amount: json['amount'],
      accountName: json['account_name'],
      categoryId: json['category_id'],
    );
  }
}

class Budget {
  final int id;
  final int userId;
  final int categoryId;
  final double amountAllocated;
  final DateTime startDate;
  final DateTime endDate;

  Budget({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amountAllocated,
    required this.startDate,
    required this.endDate,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      userId: json['user_id'],
      categoryId: json['category_id'],
      amountAllocated: json['amount_allocated'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
    );
  }
}

enum RecurringExpenseFrequency {
  WEEKLY,
  MONTHLY,
  YEARLY,
}

class RecurringExpense {
  final int id;
  final int userId;
  final String vendorName;
  final double amount;
  final int categoryId;
  final RecurringExpenseFrequency frequency;
  final DateTime nextDueDate;

  RecurringExpense({
    required this.id,
    required this.userId,
    required this.vendorName,
    required this.amount,
    required this.categoryId,
    required this.frequency,
    required this.nextDueDate,
  });

  factory RecurringExpense.fromJson(Map<String, dynamic> json) {
    return RecurringExpense(
      id: json['id'],
      userId: json['user_id'],
      vendorName: json['vendor_name'],
      amount: json['amount'],
      categoryId: json['category_id'],
      frequency: RecurringExpenseFrequency.values.firstWhere(
          (e) => e.toString().split('.').last == json['frequency']),
      nextDueDate: DateTime.parse(json['next_due_date']),
    );
  }
}

enum ExpenseAttributionStatus {
  PENDING,
  APPROVED,
  REJECTED,
}

class ExpenseAttribution {
  final int id;
  final int originalTransactionId;
  final int attributingUserId;
  final int attributedToUserId;
  final double amount;
  final ExpenseAttributionStatus status;
  final int? invoiceId;

  ExpenseAttribution({
    required this.id,
    required this.originalTransactionId,
    required this.attributingUserId,
    required this.attributedToUserId,
    required this.amount,
    required this.status,
    this.invoiceId,
  });

  factory ExpenseAttribution.fromJson(Map<String, dynamic> json) {
    return ExpenseAttribution(
      id: json['id'],
      originalTransactionId: json['original_transaction_id'],
      attributingUserId: json['attributing_user_id'],
      attributedToUserId: json['attributed_to_user_id'],
      amount: json['amount'],
      status: ExpenseAttributionStatus.values.firstWhere(
          (e) => e.toString().split('.').last == json['status']),
      invoiceId: json['invoice_id'],
    );
  }
}

enum InvoiceStatus {
  UNPAID,
  PAID,
}

class Invoice {
  final int id;
  final int fromUserId;
  final int toUserId;
  final double totalAmount;
  final DateTime dueDate;
  final InvoiceStatus status;
  final List<int> attributedExpenseIds;

  Invoice({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.totalAmount,
    required this.dueDate,
    required this.status,
    required this.attributedExpenseIds,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'],
      fromUserId: json['from_user_id'],
      toUserId: json['to_user_id'],
      totalAmount: json['total_amount'],
      dueDate: DateTime.parse(json['due_date']),
      status: InvoiceStatus.values
          .firstWhere((e) => e.toString().split('.').last == json['status']),
      attributedExpenseIds:
          List<int>.from(json['attributed_expense_ids']),
    );
  }
}
