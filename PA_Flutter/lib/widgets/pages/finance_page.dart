import 'package:flutter/material.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  final List<Transaction> _transactions = [];
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = 'Other';
  bool _isExpense = true;

  void _addTransaction() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _transactions.add(
          Transaction(
            description: _descriptionController.text,
            amount: double.parse(_amountController.text),
            category: _selectedCategory,
            isExpense: _isExpense,
            date: DateTime.now(),
          ),
        );
        _descriptionController.clear();
        _amountController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalIncome = _transactions
        .where((t) => !t.isExpense)
        .fold(0, (sum, item) => sum + item.amount);
    double totalExpenses = _transactions
        .where((t) => t.isExpense)
        .fold(0, (sum, item) => sum + item.amount);
    double netBalance = totalIncome - totalExpenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance Manager'),
      ),
      body: Column(
        children: [
          // Dashboard
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDashboardItem('Income', '\$${totalIncome.toStringAsFixed(2)}', Colors.green),
                _buildDashboardItem('Expenses', '\$${totalExpenses.toStringAsFixed(2)}', Colors.red),
                _buildDashboardItem('Balance', '\$${netBalance.toStringAsFixed(2)}', Colors.blue),
              ],
            ),
          ),
          const Divider(),
          // Transaction Form
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (value) => value!.isEmpty ? 'Please enter a description' : null,
                  ),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(labelText: 'Amount'),
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.isEmpty ? 'Please enter an amount' : null,
                  ),
                  DropdownButton<String>(
                    value: _selectedCategory,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCategory = newValue!;
                      });
                    },
                    items: <String>['Food', 'Transport', 'Salary', 'Other']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  Row(
                    children: [
                      const Text('Expense'),
                      Switch(
                        value: !_isExpense,
                        onChanged: (value) {
                          setState(() {
                            _isExpense = !value;
                          });
                        },
                      ),
                      const Text('Income'),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _addTransaction,
                    child: const Text('Add Transaction'),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          // Transaction List
          Expanded(
            child: ListView.builder(
              itemCount: _transactions.length,
              itemBuilder: (context, index) {
                final transaction = _transactions[index];
                return ListTile(
                  leading: Icon(
                    transaction.isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                    color: transaction.isExpense ? Colors.red : Colors.green,
                  ),
                  title: Text(transaction.description),
                  subtitle: Text(transaction.category),
                  trailing: Text(
                    '\$${transaction.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: transaction.isExpense ? Colors.red : Colors.green,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 20, color: color)),
      ],
    );
  }
}

class Transaction {
  final String description;
  final double amount;
  final String category;
  final bool isExpense;
  final DateTime date;

  Transaction({
    required this.description,
    required this.amount,
    required this.category,
    required this.isExpense,
    required this.date,
  });
}
