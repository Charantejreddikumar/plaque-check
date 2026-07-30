import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_card.dart';

class DoctorLoginScreen extends StatefulWidget {
  const DoctorLoginScreen({super.key});

  @override
  State<DoctorLoginScreen> createState() => _DoctorLoginScreenState();
}

class _DoctorLoginScreenState extends State<DoctorLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _obscurePassword = true;
  bool _rememberMe = true;
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
      final user = await _authService.doctorLogin(
        email: _emailController.text,
        password: _passwordController.text,
      );
      await SessionManager.clearAllUserData();
      await SessionManager.saveSession(user);
      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/doctor-dashboard');
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(_authSnackBar(error.message));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        _authSnackBar(e.toString().replaceAll('ApiException: ', '').trim()),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showForgotPasswordDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_reset_rounded, color: Color(0xFF0EA5E9)),
            SizedBox(width: 10),
            Text('Doctor Password Reset', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Please contact your Hospital / Clinic Administrator or submit a request to support@plaquecheck.com to reset your clinical account credentials.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Color(0xFF0EA5E9), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0EA5E9)),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Healthcare Branding Badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFF0EA5E9).withValues(alpha: 0.4)),
                          ),
                          child: const Icon(Icons.medical_services_rounded, color: Color(0xFF0EA5E9), size: 32),
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PlaqueCheck Clinical',
                              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                            ),
                            Text(
                              'PlaqueCheck AI Dental Platform',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    Text(
                      'Doctor Sign In',
                      style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter your clinical email & password to access patient review queue.',
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Glassmorphism Login Form Card
                    GlassCard(
                      borderRadius: 28,
                      opacity: 0.16,
                      borderOpacity: 0.24,
                      glowColor: const Color(0xFF0EA5E9),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateEmail,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration('Doctor Email Address', Icons.email_outlined),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              validator: _validateRequiredPassword,
                              style: const TextStyle(color: Colors.white),
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
                                    color: const Color(0xFF0EA5E9),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Remember Me & Forgot Password Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _rememberMe,
                                      activeColor: const Color(0xFF0EA5E9),
                                      onChanged: (val) => setState(() => _rememberMe = val ?? true),
                                    ),
                                    const Text('Remember Me', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  ],
                                ),
                                TextButton(
                                  onPressed: _showForgotPasswordDialog,
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(color: Color(0xFF0EA5E9), fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            GlassButton(
                              label: _isLoading ? 'Authenticating Doctor...' : 'Sign In to Clinical Workspace',
                              icon: Icons.login_rounded,
                              isPrimary: true,
                              onPressed: _isLoading ? () {} : _login,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Doctor Registration Application Option
                    Center(
                      child: Column(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/register-doctor'),
                            icon: const Icon(Icons.medical_information_outlined, color: Color(0xFF0EA5E9)),
                            label: const Text(
                              'Apply for Doctor Registration',
                              style: TextStyle(color: Color(0xFF0EA5E9), fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF0EA5E9)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Requires Administrator verification after submission',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
      prefixIcon: Icon(icon, color: const Color(0xFF0EA5E9)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 1.8),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Doctor email is required.';
    if (!value.contains('@')) return 'Enter a valid clinical email address.';
    return null;
  }

  String? _validateRequiredPassword(String? value) {
    if (value == null || value.trim().isEmpty) return 'Password is required.';
    return null;
  }

  SnackBar _authSnackBar(String message) {
    return SnackBar(
      backgroundColor: const Color(0xFF1E293B),
      content: Text(message, style: const TextStyle(color: Colors.white)),
    );
  }
}
