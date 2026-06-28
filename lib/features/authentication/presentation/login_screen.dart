import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/auth_providers.dart';
// Tambahkan ini

class LoginScreen extends ConsumerStatefulWidget {
  // 1. Ubah ke ConsumerStatefulWidget
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // 2. Tambahkan Controller untuk mengambil teks input
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      await ref.read(authNotifierPrvdr.notifier).login(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );

      // TIDAK perlu context.go() di sini.
      // currentUserPrvdr (stream) akan otomatis update setelah login berhasil,
      // dan refreshListenable di app_router.dart akan memicu redirect
      // ke halaman sesuai role secara otomatis.
      // Kalau dipaksa pindah manual di sini, redirect bisa "menolak" navigasi
      // karena currentUserPrvdr belum sempat ter-update (race condition),
      // efeknya terlihat seperti "klik login tapi tidak masuk".
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("ChefSync Enterprise",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController, // 3. Pasang controller
                decoration: _inputDecoration("Email"),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController, // 3. Pasang controller
                obscureText: true,
                decoration: _inputDecoration("Password"),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      _isLoading ? null : _login, // 4. Panggil fungsi login
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text("LOGIN",
                          style: TextStyle(color: Colors.black)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper untuk kerapihan kode
  InputDecoration _inputDecoration(String hint) => InputDecoration(
        filled: true,
        fillColor: const Color(0xFF0F172A),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      );
}
