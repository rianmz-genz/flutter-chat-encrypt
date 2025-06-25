// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  // --- MULAI PERUBAHAN SINGLETON ---
  static final AuthService _instance = AuthService._internal(); // Private constructor
  factory AuthService() {
    return _instance; // Return the single instance
  }
  AuthService._internal(); // Actual private constructor
  // --- AKHIR PERUBAHAN SINGLETON ---

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ... (Sisa kode AuthService Anda tetap sama) ...

  // Mendapatkan ID pengguna saat ini
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // Mendapatkan objek pengguna saat ini
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Login dengan email dan password
  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('Error during sign in: ${e.message}');
      rethrow;
    }
  }

  // Registrasi dengan email dan password
  Future<User?> registerWithEmailAndPassword(
      String email, String password, String username) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;

      if (user != null) {
        // Simpan data pengguna di Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'username': username,
          'createdAt': Timestamp.now(),
        });
      }
      return user;
    } on FirebaseAuthException catch (e) {
      print('Error during registration: ${e.message}');
      rethrow;
    }
  }

  // Logout
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error during sign out: $e');
      rethrow;
    }
  }
}