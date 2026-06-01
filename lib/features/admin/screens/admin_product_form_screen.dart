import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/category.dart' as models;
import '../../../data/models/product.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/admin_providers.dart';

class AdminProductFormScreen extends ConsumerStatefulWidget {
  final Product? product;
  const AdminProductFormScreen({super.key, this.product});

  @override
  ConsumerState<AdminProductFormScreen> createState() =>
      _AdminProductFormScreenState();
}

class _AdminProductFormScreenState
    extends ConsumerState<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _skuCtrl;
  late final TextEditingController _nameFrCtrl;
  late final TextEditingController _nameArCtrl;
  late final TextEditingController _descFrCtrl;
  late final TextEditingController _descArCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _imageUrlCtrl;

  String? _selectedCategoryId;
  bool _isFeatured = false;
  List<String> _existingImages = [];
  final List<String> _removedImages = [];
  final List<File> _newImageFiles = [];
  final List<String> _urlAddedImages = [];

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _skuCtrl = TextEditingController(text: p?.sku ?? '');
    _nameFrCtrl = TextEditingController(text: p?.nameFr ?? '');
    _nameArCtrl = TextEditingController(text: p?.nameAr ?? '');
    _descFrCtrl = TextEditingController(text: p?.descriptionFr ?? '');
    _descArCtrl = TextEditingController(text: p?.descriptionAr ?? '');
    _priceCtrl =
        TextEditingController(text: p?.basePrice.toStringAsFixed(2) ?? '');
    _stockCtrl = TextEditingController(text: (p?.stock ?? 0).toString());
    _imageUrlCtrl = TextEditingController();
    _selectedCategoryId = p?.categoryId;
    _isFeatured = p?.isFeatured ?? false;
    _existingImages = List.from(p?.images ?? []);
  }

  @override
  void dispose() {
    _skuCtrl.dispose();
    _nameFrCtrl.dispose();
    _nameArCtrl.dispose();
    _descFrCtrl.dispose();
    _descArCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(adminCategoriesProvider);
    final formState = ref.watch(productFormProvider);

    ref.listen<ProductFormState>(productFormProvider, (prev, next) {
      if (next.isSuccess && !(prev?.isSuccess ?? false)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(_isEditing ? l10n.product_saved : l10n.product_created)),
        );
        Navigator.pop(context, true);
      }
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${l10n.error_occurred}: ${next.error}'),
              backgroundColor: Colors.red),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.edit_product : l10n.add_new_product),
        backgroundColor: AppColors.deepBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(l10n.product_name),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                      child: _field(_nameFrCtrl, '(FR)',
                          hint: 'Nom du produit', required: true)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _field(_nameArCtrl, '(AR)',
                          hint: 'اسم المنتج', required: true)),
                ],
              ),
              const SizedBox(height: 20),
              _sectionTitle(l10n.description),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                      child: _field(_descFrCtrl, '(FR)',
                          hint: 'Description en français', maxLines: 3)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _field(_descArCtrl, '(AR)',
                          hint: 'الوصف بالعربية', maxLines: 3)),
                ],
              ),
              const SizedBox(height: 20),
              _sectionTitle(l10n.sku),
              const SizedBox(height: 8),
              _field(_skuCtrl, '', hint: 'MED-XXXX-001', required: true),
              const SizedBox(height: 20),
              categoriesAsync.when(
                data: (catList) {
                  final catItems =
                      catList.whereType<models.Category>().toList();
                  final topLevel = catItems
                      .where((models.Category c) => c.parentId == null)
                      .toList();
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedCategoryId,
                    decoration: InputDecoration(
                      labelText: l10n.category,
                      border: const OutlineInputBorder(),
                    ),
                    items: topLevel
                        .map((models.Category c) => DropdownMenuItem(
                            value: c.id, child: Text(c.nameFr)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCategoryId = v),
                    validator: (v) => v == null ? l10n.field_required : null,
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => Text(l10n.error_occurred),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                      child: _field(_priceCtrl, l10n.price,
                          hint: '0.00',
                          required: true,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return '${l10n.price} is required';
                            }
                            if (double.tryParse(v.trim()) == null) {
                              return 'Invalid number';
                            }
                            return null;
                          })),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _field(_stockCtrl, l10n.stock,
                          hint: '0',
                          required: true,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return '${l10n.stock} is required';
                            }
                            if (int.tryParse(v.trim()) == null) {
                              return 'Invalid integer';
                            }
                            return null;
                          })),
                ],
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                value: _isFeatured,
                onChanged: (v) => setState(() => _isFeatured = v),
                title: Text(l10n.featured),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 20),
              _sectionTitle(l10n.upload_images),
              const SizedBox(height: 8),
              _buildImageSection(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: formState.isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldenYellow,
                    foregroundColor: AppColors.deepBlue,
                  ),
                  child: formState.isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(
                          _isEditing ? l10n.save_changes : l10n.add_new_product,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text,
        style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800]));
  }

  Widget _field(TextEditingController ctrl, String label,
      {String? hint,
      bool required = false,
      int maxLines = 1,
      TextInputType? keyboardType,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator ??
          (required
              ? (v) =>
                  (v == null || v.trim().isEmpty) ? '$label is required' : null
              : null),
    );
  }

  Widget _buildImageSection() {
    final allImages = [..._existingImages, ..._urlAddedImages];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (allImages.isNotEmpty)
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: allImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final url = allImages[index];
                final isExisting = index < _existingImages.length;
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(url,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[200],
                              child:
                                  Icon(Icons.image, color: Colors.grey[400]))),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isExisting) {
                              _removedImages.add(url);
                              _existingImages.remove(url);
                            } else {
                              _urlAddedImages.remove(url);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                              color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        if (_newImageFiles.isNotEmpty)
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _newImageFiles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_newImageFiles[index],
                          width: 80, height: 80, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _newImageFiles.removeAt(index)),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                              color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.photo_library),
              label: Text(l10n.upload_images),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepBlue,
                  foregroundColor: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _imageUrlCtrl,
                decoration: InputDecoration(
                  hintText: l10n.image_url,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addImageUrl,
                  ),
                ),
                onFieldSubmitted: (_) => _addImageUrl(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() {
        _newImageFiles.addAll(picked.map((x) => File(x.path)));
      });
    }
  }

  void _addImageUrl() {
    final url = _imageUrlCtrl.text.trim();
    if (url.isNotEmpty) {
      setState(() {
        _urlAddedImages.add(url);
        _imageUrlCtrl.clear();
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'sku': _skuCtrl.text.trim(),
      'name_fr': _nameFrCtrl.text.trim(),
      'name_ar': _nameArCtrl.text.trim(),
      'description_fr':
          _descFrCtrl.text.trim().isNotEmpty ? _descFrCtrl.text.trim() : null,
      'description_ar':
          _descArCtrl.text.trim().isNotEmpty ? _descArCtrl.text.trim() : null,
      'category_id': _selectedCategoryId,
      'base_price': double.tryParse(_priceCtrl.text.trim()) ?? 0.0,
      'stock_quantity': int.tryParse(_stockCtrl.text.trim()) ?? 0,
      'is_featured': _isFeatured,
    };

    final notifier = ref.read(productFormProvider.notifier);

    if (_isEditing) {
      await notifier.updateProduct(
        id: widget.product!.id,
        updates: data,
        newImages: _newImageFiles.isNotEmpty ? _newImageFiles : null,
        removedImageUrls: _removedImages.isNotEmpty ? _removedImages : null,
        addedImageUrls: _urlAddedImages.isNotEmpty ? _urlAddedImages : null,
      );
    } else {
      await notifier.createProduct(
          data: data,
          imageFiles: _newImageFiles.isNotEmpty ? _newImageFiles : null,
          imageUrlList: _urlAddedImages.isNotEmpty ? _urlAddedImages : null);
    }
  }
}
