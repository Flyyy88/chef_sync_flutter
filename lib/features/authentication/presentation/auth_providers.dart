import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/user_model.dart';
import '../domain/repositories/auth_repository.dart';

// ============================================================
// Repository provider
// FirebaseAuthRepositoryImpl sudah punya default value internal
// (FirebaseAuth.instance & FirebaseFirestore.instance), jadi tidak
// perlu dikirim manual.
// ============================================================
final authRepositoryPrvdr = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepositoryImpl();
});

// ============================================================
// currentUserPrvdr — stream reaktif status auth
// ============================================================
final currentUserPrvdr = StreamProvider<UserModel?>((ref) {
  return ref.watch(authRepositoryPrvdr).authStateChanges;
});

// ============================================================
// AuthNotifier — action: login dan logout
// ============================================================
class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  AuthNotifier(this._repository) : super(const AsyncValue.data(null));

  final AuthRepository _repository;

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.login(email, password),
    );
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      await _repository.logout();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final authNotifierPrvdr =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier(ref.watch(authRepositoryPrvdr));
});
