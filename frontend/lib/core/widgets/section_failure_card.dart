import 'package:flutter/material.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/core/errors/app_error_message_mapper.dart';
import 'package:sofawatch/core/errors/app_exception.dart';

class SectionFailureCard extends StatelessWidget {
  const SectionFailureCard({
    required this.failureKey,
    required this.error,
    required this.onRetry,
    super.key,
  });

  final String failureKey;
  final AppException error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey<String>(failureKey),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              _messageFor(error),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (error.canRetry) ...<Widget>[
            const SizedBox(width: AppSpacing.sm),
            TextButton(
              key: ValueKey<String>('$failureKey-retry'),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}

String _messageFor(AppException error) {
  if (error.isTimeout) {
    return 'This section took too long to load.';
  }

  return AppErrorMessageMapper.map(error);
}
