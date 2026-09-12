import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileApplicationSection extends StatefulWidget {
  const ProfileApplicationSection({super.key});

  @override
  State<ProfileApplicationSection> createState() =>
      _ProfileApplicationSectionState();
}

class _ProfileApplicationSectionState extends State<ProfileApplicationSection> {
  static final Uri _githubUri = Uri.parse(
    'https://github.com/souocare/SofaWatch',
  );

  late final Future<PackageInfo> _packageInfoFuture;

  @override
  void initState() {
    super.initState();
    _packageInfoFuture = PackageInfo.fromPlatform();
  }

  Future<void> _openGitHub() async {
    final bool opened = await launchUrl(
      _githubUri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the SofaWatch GitHub repository.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('profile-application-section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Application',
          key: const ValueKey<String>('profile-application-title'),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: AppRadius.borderLarge,
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  ClipRRect(
                    borderRadius: AppRadius.borderLarge,
                    child: Image.asset(
                      'assets/branding/sofawatch_app_icon.png',
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      semanticLabel: 'SofaWatch app icon',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'SofaWatch',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        FutureBuilder<PackageInfo>(
                          future: _packageInfoFuture,
                          builder:
                              (
                                BuildContext context,
                                AsyncSnapshot<PackageInfo> snapshot,
                              ) {
                                final TextStyle? style = Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.textSecondary);

                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Text('Loading version…', style: style);
                                }

                                if (snapshot.hasError || !snapshot.hasData) {
                                  return Text(
                                    'Version unavailable',
                                    key: const ValueKey<String>(
                                      'profile-application-version',
                                    ),
                                    style: style,
                                  );
                                }

                                final PackageInfo info = snapshot.data!;

                                return Text(
                                  'Version ${info.version} (${info.buildNumber})',
                                  key: const ValueKey<String>(
                                    'profile-application-version',
                                  ),
                                  style: style,
                                );
                              },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),
              InkWell(
                key: const ValueKey<String>('profile-application-github-link'),
                borderRadius: AppRadius.borderMedium,
                onTap: _openGitHub,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.code,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'GitHub',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'souocare/SofaWatch',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.open_in_new,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
