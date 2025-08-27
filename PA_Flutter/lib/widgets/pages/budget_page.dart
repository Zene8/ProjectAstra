import 'package:flutter/material.dart';
import '../../models/finance_models.dart';
import '../../services/finance_api_service.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final FinanceApiService _apiService = FinanceApiService();
  late Future<List<Budget>> _budgetsFuture;

  @override
  void initState() {
    super.initState();
    _budgetsFuture = _fetchBudgets();
  }

  Future<List<Budget>> _fetchBudgets() async {
    final budgetsJson = await _apiService.getBudgets();
    return budgetsJson.map((json) => Budget.fromJson(json)).toList();
  }

  void _showAddBudgetDialog() {
    final formKey = GlobalKey<FormState>();
    final categoryIdController = TextEditingController();
    final amountController = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Budget'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: categoryIdController,
                  decoration: const InputDecoration(labelText: 'Category ID'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Please enter a category ID' : null,
                ),
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Please enter an amount' : null,
                ),
                // Simple date pickers for now
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(context: context, initialDate: startDate, firstDate: DateTime(2000), lastDate: DateTime(2101));
                    if (picked != null) setState(() => startDate = picked);
                  },
                  child: Text('Start Date: ${startDate.toLocal()}'.split(' ')[0])
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(context: context, initialDate: endDate, firstDate: DateTime(2000), lastDate: DateTime(2101));
                    if (picked != null) setState(() => endDate = picked);
                  },
                  child: Text('End Date: ${endDate.toLocal()}'.split(' ')[0])
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newBudget = Budget(
                    id: 0, // ID is set by the backend
                    userId: 0, // User ID is set by the backend
                    categoryId: int.parse(categoryIdController.text),
                    amountAllocated: double.parse(amountController.text),
                    startDate: startDate,
                    endDate: endDate,
                  );
                  await _apiService.createBudget(newBudget);
                  Navigator.of(context).pop();
                  setState(() {
                    _budgetsFuture = _fetchBudgets();
                  });
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddBudgetDialog,
            tooltip: 'Add Budget',
          ),
        ],
      ),
      body: FutureBuilder<List<Budget>>(
        future: _budgetsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No budgets found.'));
          }

          final budgets = snapshot.data!;
          return ListView.builder(
            itemCount: budgets.length,
            itemBuilder: (context, index) {
              final budget = budgets[index];
              return ListTile(
                title: Text('Category ID: ${budget.categoryId}'),
                subtitle: Text('${budget.startDate.toLocal().toIso8601String().split('T')[0]} - ${budget.endDate.toLocal().toIso8601String().split('T')[0]}'),
                trailing: Text('\$${budget.amountAllocated.toStringAsFixed(2)}'),
              );
            },
          );
        },
      ),
    );
  }
}