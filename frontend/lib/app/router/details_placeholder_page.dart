import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DetailsPlaceholderPage extends StatelessWidget {
  const DetailsPlaceholderPage({
    required this.title,
    required this.resourceId,
    super.key,
  });

  final String title;
  final String resourceId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close',
          onPressed: context.pop,
          icon: const Icon(Icons.close),
        ),
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              title,
              key: ValueKey<String>(
                '${title.toLowerCase().replaceAll(' ', '-')}-title',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              resourceId,
              key: const ValueKey<String>('details-resource-id'),
            ),
          ],
        ),
      ),
    );
  }
}
