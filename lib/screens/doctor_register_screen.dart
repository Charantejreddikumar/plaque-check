import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_card.dart';

class DoctorRegisterScreen extends StatefulWidget {
  const DoctorRegisterScreen({super.key});

  @override
  State<DoctorRegisterScreen> createState() => _DoctorRegisterScreenState();
}

class _DoctorRegisterScreenState extends State<DoctorRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _mobileController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _specializationController = TextEditingController();
  final _regNumController = TextEditingController();
  final _clinicController = TextEditingController();
  final _hospitalController = TextEditingController();

  final _apiService = ApiService();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _mobileController.dispose();
    _qualificationController.dispose();
    _specializationController.dispose();
    _regNumController.dispose();
    _clinicController.dispose();
    _hospitalController.dispose();
    super.dispose();
  }

  Future<void> _submitDoctorRegistration() async {
    if (!(_formKey.currentState?.validate() ?? false) || _isLoading) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await _apiService.registerDoctor({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'mobile': _mobileController.text.trim(),
        'qualification': _qualificationController.text.trim(),
        'specialization': _specializationController.text.trim(),
        'registration_number': _regNumController.text.trim(),
        'clinic_name': _clinicController.text.trim(),
        'hospital_name': _hospitalController.text.trim(),
      });

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Color(0xFF3AAFA9)),
              SizedBox(width: 10),
              Text('Registration Submitted'),
            ],
          ),
          content: Text(res['message'] ?? 'Doctor account created! Pending Administrator verification.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Back to Login', style: TextStyle(color: Color(0xFF2B7A78), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('ApiException: ', '').trim())),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF2B7A78)),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Doctor Account Registration',
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Submit your medical credentials for Administrator verification.',
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                GlassCard(
                  borderRadius: 28,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _field(_nameController, 'Full Name', Icons.person_outline),
                        const SizedBox(height: 12),
                        _field(_emailController, 'Email Address', Icons.email_outlined, type: TextInputType.emailAddress),
                        const SizedBox(height: 12),
                        _field(_passwordController, 'Password', Icons.lock_outline, obscure: true),
                        const SizedBox(height: 12),
                        _field(_mobileController, 'Mobile Phone', Icons.phone_outlined, type: TextInputType.phone),
                        const SizedBox(height: 12),
                        _field(_qualificationController, 'Qualification (e.g. BDS, MDS)', Icons.school_outlined),
                        const SizedBox(height: 12),
                        _field(_specializationController, 'Specialization (e.g. Periodontics)', Icons.medical_services_outlined),
                        const SizedBox(height: 12),
                        _field(_regNumController, 'Medical Council Reg. Number', Icons.badge_outlined),
                        const SizedBox(height: 12),
                        _field(_clinicController, 'Clinic Name', Icons.storefront_outlined),
                        const SizedBox(height: 12),
                        _field(_hospitalController, 'Hospital Name', Icons.local_hospital_outlined),
                        const SizedBox(height: 24),
                        GlassButton(
                          label: _isLoading ? 'Submitting Application...' : 'Submit Doctor Registration',
                          icon: Icons.send_rounded,
                          isPrimary: true,
                          onPressed: _isLoading ? () {} : _submitDoctorRegistration,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String hint, IconData icon, {bool obscure = false, TextInputType type = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: type,
      validator: (v) => (v == null || v.trim().isEmpty) ? '$hint is required' : null,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF3AAFA9)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
      ),
    );
  }
}
