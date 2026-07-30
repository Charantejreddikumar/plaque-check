import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_card.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
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

  void _fillDefaultAdmin() {
    setState(() {
      _emailController.text = 'admin@plaquecheck.com';
      _passwordController.text = 'password123';
    });
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false) || _isLoading) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await _authService.adminLogin(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await SessionManager.clearAllUserData();
      await SessionManager.saveSession(user);
      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/admin-dashboard');
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
    final resetEmailController = TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_reset, color: Color(0xFF805AD5)),
            SizedBox(width: 8),
            Text('Admin Password Recovery', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your registered Administrator email address to receive secure reset credentials.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Admin Email Address', Icons.email_outlined),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF805AD5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password recovery link sent to administrator email.')),
              );
            },
            child: const Text('Send Reset Instructions', style: TextStyle(color: Colors.white)),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, color: Color(0xFF805AD5)),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'PlaqueCheck Healthcare Core',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF805AD5).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF805AD5).withValues(alpha: 0.4), width: 1.5),
                            ),
                            child: const Icon(Icons.admin_panel_settings_outlined, color: Color(0xFF805AD5), size: 44),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'System Administrator Portal',
                            style: TextStyle(
                              color: AppTheme.textPrimary(context),
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Authorized Access Only • System Health & Management',
                            style: TextStyle(
                              color: AppTheme.textSecondary(context),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    GlassCard(
                      borderRadius: 28,
                      opacity: 0.14,
                      borderOpacity: 0.22,
                      glowColor: const Color(0xFF805AD5),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: _validateEmail,
                                style: TextStyle(color: AppTheme.textPrimary(context)),
                                decoration: _inputDecoration('Admin Email Address', Icons.email_outlined),
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
                                      color: const Color(0xFF805AD5),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          activeColor: const Color(0xFF805AD5),
                                          onChanged: (val) {
                                            setState(() => _rememberMe = val ?? true);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Remember Me',
                                        style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: _showForgotPasswordDialog,
                                    child: const Text(
                                      'Forgot Password?',
                                      style: TextStyle(color: Color(0xFF805AD5), fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              GlassButton(
                                label: _isLoading ? 'Authenticating Admin...' : 'Sign In as Administrator',
                                icon: Icons.shield_outlined,
                                isPrimary: true,
                                onPressed: _isLoading ? () {} : _login,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _fillDefaultAdmin,
                            icon: const Icon(Icons.key, color: Colors.white, size: 18),
                            label: const Text('Auto-Fill Default Admin Credentials'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF805AD5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Default Administrator: admin@plaquecheck.com / password123',
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
      hintStyle: TextStyle(color: AppTheme.textSecondary(context).withValues(alpha: 0.6)),
      prefixIcon: Icon(icon, color: const Color(0xFF805AD5)),
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
        borderSide: const BorderSide(color: Color(0xFF805AD5), width: 1.8),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required.';
    if (!value.contains('@')) return 'Enter a valid email address.';
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

