import 'package:flutter/material.dart';
import '../../models/finance_models.dart';
import '../../services/finance_api_service.dart';

class CollaborativeFinancePage extends StatefulWidget {
  const CollaborativeFinancePage({super.key});

  @override
  State<CollaborativeFinancePage> createState() => _CollaborativeFinancePageState();
}

class _CollaborativeFinancePageState extends State<CollaborativeFinancePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FinanceApiService _apiService = FinanceApiService();
  late Future<List<ExpenseAttribution>> _attributionsFuture;
  late Future<List<Invoice>> _invoicesFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _attributionsFuture = _fetchAttributions();
    _invoicesFuture = _fetchInvoices();
  }

  Future<List<ExpenseAttribution>> _fetchAttributions() async {
    final attributionsJson = await _apiService.getAttributions();
    return attributionsJson.map((json) => ExpenseAttribution.fromJson(json)).toList();
  }

  Future<List<Invoice>> _fetchInvoices() async {
    final invoicesJson = await _apiService.getInvoices();
    return invoicesJson.map((json) => Invoice.fromJson(json)).toList();
  }

  void _approveAttribution(int attributionId) async {
    try {
      await _apiService.approveExpenseAttribution(attributionId);
      setState(() {
        _attributionsFuture = _fetchAttributions();
      });
    } catch (e) {
      // Handle error
      print('Error approving attribution: $e');
    }
  }

  void _rejectAttribution(int attributionId) async {
    // Implement reject logic here. Backend currently doesn't have a reject endpoint.
    // For now, we'll just refresh the list.
    print('Rejecting attribution $attributionId');
    setState(() {
      _attributionsFuture = _fetchAttributions();
    });
  }

  void _showCreateInvoiceDialog() {
    final formKey = GlobalKey<FormState>();
    final toUserIdController = TextEditingController();
    final totalAmountController = TextEditingController();
    DateTime dueDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Invoice'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: toUserIdController,
                  decoration: const InputDecoration(labelText: 'To User ID'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Please enter a user ID' : null,
                ),
                TextFormField(
                  controller: totalAmountController,
                  decoration: const InputDecoration(labelText: 'Total Amount'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Please enter a total amount' : null,
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(context: context, initialDate: dueDate, firstDate: DateTime(2000), lastDate: DateTime(2101));
                    if (picked != null) setState(() => dueDate = picked);
                  },
                  child: Text('Due Date: ${dueDate.toLocal()}'.split(' ')[0])
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  await _apiService.createInvoice(
                    int.parse(toUserIdController.text),
                    double.parse(totalAmountController.text),
                    dueDate,
                    [], // No attributed expenses selected for now
                  );
                  Navigator.of(context).pop();
                  setState(() {
                    _invoicesFuture = _fetchInvoices();
                  });
                }
              },
              child: const Text('Create'),
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
        title: const Text('Collaborative Finance'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Attributions'),
            Tab(text: 'Invoices'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAttributionsTab(),
          _buildInvoicesTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 1 // Show FAB only on Invoices tab
          ? FloatingActionButton(
              onPressed: _showCreateInvoiceDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildAttributionsTab() {
    return FutureBuilder<List<ExpenseAttribution>>(
      future: _attributionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No attributions found.'));
        }

        final attributions = snapshot.data!;
        return ListView.builder(
          itemCount: attributions.length,
          itemBuilder: (context, index) {
            final attribution = attributions[index];
            return ListTile(
              title: Text('Transaction ID: ${attribution.originalTransactionId}'),
              subtitle: Text('Amount: \$${attribution.amount.toStringAsFixed(2)} - ${attribution.status.toString().split('.').last}'),
              trailing: attribution.status == ExpenseAttributionStatus.PENDING
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => _approveAttribution(attribution.id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _rejectAttribution(attribution.id),
                        ),
                      ],
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildInvoicesTab() {
    return FutureBuilder<List<Invoice>>(
      future: _invoicesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No invoices found.'));
        }

        final invoices = snapshot.data!;
        return ListView.builder(
          itemCount: invoices.length,
          itemBuilder: (context, index) {
            final invoice = invoices[index];
            return ListTile(
              title: Text('Invoice #${invoice.id}'),
              subtitle: Text('Due: ${invoice.dueDate.toLocal()}'.split(' ')[0]),
              trailing: Text('\$${invoice.totalAmount.toStringAsFixed(2)}'),
            );
          },
        );
      },
    );
  }
}
