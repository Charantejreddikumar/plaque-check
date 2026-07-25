import 'package:flutter/material.dart';

import '../services/app_config.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_card.dart';

class DeveloperSettingsScreen extends StatefulWidget {
  const DeveloperSettingsScreen({super.key});

  @override
  State<DeveloperSettingsScreen> createState() =>
      _DeveloperSettingsScreenState();
}

class _DeveloperSettingsScreenState extends State<DeveloperSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController();
  final _portController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final uri = Uri.tryParse(AppConfig.apiBaseUrl);
    _hostController.text = uri?.host ?? '';
    _portController.text = uri?.hasPort == true ? uri!.port.toString() : '';
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final url = AppConfig.buildHttpApiBaseUrl(
      host: _hostController.text,
      port: _portController.text,
    );
    await AppConfig.saveApiBaseUrl(url);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      _settingsSnackBar('Backend URL saved. New requests will use $url'),
    );
    setState(() {});
  }

  Future<void> _reset() async {
    await AppConfig.clearSavedApiBaseUrl();
    final uri = Uri.tryParse(AppConfig.apiBaseUrl);
    _hostController.text = uri?.host ?? '';
    _portController.text = uri?.hasPort == true ? uri!.port.toString() : '';

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(_settingsSnackBar('Backend URL reset to default.'));
    setState(() {});
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
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF2B7A78)),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Developer Settings',
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Configure the development backend used by PlaqueCheck.',
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                GlassCard(
                  borderRadius: 26,
                  opacity: 0.14,
                  borderOpacity: 0.22,
                  glowColor: const Color(0xFF2B7A78),
                  child: Row(
                    children: [
                      Icon(
                        Icons.dns_outlined,
                        color: AppTheme.accent(context),
                        size: 24,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Backend URL',
                              style: TextStyle(
                                color: AppTheme.textPrimary(context),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppConfig.apiBaseUrl,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppTheme.textSecondary(context),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _hostController,
                          keyboardType: TextInputType.url,
                          validator: _validateHost,
                          decoration: _inputDecoration(
                            'Backend IP or host',
                            Icons.router_outlined,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _portController,
                          keyboardType: TextInputType.number,
                          validator: _validatePort,
                          decoration: _inputDecoration(
                            'Port',
                            Icons.settings_ethernet_outlined,
                          ),
                        ),
                        const SizedBox(height: 20),
                        GlassButton(
                          label: 'Save Backend URL',
                          icon: Icons.save_outlined,
                          isPrimary: true,
                          onPressed: _save,
                        ),
                        const SizedBox(height: 12),
                        GlassButton(
                          label: 'Use Default URL',
                          icon: Icons.restart_alt_outlined,
                          onPressed: _reset,
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
}

InputDecoration _inputDecoration(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: const Color(0xFF2B7A78)),
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
      borderSide: const BorderSide(color: Color(0xFF2B7A78), width: 1.4),
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

String? _validateHost(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return 'Backend IP or host is required.';
  }
  if (text.contains(RegExp(r'\s'))) {
    return 'Backend IP or host cannot contain spaces.';
  }
  return null;
}

String? _validatePort(String? value) {
  final port = int.tryParse(value?.trim() ?? '');
  if (port == null) {
    return 'Port is required.';
  }
  if (port < 1 || port > 65535) {
    return 'Enter a port between 1 and 65535.';
  }
  return null;
}

SnackBar _settingsSnackBar(String message) {
  return SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: const Color(0xFF3BA7A4),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    content: Text(message),
  );
}
