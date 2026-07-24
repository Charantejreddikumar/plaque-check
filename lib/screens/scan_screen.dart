import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 1600,
      );

      if (image == null || !mounted) {
        return;
      }

      Navigator.pushNamed(context, '/preview', arguments: image);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF0EA5E9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          content: const Text('Camera is not available on this device yet.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _MedicalScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            title: 'Plaque Detection Scan',
            subtitle: 'Choose an image source for AI-assisted plaque mapping.',
            onBack: () => Navigator.pop(context),
          ),
          const SizedBox(height: 28),
          _ScanActionCard(
            icon: Icons.upload_file_outlined,
            title: 'Upload Image',
            subtitle: 'Select a dental photo from your gallery.',
            onTap: () => _pickImage(ImageSource.gallery),
          ),
          const SizedBox(height: 18),
          _ScanActionCard(
            icon: Icons.camera_alt_outlined,
            title: 'Capture Camera',
            subtitle: 'Open camera capture for a fresh scan.',
            onTap: () => _pickImage(ImageSource.camera),
          ),
        ],
      ),
    );
  }
}

class _ScanActionCard extends StatelessWidget {
  const _ScanActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      borderRadius: 30,
      opacity: 0.14,
      borderOpacity: 0.22,
      glowColor: const Color(0xFF0EA5E9),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0EA5E9), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.18),
                  blurRadius: 22,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF0EA5E9)),
        ],
      ),
    );
  }
}

class _MedicalScaffold extends StatelessWidget {
  const _MedicalScaffold({required this.child});

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
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle, this.onBack});

  final String title;
  final String subtitle;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onBack != null)
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, color: Color(0xFF0EA5E9)),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.12),
            ),
          ),
        if (onBack != null) const SizedBox(height: 16),
        Text(
          title,
          style: TextStyle(
            color: AppTheme.textPrimary(context),
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            color: AppTheme.textSecondary(context),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
