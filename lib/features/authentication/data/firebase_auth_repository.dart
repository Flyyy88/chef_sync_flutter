import 'package:firebase_auth/firebase_auth.dart';
import '../domain/models/user_model.dart';
import '../domain/repositories/auth_repository.dart';

// 1. UBAH KE HURUF BESAR "F"
class FirebaseAuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth;

  FirebaseAuthRepositoryImpl(this._auth);

  // 2. TAMBAHKAN KEMBALI authStateChanges YANG SEMPAT HILANG
  @override
  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().map((firebaseUser) {
      if (firebaseUser == null) return null;
      return UserModel(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? firebaseUser.email!.split('@').first,
        email: firebaseUser.email!,
        role: UserRole.waiter, // Pastikan ini sesuai dengan enum di UserModel
        isActive: true,
      );
    });
  }

  @override
  Future<UserModel> login(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user!;

    // sementara role default
    return UserModel(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? firebaseUser.email!.split('@').first,
      email: firebaseUser.email!,
      role: UserRole.waiter,
      isActive: true,
    );
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;

    if (firebaseUser == null) return null;

    return UserModel(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? firebaseUser.email!.split('@').first,
      email: firebaseUser.email!,
      role: UserRole.waiter,
      isActive: true,
    );
  }
}
