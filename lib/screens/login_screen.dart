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

  String _selectedRole = 'patient'; // 'patient', 'doctor', 'administrator'
  bool _obscurePassword = true;
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
      await SessionManager.clearAllUserData();
      await SessionManager.saveSession(user);
      if (!mounted) return;

      if (user.role == 'doctor') {
        Navigator.pushReplacementNamed(context, '/doctor-dashboard');
      } else if (user.role == 'administrator') {
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
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

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AuthLogo(),
          const SizedBox(height: 24),
          Text(
            'PlaqueCheck Clinical Portal',
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Select your role to log into your workspace.',
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),

          // Role Selector Tabs
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                _RoleTab(
                  label: 'Patient',
                  icon: Icons.person_outline,
                  isSelected: _selectedRole == 'patient',
                  onTap: () => setState(() => _selectedRole = 'patient'),
                ),
                _RoleTab(
                  label: 'Doctor',
                  icon: Icons.medical_services_outlined,
                  isSelected: _selectedRole == 'doctor',
                  onTap: () => setState(() => _selectedRole = 'doctor'),
                ),
                _RoleTab(
                  label: 'Admin',
                  icon: Icons.admin_panel_settings_outlined,
                  isSelected: _selectedRole == 'administrator',
                  onTap: () => setState(() => _selectedRole = 'administrator'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          GlassCard(
            borderRadius: 32,
            opacity: 0.14,
            borderOpacity: 0.22,
            glowColor: const Color(0xFF2B7A78),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                    decoration: _inputDecoration('Email Address', Icons.email_outlined),
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
                          color: const Color(0xFF3AAFA9),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  GlassButton(
                    label: _isLoading
                        ? 'Authenticating...'
                        : 'Sign In as ${_selectedRole.toUpperCase()}',
                    icon: Icons.arrow_forward_rounded,
                    isPrimary: true,
                    onPressed: _isLoading ? () {} : _login,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Footer links
          if (_selectedRole == 'doctor') ...[
            Center(
              child: TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/register-doctor'),
                icon: const Icon(Icons.medical_information_outlined, color: Color(0xFF3AAFA9)),
                label: const Text(
                  'Doctor Registration Request',
                  style: TextStyle(color: Color(0xFF3AAFA9), fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ] else if (_selectedRole == 'patient') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have a patient account? ",
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 13,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/register'),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      color: Color(0xFF3AAFA9),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Center(
              child: Text(
                'Default Admin: admin@plaquecheck.com / password123',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF3AAFA9)),
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
        borderSide: const BorderSide(color: Color(0xFF3AAFA9), width: 1.8),
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

class _RoleTab extends StatelessWidget {
  const _RoleTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2B7A78) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: child,
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
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2B7A78).withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.biotech, color: Color(0xFF3AAFA9), size: 30),
        ),
        const SizedBox(width: 12),
        const Text(
          'PlaqueCheck',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
