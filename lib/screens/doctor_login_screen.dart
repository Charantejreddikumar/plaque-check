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
        backgroundColor: AppTheme.cardColor(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.glassBorder(context)),
        ),
        title: Row(
          children: [
            Icon(Icons.lock_reset_rounded, color: AppTheme.accent(context)),
            const SizedBox(width: 10),
            Text(
              'Doctor Password Reset',
              style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Please contact your Hospital / Clinic Administrator or submit a request to support@plaquecheck.com to reset your clinical account credentials.',
          style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: TextStyle(color: AppTheme.accent(context), fontWeight: FontWeight.bold),
            ),
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
                      icon: Icon(Icons.arrow_back_rounded, color: AppTheme.accent(context)),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.secondarySurface(context),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Healthcare Branding Badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.accent(context).withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppTheme.accent(context).withValues(alpha: 0.3)),
                          ),
                          child: Icon(Icons.medical_services_rounded, color: AppTheme.accent(context), size: 32),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PlaqueCheck',
                              style: TextStyle(
                                color: AppTheme.textPrimary(context),
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'Clinical Doctor Workspace',
                              style: TextStyle(
                                color: AppTheme.textSecondary(context),
                                fontSize: 12,
                              ),
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

                    // Login Form Card
                    GlassCard(
                      borderRadius: 28,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateEmail,
                              style: TextStyle(color: AppTheme.textPrimary(context)),
                              decoration: _inputDecoration('Doctor Email Address', Icons.email_outlined),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              validator: _validateRequiredPassword,
                              style: TextStyle(color: AppTheme.textPrimary(context)),
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
                                    color: AppTheme.accent(context),
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
                                      activeColor: AppTheme.accent(context),
                                      onChanged: (val) => setState(() => _rememberMe = val ?? true),
                                    ),
                                    Text(
                                      'Remember Me',
                                      style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 12),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: _showForgotPasswordDialog,
                                  child: Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: AppTheme.accent(context),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
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
                            icon: Icon(Icons.medical_information_outlined, color: AppTheme.accent(context)),
                            label: Text(
                              'Apply for Doctor Registration',
                              style: TextStyle(color: AppTheme.accent(context), fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppTheme.accent(context)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Requires Administrator verification after submission',
                            style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 11),
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
      prefixIcon: Icon(icon, color: AppTheme.accent(context)),
      suffixIcon: suffixIcon,
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
      backgroundColor: AppTheme.cardColor(context),
      content: Text(message, style: TextStyle(color: AppTheme.textPrimary(context))),
    );
  }
}
