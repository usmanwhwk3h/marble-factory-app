import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import '../models/stock_item.dart';
import 'add_edit_stock_screen.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({Key? key}) : super(key: key);

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<StockItem> _slabs = [];
  List<StockItem> _tiles = [];
  List<StockItem> _blocks = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllStock();
  }

  Future<void> _loadAllStock() async {
    setState(() => _isLoading = true);
    final slabs = await DatabaseHelper.instance.getStockByCategory('slabs');
    final tiles = await DatabaseHelper.instance.getStockByCategory('tiles');
    final blocks = await DatabaseHelper.instance.getStockByCategory('blocks');

    setState(() {
      _slabs = slabs;
      _tiles = tiles;
      _blocks = blocks;
      _isLoading = false;
    });
  }

  List<StockItem> _filterItems(List<StockItem> list) {
    if (_searchQuery.isEmpty) return list;
    return list.where((item) {
      return item.marbleName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.bundleOrBlockNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.rackLocation.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  String _formatPKR(num value) {
    return 'PKR ${NumberFormat('#,##,###').format(value)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Stock Management',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: const Color(0xFF0F172A),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFFF59E0B), // Amber indicator
              indicatorWeight: 3,
              labelColor: const Color(0xFFF59E0B),
              unselectedLabelColor: Colors.grey.shade400,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              tabs: [
                Tab(text: 'Slabs (${_slabs.length})'),
                Tab(text: 'Tiles (${_tiles.length})'),
                Tab(text: 'Blocks (${_blocks.length})'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search marble name, bundle #, rack...',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Stock Items List Tabs
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildStockList(_filterItems(_slabs), 'slabs'),
                      _buildStockList(_filterItems(_tiles), 'tiles'),
                      _buildStockList(_filterItems(_blocks), 'blocks'),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final String currentCat = _tabController.index == 0
              ? 'slabs'
              : _tabController.index == 1
                  ? 'tiles'
                  : 'blocks';
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditStockScreen(initialCategory: currentCat),
            ),
          );
          _loadAllStock();
        },
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Add Stock', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStockList(List<StockItem> items, String category) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No ${category.toUpperCase()} found in yard',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap "+ Add Stock" below to record new stone stock',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isLowStock = item.totalSqFt <= item.minThreshold;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isLowStock ? Colors.amber.shade300 : Colors.grey.shade200,
              width: isLowStock ? 1.5 : 1,
            ),
          ),
          elevation: 0,
          color: Colors.white,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditStockScreen(existingItem: item),
                ),
              );
              _loadAllStock();
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo Thumbnail / Category Icon Container
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 64,
                      height: 64,
                      color: const Color(0xFF1E293B),
                      child: item.imagePath != null && File(item.imagePath!).existsSync()
                          ? Image.file(File(item.imagePath!), fit: BoxFit.cover)
                          : Center(
                              child: Text(
                                item.marbleName.isNotEmpty ? item.marbleName[0] : 'M',
                                style: const TextStyle(
                                  color: Color(0xFFF59E0B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Marble Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.marbleName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.qualityGrade,
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Bundle: ${item.bundleOrBlockNo} • Rack: ${item.rackLocation}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Size: ${item.lengthFeet}ft x ${item.heightOrWidthFeet}ft (${item.thicknessMm}mm) • ${item.piecesCount} pcs',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 6),

                        // Available Stock & Selling Rate Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${item.totalSqFt} ${category == 'blocks' ? 'Tons' : 'SqFt'}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    color: isLowStock ? Colors.red.shade700 : const Color(0xFF0F172A),
                                  ),
                                ),
                                if (isLowStock) ...[
                                  const SizedBox(width: 4),
                                  Icon(Icons.warning, size: 14, color: Colors.amber.shade800),
                                ],
                              ],
                            ),
                            Text(
                              '${_formatPKR(item.sellingRate)}/${category == 'blocks' ? 'Ton' : 'SqFt'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
