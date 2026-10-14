import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import '../models/invoice.dart';
import '../widgets/kpi_card.dart';
import '../widgets/jazzcash_receipt_card.dart';
import 'billing_screen.dart';
import 'add_edit_stock_screen.dart';
import 'wasooli_dialog.dart';

class DashboardTab extends StatefulWidget {
  final Function(int) onNavigateTab;

  const DashboardTab({Key? key, required this.onNavigateTab}) : super(key: key);

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  Map<String, dynamic> _metrics = {};
  List<Invoice> _recentInvoices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final metrics = await DatabaseHelper.instance.getDashboardMetrics();
    final allInvoices = await DatabaseHelper.instance.getAllInvoices();

    setState(() {
      _metrics = metrics;
      _recentInvoices = allInvoices.take(6).toList();
      _isLoading = false;
    });
  }

  String _formatPKR(num value) {
    return 'PKR ${NumberFormat('#,##,###').format(value)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A)));
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: const Color(0xFF0F172A),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Welcome & Offline Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF064E3B), // Deep emerald
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF34D399),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '100% Offline SQLite Active — No Internet Required',
                      style: TextStyle(
                        color: Color(0xFFA7F3D0),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.shield_outlined, color: Color(0xFF34D399), size: 16),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Quick Action Buttons
            Text(
              'QUICK ACTIONS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BillingScreen()),
                      );
                      _loadDashboardData();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669), // Emerald
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 1,
                    ),
                    icon: const Icon(Icons.add_shopping_cart, size: 16),
                    label: const Text('New Bill', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddEditStockScreen()),
                      );
                      _loadDashboardData();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB), // Blue
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 1,
                    ),
                    icon: const Icon(Icons.layers, size: 16),
                    label: const Text('Add Stock', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await showDialog(
                        context: context,
                        builder: (_) => const WasooliDialog(),
                      );
                      _loadDashboardData();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706), // Amber
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 1,
                    ),
                    icon: const Icon(Icons.payments_outlined, size: 16),
                    label: const Text('Wasooli', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // KPI Metrics Grid
            Text(
              'FACTORY OVERVIEW',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.35,
              children: [
                KpiCard(
                  title: "Today's Sales",
                  value: _formatPKR(_metrics['today_sales'] ?? 0),
                  icon: Icons.point_of_sale,
                  color: Colors.green,
                ),
                KpiCard(
                  title: "This Month",
                  value: _formatPKR(_metrics['month_sales'] ?? 0),
                  icon: Icons.calendar_month,
                  color: Colors.blue,
                ),
                KpiCard(
                  title: 'Customer Baaqi (Udhaar)',
                  value: _formatPKR(_metrics['total_udhaar'] ?? 0),
                  icon: Icons.account_balance_wallet,
                  color: Colors.red,
                  subtitle: 'Total Khata Balance',
                ),
                KpiCard(
                  title: 'Cash Collected',
                  value: _formatPKR(_metrics['total_cash_collected'] ?? 0),
                  icon: Icons.payments,
                  color: Colors.teal,
                  subtitle: 'Total Wasooli in Hand',
                ),
                KpiCard(
                  title: 'Total Stock Value',
                  value: _formatPKR(_metrics['total_stock_value'] ?? 0),
                  icon: Icons.warehouse,
                  color: Colors.indigo,
                ),
                KpiCard(
                  title: 'Low Stock Alert',
                  value: '${_metrics['low_stock_count'] ?? 0} Items',
                  icon: Icons.warning_amber_rounded,
                  color: Colors.amber.shade800,
                  subtitle: 'Below threshold level',
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Recent Invoices Header & List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RECENT DISPATCHED BILLS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.8,
                  ),
                ),
                TextButton(
                  onPressed: () => widget.onNavigateTab(2), // Switch to Reports/Billing tab
                  child: const Text('View All', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),

            if (_recentInvoices.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Text(
                  'No bills created yet. Tap "+ New Bill" above to generate your first invoice.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentInvoices.length,
                itemBuilder: (context, index) {
                  final inv = _recentInvoices[index];
                  final isKhata = inv.paymentMethod.contains('Khata');

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    elevation: 0,
                    color: Colors.white,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      title: Text(
                        inv.customerName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      subtitle: Text(
                        '${inv.invoiceNo} • ${inv.date} • ${inv.items.length} items',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatPKR(inv.netPayable),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isKhata ? Colors.red.shade50 : Colors.emerald.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              inv.paymentMethod,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isKhata ? Colors.red.shade700 : Colors.emerald.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => JazzcashReceiptCard(invoice: inv),
                        );
                      },
                    ),
                  );
                },
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
