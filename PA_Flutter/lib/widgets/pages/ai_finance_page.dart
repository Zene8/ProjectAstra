import 'package:flutter/material.dart';
import '../../services/finance_api_service.dart';

class AiFinancePage extends StatefulWidget {
  const AiFinancePage({super.key});

  @override
  State<AiFinancePage> createState() => _AiFinancePageState();
}

class _AiFinancePageState extends State<AiFinancePage> {
  final FinanceApiService _apiService = FinanceApiService();
  String _categorizationResult = 'No result';
  String _anomalyResult = 'No result';
  String _budgetPredictionResult = 'No result';

  Future<void> _categorizeTransaction() async {
    try {
      // This is a placeholder. In a real app, you'd select a transaction.
      final result = await _apiService.categorizeTransaction(1); // Dummy transaction ID
      setState(() {
        _categorizationResult = 'Categorized: ${result['predicted_category']}';
      });
    } catch (e) {
      setState(() {
        _categorizationResult = 'Error: $e';
      });
    }
  }

  Future<void> _detectAnomaly() async {
    try {
      final result = await _apiService.detectSpendingAnomaly();
      setState(() {
        _anomalyResult = 'Anomalies: ${result['anomalies']}';
      });
    } catch (e) {
      setState(() {
        _anomalyResult = 'Error: $e';
      });
    }
  }

  Future<void> _predictBudget() async {
    try {
      final result = await _apiService.predictBudget();
      setState(() {
        _budgetPredictionResult = 'Predicted Budget: ${result['suggested_budget']}';
      });
    } catch (e) {
      setState(() {
        _budgetPredictionResult = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Finance Features'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _categorizeTransaction,
              child: const Text('Categorize Transaction (Dummy)'),
            ),
            Text(_categorizationResult),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _detectAnomaly,
              child: const Text('Detect Spending Anomaly'),
            ),
            Text(_anomalyResult),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _predictBudget,
              child: const Text('Predict Budget'),
            ),
            Text(_budgetPredictionResult),
          ],
        ),
      ),
    );
  }
}
