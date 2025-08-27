import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/finance_models.dart';

class FinanceApiService {
  final String _baseUrl = "http://localhost:5000/api/finance"; // Adjust if needed

  Future<String?> _getAuthToken() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return await user.getIdToken();
    }
    return null;
  }

  Future<http.Response> _get(String endpoint, {Map<String, String>? queryParams}) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse('$_baseUrl/$endpoint').replace(queryParameters: queryParams);
    return http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<http.Response> _post(String endpoint, Map<String, dynamic> body) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('Not authenticated');
    return http.post(
      Uri.parse('$_baseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );
  }

  Future<http.Response> _put(String endpoint, Map<String, dynamic> body) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('Not authenticated');
    return http.put(
      Uri.parse('$_baseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );
  }

  Future<List<dynamic>> getTransactions() async {
    final response = await _get('transactions/');
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load transactions');
    }
  }

  Future<String> createLinkToken() async {
    final response = await _post('plaid/create_link_token', {});
    if (response.statusCode == 200) {
      return json.decode(response.body)['link_token'];
    } else {
      throw Exception('Failed to create link token');
    }
  }

  Future<void> exchangePublicToken(String publicToken) async {
    await _post('plaid/exchange_public_token', {'public_token': publicToken});
  }

  Future<void> syncTransactions() async {
    await _post('plaid/sync_transactions', {});
  }

  Future<double> getNetWorth() async {
    final response = await _get('reports/net_worth');
    if (response.statusCode == 200) {
      return json.decode(response.body)['net_worth'];
    } else {
      throw Exception('Failed to load net worth');
    }
  }

  Future<Map<String, dynamic>> getSpendingBreakdown(DateTime startDate, DateTime endDate) async {
    final response = await _get(
      'reports/spending_breakdown',
      queryParams: {
        'start_date': startDate.toIso8601String().split('T').first,
        'end_date': endDate.toIso8601String().split('T').first,
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load spending breakdown');
    }
  }

  Future<List<dynamic>> getBudgets() async {
    final response = await _get('budgets/');
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load budgets');
    }
  }

  Future<void> createBudget(Budget budget) async {
    await _post('budgets/', {
      'category_id': budget.categoryId,
      'amount_allocated': budget.amountAllocated,
      'start_date': budget.startDate.toIso8601String(),
      'end_date': budget.endDate.toIso8601String(),
    });
  }

  Future<List<dynamic>> getRecurringExpenses() async {
    final response = await _get('recurring-expenses/');
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load recurring expenses');
    }
  }

  Future<void> createRecurringExpense(RecurringExpense expense) async {
    await _post('recurring-expenses/', {
      'vendor_name': expense.vendorName,
      'amount': expense.amount,
      'category_id': expense.categoryId,
      'frequency': expense.frequency.toString().split('.').last,
      'next_due_date': expense.nextDueDate.toIso8601String(),
    });
  }

  Future<List<dynamic>> getAttributions() async {
    final response = await _get('attributions/');
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load attributions');
    }
  }

  Future<void> createExpenseAttribution(int transactionId, int attributedToUserId, double amount) async {
    await _post('attributions/', {
      'original_transaction_id': transactionId,
      'attributed_to_user_id': attributedToUserId,
      'amount': amount,
    });
  }

  Future<void> approveExpenseAttribution(int attributionId) async {
    await _put('attributions/$attributionId/approve', {});
  }

  Future<List<dynamic>> getInvoices() async {
    final response = await _get('invoices/');
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load invoices');
    }
  }

  Future<void> createInvoice(int toUserId, double totalAmount, DateTime dueDate, List<int> attributedExpenseIds) async {
    await _post('invoices/', {
      'to_user_id': toUserId,
      'total_amount': totalAmount,
      'due_date': dueDate.toIso8601String(),
      'attributed_expense_ids': attributedExpenseIds,
    });
  }

  Future<Map<String, dynamic>> categorizeTransaction(int transactionId) async {
    final response = await _post('ai/categorize_transaction', {'transaction_id': transactionId});
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to categorize transaction');
    }
  }

  Future<Map<String, dynamic>> detectSpendingAnomaly() async {
    final response = await _post('ai/detect_spending_anomaly', {});
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to detect spending anomaly');
    }
  }

  Future<Map<String, dynamic>> predictBudget() async {
    final response = await _post('ai/predict_budget', {});
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to predict budget');
    }
  }
}
