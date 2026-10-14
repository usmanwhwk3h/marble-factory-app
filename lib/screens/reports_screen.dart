import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import '../models/invoice.dart';
import '../widgets/jazzcash_receipt_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _filter = 'This Month'; // 'Today', 'This Month', 'All'
  DateTimeRange? _customRange;
  List<Invoice> _allInvoices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);
    final list = await DatabaseHelper.instance.getAllInvoices();
    setState(() {
      _allInvoices = list;
      _isLoading = false;
    });
  }

  List<Invoice> get _filteredInvoices {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final monthStr = DateFormat('yyyy-MM').format(now);

    return _allInvoices.where((inv) {
      if (_filter == 'Today') {
        return inv.date == todayStr;
      } else if (_filter == 'This Month') {
        return inv.date.startsWith(monthStr);
      } else if (_filter == 'Custom' && _customRange != null) {
        try {
          final d = DateTime.parse(inv.date);
          return d.isAfter(_customRange!.start.subtract(const Duration(days: 1))) &&
              d.isBefore(_customRange!.end.add(const Duration(days: 1)));
        } catch (_) {
          return true;
        }
      }
      return true;
    }).toList();
  }

  double get _totalRevenue {
    return _filteredInvoices.fold(0.0, (sum, i) => sum + i.netPayable);
  }

  double get _totalCashCollected {
    return _filteredInvoices.fold(0.0, (sum, i) => sum + (i.cashPaid + i.bankPaid));
  }

  double get _totalUdhaarGiven {
    return _filteredInvoices.fold(0.0, (sum, i) => sum + i.khataAmount);
  }

  String _formatPKR(num value) {
    return 'PKR ${NumberFormat('#,##,###').format(value)}';
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredInvoices;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Daily & Monthly Sales Reports', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                _filterChip('Today'),
                const SizedBox(width: 8),
                _filterChip('This Month'),
                const SizedBox(width: 8),
                _filterChip('All'),
                const SizedBox(width: 8),
                ActionChip(
                  label: Text(_customRange == null ? 'Custom Date' : 'Custom (${DateFormat('dd/MM').format(_customRange!.start)})'),
                  avatar: const Icon(Icons.date_range, size: 14),
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() {
                        _customRange = picked;
                        _filter = 'Custom';
                      });
                    }
                  },
                ),
              ],
            ),
          ),

          // Period Financial Summary Card
          Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$_filter SALES REVENUE'.toUpperCase(),
                            style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(_formatPKR(_totalRevenue),
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${list.length} Invoices',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const Divider(color: Colors.white24, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Cash / Bank Received', style: TextStyle(color: Colors.grey, fontSize: 9)),
                        Text(_formatPKR(_totalCashCollected),
                            style: const TextStyle(color: Color(0xFF34D399), fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Dispatched on Khata (Udhaar)', style: TextStyle(color: Colors.grey, fontSize: 9)),
                        Text(_formatPKR(_totalUdhaarGiven),
                            style: const TextStyle(color: Color(0xFFF87171), fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Invoices List for Selected Period
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                    ? const Center(child: Text('No sales records found for this period'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final inv = list[index];
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
                              title: Text(inv.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text(
                                '${inv.invoiceNo} • ${inv.date} • ${inv.items.length} items',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(_formatPKR(inv.netPayable),
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                                  Text(inv.paymentMethod,
                                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
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
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String filterName) {
    final isSelected = _filter == filterName;
    return ChoiceChip(
      label: Text(filterName, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black87)),
      selected: isSelected,
      selectedColor: const Color(0xFF0F172A),
      onSelected: (_) => setState(() => _filter = filterName),
    );
  }
}
