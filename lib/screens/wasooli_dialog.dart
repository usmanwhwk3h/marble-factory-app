import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import '../models/customer.dart';

class WasooliDialog extends StatefulWidget {
  final Customer? preSelectedCustomer;

  const WasooliDialog({Key? key, this.preSelectedCustomer}) : super(key: key);

  @override
  State<WasooliDialog> createState() => _WasooliDialogState();
}

class _WasooliDialogState extends State<WasooliDialog> {
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController(text: 'Counter cash wasooli');
  String _paymentMethod = 'Cash';
  Customer? _selectedCustomer;
  List<Customer> _customers = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.preSelectedCustomer;
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final list = await DatabaseHelper.instance.getAllCustomers();
    setState(() {
      _customers = list;
      if (_selectedCustomer != null) {
        // match from list to have matching instance
        _selectedCustomer = _customers.firstWhere(
          (c) => c.id == _selectedCustomer!.id,
          orElse: () => _selectedCustomer!,
        );
      }
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String _formatPKR(num value) {
    return 'PKR ${NumberFormat('#,##,###').format(value)}';
  }

  Future<void> _submitWasooli() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer')),
      );
      return;
    }

    final amount = double.tryParse(_amountCtrl.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid wasooli amount')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await DatabaseHelper.instance.recordWasooli(
        customerId: _selectedCustomer!.id!,
        amountReceived: amount,
        paymentMethod: _paymentMethod,
        notes: _notesCtrl.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wasooli of ${_formatPKR(amount)} recorded! Balance updated.'),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error recording wasooli: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _isLoading
            ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.payments_outlined, color: Color(0xFFD97706), size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Record Wasooli (Cash Collection)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              'Reduces customer Khata Baaqi immediately',
                              style: TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Customer dropdown
                  DropdownButtonFormField<Customer>(
                    value: _selectedCustomer,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Select Customer *',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _customers.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text(
                          '${c.name} (Baaqi: ${_formatPKR(c.currentBalance)})',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (c) => setState(() => _selectedCustomer = c),
                  ),

                  if (_selectedCustomer != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Current Outstanding Baaqi:', style: TextStyle(fontSize: 11, color: Colors.red)),
                          Text(
                            _formatPKR(_selectedCustomer!.currentBalance),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Amount received
                  TextFormField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                    decoration: InputDecoration(
                      labelText: 'Amount Received (PKR) *',
                      hintText: 'e.g. 50000',
                      prefixText: 'PKR ',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Payment method selector
                  Row(
                    children: [
                      _paymentChip('Cash'),
                      const SizedBox(width: 8),
                      _paymentChip('Bank Transfer'),
                      const SizedBox(width: 8),
                      _paymentChip('Cheque'),
                    ],
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _notesCtrl,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      labelText: 'Notes / Receipt Reference',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _submitWasooli,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            _isSaving ? 'Recording...' : 'Save Wasooli',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _paymentChip(String method) {
    final isSelected = _paymentMethod == method;
    return ChoiceChip(
      label: Text(method, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black87)),
      selected: isSelected,
      selectedColor: const Color(0xFF0F172A),
      onSelected: (_) => setState(() => _paymentMethod = method),
    );
  }
}
