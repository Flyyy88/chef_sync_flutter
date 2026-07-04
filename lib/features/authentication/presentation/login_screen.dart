import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/auth_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';

/// Login — the only screen every user, of every role, sees before anything
/// else. On tablet/desktop it splits into a brand panel + form panel (the
/// pattern Stripe, Linear and most B2B SaaS use for their sign-in) so the
/// product feels intentional from the first pixel instead of opening on a
/// dark card floating in space. On mobile the brand panel collapses into a
/// compact header above the form so the form still gets full width.
///
/// NOTE: `_login()` below is byte-for-byte the same auth call as before —
/// same controllers, same provider, same error handling, same "let the
/// router redirect on stream change" comment. Only the surrounding UI
/// changed.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
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
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final showBrandPanel = width >= 900;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          if (showBrandPanel) const Expanded(flex: 5, child: _BrandPanel()),
          Expanded(
            flex: 4,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!showBrandPanel) const _CompactBrandHeader(),
                        if (!showBrandPanel) const SizedBox(height: 36),
                        Text(
                          'Welcome back',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sign in to run today\'s service.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 32),
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel('Email'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  hintText: 'you@restaurant.com',
                                  prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Enter your email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),
                              _FieldLabel('Password'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _login(),
                                decoration: InputDecoration(
                                  hintText: '••••••••',
                                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 20,
                                      color: AppTheme.textTertiary,
                                    ),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Enter your password';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 28),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _login,
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.4,
                                          ),
                                        )
                                      : const Text('Sign in'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shield_outlined, size: 14, color: AppTheme.textTertiary),
                            const SizedBox(width: 6),
                            Text(
                              'Protected by role-based access control',
                              style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
    );
  }
}

/// Small header used only when the wide brand panel is hidden (mobile).
class _CompactBrandHeader extends StatelessWidget {
  const _CompactBrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: AppRadius.mdRadius,
          ),
          alignment: Alignment.center,
          child: const Text('CS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 12),
        const Text(
          'ChefSync',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.secondaryColor),
        ),
      ],
    );
  }
}

/// Wide-screen brand panel: dark, editorial, tells the product story
/// (kitchen -> counter -> dining room) instead of showing a stock photo.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.inkGradient),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(56, 56, 56, 56),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: AppRadius.mdRadius,
                  ),
                  alignment: Alignment.center,
                  child: const Text('CS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 12),
                const Text(
                  'ChefSync',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ],
            ),
            const Spacer(),
            const Text(
              'One system for\nthe whole floor.',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.15,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Orders, tables, kitchen tickets and inventory in sync — '
              'from the host stand to the pass.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            const Row(
              children: [
                _BrandStat(value: 'Live', label: 'Order sync'),
                SizedBox(width: 32),
                _BrandStat(value: 'Role', label: 'Based access'),
                SizedBox(width: 32),
                _BrandStat(value: '24/7', label: 'Kitchen ready'),
              ],
            ),
            const Spacer(),
            Text(
              '© ${DateTime.now().year} ChefSync Enterprise',
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4)),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandStat extends StatelessWidget {
  final String value;
  final String label;
  const _BrandStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.55))),
      ],
    );
  }
}
