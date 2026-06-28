import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'features/authentication/presentation/auth_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: ChefSyncApp(),
    ),
  );
}

class ChefSyncApp extends ConsumerWidget {
  const ChefSyncApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pastikan currentUserPrvdr sudah di-watch sejak awal
    // agar stream aktif sebelum GoRouter pertama kali evaluate redirect
    ref.watch(currentUserPrvdr);

    final router = ref.watch(appRouterPrvdr);

    return MaterialApp.router(
      title: 'ChefSync Enterprise',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
