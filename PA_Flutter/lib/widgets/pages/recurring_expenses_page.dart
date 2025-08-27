import 'package:flutter/material.dart';
import '../../models/finance_models.dart';
import '../../services/finance_api_service.dart';

class RecurringExpensesPage extends StatefulWidget {
  const RecurringExpensesPage({super.key});

  @override
  State<RecurringExpensesPage> createState() => _RecurringExpensesPageState();
}

class _RecurringExpensesPageState extends State<RecurringExpensesPage> {
  final FinanceApiService _apiService = FinanceApiService();
  late Future<List<RecurringExpense>> _recurringExpensesFuture;

  @override
  void initState() {
    super.initState();
    _recurringExpensesFuture = _fetchRecurringExpenses();
  }

  Future<List<RecurringExpense>> _fetchRecurringExpenses() async {
    final recurringExpensesJson = await _apiService.getRecurringExpenses();
    return recurringExpensesJson.map((json) => RecurringExpense.fromJson(json)).toList();
  }

  void _showAddRecurringExpenseDialog() {
    final formKey = GlobalKey<FormState>();
    final vendorNameController = TextEditingController();
    final amountController = TextEditingController();
    final categoryIdController = TextEditingController();
    RecurringExpenseFrequency frequency = RecurringExpenseFrequency.MONTHLY;
    DateTime nextDueDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Recurring Expense'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: vendorNameController,
                  decoration: const InputDecoration(labelText: 'Vendor Name'),
                  validator: (value) => value!.isEmpty ? 'Please enter a vendor name' : null,
                ),
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Please enter an amount' : null,
                ),
                TextFormField(
                  controller: categoryIdController,
                  decoration: const InputDecoration(labelText: 'Category ID'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Please enter a category ID' : null,
                ),
                DropdownButton<RecurringExpenseFrequency>(
                  value: frequency,
                  onChanged: (RecurringExpenseFrequency? newValue) {
                    if (newValue != null) {
                      setState(() => frequency = newValue);
                    }
                  },
                  items: RecurringExpenseFrequency.values
                      .map<DropdownMenuItem<RecurringExpenseFrequency>>((RecurringExpenseFrequency value) {
                    return DropdownMenuItem<RecurringExpenseFrequency>(
                      value: value,
                      child: Text(value.toString().split('.').last),
                    );
                  }).toList(),
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(context: context, initialDate: nextDueDate, firstDate: DateTime(2000), lastDate: DateTime(2101));
                    if (picked != null) setState(() => nextDueDate = picked);
                  },
                  child: Text('Next Due Date: ${nextDueDate.toLocal()}'.split(' ')[0])
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newExpense = RecurringExpense(
                    id: 0, // ID is set by the backend
                    userId: 0, // User ID is set by the backend
                    vendorName: vendorNameController.text,
                    amount: double.parse(amountController.text),
                    categoryId: int.parse(categoryIdController.text),
                    frequency: frequency,
                    nextDueDate: nextDueDate,
                  );
                  await _apiService.createRecurringExpense(newExpense);
                  Navigator.of(context).pop();
                  setState(() {
                    _recurringExpensesFuture = _fetchRecurringExpenses();
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
        title: const Text('Recurring Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddRecurringExpenseDialog,
            tooltip: 'Add Recurring Expense',
          ),
        ],
      ),
      body: FutureBuilder<List<RecurringExpense>>(
        future: _recurringExpensesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No recurring expenses found.'));
          }

          final recurringExpenses = snapshot.data!;
          return ListView.builder(
            itemCount: recurringExpenses.length,
            itemBuilder: (context, index) {
              final expense = recurringExpenses[index];
              return ListTile(
                title: Text(expense.vendorName),
                subtitle: Text('Next due: ${expense.nextDueDate.toLocal()}'.split(' ')[0]),
                trailing: Text('\$${expense.amount.toStringAsFixed(2)}'),
              );
            },
          );
        },
      ),
    );
  }
}