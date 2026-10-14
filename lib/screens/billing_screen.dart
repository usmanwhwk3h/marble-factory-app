import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/stock_item.dart';
import '../widgets/jazzcash_receipt_card.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({Key? key}) : super(key: key);

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();
  final _customerCityCtrl = TextEditingController(text: 'Lahore');
  final _vehicleNoCtrl = TextEditingController();
  final _driverNameCtrl = TextEditingController();

  final _loadingChargesCtrl = TextEditingController(text: '0');
  final _freightChargesCtrl = TextEditingController(text: '0');
  final _discountCtrl = TextEditingController(text: '0');
  final _cashPaidCtrl = TextEditingController(text: '0');

  String _paymentMethod = 'Cash'; // 'Cash', 'Khata (Udhaar)', 'Bank Transfer'
  Customer? _selectedCustomer;
  List<Customer> _allCustomers = [];
  List<StockItem> _availableStock = [];

  // Active items being billed
  List<InvoiceItem> _billedItems = [];

  // Temporary row inputs for adding an item
  StockItem? _selectedStockToAdd;
  final _itemQtyCtrl = TextEditingController();
  final _itemRateCtrl = TextEditingController();

  bool _isFinalizing = false;

  @override
  void initState() {
    super.initState();
    _loadPrerequisites();
  }

  Future<void> _loadPrerequisites() async {
    final custs = await DatabaseHelper.instance.getAllCustomers();
    final stock = await DatabaseHelper.instance.getAllStock();
    setState(() {
      _allCustomers = custs;
      _availableStock = stock;
    });
  }

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _customerCityCtrl.dispose();
    _vehicleNoCtrl.dispose();
    _driverNameCtrl.dispose();
    _loadingChargesCtrl.dispose();
    _freightChargesCtrl.dispose();
    _discountCtrl.dispose();
    _cashPaidCtrl.dispose();
    _itemQtyCtrl.dispose();
    _itemRateCtrl.dispose();
    super.dispose();
  }

  double get _grossTotal {
    return _billedItems.fold(0.0, (sum, i) => sum + i.amount);
  }

  double get _loadingCharges => double.tryParse(_loadingChargesCtrl.text) ?? 0.0;
  double get _freightCharges => double.tryParse(_freightChargesCtrl.text) ?? 0.0;
  double get _discount => double.tryParse(_discountCtrl.text) ?? 0.0;

  double get _netPayable {
    final net = _grossTotal + _loadingCharges + _freightCharges - _discount;
    return net.clamp(0.0, double.infinity);
  }

  double get _khataAmount {
    if (_paymentMethod.contains('Khata')) {
      final cash = double.tryParse(_cashPaidCtrl.text) ?? 0.0;
      return (_netPayable - cash).clamp(0.0, double.infinity);
    }
    return 0.0;
  }

  void _addItemToBill() {
    if (_selectedStockToAdd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a stone from yard stock first')),
      );
      return;
    }

    final qty = double.tryParse(_itemQtyCtrl.text) ?? 0.0;
    final rate = double.tryParse(_itemRateCtrl.text) ?? 0.0;

    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid quantity (Sq. Ft.)')),
      );
      return;
    }

    if (qty > _selectedStockToAdd!.totalSqFt) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Warning: Only ${_selectedStockToAdd!.totalSqFt} SqFt available in this bundle!'),
          backgroundColor: Colors.amber.shade900,
        ),
      );
    }

    final amount = qty * rate;

    setState(() {
      _billedItems.add(
        InvoiceItem(
          stockItemId: _selectedStockToAdd!.id,
          marbleName: _selectedStockToAdd!.marbleName,
          category: _selectedStockToAdd!.category,
          sizeOrSpecs:
              '${_selectedStockToAdd!.lengthFeet}x${_selectedStockToAdd!.heightOrWidthFeet} ft (${_selectedStockToAdd!.thicknessMm}mm)',
          qualityGrade: _selectedStockToAdd!.qualityGrade,
          quantity: qty,
          unit: _selectedStockToAdd!.category == 'blocks' ? 'Tons' : 'Sq. Ft.',
          rate: rate,
          amount: amount,
        ),
      );

      // Reset item inputs
      _selectedStockToAdd = null;
      _itemQtyCtrl.clear();
      _itemRateCtrl.clear();
    });
  }

  Future<void> _finalizeInvoice() async {
    if (_billedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one marble item to the bill')),
      );
      return;
    }

    if (_customerNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer name is required')),
      );
      return;
    }

    setState(() => _isFinalizing = true);

    try {
      final now = DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(now);
      final timeStr = DateFormat('hh:mm a').format(now);
      final invNo = await DatabaseHelper.instance.getNextInvoiceNumber();
      final gpNo = await DatabaseHelper.instance.getNextGatePassNumber();

      // If customer doesn't exist, create customer
      int? targetCustId = _selectedCustomer?.id;
      if (targetCustId == null && _customerNameCtrl.text.trim().isNotEmpty) {
        targetCustId = await DatabaseHelper.instance.insertCustomer(
          Customer(
            name: _customerNameCtrl.text.trim(),
            phone: _customerPhoneCtrl.text.trim(),
            city: _customerCityCtrl.text.trim(),
            currentBalance: _khataAmount,
            syncStatus: 0,
          ),
        );
      }

      final invoice = Invoice(
        invoiceNo: invNo,
        gatePassNo: gpNo,
        date: dateStr,
        dueDate: DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 15))),
        time: timeStr,
        customerId: targetCustId,
        customerName: _customerNameCtrl.text.trim(),
        customerPhone: _customerPhoneCtrl.text.trim(),
        customerCity: _customerCityCtrl.text.trim(),
        vehicleNo: _vehicleNoCtrl.text.trim(),
        driverName: _driverNameCtrl.text.trim(),
        items: _billedItems,
        grossTotal: _grossTotal,
        discount: _discount,
        loadingCharges: _loadingCharges,
        freightCharges: _freightCharges,
        netPayable: _netPayable,
        paymentMethod: _paymentMethod,
        cashPaid: _paymentMethod == 'Cash'
            ? _netPayable
            : (double.tryParse(_cashPaidCtrl.text) ?? 0.0),
        bankPaid: _paymentMethod == 'Bank Transfer' ? _netPayable : 0.0,
        khataAmount: _khataAmount,
        syncStatus: 0,
      );

      final createdInvoice = await DatabaseHelper.instance.createInvoiceTransaction(invoice);

      if (mounted) {
        // Show Digital Receipt Slip Modal immediately
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => JazzcashReceiptCard(
            invoice: createdInvoice,
            customerTotalBaaqi: _khataAmount,
            onClose: () => Navigator.pop(context),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating bill: $e')),
      );
    } finally {
      if (mounted) setState(() => _isFinalizing = false);
    }
  }

  String _formatPKR(num value) {
    return 'PKR ${NumberFormat('#,##,###').format(value)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Counter & Field Billing (POS)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Selection & Details Box
              _buildSectionCard(
                title: 'CUSTOMER INFORMATION',
                icon: Icons.person_outline,
                child: Column(
                  children: [
                    // Quick select existing customer
                    if (_allCustomers.isNotEmpty) ...[
                      DropdownButtonFormField<Customer>(
                        value: _selectedCustomer,
                        decoration: _inputDeco(hint: 'Select registered customer or enter new below'),
                        items: _allCustomers.map((c) {
                          return DropdownMenuItem(
                            value: c,
                            child: Text('${c.name} (${c.phone}) - Baaqi: PKR ${c.currentBalance.toInt()}'),
                          );
                        }).toList(),
                        onChanged: (c) {
                          setState(() {
                            _selectedCustomer = c;
                            if (c != null) {
                              _customerNameCtrl.text = c.name;
                              _customerPhoneCtrl.text = c.phone;
                              _customerCityCtrl.text = c.city;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                    ],

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _customerNameCtrl,
                            style: const TextStyle(fontSize: 13),
                            decoration: _inputDeco(label: 'Customer Name *', hint: 'e.g. Malik Tariq'),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _customerPhoneCtrl,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(fontSize: 13),
                            decoration: _inputDeco(label: 'WhatsApp Phone *', hint: '0300-8452190'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _customerCityCtrl,
                            style: const TextStyle(fontSize: 13),
                            decoration: _inputDeco(label: 'City / Delivery Site', hint: 'Lahore'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _vehicleNoCtrl,
                            style: const TextStyle(fontSize: 13),
                            decoration: _inputDeco(label: 'Truck / Vehicle No', hint: 'TLK-4819'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Item Entry Box (Auto-suggest from local stock)
              _buildSectionCard(
                title: 'SELECT STONE ITEMS FROM STOCK',
                icon: Icons.layers_outlined,
                child: Column(
                  children: [
                    DropdownButtonFormField<StockItem>(
                      value: _selectedStockToAdd,
                      isExpanded: true,
                      decoration: _inputDeco(hint: 'Choose marble stock item'),
                      items: _availableStock.map((s) {
                        return DropdownMenuItem(
                          value: s,
                          child: Text(
                            '${s.marbleName} (${s.bundleOrBlockNo}) — ${s.totalSqFt} SqFt @ PKR ${s.sellingRate}',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (item) {
                        setState(() {
                          _selectedStockToAdd = item;
                          if (item != null) {
                            _itemRateCtrl.text = item.sellingRate.toString();
                            _itemQtyCtrl.text = item.totalSqFt.toString();
                          }
                        });
                      },
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _itemQtyCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            decoration: _inputDeco(label: 'Quantity (Sq. Ft.)', hint: '0'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _itemRateCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            decoration: _inputDeco(label: 'Rate / Sq. Ft. (PKR)', hint: '0'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _addItemToBill,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('+ Add', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),

                    // Billed Items Table
                    if (_billedItems.isNotEmpty) ...[
                      const Divider(height: 24),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _billedItems.length,
                        itemBuilder: (context, index) {
                          final it = _billedItems[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        it.marbleName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                      Text(
                                        '${it.quantity} ${it.unit} @ PKR ${it.rate}',
                                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatPKR(it.amount),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 16, color: Colors.red),
                                  onPressed: () => setState(() => _billedItems.removeAt(index)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Charges & Payment Split Card
              _buildSectionCard(
                title: 'CHARGES & PAYMENT ALLOCATION',
                icon: Icons.account_balance_wallet_outlined,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _loadingChargesCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(fontSize: 13),
                            decoration: _inputDeco(label: 'Loading/Mazdoori', hint: '0'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _freightChargesCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(fontSize: 13),
                            decoration: _inputDeco(label: 'Freight/Truck', hint: '0'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _discountCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(fontSize: 13),
                            decoration: _inputDeco(label: 'Discount (PKR)', hint: '0'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Payment Method Segmented Choice
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('PAYMENT MODE', style: _labelStyle()),
                    ),
                    const SizedBox(height: 6),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'Cash', label: Text('Cash (نقد)')),
                        ButtonSegment(value: 'Khata (Udhaar)', label: Text('Khata (ادھار)')),
                        ButtonSegment(value: 'Bank Transfer', label: Text('Online / Bank')),
                      ],
                      selected: {_paymentMethod},
                      onSelectionChanged: (set) => setState(() => _paymentMethod = set.first),
                    ),

                    if (_paymentMethod.contains('Khata')) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _cashPaidCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        decoration: _inputDeco(
                          label: 'Cash Token / Advance Received Now (PKR)',
                          hint: '0',
                        ),
                      ),
                    ],

                    const Divider(height: 24),

                    // Grand Totals Summary Row
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF), // Soft blue
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Gross Stone Total:', style: TextStyle(fontSize: 12)),
                              Text(_formatPKR(_grossTotal), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('NET PAYABLE:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                              Text(
                                _formatPKR(_netPayable),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1D4ED8)),
                              ),
                            ],
                          ),
                          if (_khataAmount > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Will be added to Customer Khata (Baaqi):',
                                    style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                                Text(_formatPKR(_khataAmount),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Finalize Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isFinalizing ? null : _finalizeInvoice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669), // Emerald
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: _isFinalizing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.receipt_long),
                  label: Text(
                    _isFinalizing ? 'Deducting Stock & Generating Slip...' : 'Finalize Bill & Open WhatsApp Slip',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF0F172A)),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDeco({String? label, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(fontSize: 11, color: Colors.grey.shade600),
      hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5)),
    );
  }

  TextStyle _labelStyle() {
    return TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 0.5);
  }
}
