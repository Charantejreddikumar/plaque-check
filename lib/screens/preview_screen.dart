import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_card.dart';
import '../widgets/platform_image.dart';

class PreviewScreen extends StatelessWidget {
  const PreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final image = ModalRoute.of(context)?.settings.arguments as XFile?;

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
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Review Scan Image',
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Confirm image quality before AI analysis.',
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 26),
                GlassCard(
                  borderRadius: 34,
                  opacity: 0.16,
                  borderOpacity: 0.24,
                  glowColor: const Color(0xFF2B7A78),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.image_search_outlined,
                            color: Color(0xFF69C7C3),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Dental imaging review',
                            style: TextStyle(
                              color: AppTheme.textPrimary(context),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: AspectRatio(
                          aspectRatio: 0.82,
                          child: image == null
                              ? const _MissingImagePlaceholder()
                              : buildPlatformImage(
                                  imagePath: image.path,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ensure the teeth are well lit, centered, and sharp enough for plaque region detection.',
                        style: TextStyle(
                          color: AppTheme.textSecondary(context),
                          fontSize: 12,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                GlassButton(
                  label: 'Analyze Scan',
                  icon: Icons.biotech_outlined,
                  isPrimary: true,
                  onPressed: image == null
                      ? () => Navigator.pop(context)
                      : () => Navigator.pushNamed(
                          context,
                          '/analysis',
                          arguments: image,
                        ),
                ),
                const SizedBox(height: 12),
                GlassButton(
                  label: 'Retake',
                  icon: Icons.camera_alt_outlined,
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

class _MissingImagePlaceholder extends StatelessWidget {
  const _MissingImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withValues(alpha: 0.06),
      alignment: Alignment.center,
      child: Text(
        'No scan image available',
        style: TextStyle(
          color: AppTheme.textSecondary(context),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
