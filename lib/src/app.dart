import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'theme.dart';
import 'widgets/login_screen.dart';
import 'widgets/home_shell.dart';

class F2PGamerApp extends StatelessWidget {
  const F2PGamerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'F2PGamer - The Free-to-Play Tracker',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      // The Firebase auth stream is the single source of truth for which
      // screen to show. Signing in/out anywhere rebuilds this automatically.
      home: StreamBuilder<User?>(
        stream: AuthService.instance.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _SplashScreen();
          }
          if (snapshot.hasData) {
            return const HomeShell(); //logged in
          }
          return const LoginScreen(); //logged out
        },
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(color: AppTheme.accentCyan),
            SizedBox(height: 16),
            Text(
              'Initializing F2PGamer...',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
