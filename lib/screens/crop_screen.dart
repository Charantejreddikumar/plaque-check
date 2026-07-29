import 'dart:io';
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../theme/app_theme.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_card.dart';

class CropScreenArguments {
  const CropScreenArguments({
    required this.image,
    this.label = 'Teeth Scan',
  });

  final XFile image;
  final String label;
}

class CropScreen extends StatefulWidget {
  const CropScreen({super.key});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  final CropController _cropController = CropController();

  XFile? _originalFile;
  String _label = 'Teeth Scan';
  Uint8List? _imageBytes;

  bool _isCropping = false;
  bool _isLoadingImage = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_originalFile != null) return;

    final rawArg = ModalRoute.of(context)?.settings.arguments;
    if (rawArg is CropScreenArguments) {
      _originalFile = rawArg.image;
      _label = rawArg.label;
    } else if (rawArg is XFile) {
      _originalFile = rawArg;
    }

    if (_originalFile != null) {
      _loadImageBytes();
    }
  }

  Future<void> _loadImageBytes() async {
    try {
      final bytes = await _originalFile!.readAsBytes();
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _isLoadingImage = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingImage = false);
    }
  }

  Future<void> _saveCroppedImage(Uint8List croppedBytes) async {
    try {
      XFile croppedFile;
      if (kIsWeb) {
        croppedFile = XFile.fromData(
          croppedBytes,
          mimeType: 'image/png',
          name: 'cropped_${_originalFile?.name ?? "teeth.png"}',
        );
      } else {
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final targetPath = '${tempDir.path}/cropped_$timestamp.png';
        final file = File(targetPath);
        await file.writeAsBytes(croppedBytes);
        croppedFile = XFile(targetPath);
      }

      if (!mounted) return;
      Navigator.pop(context, croppedFile);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCropping = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save cropped image: $e')),
      );
    }
  }

  void _onCropPressed() {
    if (_isCropping) return;
    setState(() => _isCropping = true);
    _cropController.crop();
  }

  void _onSkipPressed() {
    Navigator.pop(context, _originalFile);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.pageDecoration(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: theme,
        child: SafeArea(
          child: Column(
            children: [
              // Top Header Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context, _originalFile),
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF2B7A78)),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Crop Dental Photo',
                            style: TextStyle(
                              color: AppTheme.textPrimary(context),
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            _label,
                            style: TextStyle(
                              color: AppTheme.textSecondary(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _onSkipPressed,
                      icon: const Icon(Icons.skip_next_outlined, size: 18),
                      label: const Text('Skip Crop'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),

              // Guidance Notice Banner Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: GlassCard(
                  borderRadius: 16,
                  opacity: 0.14,
                  borderOpacity: 0.22,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.crop_outlined,
                          color: Color(0xFF69C7C3),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Crop the image so only the teeth are visible. Remove unnecessary background such as lips, facial hair, cheeks, and skin where possible.',
                            style: TextStyle(
                              color: AppTheme.textPrimary(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Main Crop Viewer Canvas
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.85),
                      child: _isLoadingImage || _imageBytes == null
                          ? const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3AAFA9)),
                              ),
                            )
                          : Stack(
                              children: [
                                Crop(
                                  image: _imageBytes!,
                                  controller: _cropController,
                                  onCropped: (croppedImage) {
                                    _saveCroppedImage(croppedImage);
                                  },
                                  interactive: true,
                                  fixCropRect: false,
                                  baseColor: Colors.black,
                                  maskColor: Colors.black.withValues(alpha: 0.65),
                                  initialSize: 0.85,
                                ),
                                if (_isCropping)
                                  Container(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    child: const Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3AAFA9)),
                                          ),
                                          SizedBox(height: 14),
                                          Text(
                                            'Processing High-Res Crop...',
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
              ),

              const SizedBox(height: 12),

              // Bottom Action Controls Toolbar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            // Re-load image bytes to reset crop rect
                            _loadImageBytes();
                          },
                          icon: const Icon(Icons.restart_alt, size: 18),
                          label: const Text('Reset Crop'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textPrimary(context),
                            side: BorderSide(color: AppTheme.highlight(context).withValues(alpha: 0.3)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GlassButton(
                      label: 'Apply & Save Crop',
                      icon: Icons.check_circle_outline,
                      isPrimary: true,
                      onPressed: _onCropPressed,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
