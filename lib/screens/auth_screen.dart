// lib/screens/auth_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutterchatencrypt/screens/groups_screen.dart';
import 'package:flutterchatencrypt/services/auth_service.dart';
import 'package:flutterchatencrypt/widgets/custom_text_field.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLogin = true;
  bool _isLoading = false;

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _authenticate() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        User? user = await _authService.signInWithEmailAndPassword(
          _emailController.text,
          _passwordController.text,
        );
        await user?.reload();
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const GroupsScreen()));
      } else {
        if (_usernameController.text.isEmpty) {
          _showErrorSnackBar('Nama pengguna tidak boleh kosong.');
          setState(() {
            _isLoading = false;
          });
          return;
        }
        await _authService.registerWithEmailAndPassword(
          _emailController.text,
          _passwordController.text,
          _usernameController.text,
        );
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const GroupsScreen()));
      }
    } catch (e) {
      String errorMessage = 'Terjadi kesalahan. Silakan coba lagi.';
      if (e.toString().contains('incorrect')) {
        errorMessage = 'Pengguna tidak ditemukan.';
      } else if (e.toString().contains('wrong-password')) {
        errorMessage = 'Password salah.';
      } else if (e.toString().contains('email-already-in-use')) {
        errorMessage = 'Email sudah terdaftar.';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'Format email tidak valid.';
      } else if (e.toString().contains('weak-password')) {
        errorMessage = 'Password terlalu lemah (minimal 6 karakter).';
      }
      _showErrorSnackBar(errorMessage);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login' : 'Daftar'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    _isLogin ? 'Selamat Datang Kembali!' : 'Buat Akun Baru',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  CustomTextField(
                    controller: _emailController,
                    labelText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon:
                        const Icon(Icons.email, color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: _passwordController,
                    labelText: 'Password',
                    obscureText: true,
                    prefixIcon:
                        const Icon(Icons.lock, color: Colors.blueAccent),
                  ),
                  if (!_isLogin) ...[
                    const SizedBox(height: 15),
                    CustomTextField(
                      controller: _usernameController,
                      labelText: 'Nama Pengguna',
                      prefixIcon:
                          const Icon(Icons.person, color: Colors.blueAccent),
                    ),
                  ],
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _authenticate,
                      child: Text(_isLogin ? 'Login' : 'Daftar',
                          style: const TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                        _emailController.clear();
                        _passwordController.clear();
                        _usernameController.clear();
                      });
                    },
                    child: Text(
                      _isLogin
                          ? 'Belum punya akun? Daftar Sekarang'
                          : 'Sudah punya akun? Login',
                      style: TextStyle(color: Colors.blueGrey[700]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
