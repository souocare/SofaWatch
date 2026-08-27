import 'package:flutter/material.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';

class HomeSection extends StatelessWidget {
  const HomeSection({
    required this.title,
    required this.child,
    required this.sectionKey,
    this.subtitle,
    this.trailing,
    super.key,
  });

  final String title;

  final String? subtitle;

  final Widget? trailing;

  final Widget child;

  /// Stable identifier used by widget tests and section-level interactions.
  final String sectionKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey<String>(sectionKey),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _HomeSectionHeader(
          title: title,
          subtitle: subtitle,
          trailing: trailing,
        ),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}

class _HomeSectionHeader extends StatelessWidget {
  const _HomeSectionHeader({required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final String? normalizedSubtitle = subtitle?.trim();

    return Row(
      crossAxisAlignment: normalizedSubtitle == null
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (normalizedSubtitle != null &&
                  normalizedSubtitle.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  normalizedSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...<Widget>[
          const SizedBox(width: AppSpacing.md),
          trailing!,
        ],
      ],
    );
  }
}
