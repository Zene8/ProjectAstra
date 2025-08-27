import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/finance_models.dart';
import '../../services/finance_api_service.dart';
import './budget_page.dart';
import './recurring_expenses_page.dart';
import './collaborative_finance_page.dart';
import './ai_finance_page.dart';

class _DashboardData {
  final double netWorth;
  final Map<String, dynamic> spendingBreakdown;
  final List<Transaction> transactions;

  _DashboardData({
    required this.netWorth,
    required this.spendingBreakdown,
    required this.transactions,
  });
}

class FinanceDashboardScreen extends StatefulWidget {
  const FinanceDashboardScreen({super.key});

  @override
  State<FinanceDashboardScreen> createState() => _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState extends State<FinanceDashboardScreen> {
  final FinanceApiService _apiService = FinanceApiService();
  late Future<_DashboardData> _dashboardDataFuture;

  @override
  void initState() {
    super.initState();
    _dashboardDataFuture = _fetchDashboardData();
  }

  Future<_DashboardData> _fetchDashboardData() async {
    final netWorth = _apiService.getNetWorth();
    final spendingBreakdown = _apiService.getSpendingBreakdown(
      DateTime.now().subtract(const Duration(days: 30)),
      DateTime.now(),
    );
    final transactions = _apiService
        .getTransactions()
        .then((json) => json.map((j) => Transaction.fromJson(j)).toList());

    final results =
        await Future.wait([netWorth, spendingBreakdown, transactions]);

    return _DashboardData(
      netWorth: results[0] as double,
      spendingBreakdown: results[1] as Map<String, dynamic>,
      transactions: results[2] as List<Transaction>,
    );
  }

  void _openPlaidLink() async {
    // try {
    //   final linkToken = await _apiService.createLinkToken();
    //   final plaidLink = PlaidLink(
    //     linkTokenConfiguration: LinkTokenConfiguration(
    //       token: linkToken,
    //     ),
    //     onSuccess: (publicToken, metadata) async {
    //       await _apiService.exchangePublicToken(publicToken);
    //       await _apiService.syncTransactions();
    //       setState(() {
    //         _dashboardDataFuture = _fetchDashboardData();
    //       });
    //     },
    //   );
    //   plaidLink.open();
    // } catch (e) {
    //   print("Error with Plaid Link: $e");
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_card),
            onPressed: _openPlaidLink,
            tooltip: 'Link Bank Account',
          ),
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            onPressed: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const BudgetPage()));
            },
            tooltip: 'Budgets',
          ),
          IconButton(
            icon: const Icon(Icons.event_repeat),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const RecurringExpensesPage()));
            },
            tooltip: 'Recurring Expenses',
          ),
          IconButton(
            icon: const Icon(Icons.people_alt_outlined),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const CollaborativeFinancePage()));
            },
            tooltip: 'Collaborative Finance',
          ),
          IconButton(
            icon: const Icon(Icons.psychology_outlined),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const AiFinancePage()));
            },
            tooltip: 'AI Features',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _dashboardDataFuture = _fetchDashboardData();
              });
            },
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: FutureBuilder<_DashboardData>(
        future: _dashboardDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No data found.'));
          }

          final dashboardData = snapshot.data!;
          return _buildDashboardUI(dashboardData);
        },
      ),
    );
  }

  Widget _buildDashboardUI(_DashboardData data) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSummarySection(data.netWorth),
        const SizedBox(height: 24),
        _buildSpendingChart(data.spendingBreakdown),
        const SizedBox(height: 24),
        _buildRecentTransactions(data.transactions),
      ],
    );
  }

  Widget _buildSummarySection(double netWorth) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Net Worth',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(NumberFormat.currency(symbol: '\$').format(netWorth),
                style: const TextStyle(fontSize: 28, color: Colors.green)),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingChart(Map<String, dynamic> spendingData) {
    final List<PieChartSectionData> sections =
        spendingData.entries.map((entry) {
      return PieChartSectionData(
        color: Colors.primaries[spendingData.keys.toList().indexOf(entry.key) %
            Colors.primaries.length],
        value: (entry.value as num).toDouble(),
        title: entry.key,
        radius: 100,
        titleStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Spending Last 30 Days',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(PieChartData(sections: sections)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(List<Transaction> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Transactions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length > 10 ? 10 : transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.receipt_long),
                title: Text(transaction.vendorName),
                subtitle: Text(transaction.accountName ?? ''),
                trailing: Text(
                  NumberFormat.currency(symbol: '\$')
                      .format(transaction.amount),
                  style: TextStyle(
                      color:
                          transaction.amount > 0 ? Colors.green : Colors.red),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
