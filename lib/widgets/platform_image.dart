import 'package:flutter/material.dart';

import '../services/session_manager.dart';
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
  return AuthenticatedNetworkImage(
    imageUrl: imageUrl,
    fit: fit,
    errorWidget: errorWidget,
  );
}

class AuthenticatedNetworkImage extends StatefulWidget {
  const AuthenticatedNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.errorWidget,
  });

  final String imageUrl;
  final BoxFit fit;
  final Widget? errorWidget;

  @override
  State<AuthenticatedNetworkImage> createState() =>
      _AuthenticatedNetworkImageState();
}

class _AuthenticatedNetworkImageState
    extends State<AuthenticatedNetworkImage> {
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadSessionToken();
  }

  Future<void> _loadSessionToken() async {
    final user = await SessionManager.currentUser();
    if (mounted && user != null && user.accessToken.isNotEmpty) {
      setState(() {
        _token = user.accessToken;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl.isEmpty) {
      return widget.errorWidget ?? const _ImageLoadError();
    }

    final token = _token;
    String finalUrl = widget.imageUrl;
    Map<String, String>? headers;

    if (token != null && token.isNotEmpty) {
      headers = {'Authorization': 'Bearer $token'};
      if (!finalUrl.contains('token=')) {
        final uri = Uri.tryParse(finalUrl);
        if (uri != null) {
          final queryParams = Map<String, String>.from(uri.queryParameters);
          queryParams['token'] = token;
          finalUrl = uri.replace(queryParameters: queryParams).toString();
        }
      }
    }

    return Image.network(
      finalUrl,
      fit: widget.fit,
      headers: headers,
      errorBuilder: (context, error, stackTrace) =>
          widget.errorWidget ?? const _ImageLoadError(),
    );
  }
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
