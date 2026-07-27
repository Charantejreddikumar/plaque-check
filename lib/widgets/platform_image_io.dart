import 'dart:io';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'platform_image.dart';

Widget buildPlatformImage({
  required String imagePath,
  required BoxFit fit,
  Widget? errorWidget,
}) {
  if (imagePath.isEmpty) {
    return errorWidget ?? const _ImageLoadError();
  }

  if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
    return buildNetworkImage(
      imageUrl: imagePath,
      fit: fit,
      errorWidget: errorWidget,
    );
  }

  String normalizedPath = imagePath;
  if (normalizedPath.startsWith('file://')) {
    try {
      normalizedPath = Uri.parse(normalizedPath).toFilePath();
    } catch (_) {
      normalizedPath = normalizedPath.replaceFirst('file://', '');
    }
  }

  if (!normalizedPath.startsWith('/') &&
      !normalizedPath.contains(':\\') &&
      !normalizedPath.contains(':/')) {
    final backendUrl = ApiService().mediaUrl(normalizedPath);
    return buildNetworkImage(
      imageUrl: backendUrl,
      fit: fit,
      errorWidget: errorWidget,
    );
  }

  final file = File(normalizedPath);
  return Image.file(
    file,
    fit: fit,
    errorBuilder: (context, error, stackTrace) {
      if (errorWidget != null) {
        return errorWidget;
      }
      final fallbackUrl = ApiService().mediaUrl(imagePath);
      if (fallbackUrl.startsWith('http')) {
        return buildNetworkImage(
          imageUrl: fallbackUrl,
          fit: fit,
          errorWidget: const _ImageLoadError(),
        );
      }
      return const _ImageLoadError();
    },
  );
}

class _ImageLoadError extends StatelessWidget {
  const _ImageLoadError();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      color: Colors.white24,
      child: const Text(
        'Unable to load image',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFFE2E8F0),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
