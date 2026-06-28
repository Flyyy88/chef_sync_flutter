import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'menu_providers.dart';
import '../domain/models/menu_item.dart';
import '../../../core/theme/app_theme.dart';

class AddMenuScreen extends ConsumerStatefulWidget {
  const AddMenuScreen({super.key});

  @override
  ConsumerState<AddMenuScreen> createState() => _AddMenuScreenState();
}

class _AddMenuScreenState extends ConsumerState<AddMenuScreen> {
  // 1. FORM VALIDATION: gunakan Form + GlobalKey untuk validasi terstruktur
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  // 2. LOADING STATE: flag lokal untuk menonaktifkan tombol & tampilkan spinner
  bool _isSaving = false;

  @override
  void dispose() {
    // FIX: controller wajib di-dispose agar tidak memory leak
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    // Validasi form sebelum hit Firebase — mencegah data kosong/invalid masuk DB
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final newMenu = MenuItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      description: 'Menu baru dari aplikasi',
      price: double.parse(_priceController.text.trim()),
      category: 'Mains',
      imageUrl: 'https://via.placeholder.com/150',
      isPopular: false,
    );

    try {
      await ref.read(menuRepositoryProvider).addMenuItem(newMenu);
      ref.invalidate(menuListProvider); // refresh dashboard & menu list

      if (!mounted) return;
      context.pop();
    } catch (e) {
      // 3. ERROR HANDLING: tampilkan ke user, bukan cuma debugPrint
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan menu: $e'),
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
        title: const Text('Tambah Menu Baru'),
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
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama Makanan',
                hintText: 'Contoh: Nasi Goreng Magelangan',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama menu wajib diisi';
                }
                if (value.trim().length < 3) {
                  return 'Nama menu minimal 3 karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Harga',
                hintText: 'Contoh: 25000',
                prefixText: 'Rp ',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Harga wajib diisi';
                }
                final parsed = double.tryParse(value.trim());
                if (parsed == null) {
                  return 'Harga harus berupa angka';
                }
                if (parsed <= 0) {
                  return 'Harga harus lebih besar dari 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
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
                    : const Text(
                        'SIMPAN MENU',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
