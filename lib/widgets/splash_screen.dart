import 'package:flutter/material.dart';
import 'package:flutterchatencrypt/screens/auth_screen.dart';
import 'package:flutterchatencrypt/screens/groups_screen.dart';
import 'package:flutterchatencrypt/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();

    // Delay 0.5 detik agar tidak terlalu cepat langsung pindah
    Future.delayed(Duration(milliseconds: 500), () {
      _authService.authStateChanges.first.then((user) {
        if (user != null) {
          print('Redirect ke GroupsScreen karena sudah login: ${user.email}');
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const GroupsScreen()));
        } else {
          print('Redirect ke AuthScreen karena belum login.');
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AuthScreen()));
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
