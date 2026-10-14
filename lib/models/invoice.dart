import 'dart:convert';

class InvoiceItem {
  final int? stockItemId;
  final String marbleName;
  final String category;
  final String? sizeOrSpecs;
  final String qualityGrade;
  final double quantity; // Sq Ft or Pieces or Tons
  final String unit;
  final double rate;
  final double amount;

  InvoiceItem({
    this.stockItemId,
    required this.marbleName,
    this.category = 'slabs',
    this.sizeOrSpecs,
    this.qualityGrade = 'Grade A',
    required this.quantity,
    this.unit = 'Sq. Ft.',
    required this.rate,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'stock_item_id': stockItemId,
      'marble_name': marbleName,
      'category': category,
      'size_or_specs': sizeOrSpecs,
      'quality_grade': qualityGrade,
      'quantity': quantity,
      'unit': unit,
      'rate': rate,
      'amount': amount,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      stockItemId: map['stock_item_id'],
      marbleName: map['marble_name'] ?? '',
      category: map['category'] ?? 'slabs',
      sizeOrSpecs: map['size_or_specs'],
      qualityGrade: map['quality_grade'] ?? 'Grade A',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] ?? 'Sq. Ft.',
      rate: (map['rate'] as num?)?.toDouble() ?? 0.0,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Invoice {
  final int? id;
  final String invoiceNo;
  final String gatePassNo;
  final String date;
  final String? dueDate;
  final String time;
  final int? customerId;
  final String customerName;
  final String customerPhone;
  final String customerCity;
  final String? vehicleNo;
  final String? driverName;
  final List<InvoiceItem> items;
  final double grossTotal;
  final double discount;
  final double loadingCharges; // Mazdoori
  final double freightCharges; // Transport
  final double netPayable;
  final String paymentMethod; // 'Cash', 'Bank Transfer', 'Khata (Udhaar)'
  final double cashPaid;
  final double bankPaid;
  final double khataAmount;
  final int isCancelled;
  final int syncStatus;
  final String updatedAt;

  Invoice({
    this.id,
    required this.invoiceNo,
    required this.gatePassNo,
    required this.date,
    this.dueDate,
    required this.time,
    this.customerId,
    required this.customerName,
    required this.customerPhone,
    this.customerCity = 'Local Yard',
    this.vehicleNo,
    this.driverName,
    required this.items,
    required this.grossTotal,
    this.discount = 0.0,
    this.loadingCharges = 0.0,
    this.freightCharges = 0.0,
    required this.netPayable,
    required this.paymentMethod,
    this.cashPaid = 0.0,
    this.bankPaid = 0.0,
    this.khataAmount = 0.0,
    this.isCancelled = 0,
    this.syncStatus = 0,
    String? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'invoice_no': invoiceNo,
      'gate_pass_no': gatePassNo,
      'date': date,
      'due_date': dueDate,
      'time': time,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_city': customerCity,
      'vehicle_no': vehicleNo,
      'driver_name': driverName,
      'items_json': jsonEncode(items.map((i) => i.toMap()).toList()),
      'gross_total': grossTotal,
      'discount': discount,
      'loading_charges': loadingCharges,
      'freight_charges': freightCharges,
      'net_payable': netPayable,
      'payment_method': paymentMethod,
      'cash_paid': cashPaid,
      'bank_paid': bankPaid,
      'khata_amount': khataAmount,
      'is_cancelled': isCancelled,
      'sync_status': syncStatus,
      'updated_at': updatedAt,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    List<InvoiceItem> parsedItems = [];
    if (map['items_json'] != null) {
      try {
        final List<dynamic> list = jsonDecode(map['items_json']);
        parsedItems = list.map((item) => InvoiceItem.fromMap(item)).toList();
      } catch (_) {}
    }

    return Invoice(
      id: map['id'],
      invoiceNo: map['invoice_no'] ?? '',
      gatePassNo: map['gate_pass_no'] ?? '',
      date: map['date'] ?? '',
      dueDate: map['due_date'],
      time: map['time'] ?? '',
      customerId: map['customer_id'],
      customerName: map['customer_name'] ?? '',
      customerPhone: map['customer_phone'] ?? '',
      customerCity: map['customer_city'] ?? 'Local Yard',
      vehicleNo: map['vehicle_no'],
      driverName: map['driver_name'],
      items: parsedItems,
      grossTotal: (map['gross_total'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      loadingCharges: (map['loading_charges'] as num?)?.toDouble() ?? 0.0,
      freightCharges: (map['freight_charges'] as num?)?.toDouble() ?? 0.0,
      netPayable: (map['net_payable'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['payment_method'] ?? 'Cash',
      cashPaid: (map['cash_paid'] as num?)?.toDouble() ?? 0.0,
      bankPaid: (map['bank_paid'] as num?)?.toDouble() ?? 0.0,
      khataAmount: (map['khata_amount'] as num?)?.toDouble() ?? 0.0,
      isCancelled: map['is_cancelled'] ?? 0,
      syncStatus: map['sync_status'] ?? 0,
      updatedAt: map['updated_at'] ?? DateTime.now().toIso8601String(),
    );
  }
}
