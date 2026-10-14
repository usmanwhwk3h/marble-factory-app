class StockItem {
  final int? id;
  final String category; // 'slabs', 'tiles', 'blocks'
  final String marbleName;
  final String bundleOrBlockNo;
  final double lengthFeet;
  final double heightOrWidthFeet;
  final int thicknessMm;
  final int piecesCount;
  final double totalSqFt;
  final String qualityGrade; // 'Super', 'Grade A', 'Grade B', 'Commercial'
  final String surfaceFinish;
  final String rackLocation;
  final double costPrice;
  final double sellingRate;
  final double minThreshold;
  final String? imagePath;
  final String? notes;
  final int syncStatus; // 0 = local/unsynced, 1 = synced to cloud/laptop
  final String updatedAt;

  StockItem({
    this.id,
    required this.category,
    required this.marbleName,
    required this.bundleOrBlockNo,
    required this.lengthFeet,
    required this.heightOrWidthFeet,
    required this.thicknessMm,
    required this.piecesCount,
    required this.totalSqFt,
    this.qualityGrade = 'Grade A',
    this.surfaceFinish = 'Mirror Polished',
    this.rackLocation = 'Yard A',
    required this.costPrice,
    required this.sellingRate,
    this.minThreshold = 200.0,
    this.imagePath,
    this.notes,
    this.syncStatus = 0,
    String? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'category': category,
      'marble_name': marbleName,
      'bundle_or_block_no': bundleOrBlockNo,
      'length_feet': lengthFeet,
      'height_or_width_feet': heightOrWidthFeet,
      'thickness_mm': thicknessMm,
      'pieces_count': piecesCount,
      'total_sqft': totalSqFt,
      'quality_grade': qualityGrade,
      'surface_finish': surfaceFinish,
      'rack_location': rackLocation,
      'cost_price': costPrice,
      'selling_rate': sellingRate,
      'min_threshold': minThreshold,
      'image_path': imagePath,
      'notes': notes,
      'sync_status': syncStatus,
      'updated_at': updatedAt,
    };
  }

  factory StockItem.fromMap(Map<String, dynamic> map) {
    return StockItem(
      id: map['id'],
      category: map['category'] ?? 'slabs',
      marbleName: map['marble_name'] ?? '',
      bundleOrBlockNo: map['bundle_or_block_no'] ?? '',
      lengthFeet: (map['length_feet'] as num?)?.toDouble() ?? 0.0,
      heightOrWidthFeet: (map['height_or_width_feet'] as num?)?.toDouble() ?? 0.0,
      thicknessMm: map['thickness_mm'] ?? 18,
      piecesCount: map['pieces_count'] ?? 0,
      totalSqFt: (map['total_sqft'] as num?)?.toDouble() ?? 0.0,
      qualityGrade: map['quality_grade'] ?? 'Grade A',
      surfaceFinish: map['surface_finish'] ?? 'Mirror Polished',
      rackLocation: map['rack_location'] ?? 'Yard A',
      costPrice: (map['cost_price'] as num?)?.toDouble() ?? 0.0,
      sellingRate: (map['selling_rate'] as num?)?.toDouble() ?? 0.0,
      minThreshold: (map['min_threshold'] as num?)?.toDouble() ?? 200.0,
      imagePath: map['image_path'],
      notes: map['notes'],
      syncStatus: map['sync_status'] ?? 0,
      updatedAt: map['updated_at'] ?? DateTime.now().toIso8601String(),
    );
  }

  StockItem copyWith({
    int? id,
    String? category,
    String? marbleName,
    String? bundleOrBlockNo,
    double? lengthFeet,
    double? heightOrWidthFeet,
    int? thicknessMm,
    int? piecesCount,
    double? totalSqFt,
    String? qualityGrade,
    String? surfaceFinish,
    String? rackLocation,
    double? costPrice,
    double? sellingRate,
    double? minThreshold,
    String? imagePath,
    String? notes,
    int? syncStatus,
    String? updatedAt,
  }) {
    return StockItem(
      id: id ?? this.id,
      category: category ?? this.category,
      marbleName: marbleName ?? this.marbleName,
      bundleOrBlockNo: bundleOrBlockNo ?? this.bundleOrBlockNo,
      lengthFeet: lengthFeet ?? this.lengthFeet,
      heightOrWidthFeet: heightOrWidthFeet ?? this.heightOrWidthFeet,
      thicknessMm: thicknessMm ?? this.thicknessMm,
      piecesCount: piecesCount ?? this.piecesCount,
      totalSqFt: totalSqFt ?? this.totalSqFt,
      qualityGrade: qualityGrade ?? this.qualityGrade,
      surfaceFinish: surfaceFinish ?? this.surfaceFinish,
      rackLocation: rackLocation ?? this.rackLocation,
      costPrice: costPrice ?? this.costPrice,
      sellingRate: sellingRate ?? this.sellingRate,
      minThreshold: minThreshold ?? this.minThreshold,
      imagePath: imagePath ?? this.imagePath,
      notes: notes ?? this.notes,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? DateTime.now().toIso8601String(),
    );
  }
}
