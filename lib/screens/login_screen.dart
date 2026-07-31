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

  void _fillAdminCredentials() {
    setState(() {
      _selectedRole = 'administrator';
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
      final SessionUser user;
      if (_selectedRole == 'doctor') {
        user = await _authService.doctorLogin(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else if (_selectedRole == 'administrator') {
        user = await _authService.adminLogin(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        user = await _authService.patientLogin(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
      await SessionManager.clearSession();
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

          // Role Switcher Cards Title
          Text(
            _selectedRole == 'doctor'
                ? '🩺 Doctor Clinical Portal'
                : _selectedRole == 'administrator'
                    ? '🛡️ Administrator Portal'
                    : '👤 Patient Sign In',
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _selectedRole == 'doctor'
                ? 'Access patient queue, review scans & prescribe treatments.'
                : _selectedRole == 'administrator'
                    ? 'System metrics, doctor approvals & security audit logs.'
                    : 'Sign in to track your personal plaque & oral health.',
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),

          // Prominent Role Selection Cards
          Row(
            children: [
              Expanded(
                child: _RoleCard(
                  title: 'Patient',
                  subtitle: 'Login',
                  icon: Icons.person_outline,
                  color: const Color(0xFF3AAFA9),
                  isSelected: _selectedRole == 'patient',
                  onTap: () => setState(() => _selectedRole = 'patient'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RoleCard(
                  title: 'Doctor',
                  subtitle: 'Portal',
                  icon: Icons.medical_services_outlined,
                  color: const Color(0xFF3182CE),
                  isSelected: _selectedRole == 'doctor',
                  onTap: () => setState(() => _selectedRole = 'doctor'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RoleCard(
                  title: 'Admin',
                  subtitle: 'Portal',
                  icon: Icons.admin_panel_settings_outlined,
                  color: const Color(0xFF805AD5),
                  isSelected: _selectedRole == 'administrator',
                  onTap: () => setState(() => _selectedRole = 'administrator'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          GlassCard(
            borderRadius: 28,
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
                    decoration: _inputDecoration(
                      _selectedRole == 'doctor'
                          ? 'Doctor Email Address'
                          : _selectedRole == 'administrator'
                              ? 'Admin Email (admin@plaquecheck.com)'
                              : 'Patient Email Address',
                      Icons.email_outlined,
                    ),
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

          // Role-specific quick actions
          if (_selectedRole == 'doctor') ...[
            Center(
              child: Column(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/register-doctor'),
                    icon: const Icon(Icons.medical_information_outlined, color: Color(0xFF3AAFA9)),
                    label: const Text(
                      'Apply for Doctor Registration',
                      style: TextStyle(color: Color(0xFF3AAFA9), fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF3AAFA9)),
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
          ] else if (_selectedRole == 'administrator') ...[
            Center(
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _fillAdminCredentials,
                    icon: const Icon(Icons.key, color: Colors.white, size: 18),
                    label: const Text('Auto-Fill System Admin Credentials'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF805AD5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Default Admin: admin@plaquecheck.com / password123',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                  ),
                ],
              ),
            ),
          ] else ...[
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

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.12),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? color : Colors.white70,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected ? color : Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
