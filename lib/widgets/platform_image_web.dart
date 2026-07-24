import 'package:flutter/material.dart';

Widget buildPlatformImage({
  required String imagePath,
  required BoxFit fit,
  Widget? errorWidget,
}) {
  return Image.network(
    imagePath,
    fit: fit,
    errorBuilder: (context, error, stackTrace) =>
        errorWidget ?? const _ImageLoadError(),
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
