import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';

import '../models/stock_item.dart';
import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/khata_entry.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('marble_factory_mobile.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // 1. Stock Items Table
    await db.execute('''
      CREATE TABLE stock_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        marble_name TEXT NOT NULL,
        bundle_or_block_no TEXT NOT NULL,
        length_feet REAL NOT NULL,
        height_or_width_feet REAL NOT NULL,
        thickness_mm INTEGER NOT NULL,
        pieces_count INTEGER NOT NULL,
        total_sqft REAL NOT NULL,
        quality_grade TEXT NOT NULL,
        surface_finish TEXT NOT NULL,
        rack_location TEXT NOT NULL,
        cost_price REAL NOT NULL,
        selling_rate REAL NOT NULL,
        min_threshold REAL NOT NULL,
        image_path TEXT,
        notes TEXT,
        sync_status INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');

    // 2. Customers Table
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        company_name TEXT,
        phone TEXT NOT NULL,
        city TEXT NOT NULL,
        address TEXT,
        credit_limit REAL NOT NULL DEFAULT 1000000.0,
        current_balance REAL NOT NULL DEFAULT 0.0,
        sync_status INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');

    // 3. Invoices Table
    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_no TEXT NOT NULL UNIQUE,
        gate_pass_no TEXT NOT NULL UNIQUE,
        date TEXT NOT NULL,
        due_date TEXT,
        time TEXT NOT NULL,
        customer_id INTEGER,
        customer_name TEXT NOT NULL,
        customer_phone TEXT NOT NULL,
        customer_city TEXT NOT NULL,
        vehicle_no TEXT,
        driver_name TEXT,
        items_json TEXT NOT NULL,
        gross_total REAL NOT NULL,
        discount REAL NOT NULL DEFAULT 0.0,
        loading_charges REAL NOT NULL DEFAULT 0.0,
        freight_charges REAL NOT NULL DEFAULT 0.0,
        net_payable REAL NOT NULL,
        payment_method TEXT NOT NULL,
        cash_paid REAL NOT NULL DEFAULT 0.0,
        bank_paid REAL NOT NULL DEFAULT 0.0,
        khata_amount REAL NOT NULL DEFAULT 0.0,
        is_cancelled INTEGER NOT NULL DEFAULT 0,
        sync_status INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');

    // 4. Khata Ledger Entries Table
    await db.execute('''
      CREATE TABLE khata_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        type TEXT NOT NULL,
        ref_no TEXT NOT NULL,
        description TEXT NOT NULL,
        debit REAL NOT NULL DEFAULT 0.0,
        credit REAL NOT NULL DEFAULT 0.0,
        balance_after REAL NOT NULL,
        payment_method TEXT NOT NULL DEFAULT 'Cash',
        sync_status INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');

    // Seed realistic sample data so app is immediately ready out of the box
    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    final nowStr = DateTime.now().toIso8601String();
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Slabs
    await db.insert('stock_items', {
      'category': 'slabs',
      'marble_name': 'Ziarat White (Super Grade)',
      'bundle_or_block_no': 'ZW-B-101',
      'length_feet': 8.5,
      'height_or_width_feet': 4.8,
      'thickness_mm': 18,
      'pieces_count': 22,
      'total_sqft': 897.6,
      'quality_grade': 'Super',
      'surface_finish': 'Mirror Polished',
      'rack_location': 'Shed 1 - Bay A4',
      'cost_price': 340.0,
      'selling_rate': 520.0,
      'min_threshold': 300.0,
      'notes': 'Pure crystalline white marble from Mohmand hills',
      'sync_status': 0,
      'updated_at': nowStr,
    });

    await db.insert('stock_items', {
      'category': 'slabs',
      'marble_name': 'Sunny Grey (Classic)',
      'bundle_or_block_no': 'SG-B-204',
      'length_feet': 9.0,
      'height_or_width_feet': 5.2,
      'thickness_mm': 18,
      'pieces_count': 30,
      'total_sqft': 1404.0,
      'quality_grade': 'Grade A',
      'surface_finish': 'Mirror Polished',
      'rack_location': 'Shed 1 - Bay B2',
      'cost_price': 180.0,
      'selling_rate': 290.0,
      'min_threshold': 400.0,
      'notes': 'Uniform fine grain, high strength',
      'sync_status': 0,
      'updated_at': nowStr,
    });

    // Tiles
    await db.insert('stock_items', {
      'category': 'tiles',
      'marble_name': 'Sunny Grey Tiles (12x24)',
      'bundle_or_block_no': 'SG-T-501',
      'length_feet': 2.0,
      'height_or_width_feet': 1.0,
      'thickness_mm': 18,
      'pieces_count': 720,
      'total_sqft': 1440.0,
      'quality_grade': 'Grade A',
      'surface_finish': 'Mirror Polished',
      'rack_location': 'Tile Yard - Row 1',
      'cost_price': 160.0,
      'selling_rate': 250.0,
      'min_threshold': 500.0,
      'notes': 'Standard 12x24 cut tiles in 120 boxes',
      'sync_status': 0,
      'updated_at': nowStr,
    });

    // Raw Blocks
    await db.insert('stock_items', {
      'category': 'blocks',
      'marble_name': 'Black & Gold (Michael Angelo)',
      'bundle_or_block_no': 'BLK-2026-092',
      'length_feet': 9.5,
      'height_or_width_feet': 5.4,
      'thickness_mm': 0,
      'pieces_count': 1,
      'total_sqft': 25.5, // Used as Tons here
      'quality_grade': 'Super',
      'surface_finish': 'Rough Sawn Quarry Block',
      'rack_location': 'Open Yard - Section B',
      'cost_price': 420000.0,
      'selling_rate': 650000.0,
      'min_threshold': 2.0,
      'notes': 'Quarried from Khuzdar, Balochistan. Ready for gang saw.',
      'sync_status': 0,
      'updated_at': nowStr,
    });

    // Initial Customers
    final cust1Id = await db.insert('customers', {
      'name': 'Malik Tariq Mehmood',
      'company_name': 'Tariq Builders & Developers',
      'phone': '03008452190',
      'city': 'Lahore (DHA Phase 6)',
      'address': 'Main Commercial Sector C',
      'credit_limit': 1500000.0,
      'current_balance': 485000.0,
      'sync_status': 0,
      'updated_at': nowStr,
    });

    await db.insert('khata_entries', {
      'customer_id': cust1Id,
      'date': todayStr,
      'time': '10:00 AM',
      'type': 'Opening Balance',
      'ref_no': 'OPEN-01',
      'description': 'Previous seasonal stone balance brought forward',
      'debit': 485000.0,
      'credit': 0.0,
      'balance_after': 485000.0,
      'payment_method': 'Khata',
      'sync_status': 0,
      'updated_at': nowStr,
    });

    await db.insert('customers', {
      'name': 'Haji Aslam Marble Traders',
      'company_name': 'Aslam & Sons Marble Yard',
      'phone': '03219923841',
      'city': 'Peshawar (Ring Road)',
      'address': 'Plot 44, Stone Market',
      'credit_limit': 2500000.0,
      'current_balance': 320000.0,
      'sync_status': 0,
      'updated_at': nowStr,
    });
  }

  // ==================== STOCK OPERATIONS ====================

  Future<int> insertStock(StockItem item) async {
    final db = await instance.database;
    return await db.insert('stock_items', item.toMap());
  }

  Future<int> updateStock(StockItem item) async {
    final db = await instance.database;
    return await db.update(
      'stock_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteStock(int id) async {
    final db = await instance.database;
    return await db.delete('stock_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<StockItem>> getStockByCategory(String category) async {
    final db = await instance.database;
    final maps = await db.query(
      'stock_items',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'id DESC',
    );
    return maps.map((m) => StockItem.fromMap(m)).toList();
  }

  Future<List<StockItem>> getAllStock() async {
    final db = await instance.database;
    final maps = await db.query('stock_items', orderBy: 'id DESC');
    return maps.map((m) => StockItem.fromMap(m)).toList();
  }

  // ==================== INVOICING & FAST BILLING ====================

  Future<Invoice> createInvoiceTransaction(Invoice invoice) async {
    final db = await instance.database;
    final nowStr = DateTime.now().toIso8601String();

    return await db.transaction<Invoice>((txn) async {
      // 1. Insert Invoice
      final invId = await txn.insert('invoices', invoice.toMap());

      // 2. Automatically Deduct Stock Quantity for all sold items
      for (final item in invoice.items) {
        if (item.stockItemId != null) {
          final res = await txn.query(
            'stock_items',
            columns: ['total_sqft', 'pieces_count'],
            where: 'id = ?',
            whereArgs: [item.stockItemId],
          );
          if (res.isNotEmpty) {
            final currentSqFt = (res.first['total_sqft'] as num).toDouble();
            final currentPieces = res.first['pieces_count'] as int;

            final newSqFt = (currentSqFt - item.quantity).clamp(0.0, double.infinity);
            final newPieces = (currentPieces - 1).clamp(0, 999999);

            await txn.update(
              'stock_items',
              {
                'total_sqft': double.parse(newSqFt.toStringAsFixed(1)),
                'pieces_count': newPieces,
                'sync_status': 0,
                'updated_at': nowStr,
              },
              where: 'id = ?',
              whereArgs: [item.stockItemId],
            );
          }
        }
      }

      // 3. Update Customer Khata if Udhaar involved or linked to customer
      if (invoice.customerId != null && invoice.customerId! > 0) {
        final custRes = await txn.query(
          'customers',
          columns: ['current_balance'],
          where: 'id = ?',
          whereArgs: [invoice.customerId],
        );

        if (custRes.isNotEmpty) {
          final currentBalance = (custRes.first['current_balance'] as num).toDouble();
          final newBalance = currentBalance + invoice.khataAmount;

          await txn.update(
            'customers',
            {
              'current_balance': newBalance,
              'sync_status': 0,
              'updated_at': nowStr,
            },
            where: 'id = ?',
            whereArgs: [invoice.customerId],
          );

          // Add Ledger Entry
          await txn.insert('khata_entries', {
            'customer_id': invoice.customerId,
            'date': invoice.date,
            'time': invoice.time,
            'type': 'Debit',
            'ref_no': invoice.invoiceNo,
            'description': 'Dispatched: ${invoice.items.map((i) => "${i.marbleName} (${i.quantity} ${i.unit})").join(", ")}',
            'debit': invoice.netPayable,
            'credit': invoice.cashPaid + invoice.bankPaid,
            'balance_after': newBalance,
            'payment_method': invoice.paymentMethod,
            'sync_status': 0,
            'updated_at': nowStr,
          });
        }
      }

      return Invoice(
        id: invId,
        invoiceNo: invoice.invoiceNo,
        gatePassNo: invoice.gatePassNo,
        date: invoice.date,
        dueDate: invoice.dueDate,
        time: invoice.time,
        customerId: invoice.customerId,
        customerName: invoice.customerName,
        customerPhone: invoice.customerPhone,
        customerCity: invoice.customerCity,
        vehicleNo: invoice.vehicleNo,
        driverName: invoice.driverName,
        items: invoice.items,
        grossTotal: invoice.grossTotal,
        discount: invoice.discount,
        loadingCharges: invoice.loadingCharges,
        freightCharges: invoice.freightCharges,
        netPayable: invoice.netPayable,
        paymentMethod: invoice.paymentMethod,
        cashPaid: invoice.cashPaid,
        bankPaid: invoice.bankPaid,
        khataAmount: invoice.khataAmount,
        isCancelled: invoice.isCancelled,
        syncStatus: 0,
        updatedAt: nowStr,
      );
    });
  }

  Future<List<Invoice>> getAllInvoices() async {
    final db = await instance.database;
    final maps = await db.query('invoices', orderBy: 'id DESC');
    return maps.map((m) => Invoice.fromMap(m)).toList();
  }

  Future<String> getNextInvoiceNumber() async {
    final db = await instance.database;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM invoices')) ?? 0;
    return 'INV-2026-${(1001 + count).toString().padLeft(4, '0')}';
  }

  Future<String> getNextGatePassNumber() async {
    final db = await instance.database;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM invoices')) ?? 0;
    return 'GP-2026-${(801 + count).toString().padLeft(4, '0')}';
  }

  // ==================== CUSTOMER & KHATA OPERATIONS ====================

  Future<int> insertCustomer(Customer customer) async {
    final db = await instance.database;
    return await db.insert('customers', customer.toMap());
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await instance.database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<List<Customer>> getAllCustomers() async {
    final db = await instance.database;
    final maps = await db.query('customers', orderBy: 'current_balance DESC');
    return maps.map((m) => Customer.fromMap(m)).toList();
  }

  Future<Customer?> getCustomerById(int id) async {
    final db = await instance.database;
    final maps = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Customer.fromMap(maps.first);
    }
    return null;
  }

  // Record Wasooli (Payment Received to decrease Customer Baaqi Udhaar)
  Future<void> recordWasooli({
    required int customerId,
    required double amountReceived,
    required String paymentMethod,
    required String notes,
  }) async {
    final db = await instance.database;
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final timeStr = DateFormat('hh:mm a').format(now);
    final nowStr = now.toIso8601String();
    final receiptCode = 'WAS-${now.millisecondsSinceEpoch.toString().substring(7)}';

    await db.transaction((txn) async {
      // 1. Get current balance
      final cust = await txn.query(
        'customers',
        columns: ['current_balance'],
        where: 'id = ?',
        whereArgs: [customerId],
      );

      if (cust.isNotEmpty) {
        final currentBal = (cust.first['current_balance'] as num).toDouble();
        final newBal = currentBal - amountReceived;

        // 2. Update customer balance
        await txn.update(
          'customers',
          {
            'current_balance': newBal,
            'sync_status': 0,
            'updated_at': nowStr,
          },
          where: 'id = ?',
          whereArgs: [customerId],
        );

        // 3. Insert into Khata Entries
        await txn.insert('khata_entries', {
          'customer_id': customerId,
          'date': todayStr,
          'time': timeStr,
          'type': 'Credit',
          'ref_no': receiptCode,
          'description': 'Wasooli (Payment Received) - $notes',
          'debit': 0.0,
          'credit': amountReceived,
          'balance_after': newBal,
          'payment_method': paymentMethod,
          'sync_status': 0,
          'updated_at': nowStr,
        });
      }
    });
  }

  Future<List<KhataEntry>> getLedgerForCustomer(int customerId) async {
    final db = await instance.database;
    final maps = await db.query(
      'khata_entries',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'id DESC',
    );
    return maps.map((m) => KhataEntry.fromMap(m)).toList();
  }

  // ==================== DASHBOARD & REPORTS METRICS ====================

  Future<Map<String, dynamic>> getDashboardMetrics() async {
    final db = await instance.database;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final currentMonthStr = DateFormat('yyyy-MM').format(DateTime.now());

    // 1. Today's Sales
    final todayRes = await db.rawQuery(
      'SELECT SUM(net_payable) as total FROM invoices WHERE date = ? AND is_cancelled = 0',
      [todayStr],
    );
    final todaySales = (todayRes.first['total'] as num?)?.toDouble() ?? 0.0;

    // 2. Month's Sales
    final monthRes = await db.rawQuery(
      "SELECT SUM(net_payable) as total FROM invoices WHERE strftime('%Y-%m', date) = ? AND is_cancelled = 0",
      [currentMonthStr],
    );
    final monthSales = (monthRes.first['total'] as num?)?.toDouble() ?? 0.0;

    // 3. Total Cash & Bank Collected
    final cashRes = await db.rawQuery(
      'SELECT SUM(credit) as total FROM khata_entries WHERE type = "Credit"',
    );
    final directCashRes = await db.rawQuery(
      'SELECT SUM(cash_paid + bank_paid) as total FROM invoices WHERE is_cancelled = 0',
    );
    final totalWasooli = (cashRes.first['total'] as num?)?.toDouble() ?? 0.0;
    final directCash = (directCashRes.first['total'] as num?)?.toDouble() ?? 0.0;

    // 4. Customer Total Baaqi (Udhaar)
    final udhaarRes = await db.rawQuery(
      'SELECT SUM(current_balance) as total FROM customers WHERE current_balance > 0',
    );
    final totalUdhaar = (udhaarRes.first['total'] as num?)?.toDouble() ?? 0.0;

    // 5. Total Stock SqFt / Valuation
    final stockRes = await db.rawQuery(
      'SELECT SUM(total_sqft * selling_rate) as total_val, COUNT(*) as count FROM stock_items',
    );
    final totalStockValue = (stockRes.first['total_val'] as num?)?.toDouble() ?? 0.0;

    // 6. Low stock count
    final lowStockCount = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM stock_items WHERE total_sqft <= min_threshold',
        )) ??
        0;

    return {
      'today_sales': todaySales,
      'month_sales': monthSales,
      'total_cash_collected': totalWasooli + directCash,
      'total_udhaar': totalUdhaar,
      'total_stock_value': totalStockValue,
      'low_stock_count': lowStockCount,
    };
  }

  // ==================== FUTURE SYNC READY HELPERS ====================

  Future<List<Map<String, dynamic>>> getUnsyncedRecords(String table) async {
    final db = await instance.database;
    return await db.query(table, where: 'sync_status = 0');
  }

  Future<void> markRecordSynced(String table, int id) async {
    final db = await instance.database;
    await db.update(
      table,
      {'sync_status': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
