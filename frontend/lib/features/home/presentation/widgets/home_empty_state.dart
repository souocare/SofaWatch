import 'package:flutter/material.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';

class HomeEmptyState extends StatelessWidget {
  const HomeEmptyState({
    required this.title,
    required this.message,
    required this.emptyStateKey,
    super.key,
    this.subtitle,
    this.icon = Icons.check_circle_outline_rounded,
  });

  final String title;
  final String? subtitle;
  final String message;
  final String emptyStateKey;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey<String>(emptyStateKey),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            Icon(icon, size: 18, color: AppColors.textMuted),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
