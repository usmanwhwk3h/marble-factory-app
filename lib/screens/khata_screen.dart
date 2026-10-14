import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../database/database_helper.dart';
import '../models/customer.dart';
import '../models/khata_entry.dart';
import 'wasooli_dialog.dart';

class KhataScreen extends StatefulWidget {
  const KhataScreen({Key? key}) : super(key: key);

  @override
  State<KhataScreen> createState() => _KhataScreenState();
}

class _KhataScreenState extends State<KhataScreen> {
  List<Customer> _customers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    final list = await DatabaseHelper.instance.getAllCustomers();
    setState(() {
      _customers = list;
      _isLoading = false;
    });
  }

  List<Customer> get _filteredCustomers {
    if (_searchQuery.isEmpty) return _customers;
    return _customers.where((c) {
      return c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.phone.contains(_searchQuery) ||
          c.city.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  String _formatPKR(num value) {
    return 'PKR ${NumberFormat('#,##,###').format(value)}';
  }

  double get _totalUdhaar {
    return _customers.fold(0.0, (sum, c) => sum + (c.currentBalance > 0 ? c.currentBalance : 0.0));
  }

  // Open customer ledger modal
  void _openLedger(Customer customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => CustomerLedgerSheet(
        customer: customer,
        onWasooliDone: () {
          _loadCustomers();
        },
      ),
    );
  }

  void _sendWhatsAppReminder(Customer customer) async {
    final message = '''
السلام علیکم ورحمۃ اللہ،
محترم جناب *${customer.name}* صاحب،
ماربل فیکٹری کے کھاتہ کے مطابق آپ کا واجب الادا بقایا جات (Total Outstanding Balance):
*PKR ${_formatPKR(customer.currentBalance)}* ہے.
برائے مہربانی جلد از جلد ادائیگی کی تصدیق فرما دیجئے۔ شکریہ!
— المدینہ ماربل اینڈ گرینائٹ انڈسٹریز
''';

    String phone = customer.phone.replaceAll(RegExp(r'\D'), '');
    if (phone.startsWith('0')) phone = '92${phone.substring(1)}';

    final uri = Uri.parse('https://api.whatsapp.com/send?phone=$phone&text=${Uri.encodeComponent(message)}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Customer Khata (Ledger & Udhaar)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Total Baaqi Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF0F172A),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TOTAL KUL BAAQI UDHAAR', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                      _formatPKR(_totalUdhaar),
                      style: const TextStyle(color: Color(0xFFF87171), fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final res = await showDialog(context: context, builder: (_) => const WasooliDialog());
                    if (res == true) _loadCustomers();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.payments_outlined, size: 16),
                  label: const Text('Record Wasooli', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            ),
          ),

          // Search Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search customer name, phone, city...',
                prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),

          // Customers List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCustomers.isEmpty
                    ? const Center(child: Text('No customers found'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        itemCount: _filteredCustomers.length,
                        itemBuilder: (context, index) {
                          final cust = _filteredCustomers[index];
                          final hasUdhaar = cust.currentBalance > 0;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            elevation: 0,
                            color: Colors.white,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => _openLedger(cust),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: hasUdhaar ? Colors.red.shade50 : Colors.blue.shade50,
                                      child: Text(
                                        cust.name.isNotEmpty ? cust.name[0] : 'C',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: hasUdhaar ? Colors.red.shade800 : Colors.blue.shade800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(cust.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          Text(
                                            '${cust.phone} • ${cust.city}',
                                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          _formatPKR(cust.currentBalance),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 13,
                                            color: hasUdhaar ? Colors.red.shade700 : Colors.grey.shade800,
                                          ),
                                        ),
                                        Text(
                                          hasUdhaar ? 'Baaqi Udhaar' : 'Nil Balance',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: hasUdhaar ? Colors.red.shade600 : Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (hasUdhaar) ...[
                                      const SizedBox(width: 6),
                                      IconButton(
                                        icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366), size: 20),
                                        onPressed: () => _sendWhatsAppReminder(cust),
                                        tooltip: 'WhatsApp Reminder',
                                      ),
                                    ],
                                  ],
                                ),
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
}

// Bottom Sheet displaying detailed Customer Ledger Entries
class CustomerLedgerSheet extends StatefulWidget {
  final Customer customer;
  final VoidCallback onWasooliDone;

  const CustomerLedgerSheet({Key? key, required this.customer, required this.onWasooliDone}) : super(key: key);

  @override
  State<CustomerLedgerSheet> createState() => _CustomerLedgerSheetState();
}

class _CustomerLedgerSheetState extends State<CustomerLedgerSheet> {
  List<KhataEntry> _entries = [];
  late Customer _currentCustomer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentCustomer = widget.customer;
    _loadLedger();
  }

  Future<void> _loadLedger() async {
    setState(() => _isLoading = true);
    final list = await DatabaseHelper.instance.getLedgerForCustomer(_currentCustomer.id!);
    final updatedCust = await DatabaseHelper.instance.getCustomerById(_currentCustomer.id!);
    setState(() {
      _entries = list;
      if (updatedCust != null) _currentCustomer = updatedCust;
      _isLoading = false;
    });
  }

  String _formatPKR(num value) {
    return 'PKR ${NumberFormat('#,##,###').format(value)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_currentCustomer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      '${_currentCustomer.phone} • ${_currentCustomer.city}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),

          const SizedBox(height: 12),

          // Balance Card & Wasooli Trigger
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CURRENT OUTSTANDING BAAQI', style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                      _formatPKR(_currentCustomer.currentBalance),
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () async {
                    final res = await showDialog(
                      context: context,
                      builder: (_) => WasooliDialog(preSelectedCustomer: _currentCustomer),
                    );
                    if (res == true) {
                      _loadLedger();
                      widget.onWasooliDone();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Record Wasooli', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Text('TRANSACTION LEDGER HISTORY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 8),

          // Ledger Table / List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _entries.isEmpty
                    ? const Center(child: Text('No ledger entries recorded yet'))
                    : ListView.builder(
                        itemCount: _entries.length,
                        itemBuilder: (context, index) {
                          final e = _entries[index];
                          final isDebit = e.debit > 0;

                          return Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isDebit ? Icons.arrow_outward : Icons.arrow_downward,
                                  color: isDebit ? Colors.red : Colors.green,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${e.date} (${e.refNo})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                      Text(e.description, style: TextStyle(fontSize: 10, color: Colors.grey.shade600), maxLines: 2),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      isDebit ? '+ ${_formatPKR(e.debit)}' : '- ${_formatPKR(e.credit)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isDebit ? Colors.red.shade700 : Colors.green.shade700,
                                      ),
                                    ),
                                    Text(
                                      'Bal: ${_formatPKR(e.balanceAfter)}',
                                      style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
