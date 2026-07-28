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
    final rawArg = ModalRoute.of(context)?.settings.arguments;

    Map<String, XFile> imagesMap = {};
    if (rawArg is Map<String, XFile>) {
      imagesMap = rawArg;
    } else if (rawArg is XFile) {
      imagesMap['Front View'] = rawArg;
    }

    final hasImages = imagesMap.isNotEmpty;

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
                  'Review Multi-Angle Scan',
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Confirm image quality for each angle before AI plaque analysis.',
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                if (!hasImages)
                  const GlassCard(
                    borderRadius: 24,
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text('No scan images selected.'),
                      ),
                    ),
                  )
                else
                  ...imagesMap.entries.map((entry) {
                    final label = entry.key;
                    final file = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: GlassCard(
                        borderRadius: 24,
                        opacity: 0.16,
                        borderOpacity: 0.24,
                        glowColor: const Color(0xFF2B7A78),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.camera_alt_outlined,
                                  color: Color(0xFF69C7C3),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  label,
                                  style: TextStyle(
                                    color: AppTheme.textPrimary(context),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: AspectRatio(
                                aspectRatio: 1.25,
                                child: buildPlatformImage(
                                  imagePath: file.path,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 16),
                GlassButton(
                  label: 'Analyze Scan (${imagesMap.length} Angle${imagesMap.length > 1 ? 's' : ''})',
                  icon: Icons.biotech_outlined,
                  isPrimary: true,
                  onPressed: !hasImages
                      ? () => Navigator.pop(context)
                      : () => Navigator.pushNamed(
                          context,
                          '/analysis',
                          arguments: rawArg,
                        ),
                ),
                const SizedBox(height: 12),
                GlassButton(
                  label: 'Retake Angles',
                  icon: Icons.refresh_outlined,
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
