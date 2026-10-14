import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../database/database_helper.dart';
import '../models/stock_item.dart';

class AddEditStockScreen extends StatefulWidget {
  final StockItem? existingItem;
  final String? initialCategory;

  const AddEditStockScreen({
    Key? key,
    this.existingItem,
    this.initialCategory,
  }) : super(key: key);

  @override
  State<AddEditStockScreen> createState() => _AddEditStockScreenState();
}

class _AddEditStockScreenState extends State<AddEditStockScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _category;
  late TextEditingController _nameController;
  late TextEditingController _bundleNoController;
  late TextEditingController _lengthController;
  late TextEditingController _heightController;
  late TextEditingController _thicknessController;
  late TextEditingController _piecesController;
  late TextEditingController _totalSqFtController;
  late TextEditingController _costPriceController;
  late TextEditingController _sellingRateController;
  late TextEditingController _rackController;
  late TextEditingController _notesController;

  String _qualityGrade = 'Grade A';
  String _surfaceFinish = 'Mirror Polished';
  String? _imagePath;
  bool _isSaving = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    _category = item?.category ?? widget.initialCategory ?? 'slabs';

    _nameController = TextEditingController(text: item?.marbleName ?? 'Ziarat White (Super)');
    _bundleNoController = TextEditingController(
      text: item?.bundleOrBlockNo ?? 'BND-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
    );
    _lengthController = TextEditingController(text: item?.lengthFeet.toString() ?? '8.5');
    _heightController = TextEditingController(text: item?.heightOrWidthFeet.toString() ?? '4.8');
    _thicknessController = TextEditingController(text: item?.thicknessMm.toString() ?? '18');
    _piecesController = TextEditingController(text: item?.piecesCount.toString() ?? '20');
    _totalSqFtController = TextEditingController(text: item?.totalSqFt.toString() ?? '816.0');
    _costPriceController = TextEditingController(text: item?.costPrice.toString() ?? '340');
    _sellingRateController = TextEditingController(text: item?.sellingRate.toString() ?? '520');
    _rackController = TextEditingController(text: item?.rackLocation ?? 'Shed 1 - Bay A');
    _notesController = TextEditingController(text: item?.notes ?? '');

    _qualityGrade = item?.qualityGrade ?? 'Grade A';
    _surfaceFinish = item?.surfaceFinish ?? 'Mirror Polished';
    _imagePath = item?.imagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bundleNoController.dispose();
    _lengthController.dispose();
    _heightController.dispose();
    _thicknessController.dispose();
    _piecesController.dispose();
    _totalSqFtController.dispose();
    _costPriceController.dispose();
    _sellingRateController.dispose();
    _rackController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Auto-calculate Total SqFt = Length * Height * Pieces
  void _calculateSqFt() {
    final l = double.tryParse(_lengthController.text) ?? 0.0;
    final h = double.tryParse(_heightController.text) ?? 0.0;
    final p = int.tryParse(_piecesController.text) ?? 1;

    if (_category != 'blocks') {
      final total = (l * h * p);
      _totalSqFtController.text = total.toStringAsFixed(1);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (file != null) {
        setState(() {
          _imagePath = file.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  Future<void> _saveStock() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final item = StockItem(
        id: widget.existingItem?.id,
        category: _category,
        marbleName: _nameController.text.trim(),
        bundleOrBlockNo: _bundleNoController.text.trim(),
        lengthFeet: double.tryParse(_lengthController.text) ?? 0.0,
        heightOrWidthFeet: double.tryParse(_heightController.text) ?? 0.0,
        thicknessMm: int.tryParse(_thicknessController.text) ?? 18,
        piecesCount: int.tryParse(_piecesController.text) ?? 0,
        totalSqFt: double.tryParse(_totalSqFtController.text) ?? 0.0,
        qualityGrade: _qualityGrade,
        surfaceFinish: _surfaceFinish,
        rackLocation: _rackController.text.trim(),
        costPrice: double.tryParse(_costPriceController.text) ?? 0.0,
        sellingRate: double.tryParse(_sellingRateController.text) ?? 0.0,
        imagePath: _imagePath,
        notes: _notesController.text.trim(),
        syncStatus: 0,
      );

      if (widget.existingItem != null) {
        await DatabaseHelper.instance.updateStock(item);
      } else {
        await DatabaseHelper.instance.insertStock(item);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingItem != null ? 'Stock updated successfully!' : 'New stock added!'),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving stock: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingItem != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Stock Item' : 'Add New Stone Stock',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Stock Item?'),
                    content: const Text('Are you sure you want to remove this stone from yard stock?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await DatabaseHelper.instance.deleteStock(widget.existingItem!.id!);
                  if (mounted) Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Attachment Section (Camera + Gallery)
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => _showPhotoPickerSheet(),
                      child: Container(
                        width: double.infinity,
                        height: 180,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: _imagePath != null && File(_imagePath!).existsSync()
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.file(File(_imagePath!), fit: BoxFit.cover),
                                    Positioned(
                                      top: 10,
                                      right: 10,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.edit, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.add_a_photo_outlined, size: 40, color: Color(0xFFF59E0B)),
                                  SizedBox(height: 8),
                                  Text(
                                    'Take Stone Photo (Camera / Gallery)',
                                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Attach photo to show customers veining & polish',
                                    style: TextStyle(color: Colors.grey, fontSize: 10),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Category Selector
              Text('STOCK CATEGORY', style: _labelStyle()),
              const SizedBox(height: 6),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'slabs', label: Text('Slabs (تھان)')),
                  ButtonSegment(value: 'tiles', label: Text('Tiles (سائز)')),
                  ButtonSegment(value: 'blocks', label: Text('Blocks (بلاک)')),
                ],
                selected: {_category},
                onSelectionChanged: (set) {
                  setState(() {
                    _category = set.first;
                    _calculateSqFt();
                  });
                },
              ),

              const SizedBox(height: 16),

              // Marble Variety & Bundle #
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      controller: _nameController,
                      label: 'Marble Name / Variety *',
                      hint: 'e.g. Ziarat White',
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _bundleNoController,
                      label: _category == 'blocks' ? 'Block No *' : 'Bundle No *',
                      hint: 'BND-101',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Quality Grade & Finish
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('QUALITY GRADE', style: _labelStyle()),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          value: _qualityGrade,
                          decoration: _inputDecoration(),
                          items: const [
                            DropdownMenuItem(value: 'Super', child: Text('Super (سپر)')),
                            DropdownMenuItem(value: 'Grade A', child: Text('Grade A')),
                            DropdownMenuItem(value: 'Grade B', child: Text('Grade B')),
                            DropdownMenuItem(value: 'Commercial', child: Text('Commercial')),
                          ],
                          onChanged: (val) => setState(() => _qualityGrade = val ?? 'Grade A'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _rackController,
                      label: 'Location / Rack',
                      hint: 'Shed 1 - Bay B',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Dimensions: Length x Height x Thickness
              Text('DIMENSIONS & PIECES COUNT', style: _labelStyle()),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _lengthController,
                      label: 'Length (Ft)',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => _calculateSqFt(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      controller: _heightController,
                      label: _category == 'blocks' ? 'Width (Ft)' : 'Height (Ft)',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => _calculateSqFt(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      controller: _piecesController,
                      label: 'Pieces',
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _calculateSqFt(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      controller: _thicknessController,
                      label: 'Thickness (mm)',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Total Sq. Ft. & Rates
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _totalSqFtController,
                      label: _category == 'blocks' ? 'Total Tons' : 'Total Sq. Ft. *',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      isHighlighted: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _sellingRateController,
                      label: 'Selling Rate (PKR) *',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      isHighlighted: true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _costPriceController,
                      label: 'Cost / Purchase Rate',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _notesController,
                      label: 'Special Notes / Crack Status',
                      hint: 'Sound condition',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveStock,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    _isSaving ? 'Saving...' : (isEdit ? 'Update Stock Item' : 'Add to Factory Stock'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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

  void _showPhotoPickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Attach Marble Stone Photo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF0F172A)),
                title: const Text('Take Photo from Camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF0F172A)),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _labelStyle() {
    return TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.bold,
      color: Colors.grey.shade600,
      letterSpacing: 0.5,
    );
  }

  InputDecoration _inputDecoration({String? hint, bool isHighlighted = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
      filled: true,
      fillColor: isHighlighted ? const Color(0xFFEFF6FF) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isHighlighted ? Colors.blue.shade300 : Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    bool isHighlighted = false,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: _labelStyle()),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            color: isHighlighted ? const Color(0xFF1D4ED8) : const Color(0xFF0F172A),
          ),
          decoration: _inputDecoration(hint: hint, isHighlighted: isHighlighted),
          validator: validator,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
