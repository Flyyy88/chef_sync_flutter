import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/user_model.dart';

// ============================================================
// AuthRepository — abstract contract
// Implementasi bisa swap antara Firebase dan Mock
// ============================================================
abstract class AuthRepository {
  /// Login dengan email + password.
  /// Melempar [AuthException] jika credentials salah atau user tidak aktif.
  Future<UserModel> login(String email, String password);

  /// Logout dari Firebase Auth.
  Future<void> logout();

  /// Ambil user yang sedang login (null kalau belum login).
  Future<UserModel?> getCurrentUser();

  /// Stream perubahan auth state — dipakai GoRouter untuk redirect reaktif.
  Stream<UserModel?> get authStateChanges;
}

// ============================================================
// Custom exception agar UI bisa bedakan jenis error
// ============================================================
class AuthException implements Exception {
  final String message;
  final AuthErrorCode code;

  const AuthException(this.message, {this.code = AuthErrorCode.unknown});

  @override
  String toString() => message;
}

enum AuthErrorCode {
  invalidCredential,
  userDisabled,
  accountInactive, // isActive == false di Firestore
  userNotFound, // login berhasil tapi dokumen Firestore tidak ada
  networkError,
  unknown,
}

// ============================================================
// FirebaseAuthRepositoryImpl — implementasi produksi
//
// Alur login:
//   1. signInWithEmailAndPassword  → Firebase Auth
//   2. Ambil dokumen /users/{uid}  → Firestore
//   3. Validasi isActive
//   4. Return UserModel lengkap dengan role
//
// Alur authStateChanges:
//   - Listen Firebase Auth stream
//   - Setiap perubahan UID → ambil dokumen Firestore
//   - Emit UserModel (atau null kalau logout)
// ============================================================
class FirebaseAuthRepositoryImpl implements AuthRepository {
  FirebaseAuthRepositoryImpl({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const _usersCollection = 'users';

  // ----------------------------------------------------------
  // LOGIN
  // ----------------------------------------------------------
  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;
      return await _fetchAndValidateUser(uid);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(
        'Terjadi kesalahan saat login. Coba lagi.',
        code: AuthErrorCode.unknown,
      );
    }
  }

  // ----------------------------------------------------------
  // LOGOUT
  // ----------------------------------------------------------
  @override
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      // Logout jarang gagal, tapi jangan biarkan exception tak tertangani
      throw AuthException(
        'Gagal logout. Coba lagi.',
        code: AuthErrorCode.unknown,
      );
    }
  }

  // ----------------------------------------------------------
  // GET CURRENT USER
  // Dipanggil saat app restart untuk restore session
  // ----------------------------------------------------------
  @override
  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    try {
      return await _fetchAndValidateUser(firebaseUser.uid);
    } on AuthException {
      // Kalau user tidak aktif atau dokumen tidak ada, paksa logout
      await _auth.signOut();
      return null;
    }
  }

  // ----------------------------------------------------------
  // AUTH STATE STREAM
  // GoRouter listen stream ini untuk redirect reaktif
  // ----------------------------------------------------------
  @override
  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      try {
        return await _fetchAndValidateUser(firebaseUser.uid);
      } on AuthException {
        // Jika user tidak valid/tidak aktif, emit null agar router redirect ke login
        await _auth.signOut();
        return null;
      }
    });
  }

  // ----------------------------------------------------------
  // PRIVATE: Ambil dokumen Firestore + validasi
  // ----------------------------------------------------------
  Future<UserModel> _fetchAndValidateUser(String uid) async {
    final doc = await _firestore.collection(_usersCollection).doc(uid).get();

    if (!doc.exists || doc.data() == null) {
      // Akun ada di Firebase Auth tapi belum ada di Firestore.
      // Bisa terjadi kalau Cloud Function gagal, atau akun dibuat manual.
      throw const AuthException(
        'Akun belum terdaftar di sistem. Hubungi administrator.',
        code: AuthErrorCode.userNotFound,
      );
    }

    final data = doc.data()!;
    final isActive = data['isActive'] as bool? ?? false;

    if (!isActive) {
      throw const AuthException(
        'Akun Anda telah dinonaktifkan. Hubungi administrator.',
        code: AuthErrorCode.accountInactive,
      );
    }

    return UserModel.fromJson(data);
  }

  // ----------------------------------------------------------
  // PRIVATE: Map FirebaseAuthException ke AuthException
  // ----------------------------------------------------------
  AuthException _mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-email':
        return const AuthException(
          'Email atau password salah.',
          code: AuthErrorCode.invalidCredential,
        );
      case 'user-disabled':
        return const AuthException(
          'Akun ini telah dinonaktifkan oleh administrator.',
          code: AuthErrorCode.userDisabled,
        );
      case 'network-request-failed':
        return const AuthException(
          'Tidak ada koneksi internet. Periksa jaringan Anda.',
          code: AuthErrorCode.networkError,
        );
      case 'too-many-requests':
        return const AuthException(
          'Terlalu banyak percobaan login. Coba lagi beberapa menit lagi.',
          code: AuthErrorCode.unknown,
        );
      default:
        return AuthException(
          'Login gagal: ${e.message ?? e.code}',
          code: AuthErrorCode.unknown,
        );
    }
  }
}

// ============================================================
// MockAuthRepositoryImpl — hanya untuk unit test & dev offline
// JANGAN inject ke production app
// ============================================================
class MockAuthRepositoryImpl implements AuthRepository {
  UserModel? _currentUser;

  final _controller = StreamController<UserModel?>.broadcast();

  @override
  Stream<UserModel?> get authStateChanges => _controller.stream;

  @override
  Future<UserModel> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));

    if (password.isEmpty) {
      throw const AuthException(
        'Password tidak boleh kosong.',
        code: AuthErrorCode.invalidCredential,
      );
    }

    final roleMap = {
      'admin@sync.com': (UserRole.admin, 'u1', 'Alexander Sterling'),
      'manager@sync.com': (UserRole.manager, 'u2', 'Sophia Chen'),
      'cashier@sync.com': (UserRole.cashier, 'u3', 'Marcus Brody'),
      'kitchen@sync.com': (UserRole.kitchen, 'u4', 'Chef Gordon'),
      'waiter@sync.com': (UserRole.waiter, 'u5', 'James Carter'),
    };

    final entry = roleMap[email.toLowerCase().trim()];
    _currentUser = UserModel(
      id: entry?.$2 ?? 'u5',
      name: entry?.$3 ?? 'Staff',
      email: email,
      role: entry?.$1 ?? UserRole.waiter,
    );

    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Future<UserModel?> getCurrentUser() async => _currentUser;
}
