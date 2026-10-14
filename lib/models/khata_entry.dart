class KhataEntry {
  final int? id;
  final int customerId;
  final String date;
  final String time;
  final String type; // 'Debit', 'Credit' (Wasooli), 'Opening Balance'
  final String refNo;
  final String description;
  final double debit;
  final double credit;
  final double balanceAfter;
  final String paymentMethod;
  final int syncStatus;
  final String updatedAt;

  KhataEntry({
    this.id,
    required this.customerId,
    required this.date,
    required this.time,
    required this.type,
    required this.refNo,
    required this.description,
    required this.debit,
    required this.credit,
    required this.balanceAfter,
    this.paymentMethod = 'Cash',
    this.syncStatus = 0,
    String? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'customer_id': customerId,
      'date': date,
      'time': time,
      'type': type,
      'ref_no': refNo,
      'description': description,
      'debit': debit,
      'credit': credit,
      'balance_after': balanceAfter,
      'payment_method': paymentMethod,
      'sync_status': syncStatus,
      'updated_at': updatedAt,
    };
  }

  factory KhataEntry.fromMap(Map<String, dynamic> map) {
    return KhataEntry(
      id: map['id'],
      customerId: map['customer_id'],
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      type: map['type'] ?? 'Credit',
      refNo: map['ref_no'] ?? '',
      description: map['description'] ?? '',
      debit: (map['debit'] as num?)?.toDouble() ?? 0.0,
      credit: (map['credit'] as num?)?.toDouble() ?? 0.0,
      balanceAfter: (map['balance_after'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['payment_method'] ?? 'Cash',
      syncStatus: map['sync_status'] ?? 0,
      updatedAt: map['updated_at'] ?? DateTime.now().toIso8601String(),
    );
  }
}
