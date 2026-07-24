import 'package:flutter/material.dart';

import 'platform_image_stub.dart'
    if (dart.library.io) 'platform_image_io.dart'
    if (dart.library.html) 'platform_image_web.dart'
    as platform_image;

Widget buildPlatformImage({
  required String imagePath,
  BoxFit fit = BoxFit.cover,
  Widget? errorWidget,
}) {
  return platform_image.buildPlatformImage(
    imagePath: imagePath,
    fit: fit,
    errorWidget: errorWidget,
  );
}

Widget buildNetworkImage({
  required String imageUrl,
  BoxFit fit = BoxFit.cover,
  Widget? errorWidget,
}) {
  return Image.network(
    imageUrl,
    fit: fit,
    errorBuilder: (context, error, stackTrace) =>
        errorWidget ?? const _ImageLoadError(),
  );
}

class ImageLoadError extends StatelessWidget {
  const ImageLoadError({super.key});

  @override
  Widget build(BuildContext context) => const _ImageLoadError();
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
