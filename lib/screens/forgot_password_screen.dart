import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_card.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _resetSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendReset() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _resetSent = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(_authSnackBar('Demo reset confirmation sent.'));
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
            'Reset Password',
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your email and PlaqueCheck will prepare a demo reset confirmation.',
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
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                    decoration: _inputDecoration('Email', Icons.email_outlined),
                  ),
                  if (_resetSent) ...[
                    const SizedBox(height: 18),
                    GlassCard(
                      borderRadius: 22,
                      opacity: 0.12,
                      borderOpacity: 0.2,
                      padding: const EdgeInsets.all(16),
                      glowColor: const Color(0xFF3B82F6),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: Color(0xFF38BDF8),
                            size: 22,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Demo reset confirmation sent. Check your inbox placeholder.',
                              style: TextStyle(
                                color: Color(0xFFCBD5E1),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  GlassButton(
                    label: 'Send Reset Link',
                    icon: Icons.mark_email_read_outlined,
                    isPrimary: true,
                    onPressed: _sendReset,
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

InputDecoration _inputDecoration(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: const Color(0xFF0EA5E9)),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.1),
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
