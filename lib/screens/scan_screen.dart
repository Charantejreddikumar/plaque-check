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

  Future<void> _captureImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 88,
        maxWidth: 1600,
      );
      _openPreview(image);
    } catch (_) {
      _showPickerMessage(
        'Camera is not available on this device or browser. Please allow camera access and try again.',
      );
    }
  }

  Future<void> _selectFromGallery() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1600,
      );
      _openPreview(image);
    } catch (_) {
      _showPickerMessage('Gallery is not available on this device yet.');
    }
  }

  void _openPreview(XFile? image) {
    if (image == null || !mounted) {
      return;
    }

    Navigator.pushNamed(context, '/preview', arguments: image);
  }

  void _showPickerMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
    );
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
            icon: Icons.camera_alt_outlined,
            title: 'Capture Image',
            subtitle: 'Open camera capture for a fresh scan.',
            onTap: _captureImage,
          ),
          const SizedBox(height: 18),
          _ScanActionCard(
            icon: Icons.photo_library_outlined,
            title: 'Gallery',
            subtitle: 'Select an existing dental photo.',
            onTap: _selectFromGallery,
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
      borderRadius: 16,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.secondarySurface(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.highlight(context), size: 27),
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
          Icon(Icons.chevron_right, color: AppTheme.highlight(context)),
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
            icon: Icon(Icons.arrow_back, color: AppTheme.highlight(context)),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.secondarySurface(context),
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
