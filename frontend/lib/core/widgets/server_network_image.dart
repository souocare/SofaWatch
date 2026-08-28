import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/api/api_client.dart';

class ServerNetworkImage extends StatelessWidget {
  const ServerNetworkImage({
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorBuilder,
    super.key,
  });

  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    final ApiClient apiClient = context.read<ApiClient>();

    final String? resolvedImageUrl = apiClient.resolveServerUrl(imageUrl);

    if (resolvedImageUrl == null) {
      return errorBuilder?.call(
            context,
            const FormatException('Image URL is missing.'),
            null,
          ) ??
          const SizedBox.shrink();
    }

    return Image.network(
      resolvedImageUrl,
      width: width,
      height: height,
      fit: fit,
      headers: apiClient.authenticatedResourceHeaders,
      errorBuilder: errorBuilder,
    );
  }
}
