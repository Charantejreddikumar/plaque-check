import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'crop_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_card.dart';
import '../widgets/platform_image.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();

  XFile? _frontImage;
  XFile? _leftImage;
  XFile? _rightImage;

  Future<void> _pickImageForSlot(String slot, ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 92,
        maxWidth: 1800,
      );
      if (image == null || !mounted) return;

      final slotLabel = slot == 'front'
          ? 'Front View (Center)'
          : slot == 'left'
              ? 'Left Angle View'
              : 'Right Angle View';

      final croppedResult = await Navigator.pushNamed(
        context,
        '/crop',
        arguments: CropScreenArguments(
          image: image,
          label: slotLabel,
        ),
      );

      final finalImage = (croppedResult is XFile) ? croppedResult : image;

      setState(() {
        if (slot == 'front') _frontImage = finalImage;
        if (slot == 'left') _leftImage = finalImage;
        if (slot == 'right') _rightImage = finalImage;
      });
    } catch (_) {
      _showPickerMessage('Camera/Gallery access error. Please try again.');
    }
  }

  void _proceedToPreview() {
    final images = <String, XFile>{};
    if (_frontImage != null) images['Front View'] = _frontImage!;
    if (_leftImage != null) images['Left Angle'] = _leftImage!;
    if (_rightImage != null) images['Right Angle'] = _rightImage!;

    if (images.isEmpty) {
      _showPickerMessage('Please capture or select at least 1 photo of your teeth.');
      return;
    }

    Navigator.pushNamed(context, '/preview', arguments: images);
  }

  void _showPickerMessage(String message) {
    if (!mounted) return;
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
            title: 'Multi-Angle Dental Scan',
            subtitle: 'Take 1 to 3 photos of your lower face (nose, mouth, chin, & teeth) from different angles for optimal plaque analysis.',
            onBack: () => Navigator.pop(context),
          ),
          const SizedBox(height: 24),
          _AngleSlotCard(
            title: 'Front View (Center)',
            subtitle: 'Direct front photo of upper & lower teeth.',
            image: _frontImage,
            isRequired: true,
            onCameraTap: () => _pickImageForSlot('front', ImageSource.camera),
            onGalleryTap: () => _pickImageForSlot('front', ImageSource.gallery),
            onRemove: () => setState(() => _frontImage = null),
          ),
          const SizedBox(height: 16),
          _AngleSlotCard(
            title: 'Left Angle View',
            subtitle: 'Side photo focusing on left molars & premolars.',
            image: _leftImage,
            isRequired: false,
            onCameraTap: () => _pickImageForSlot('left', ImageSource.camera),
            onGalleryTap: () => _pickImageForSlot('left', ImageSource.gallery),
            onRemove: () => setState(() => _leftImage = null),
          ),
          const SizedBox(height: 16),
          _AngleSlotCard(
            title: 'Right Angle View',
            subtitle: 'Side photo focusing on right molars & premolars.',
            image: _rightImage,
            isRequired: false,
            onCameraTap: () => _pickImageForSlot('right', ImageSource.camera),
            onGalleryTap: () => _pickImageForSlot('right', ImageSource.gallery),
            onRemove: () => setState(() => _rightImage = null),
          ),
          const SizedBox(height: 28),
          GlassButton(
            label: 'Review Captured Angles (${[_frontImage, _leftImage, _rightImage].where((e) => e != null).length}/3)',
            icon: Icons.preview_outlined,
            isPrimary: true,
            onPressed: _proceedToPreview,
          ),
        ],
      ),
    );
  }
}

class _AngleSlotCard extends StatelessWidget {
  const _AngleSlotCard({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.isRequired,
    required this.onCameraTap,
    required this.onGalleryTap,
    required this.onRemove,
  });

  final String title;
  final String subtitle;
  final XFile? image;
  final bool isRequired;
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                image != null ? Icons.check_circle : Icons.camera_enhance_outlined,
                color: image != null ? const Color(0xFF4ECCA3) : AppTheme.highlight(context),
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isRequired)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B7A78).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Primary',
                    style: TextStyle(color: Color(0xFF69C7C3), fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 12),
          ),
          const SizedBox(height: 14),
          if (image != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: buildPlatformImage(imagePath: image!.path, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onCameraTap,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retake'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                  label: const Text('Remove', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCameraTap,
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: const Text('Camera'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary(context),
                      side: BorderSide(color: AppTheme.highlight(context).withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onGalleryTap,
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Gallery'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary(context),
                      side: BorderSide(color: AppTheme.highlight(context).withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
