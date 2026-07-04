import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'menu_providers.dart';
import '../domain/models/menu_item.dart';
import '../../../core/theme/app_theme.dart';

/// Handles both "add" and "edit" flows for a single menu item. When
/// [initialItem] is supplied (via GoRouter's `extra`) the form is
/// pre-filled and saving calls `updateMenuItem` instead of `addMenuItem` —
/// same repository, same business logic, only the presentation adapts.
class AddMenuScreen extends ConsumerStatefulWidget {
  final MenuItem? initialItem;

  const AddMenuScreen({super.key, this.initialItem});

  @override
  ConsumerState<AddMenuScreen> createState() => _AddMenuScreenState();
}

class _AddMenuScreenState extends ConsumerState<AddMenuScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;
  late final TextEditingController _imageUrlController;
  late bool _isPopular;
  late bool _isAvailable;

  bool _isSaving = false;

  bool get _isEditing => widget.initialItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    _nameController = TextEditingController(text: item?.name ?? '');
    _priceController = TextEditingController(
      text: item != null ? _trimZeros(item.price) : '',
    );
    _descriptionController = TextEditingController(text: item?.description ?? '');
    _categoryController = TextEditingController(text: item?.category ?? '');
    _imageUrlController = TextEditingController(text: item?.imageUrl ?? '');
    _isPopular = item?.isPopular ?? false;
    _isAvailable = item?.isAvailable ?? true;
  }

  String _trimZeros(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final category = _categoryController.text.trim();
    final imageUrl = _imageUrlController.text.trim();

    final menu = MenuItem(
      id: widget.initialItem?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? 'No description provided.'
          : _descriptionController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      category: category.isEmpty ? 'Mains' : category,
      imageUrl: imageUrl.isEmpty ? 'https://via.placeholder.com/400' : imageUrl,
      isPopular: _isPopular,
      isAvailable: _isAvailable,
    );

    try {
      final repository = ref.read(menuRepositoryProvider);
      if (_isEditing) {
        await repository.updateMenuItem(menu);
      } else {
        await repository.addMenuItem(menu);
      }
      ref.invalidate(menuListProvider);

      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save menu item: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColorLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(_isEditing ? 'Edit Menu Item' : 'Add Menu Item'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isSaving ? null : () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            _PreviewImage(url: _imageUrlController.text),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Dish name',
                hintText: 'e.g. Truffle Tagliolini',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Dish name is required';
                }
                if (value.trim().length < 3) {
                  return 'Name must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Short description shown on the menu',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      hintText: '25000',
                      prefixText: 'Rp ',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Price is required';
                      }
                      final parsed = double.tryParse(value.trim());
                      if (parsed == null) return 'Enter a valid number';
                      if (parsed <= 0) return 'Must be greater than 0';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _categoryController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      hintText: 'Mains',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'Image URL',
                hintText: 'https://...',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mark as popular', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Shows a "Popular" badge on the menu'),
              value: _isPopular,
              activeColor: AppTheme.primaryColor,
              onChanged: (v) => setState(() => _isPopular = v),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Available for order', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Turn off to hide this item from cashiers and waiters'),
              value: _isAvailable,
              activeColor: AppTheme.primaryColor,
              onChanged: (v) => setState(() => _isAvailable = v),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                child: _isSaving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEditing ? 'SAVE CHANGES' : 'SAVE MENU ITEM',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewImage extends StatelessWidget {
  final String url;

  const _PreviewImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.grey.shade100,
          child: url.trim().startsWith('http')
              ? Image.network(
                  url.trim(),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const _ImagePlaceholder(),
                )
              : const _ImagePlaceholder(),
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.image_outlined, size: 40, color: Colors.grey),
    );
  }
}
