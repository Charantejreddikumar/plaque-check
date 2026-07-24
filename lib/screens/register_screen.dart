import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_card.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!(_formKey.currentState?.validate() ?? false) || _isLoading) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(_authSnackBar('Account created'));
      Navigator.pop(context);
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(_authSnackBar(error.message));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        _authSnackBar('Unable to create account. Please try again.'),
      );
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
          _BackButton(onTap: () => Navigator.pop(context)),
          const SizedBox(height: 18),
          Text(
            'Create Account',
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set up a secure PlaqueCheck profile for AI oral health tracking.',
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.35,
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
                    controller: _nameController,
                    validator: _validateRequiredName,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDecoration(
                      'Full Name',
                      Icons.badge_outlined,
                    ),
                  ),
                  const SizedBox(height: 16),
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
                    validator: _validatePassword,
                    decoration: _inputDecoration(
                      'Password',
                      Icons.lock_outline,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
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
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    validator: _validateConfirmPassword,
                    decoration: _inputDecoration(
                      'Confirm Password',
                      Icons.lock_reset_outlined,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: const Color(0xFF38BDF8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  GlassButton(
                    label: _isLoading ? 'Creating...' : 'Create Account',
                    icon: Icons.person_add_alt_1,
                    isPrimary: true,
                    onPressed: _isLoading ? () {} : _createAccount,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _validateConfirmPassword(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Confirm your password.';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match.';
    }
    return null;
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

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: const Icon(Icons.arrow_back, color: Color(0xFF0EA5E9)),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.12),
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

SnackBar _authSnackBar(String message) {
  return SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: const Color(0xFF3B82F6),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    content: Text(message),
  );
}

String? _validateRequiredName(String? value) {
  if ((value?.trim() ?? '').isEmpty) {
    return 'Full name is required.';
  }
  return null;
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

String? _validatePassword(String? value) {
  final password = value ?? '';
  if (password.isEmpty) {
    return 'Password is required.';
  }
  if (password.length < 6) {
    return 'Password must be at least 6 characters.';
  }
  return null;
}
