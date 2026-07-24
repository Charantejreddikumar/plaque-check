import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _obscurePassword = true;
  bool _rememberSession = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false) || _isLoading) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await _authService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
      await SessionManager.saveSession(user);
      if (!mounted) {
        return;
      }
      Navigator.pushReplacementNamed(context, '/dashboard');
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(_authSnackBar(error.message));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(_authSnackBar('Unable to login. Please try again.'));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AuthLogo(),
          const SizedBox(height: 28),
          Text(
            'Welcome to PlaqueCheck',
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to continue your dental AI tracking.',
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          GlassCard(
            borderRadius: 32,
            opacity: 0.14,
            borderOpacity: 0.22,
            glowColor: const Color(0xFF0EA5E9),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                    decoration: _inputDecoration('Email', Icons.email_outlined),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    validator: _validateRequiredPassword,
                    decoration: _inputDecoration(
                      'Password',
                      Icons.lock_outline,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: const Color(0xFF38BDF8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberSession,
                        activeColor: const Color(0xFF3B82F6),
                        onChanged: (value) {
                          setState(() => _rememberSession = value ?? false);
                        },
                      ),
                      Expanded(
                        child: Text(
                          'Remember session',
                          style: TextStyle(
                            color: AppTheme.textSecondary(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _AuthTextButton(
                        text: 'Forgot password?',
                        onTap: () =>
                            Navigator.pushNamed(context, '/forgot-password'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  GlassButton(
                    label: _isLoading ? 'Logging in...' : 'Login',
                    icon: Icons.login,
                    isPrimary: true,
                    onPressed: _isLoading ? () {} : _login,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'New user? ',
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _AuthTextButton(
                  text: 'Create account',
                  onTap: () => Navigator.pushNamed(context, '/register'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AppTheme.pageDecoration(context),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthLogo extends StatelessWidget {
  const _AuthLogo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 74,
        height: 74,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0EA5E9), Color(0xFF3B82F6)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0EA5E9).withValues(alpha: 0.18),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: const Icon(
          Icons.medical_information_outlined,
          color: Colors.white,
          size: 34,
        ),
      ),
    );
  }
}

class _AuthTextButton extends StatelessWidget {
  const _AuthTextButton({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF38BDF8),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(
  String label,
  IconData icon, {
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: const Color(0xFF0EA5E9)),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.1),
    errorMaxLines: 2,
    errorStyle: const TextStyle(
      color: Color(0xFFFCA5A5),
      fontWeight: FontWeight.w600,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFFCA5A5), width: 1.2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFFCA5A5), width: 1.4),
    ),
  );
}

String? _validateEmail(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return 'Email is required.';
  }
  final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (!emailPattern.hasMatch(text)) {
    return 'Enter a valid email address.';
  }
  return null;
}

String? _validateRequiredPassword(String? value) {
  if ((value ?? '').isEmpty) {
    return 'Password is required.';
  }
  return null;
}

SnackBar _authSnackBar(String message) {
  return SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: const Color(0xFF3B82F6),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    content: Text(message),
  );
}
