import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_card.dart';

class ComplaintScreen extends StatefulWidget {
  const ComplaintScreen({super.key});

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _reportRelated = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList('complaints') ?? [];
    final complaint = {
      'subject': _subjectController.text.trim(),
      'description': _descriptionController.text.trim(),
      'reportRelated': _reportRelated,
      'createdAt': DateTime.now().toIso8601String(),
    };
    await prefs.setStringList('complaints', [
      jsonEncode(complaint),
      ...existing,
    ]);
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Concern recorded'),
        content: const Text(
          'Your concern has been recorded and will be reviewed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (mounted) {
      Navigator.pop(context);
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
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF0EA5E9)),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Report Issue',
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Submit a privacy, report, or scan concern for future review workflows.',
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                GlassCard(
                  borderRadius: 30,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _subjectController,
                          validator: _required,
                          decoration: _inputDecoration(
                            'Subject',
                            Icons.subject,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          validator: _required,
                          minLines: 4,
                          maxLines: 6,
                          decoration: _inputDecoration(
                            'Description',
                            Icons.notes_outlined,
                          ),
                        ),
                        const SizedBox(height: 12),
                        CheckboxListTile(
                          value: _reportRelated,
                          onChanged: (value) {
                            setState(() => _reportRelated = value ?? false);
                          },
                          activeColor: AppTheme.accent(context),
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'This concern is related to a saved report',
                            style: TextStyle(
                              color: AppTheme.textPrimary(context),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                GlassButton(
                  label: 'Submit',
                  icon: Icons.send_outlined,
                  isPrimary: true,
                  onPressed: _submit,
                ),
                const SizedBox(height: 12),
                GlassButton(
                  label: 'Cancel',
                  icon: Icons.close,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: const Color(0xFF0EA5E9)),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 1.4),
    ),
  );
}

String? _required(String? value) {
  if ((value?.trim() ?? '').isEmpty) {
    return 'This field is required.';
  }
  return null;
}
