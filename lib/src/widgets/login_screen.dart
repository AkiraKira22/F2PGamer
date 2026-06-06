import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Validates the email/password fields. Returns null if OK, otherwise an
  /// error message.
  String? _validateForm(String email, String password) {
    if (email.isEmpty || password.isEmpty) {
      return 'System Firewall: All fields required!';
    }
    if (!email.contains('@')) {
      return 'System Firewall: Invalid email format!';
    }
    if (password.length < 6) {
      return 'System Firewall: Password must be at least 6 characters!';
    }
    return null;
  }

  Future<void> _submitEmail({required bool register}) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final validationError = _validateForm(email, password);
    if (validationError != null) {
      _showErrorSnackBar(validationError);
      return;
    }

    await _runAuth(() {
      return register
          ? AuthService.instance.registerWithEmail(email, password)
          : AuthService.instance.signInWithEmail(email, password);
    });
  }

  Future<void> _signInWithGoogle() =>
      _runAuth(() => AuthService.instance.signInWithGoogle());

  /// Shared runner: toggles the loading state, calls [action], and surfaces
  /// any [AuthException] as a snackbar. On success it does nothing — the auth
  /// stream in app.dart swaps this screen for the home screen automatically.
  Future<void> _runAuth(Future<Object?> Function() action) async {
    setState(() => _isLoading = true);
    try {
      await action();
      // Success: the StreamBuilder rebuilds to the home screen; this widget
      // will be disposed, so we don't navigate or setState here.
    } on AuthException catch (e) {
      if (!e.cancelled) _showErrorSnackBar('${e.message}');
    } catch (e) {
      _showErrorSnackBar('System Firewall: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorRed,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  OutlineInputBorder _border(double width) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: AppTheme.accentCyan, width: width),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 48),
            // Logo Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.accentCyan, width: 2),
              ),
              child: const Icon(
                Icons.games,
                color: AppTheme.accentCyan,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'F2PGAMER',
              style: TextStyle(
                color: AppTheme.accentCyan,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The Free-to-Play Tracker',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 48),
            // Form Card
            Card(
              color: AppTheme.cardBg,
              margin: const EdgeInsets.symmetric(horizontal: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.accentCyan, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Email Field
                    TextField(
                      controller: _emailController,
                      enabled: !_isLoading,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        hintText: 'user@example.com',
                        prefixIcon: const Icon(
                          Icons.email,
                          color: AppTheme.accentCyan,
                        ),
                        border: _border(0.5),
                        enabledBorder: _border(0.5),
                        focusedBorder: _border(2),
                      ),
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 16),
                    // Password Field
                    TextField(
                      controller: _passwordController,
                      enabled: !_isLoading,
                      obscureText: _obscurePassword,
                      onSubmitted: (_) =>
                          _isLoading ? null : _submitEmail(register: false),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(
                          Icons.lock,
                          color: AppTheme.accentCyan,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: AppTheme.accentCyan,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                        border: _border(0.5),
                        enabledBorder: _border(0.5),
                        focusedBorder: _border(2),
                      ),
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 24),
                    // Sign In Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () => _submitEmail(register: false),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: AppTheme.darkBg,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Create Account Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => _submitEmail(register: true),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppTheme.accentMagenta,
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'Create Account',
                          style: TextStyle(
                            color: AppTheme.accentMagenta,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Divider
                    Row(
                      children: const [
                        Expanded(child: Divider(color: AppTheme.textSecondary)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: AppTheme.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Google Sign-In Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _signInWithGoogle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1F1F1F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            'G',
                            style: TextStyle(
                              color: Color(0xFF4285F4),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        label: const Text(
                          'Sign in with Google',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'New here? Enter an email + password and tap '
                '“Create Account”, or continue with Google.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
