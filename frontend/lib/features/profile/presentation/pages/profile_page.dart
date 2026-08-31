import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/router/app_routes.dart';
import 'package:sofawatch/app/router/route_paths.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_error_message_mapper.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/core/files/json_file_picker.dart';
import 'package:sofawatch/core/widgets/section_failure_card.dart';
import 'package:sofawatch/core/widgets/server_network_image.dart';
import 'package:sofawatch/features/admin_users/application/cubit/admin_user_password_recovery_cubit.dart';
import 'package:sofawatch/features/admin_users/application/cubit/admin_user_password_recovery_state.dart';
import 'package:sofawatch/features/admin_users/application/cubit/admin_users_cubit.dart';
import 'package:sofawatch/features/admin_users/application/cubit/admin_users_state.dart';
import 'package:sofawatch/features/admin_users/application/cubit/admin_users_summary_cubit.dart';
import 'package:sofawatch/features/admin_users/application/cubit/admin_users_summary_state.dart';
import 'package:sofawatch/features/admin_users/domain/models/admin_user.dart';
import 'package:sofawatch/features/admin_users/domain/models/password_recovery_link.dart';
import 'package:sofawatch/features/admin_users/domain/repositories/admin_users_repository.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_cubit.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_state.dart';
import 'package:sofawatch/features/history/application/cubit/history_preview_cubit.dart';
import 'package:sofawatch/features/history/application/cubit/history_preview_state.dart';
import 'package:sofawatch/features/history/domain/models/history_episode_item.dart';
import 'package:sofawatch/features/history/domain/models/history_movie_item.dart';
import 'package:sofawatch/features/history/domain/models/history_preview.dart';
import 'package:sofawatch/features/library/application/cubit/library_preview_cubit.dart';
import 'package:sofawatch/features/library/application/cubit/library_preview_state.dart';
import 'package:sofawatch/features/library/domain/models/library_preview.dart';
import 'package:sofawatch/features/profile/application/cubit/data_transfer_cubit.dart';
import 'package:sofawatch/features/profile/application/cubit/data_transfer_state.dart';
import 'package:sofawatch/features/profile/application/cubit/profile_cubit.dart';
import 'package:sofawatch/features/profile/application/cubit/profile_state.dart';
import 'package:sofawatch/features/profile/application/services/open_web_app_service.dart';
import 'package:sofawatch/features/profile/domain/models/data_import_result.dart';
import 'package:sofawatch/features/profile/domain/models/profile_user.dart';
import 'package:sofawatch/features/security/application/cubit/security_settings_cubit.dart';
import 'package:sofawatch/features/security/application/cubit/security_settings_state.dart';
import 'package:sofawatch/features/security/domain/models/security_settings.dart';
import 'package:sofawatch/features/security/domain/repositories/security_settings_repository.dart';
import 'package:sofawatch/features/server/application/cubit/background_jobs_cubit.dart';
import 'package:sofawatch/features/server/application/cubit/background_jobs_state.dart';
import 'package:sofawatch/features/server/application/cubit/server_health_cubit.dart';
import 'package:sofawatch/features/server/application/cubit/server_health_state.dart';
import 'package:sofawatch/features/server/application/cubit/server_logs_cubit.dart';
import 'package:sofawatch/features/server/application/cubit/server_logs_state.dart';
import 'package:sofawatch/features/server/domain/models/background_job.dart';
import 'package:sofawatch/features/server/domain/models/server_health.dart';
import 'package:sofawatch/features/server/domain/models/server_logs.dart';
import 'package:sofawatch/features/server/domain/repositories/server_repository.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_summary_cubit.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_summary_state.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_summary.dart';

const double _profileServerMetricCardExtent = 136;

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, this.isWebOverride});

  @visibleForTesting
  final bool? isWebOverride;

  @override
  Widget build(BuildContext context) {
    final bool isWeb = isWebOverride ?? kIsWeb;
    return Scaffold(
      key: const ValueKey<String>('profile-page'),
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          key: const ValueKey<String>('profile-scroll-view'),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.mobileHorizontalPadding,
            AppSpacing.xxl,
            AppSpacing.mobileHorizontalPadding,
            AppSpacing.section,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.maxContentWidth,
              ),
              child: Column(
                key: const ValueKey<String>('profile-content'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Profile',
                    key: const ValueKey<String>('profile-page-title'),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  const _ProfileBody(),

                  const SizedBox(height: AppSpacing.xl),

                  _ProfileAccountSection(isWeb: isWeb),

                  const SizedBox(height: AppSpacing.section),

                  const _ProfileStatisticsSection(),

                  const SizedBox(height: AppSpacing.section),

                  const _ProfileLibrarySection(),

                  const SizedBox(height: AppSpacing.section),

                  const _ProfileHistorySection(),

                  if (isWeb) ...<Widget>[
                    const SizedBox(height: AppSpacing.xl),
                    const _ProfileDataTransferSection(),
                  ],

                  const SizedBox(height: AppSpacing.xl),

                  const _ProfileServerGate(),

                  const SizedBox(height: AppSpacing.xxxl),

                  const _ProfileUsersGate(),

                  const _ProfileSecurityGate(),

                  const SizedBox(height: AppSpacing.section),
                  const _ProfileSessionActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (BuildContext context, ProfileState state) {
        return switch (state) {
          ProfileInitial() || ProfileLoading() => const _ProfileLoading(),

          ProfileSuccess(:final user) => _ProfileContent(user: user),

          ProfileFailure(:final error) => _ProfileFailure(error: error),
        };
      },
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.user});

  final ProfileUser user;

  @override
  Widget build(BuildContext context) {
    return _ProfileIdentityCard(user: user);
  }
}

class _ProfileIdentityCard extends StatelessWidget {
  const _ProfileIdentityCard({required this.user});

  final ProfileUser user;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey<String>('profile-user-card'),
      color: AppColors.surfaceHigh,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderLarge,
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const ValueKey<String>('profile-edit-display-name-action'),
        onTap: () {
          _showEditDisplayName(context, user);
        },
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            children: <Widget>[
              Container(
                key: const ValueKey<String>('profile-user-avatar'),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                alignment: Alignment.center,
                child: Text(
                  _initialFor(user.displayName),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),

              const SizedBox(width: AppSpacing.lg),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      user.displayName,
                      key: const ValueKey<String>('profile-user-display-name'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    Text(
                      'SofaWatch profile',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAccountSection extends StatelessWidget {
  const _ProfileAccountSection({required this.isWeb});

  final bool isWeb;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('profile-account-section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Account',
          key: const ValueKey<String>('profile-account-title'),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.md),
        Material(
          color: AppColors.surfaceHigh,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.borderLarge,
            side: const BorderSide(color: AppColors.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: const ValueKey<String>('profile-change-password-action'),
            onTap: () {
              _showChangePassword(context);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.borderMedium,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.password_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Change password',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!isWeb) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Material(
            color: AppColors.surfaceHigh,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.borderLarge,
              side: const BorderSide(color: AppColors.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: const ValueKey<String>('profile-open-web-app'),
              onTap: () {
                _openSofaWatchWeb(context);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.borderMedium,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.language_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Open SofaWatch Web',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(
                      Icons.open_in_new_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ProfileSessionActions extends StatelessWidget {
  const _ProfileSessionActions();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      buildWhen: (AuthState previous, AuthState current) {
        return previous.runtimeType != current.runtimeType &&
            (previous is AuthLoggingOut ||
                previous is AuthLoggingOutEverywhere ||
                current is AuthLoggingOut ||
                current is AuthLoggingOutEverywhere ||
                current is AuthUnauthenticated);
      },
      builder: (BuildContext context, AuthState state) {
        final bool isLoggingOut =
            state is AuthLoggingOut || state is AuthLoggingOutEverywhere;

        return Column(
          key: const ValueKey<String>('profile-session-actions'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            OutlinedButton.icon(
              key: const ValueKey<String>('profile-logout-action'),
              onPressed: isLoggingOut
                  ? null
                  : () {
                      _confirmLogout(context);
                    },
              icon: state is AuthLoggingOut
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout_rounded),
              label: const Text('Log out'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              key: const ValueKey<String>('profile-logout-everywhere-action'),
              onPressed: isLoggingOut
                  ? null
                  : () {
                      _confirmLogoutEverywhere(context);
                    },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: state is AuthLoggingOutEverywhere
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Text('Logging out everywhere…'),
                      ],
                    )
                  : const Text('Log out everywhere'),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileStatisticsSection extends StatelessWidget {
  const _ProfileStatisticsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('profile-statistics'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Statistics',
          key: const ValueKey<String>('profile-statistics-title'),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),

        const SizedBox(height: AppSpacing.md),

        BlocBuilder<StatisticsSummaryCubit, StatisticsSummaryState>(
          builder: (BuildContext context, StatisticsSummaryState state) {
            return switch (state) {
              StatisticsSummaryInitial() ||
              StatisticsSummaryLoading() => const _ProfileStatisticsLoading(),

              StatisticsSummarySuccess(:final summary) =>
                _ProfileStatisticsContent(summary: summary),

              StatisticsSummaryFailure(:final error) => SectionFailureCard(
                failureKey: 'profile-statistics-failure',
                error: error,
                onRetry: context.read<StatisticsSummaryCubit>().retry,
              ),
            };
          },
        ),
      ],
    );
  }
}

class _ProfileStatisticsContent extends StatelessWidget {
  const _ProfileStatisticsContent({required this.summary});

  final StatisticsSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          key: const ValueKey<String>('profile-statistics-grid'),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: AppRadius.borderLarge,
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _ProfileStatisticItem(
                  cardKey: 'profile-stat-shows',
                  icon: Icons.tv_rounded,
                  value: summary.showsWatched.toString(),
                  label: 'Shows',
                ),
              ),
              const _ProfileStatisticDivider(),
              Expanded(
                child: _ProfileStatisticItem(
                  cardKey: 'profile-stat-movies',
                  icon: Icons.movie_rounded,
                  value: summary.moviesWatched.toString(),
                  label: 'Movies',
                ),
              ),
              const _ProfileStatisticDivider(),
              Expanded(
                child: _ProfileStatisticItem(
                  cardKey: 'profile-stat-episodes',
                  icon: Icons.play_circle_rounded,
                  value: summary.episodesWatched.toString(),
                  label: 'Episodes',
                ),
              ),
              const _ProfileStatisticDivider(),
              Expanded(
                child: _ProfileStatisticItem(
                  cardKey: 'profile-stat-watch-time',
                  icon: Icons.schedule_rounded,
                  value: formatProfileWatchTime(summary.watchTimeMinutes),
                  label: 'Time',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            key: const ValueKey<String>('profile-detailed-statistics-action'),
            onPressed: () {
              context.pushNamed(AppRoute.detailedStatistics.name);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xs,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'View detailed statistics →',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileStatisticItem extends StatelessWidget {
  const _ProfileStatisticItem({
    required this.cardKey,
    required this.icon,
    required this.value,
    required this.label,
  });

  final String cardKey;
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: ValueKey<String>(cardKey),
      container: true,
      label: '$label: $value',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStatisticDivider extends StatelessWidget {
  const _ProfileStatisticDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 48,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      color: AppColors.outlineVariant,
    );
  }
}

class _ProfileStatisticsLoading extends StatelessWidget {
  const _ProfileStatisticsLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('profile-statistics-loading'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: const Row(
        children: <Widget>[
          Expanded(child: _ProfileStatisticSkeleton()),
          _ProfileStatisticDivider(),
          Expanded(child: _ProfileStatisticSkeleton()),
          _ProfileStatisticDivider(),
          Expanded(child: _ProfileStatisticSkeleton()),
          _ProfileStatisticDivider(),
          Expanded(child: _ProfileStatisticSkeleton()),
        ],
      ),
    );
  }
}

class _ProfileStatisticSkeleton extends StatelessWidget {
  const _ProfileStatisticSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: AppColors.surfaceSubtle,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            width: 34,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: AppRadius.borderSmall,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            width: 42,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: AppRadius.borderSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileLoading extends StatelessWidget {
  const _ProfileLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      key: ValueKey<String>('profile-loading'),
      height: 120,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ProfileFailure extends StatelessWidget {
  const _ProfileFailure({required this.error});

  final AppException error;

  @override
  Widget build(BuildContext context) {
    final String message = AppErrorMessageMapper.map(error);

    return Container(
      key: const ValueKey<String>('profile-failure'),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            key: const ValueKey<String>('profile-retry'),
            onPressed: context.read<ProfileCubit>().retry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

String _initialFor(String displayName) {
  final String trimmed = displayName.trim();

  if (trimmed.isEmpty) {
    return '?';
  }

  return trimmed.characters.first.toUpperCase();
}

String formatProfileWatchTime(int totalMinutes) {
  if (totalMinutes <= 0) {
    return '0m';
  }

  final int days = totalMinutes ~/ (24 * 60);
  final int remainingAfterDays = totalMinutes % (24 * 60);

  final int hours = remainingAfterDays ~/ 60;
  final int minutes = remainingAfterDays % 60;

  if (days > 0) {
    if (hours > 0) {
      return '${days}d ${hours}h';
    }

    return '${days}d';
  }

  if (hours > 0) {
    if (minutes > 0) {
      return '${hours}h ${minutes}m';
    }

    return '${hours}h';
  }

  return '${minutes}m';
}

class _ProfileLibrarySection extends StatelessWidget {
  const _ProfileLibrarySection();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('profile-library'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Library',
          key: const ValueKey<String>('profile-library-title'),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),

        const SizedBox(height: AppSpacing.md),

        BlocBuilder<LibraryPreviewCubit, LibraryPreviewState>(
          builder: (BuildContext context, LibraryPreviewState state) {
            return switch (state) {
              LibraryPreviewInitial() ||
              LibraryPreviewLoading() => const _ProfileLibraryLoading(),

              LibraryPreviewSuccess(:final preview) => _ProfileLibraryContent(
                preview: preview,
              ),

              LibraryPreviewFailure(:final error) => SectionFailureCard(
                failureKey: 'profile-library-failure',
                error: error,
                onRetry: context.read<LibraryPreviewCubit>().retry,
              ),
            };
          },
        ),
      ],
    );
  }
}

class _ProfileLibraryContent extends StatelessWidget {
  const _ProfileLibraryContent({required this.preview});

  final LibraryPreview preview;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('profile-library-content'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _ProfileLibraryGroup(
          groupKey: 'profile-library-shows',
          title: 'Shows',
          totalItems: preview.totalShows,
          isEmpty: preview.shows.isEmpty,
          emptyMessage: 'No Shows in your Library yet.',
          onViewAll: () {
            context.pushNamed(
              AppRoute.libraryCollection.name,
              queryParameters: const <String, String>{'tab': 'shows'},
            );
          },
          children: preview.shows
              .map(
                (LibraryPreviewShow show) => _ProfileLibraryPoster(
                  posterKey: 'profile-library-show-${show.id}',
                  title: show.title,
                  posterUrl: show.posterUrl,
                  icon: Icons.tv_rounded,
                ),
              )
              .toList(growable: false),
        ),

        const SizedBox(height: AppSpacing.xl),

        _ProfileLibraryGroup(
          groupKey: 'profile-library-movies',
          title: 'Movies',
          totalItems: preview.totalMovies,
          isEmpty: preview.movies.isEmpty,
          emptyMessage: 'No Movies in your Library yet.',
          onViewAll: () {
            context.pushNamed(
              AppRoute.libraryCollection.name,
              queryParameters: const <String, String>{'tab': 'movies'},
            );
          },
          children: preview.movies
              .map(
                (LibraryPreviewMovie movie) => _ProfileLibraryPoster(
                  posterKey: 'profile-library-movie-${movie.id}',
                  title: movie.title,
                  posterUrl: movie.posterUrl,
                  icon: Icons.movie_rounded,
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _ProfileLibraryGroup extends StatelessWidget {
  const _ProfileLibraryGroup({
    required this.groupKey,
    required this.title,
    required this.totalItems,
    required this.isEmpty,
    required this.emptyMessage,
    required this.children,
    required this.onViewAll,
  });

  final String groupKey;
  final String title;
  final int totalItems;
  final bool isEmpty;
  final String emptyMessage;
  final List<Widget> children;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey<String>(groupKey),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                key: ValueKey<String>('$groupKey-title'),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              key: ValueKey<String>('$groupKey-view-all-header'),
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xs,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'View All ($totalItems)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (isEmpty)
          _ProfileLibraryEmpty(
            emptyKey: '$groupKey-empty',
            message: emptyMessage,
          )
        else
          SizedBox(
            key: ValueKey<String>('$groupKey-list'),
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: children.length + 1,
              separatorBuilder: (BuildContext context, int index) {
                return const SizedBox(width: AppSpacing.sm);
              },
              itemBuilder: (BuildContext context, int index) {
                if (index == children.length) {
                  return _ProfileLibraryViewAllPoster(
                    viewAllKey: '$groupKey-view-all',
                    totalItems: totalItems,
                    onTap: onViewAll,
                  );
                }

                return children[index];
              },
            ),
          ),
      ],
    );
  }
}

class _ProfileLibraryViewAllPoster extends StatelessWidget {
  const _ProfileLibraryViewAllPoster({
    required this.viewAllKey,
    required this.totalItems,
    required this.onTap,
  });

  final String viewAllKey;
  final int totalItems;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey<String>(viewAllKey),
      width: 108,
      child: Align(
        alignment: Alignment.topCenter,
        child: AspectRatio(
          aspectRatio: 2 / 3,
          child: Material(
            color: AppColors.surfaceSubtle,
            borderRadius: AppRadius.borderLarge,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.grid_view_rounded,
                        size: 22,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'View All',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '($totalItems)',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileLibraryPoster extends StatelessWidget {
  const _ProfileLibraryPoster({
    required this.posterKey,
    required this.title,
    required this.posterUrl,
    required this.icon,
  });

  final String posterKey;
  final String title;
  final String? posterUrl;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey<String>(posterKey),
      width: 108,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AspectRatio(
            aspectRatio: 2 / 3,
            child: ClipRRect(
              borderRadius: AppRadius.borderLarge,
              child: _ProfileLibraryPosterImage(
                posterUrl: posterUrl,
                icon: icon,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileLibraryPosterImage extends StatelessWidget {
  const _ProfileLibraryPosterImage({
    required this.posterUrl,
    required this.icon,
  });

  final String? posterUrl;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final String? url = posterUrl?.trim();

    if (url == null || url.isEmpty) {
      return _ProfileLibraryPosterPlaceholder(icon: icon);
    }

    return ServerNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) {
            return _ProfileLibraryPosterPlaceholder(icon: icon);
          },
    );
  }
}

class _ProfileLibraryPosterPlaceholder extends StatelessWidget {
  const _ProfileLibraryPosterPlaceholder({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceHigh,
      alignment: Alignment.center,
      child: Icon(icon, size: 28, color: AppColors.textSecondary),
    );
  }
}

class _ProfileLibraryEmpty extends StatelessWidget {
  const _ProfileLibraryEmpty({required this.emptyKey, required this.message});

  final String emptyKey;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey<String>(emptyKey),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _ProfileLibraryLoading extends StatelessWidget {
  const _ProfileLibraryLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('profile-library-loading'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _ProfileLibraryLoadingGroup(),

        const SizedBox(height: AppSpacing.xl),

        const _ProfileLibraryLoadingGroup(),
      ],
    );
  }
}

class _ProfileLibraryLoadingGroup extends StatelessWidget {
  const _ProfileLibraryLoadingGroup();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 72,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: AppRadius.borderLarge,
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            separatorBuilder: (BuildContext context, int index) {
              return const SizedBox(width: AppSpacing.sm);
            },
            itemBuilder: (BuildContext context, int index) {
              return Container(
                width: 108,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: AppRadius.borderLarge,
                  border: Border.all(color: AppColors.outlineVariant),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProfileHistorySection extends StatelessWidget {
  const _ProfileHistorySection();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('profile-history'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'History',
          key: const ValueKey<String>('profile-history-title'),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),

        const SizedBox(height: AppSpacing.md),

        BlocBuilder<HistoryPreviewCubit, HistoryPreviewState>(
          builder: (BuildContext context, HistoryPreviewState state) {
            return switch (state) {
              HistoryPreviewInitial() ||
              HistoryPreviewLoading() => const _ProfileHistoryLoading(),

              HistoryPreviewSuccess(:final preview) => _ProfileHistoryContent(
                preview: preview,
              ),

              HistoryPreviewFailure(:final error) => SectionFailureCard(
                failureKey: 'profile-history-failure',
                error: error,
                onRetry: context.read<HistoryPreviewCubit>().retry,
              ),
            };
          },
        ),
      ],
    );
  }
}

class _ProfileHistoryContent extends StatelessWidget {
  const _ProfileHistoryContent({required this.preview});

  final HistoryPreview preview;

  @override
  Widget build(BuildContext context) {
    if (preview.isEmpty) {
      return const _ProfileHistoryEmpty();
    }

    return Column(
      key: const ValueKey<String>('profile-history-content'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (preview.episodes.isNotEmpty)
          _ProfileHistoryGroup(
            groupKey: 'profile-history-episodes',
            title: 'Episodes',
            onSeeAll: () {
              context.pushNamed(
                AppRoute.history.name,
                queryParameters: const <String, String>{'type': 'episode'},
              );
            },
            children: preview.episodes
                .map(
                  (HistoryEpisodeItem item) =>
                      _ProfileEpisodeHistoryRow(item: item),
                )
                .toList(growable: false),
          ),

        if (preview.episodes.isNotEmpty && preview.movies.isNotEmpty)
          const SizedBox(height: AppSpacing.xl),

        if (preview.movies.isNotEmpty)
          _ProfileHistoryGroup(
            groupKey: 'profile-history-movies',
            title: 'Movies',
            onSeeAll: () {
              context.pushNamed(
                AppRoute.history.name,
                queryParameters: const <String, String>{'type': 'movie'},
              );
            },
            children: preview.movies
                .map(
                  (HistoryMovieItem item) =>
                      _ProfileMovieHistoryRow(item: item),
                )
                .toList(growable: false),
          ),
      ],
    );
  }
}

class _ProfileHistoryGroup extends StatelessWidget {
  const _ProfileHistoryGroup({
    required this.groupKey,
    required this.title,
    required this.children,
    required this.onSeeAll,
  });

  final String groupKey;
  final String title;
  final List<Widget> children;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey<String>(groupKey),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                key: ValueKey<String>('$groupKey-title'),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),

            TextButton(
              key: ValueKey<String>('$groupKey-see-all'),
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xs,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('See All'),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: AppRadius.borderLarge,
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Column(
            children: <Widget>[
              for (int index = 0; index < children.length; index++) ...<Widget>[
                children[index],

                if (index < children.length - 1)
                  Divider(height: 1, color: AppColors.outlineVariant),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileEpisodeHistoryRow extends StatelessWidget {
  const _ProfileEpisodeHistoryRow({required this.item});

  final HistoryEpisodeItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey<String>('profile-history-episode-${item.eventId}'),
      borderRadius: AppRadius.borderLarge,
      onTap: () {
        context.pushNamed(
          AppRoute.episodeDetails.name,
          pathParameters: <String, String>{'episodeId': item.episode.id},
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: <Widget>[
            _ProfileHistoryArtwork(
              imageUrl: item.episode.stillUrl ?? item.posterUrl,
              icon: Icons.tv_outlined,
              isPoster: false,
            ),

            const SizedBox(width: AppSpacing.md),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.showTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  Text(
                    '${item.episode.code} · ${item.episode.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  Text(
                    _formatProfileHistoryDate(item.watchedAt),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _ProfileMovieHistoryRow extends StatelessWidget {
  const _ProfileMovieHistoryRow({required this.item});

  final HistoryMovieItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey<String>('profile-history-movie-${item.eventId}'),
      borderRadius: AppRadius.borderLarge,
      onTap: () {
        context.pushNamed(
          AppRoute.movieDetails.name,
          pathParameters: <String, String>{
            'movieId': item.movieTmdbId.toString(),
          },
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: <Widget>[
            _ProfileHistoryArtwork(
              imageUrl: item.posterUrl,
              icon: Icons.movie_outlined,
              isPoster: true,
            ),

            const SizedBox(width: AppSpacing.md),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.movieTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  Text(
                    _formatProfileHistoryDate(item.watchedAt),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _ProfileHistoryArtwork extends StatelessWidget {
  const _ProfileHistoryArtwork({
    required this.imageUrl,
    required this.icon,
    required this.isPoster,
  });

  final String? imageUrl;
  final IconData icon;
  final bool isPoster;

  @override
  Widget build(BuildContext context) {
    final String? normalizedUrl = imageUrl?.trim();

    final double width = isPoster ? 42 : 72;
    final double height = isPoster ? 63 : 46;

    return ClipRRect(
      borderRadius: AppRadius.borderMedium,
      child: SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: normalizedUrl == null || normalizedUrl.isEmpty
              ? Icon(icon, size: 24, color: AppColors.textMuted)
              : ServerNetworkImage(
                  imageUrl: normalizedUrl,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (
                        BuildContext context,
                        Object error,
                        StackTrace? stackTrace,
                      ) {
                        return Icon(icon, size: 24, color: AppColors.textMuted);
                      },
                ),
        ),
      ),
    );
  }
}

class _ProfileHistoryEmpty extends StatelessWidget {
  const _ProfileHistoryEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('profile-history-empty'),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Text(
        'Your viewing History is empty.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _ProfileHistoryLoading extends StatelessWidget {
  const _ProfileHistoryLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('profile-history-loading'),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: const Column(
        children: <Widget>[
          _ProfileHistoryLoadingRow(),
          SizedBox(height: AppSpacing.sm),
          _ProfileHistoryLoadingRow(),
          SizedBox(height: AppSpacing.sm),
          _ProfileHistoryLoadingRow(),
        ],
      ),
    );
  }
}

class _ProfileHistoryLoadingRow extends StatelessWidget {
  const _ProfileHistoryLoadingRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 72,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.borderMedium,
          ),
        ),

        const SizedBox(width: AppSpacing.md),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 140,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.borderMedium,
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              Container(
                width: 100,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.borderMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Future<void> _pickDataImportFile(BuildContext context) async {
  try {
    final PickedJsonFile? file = await const WebJsonFilePicker().pick();

    if (file == null || !context.mounted) {
      return;
    }

    await context.read<DataTransferCubit>().previewImport(
      filename: file.name,
      json: file.content,
    );
  } on FormatException {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'The selected file could not be read as a valid JSON file.',
        ),
      ),
    );
  } on Object {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('The selected file could not be opened.')),
    );
  }
}

class _ProfileDataTransferSection extends StatelessWidget {
  const _ProfileDataTransferSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('profile-data-transfer'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Import / Export',
          key: const ValueKey<String>('profile-data-transfer-title'),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),

        const SizedBox(height: AppSpacing.md),

        Text(
          'Back up your SofaWatch Library and viewing History, '
          'or restore them from a previous export.',
          key: const ValueKey<String>('profile-data-transfer-description'),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),

        const SizedBox(height: AppSpacing.md),

        const _ProfileDataExportCard(),

        const SizedBox(height: AppSpacing.md),

        const _ProfileDataImportCard(),
      ],
    );
  }
}

class _ProfileDataExportCard extends StatelessWidget {
  const _ProfileDataExportCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataTransferCubit, DataTransferState>(
      builder: (BuildContext context, DataTransferState state) {
        final bool isExporting = state is DataTransferExporting;

        return Container(
          key: const ValueKey<String>('profile-data-transfer-export-card'),
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: AppRadius.borderLarge,
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Export data',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: AppSpacing.xs),

              Text(
                'Create a portable JSON backup containing your '
                'Library and viewing History.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),

              const SizedBox(height: AppSpacing.md),

              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  key: const ValueKey<String>('profile-data-transfer-export'),
                  onPressed: isExporting
                      ? null
                      : context.read<DataTransferCubit>().exportData,
                  icon: isExporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_rounded),
                  label: Text(isExporting ? 'Exporting…' : 'Export data'),
                ),
              ),

              if (state case DataTransferExportFailure(
                :final error,
              )) ...<Widget>[
                const SizedBox(height: AppSpacing.md),

                Text(
                  AppErrorMessageMapper.map(error),
                  key: const ValueKey<String>(
                    'profile-data-transfer-export-error',
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ProfileDataImportCard extends StatelessWidget {
  const _ProfileDataImportCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataTransferCubit, DataTransferState>(
      builder: (BuildContext context, DataTransferState state) {
        final bool isPreviewLoading = state is DataTransferImportPreviewLoading;

        final bool isImporting = state is DataTransferImporting;

        return Container(
          key: const ValueKey<String>('profile-data-transfer-import-card'),
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: AppRadius.borderLarge,
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Import data',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: AppSpacing.xs),

              Text(
                'Restore data from a SofaWatch JSON backup. '
                'Nothing will be changed until you confirm the import.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),

              const SizedBox(height: AppSpacing.md),

              switch (state) {
                DataTransferImportPreviewReady(
                  :final filename,
                  :final json,
                  :final preview,
                ) =>
                  _ProfileDataImportPreview(
                    filename: filename,
                    userDisplayName: preview.userDisplayName,
                    format: preview.format,
                    version: preview.version,
                    libraryShows: preview.libraryShows,
                    libraryMovies: preview.libraryMovies,
                    episodeWatchEvents: preview.episodeWatchEvents,
                    movieWatchEvents: preview.movieWatchEvents,
                    onCancel: context.read<DataTransferCubit>().reset,
                    onImport: () {
                      context.read<DataTransferCubit>().importData(json);
                    },
                  ),

                DataTransferImporting() => const _ProfileDataImportProgress(),

                DataTransferImportSuccess(:final result) =>
                  _ProfileDataImportSuccess(result: result),

                DataTransferImportPreviewFailure(
                  :final filename,
                  :final error,
                ) =>
                  _ProfileDataImportSelectionFailure(
                    filename: filename,
                    error: error,
                  ),

                DataTransferImportFailure(:final error) =>
                  _ProfileDataImportFailure(error: error),

                _ => Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    key: const ValueKey<String>(
                      'profile-data-transfer-import-select',
                    ),
                    onPressed: isPreviewLoading || isImporting
                        ? null
                        : () {
                            _pickDataImportFile(context);
                          },
                    icon: isPreviewLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file_rounded),
                    label: Text(
                      isPreviewLoading ? 'Validating…' : 'Choose backup file',
                    ),
                  ),
                ),
              },
            ],
          ),
        );
      },
    );
  }
}

class _ProfileDataImportSuccess extends StatelessWidget {
  const _ProfileDataImportSuccess({required this.result});

  final DataImportResult result;

  @override
  Widget build(BuildContext context) {
    final bool hasFailures = result.hasFailures;

    return Column(
      key: const ValueKey<String>('profile-data-transfer-import-success'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.borderMedium,
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    hasFailures
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 22,
                  ),

                  const SizedBox(width: AppSpacing.sm),

                  Expanded(
                    child: Text(
                      hasFailures
                          ? 'Import completed with some issues'
                          : 'Import completed',
                      key: const ValueKey<String>(
                        'profile-data-transfer-import-success-title',
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xs),

              Text(
                hasFailures
                    ? 'The supported data that could be restored was merged '
                          'successfully. Some items could not be imported.'
                    : 'Your SofaWatch data has been merged with the '
                          'data already stored on this server.',
                key: const ValueKey<String>(
                  'profile-data-transfer-import-success-description',
                ),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),

              const SizedBox(height: AppSpacing.lg),

              const _ProfileDataImportGroupTitle(title: 'Library'),

              const SizedBox(height: AppSpacing.sm),

              _ProfileDataImportMediaResult(
                mediaKey: 'shows',
                label: 'Shows',
                result: result.library.shows,
              ),

              const SizedBox(height: AppSpacing.sm),

              _ProfileDataImportMediaResult(
                mediaKey: 'movies',
                label: 'Movies',
                result: result.library.movies,
              ),

              const SizedBox(height: AppSpacing.lg),

              const _ProfileDataImportGroupTitle(title: 'Watch History'),

              const SizedBox(height: AppSpacing.sm),

              _ProfileDataImportHistoryResult(
                mediaKey: 'episodes',
                label: 'Episode viewings',
                result: result.history.episodes,
              ),

              const SizedBox(height: AppSpacing.sm),

              _ProfileDataImportHistoryResult(
                mediaKey: 'movies',
                label: 'Movie viewings',
                result: result.history.movies,
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            key: const ValueKey<String>('profile-data-transfer-import-another'),
            onPressed: context.read<DataTransferCubit>().reset,
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Import another backup'),
          ),
        ),
      ],
    );
  }
}

class _ProfileDataImportMediaResult extends StatelessWidget {
  const _ProfileDataImportMediaResult({
    required this.mediaKey,
    required this.label,
    required this.result,
  });

  final String mediaKey;
  final String label;
  final DataImportMediaResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey<String>(
        'profile-data-transfer-import-result-library-$mediaKey',
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: AppRadius.borderMedium,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: AppSpacing.sm),

          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              _ProfileDataImportResultValue(
                valueKey: 'library-$mediaKey-created',
                label: 'Created',
                value: result.created,
              ),

              _ProfileDataImportResultValue(
                valueKey: 'library-$mediaKey-updated',
                label: 'Updated',
                value: result.updated,
              ),

              _ProfileDataImportResultValue(
                valueKey: 'library-$mediaKey-unchanged',
                label: 'Unchanged',
                value: result.unchanged,
              ),
              if (result.failed > 0)
                _ProfileDataImportResultValue(
                  valueKey: 'library-$mediaKey-failed',
                  label: 'Failed',
                  value: result.failed,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileDataImportHistoryResult extends StatelessWidget {
  const _ProfileDataImportHistoryResult({
    required this.mediaKey,
    required this.label,
    required this.result,
  });

  final String mediaKey;
  final String label;
  final DataImportHistoryMediaResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey<String>(
        'profile-data-transfer-import-result-history-$mediaKey',
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: AppRadius.borderMedium,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: AppSpacing.sm),

          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              _ProfileDataImportResultValue(
                valueKey: 'history-$mediaKey-created',
                label: 'Imported',
                value: result.created,
              ),

              _ProfileDataImportResultValue(
                valueKey: 'history-$mediaKey-skipped',
                label: 'Already present',
                value: result.skipped,
              ),

              if (result.failed > 0)
                _ProfileDataImportResultValue(
                  valueKey: 'history-$mediaKey-failed',
                  label: 'Failed',
                  value: result.failed,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileDataImportResultValue extends StatelessWidget {
  const _ProfileDataImportResultValue({
    required this.valueKey,
    required this.label,
    required this.value,
  });

  final String valueKey;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      key: ValueKey<String>('profile-data-transfer-import-result-$valueKey'),
      TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: value.toString(),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          TextSpan(
            text: ' $label',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ProfileDataImportPreview extends StatelessWidget {
  const _ProfileDataImportPreview({
    required this.filename,
    required this.userDisplayName,
    required this.format,
    required this.version,
    required this.libraryShows,
    required this.libraryMovies,
    required this.episodeWatchEvents,
    required this.movieWatchEvents,
    required this.onCancel,
    required this.onImport,
  });

  final String filename;
  final String userDisplayName;
  final String format;
  final int version;

  final int libraryShows;
  final int libraryMovies;
  final int episodeWatchEvents;
  final int movieWatchEvents;

  final VoidCallback onCancel;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('profile-data-transfer-import-preview'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.borderMedium,
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.description_outlined, size: 20),

                  const SizedBox(width: AppSpacing.sm),

                  Expanded(
                    child: Text(
                      filename,
                      key: const ValueKey<String>(
                        'profile-data-transfer-import-filename',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                'Backup from $userDisplayName',
                key: const ValueKey<String>(
                  'profile-data-transfer-import-user',
                ),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: AppSpacing.xs),

              Text(
                '$format · Version $version',
                key: const ValueKey<String>(
                  'profile-data-transfer-import-format',
                ),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),

              const SizedBox(height: AppSpacing.lg),

              const _ProfileDataImportGroupTitle(title: 'Library'),

              const SizedBox(height: AppSpacing.sm),

              _ProfileDataImportSummaryRow(
                label: 'Shows',
                value: libraryShows,
                rowKey: 'library-shows',
              ),

              const SizedBox(height: AppSpacing.xs),

              _ProfileDataImportSummaryRow(
                label: 'Movies',
                value: libraryMovies,
                rowKey: 'library-movies',
              ),

              const SizedBox(height: AppSpacing.lg),

              const _ProfileDataImportGroupTitle(title: 'Watch History'),

              const SizedBox(height: AppSpacing.sm),

              _ProfileDataImportSummaryRow(
                label: 'Episode viewings',
                value: episodeWatchEvents,
                rowKey: 'episode-watch-events',
              ),

              const SizedBox(height: AppSpacing.xs),

              _ProfileDataImportSummaryRow(
                label: 'Movie viewings',
                value: movieWatchEvents,
                rowKey: 'movie-watch-events',
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.end,
          children: <Widget>[
            TextButton(
              key: const ValueKey<String>(
                'profile-data-transfer-import-cancel',
              ),
              onPressed: onCancel,
              child: const Text('Cancel'),
            ),

            FilledButton.icon(
              key: const ValueKey<String>(
                'profile-data-transfer-import-confirm',
              ),
              onPressed: onImport,
              icon: const Icon(Icons.restore_rounded),
              label: const Text('Import data'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileDataImportGroupTitle extends StatelessWidget {
  const _ProfileDataImportGroupTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _ProfileDataImportSummaryRow extends StatelessWidget {
  const _ProfileDataImportSummaryRow({
    required this.label,
    required this.value,
    required this.rowKey,
  });

  final String label;
  final int value;
  final String rowKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: ValueKey<String>('profile-data-transfer-import-preview-$rowKey'),
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ),

        const SizedBox(width: AppSpacing.md),

        Text(
          value.toString(),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _ProfileDataImportProgress extends StatelessWidget {
  const _ProfileDataImportProgress();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('profile-data-transfer-import-progress'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderMedium,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: const Row(
        children: <Widget>[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),

          SizedBox(width: AppSpacing.md),

          Expanded(child: Text('Importing your SofaWatch data…')),
        ],
      ),
    );
  }
}

class _ProfileDataImportSelectionFailure extends StatelessWidget {
  const _ProfileDataImportSelectionFailure({
    required this.filename,
    required this.error,
  });

  final String filename;
  final AppException error;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>(
        'profile-data-transfer-import-preview-failure',
      ),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.borderMedium,
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                filename,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: AppSpacing.sm),

              Text(
                AppErrorMessageMapper.map(error),
                key: const ValueKey<String>(
                  'profile-data-transfer-import-preview-error',
                ),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            key: const ValueKey<String>(
              'profile-data-transfer-import-select-again',
            ),
            onPressed: () {
              _pickDataImportFile(context);
            },
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Choose another file'),
          ),
        ),
      ],
    );
  }
}

class _ProfileDataImportFailure extends StatelessWidget {
  const _ProfileDataImportFailure({required this.error});

  final AppException error;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('profile-data-transfer-import-failure'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          AppErrorMessageMapper.map(error),
          key: const ValueKey<String>('profile-data-transfer-import-error'),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),

        const SizedBox(height: AppSpacing.md),

        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            key: const ValueKey<String>(
              'profile-data-transfer-import-start-over',
            ),
            onPressed: context.read<DataTransferCubit>().reset,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Start again'),
          ),
        ),
      ],
    );
  }
}

class _ProfileServerGate extends StatelessWidget {
  const _ProfileServerGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      buildWhen: (ProfileState previous, ProfileState current) {
        final bool previousIsAdmin = switch (previous) {
          ProfileSuccess(:final user) => user.isAdmin,
          _ => false,
        };

        final bool currentIsAdmin = switch (current) {
          ProfileSuccess(:final user) => user.isAdmin,
          _ => false,
        };

        return previousIsAdmin != currentIsAdmin;
      },
      builder: (BuildContext context, ProfileState state) {
        final bool isAdmin = switch (state) {
          ProfileSuccess(:final user) => user.isAdmin,
          _ => false,
        };

        if (!isAdmin) {
          return const SizedBox.shrink();
        }

        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool showDesktopDetails =
                constraints.maxWidth >= AppBreakpoints.profileFourColumns;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: AppSpacing.section),
                MultiBlocProvider(
                  providers: <BlocProvider<dynamic>>[
                    BlocProvider<BackgroundJobsCubit>(
                      create: (BuildContext context) {
                        return BackgroundJobsCubit(
                          repository: context.read<ServerRepository>(),
                        )..load();
                      },
                    ),
                    BlocProvider<ServerHealthCubit>(
                      create: (BuildContext context) {
                        return ServerHealthCubit(
                          repository: context.read<ServerRepository>(),
                        )..load();
                      },
                    ),
                    if (showDesktopDetails)
                      BlocProvider<ServerLogsCubit>(
                        create: (BuildContext context) {
                          return ServerLogsCubit(
                            repository: context.read<ServerRepository>(),
                            pageSize: 10,
                          )..load();
                        },
                      ),
                  ],
                  child: _ProfileServerSection(
                    showDesktopDetails: showDesktopDetails,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ProfileServerSection extends StatelessWidget {
  const _ProfileServerSection({required this.showDesktopDetails});

  final bool showDesktopDetails;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('profile-server'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (showDesktopDetails) ...<Widget>[
          Text(
            'Server',
            key: const ValueKey<String>('profile-server-title'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.md),
          BlocBuilder<ServerHealthCubit, ServerHealthState>(
            builder: (BuildContext context, ServerHealthState state) {
              return switch (state) {
                ServerHealthInitial() ||
                ServerHealthLoading() => const _ProfileServerLoading(),

                ServerHealthSuccess(:final health) =>
                  _ProfileServerHealthSummary(health: health),

                ServerHealthFailure(:final error) => SectionFailureCard(
                  failureKey: 'profile-server-failure',
                  error: error,
                  onRetry: context.read<ServerHealthCubit>().retry,
                ),
              };
            },
          ),
          const SizedBox(height: AppSpacing.section),
        ] else ...<Widget>[
          const _ProfileMobileServerSummary(),
          const SizedBox(height: AppSpacing.section),
        ],

        const _ProfileBackgroundJobsSection(),

        if (showDesktopDetails) ...<Widget>[
          const SizedBox(height: AppSpacing.section),
          const _ProfileServerLogsSection(),
        ],
      ],
    );
  }
}

class _ProfileMobileAdministrationRow extends StatelessWidget {
  const _ProfileMobileAdministrationRow({
    required this.rowKey,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String rowKey;
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: ValueKey<String>(rowKey),
      color: AppColors.surfaceHigh,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderLarge,
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.borderMedium,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),

            const SizedBox(width: AppSpacing.md),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            if (trailing != null) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileServerHealthSummary extends StatelessWidget {
  const _ProfileServerHealthSummary({required this.health});

  final ServerHealth health;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('profile-server-health'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _ProfileServerOverallHealthCard(health: health),

        const SizedBox(height: AppSpacing.sm),

        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool useWideLayout =
                constraints.maxWidth >= AppBreakpoints.profileFourColumns;

            return GridView.count(
              key: const ValueKey<String>('profile-server-health-grid'),
              crossAxisCount: useWideLayout ? 3 : 2,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisExtent: _profileServerMetricCardExtent,
              children: <Widget>[
                _ProfileServerMetricCard(
                  cardKey: 'profile-server-checked-at',
                  icon: Icons.update_rounded,
                  value: _formatServerCheckedAt(health.checkedAt),
                  label: 'Checked at',
                ),
                _ProfileServerMetricCard(
                  cardKey: 'profile-server-uptime',
                  icon: Icons.timer_outlined,
                  value: _formatServerUptime(health.uptimeSeconds),
                  label: 'Uptime',
                ),
                _ProfileServerMetricCard(
                  cardKey: 'profile-server-database',
                  icon: Icons.storage_rounded,
                  value: _serverComponentStatusLabel(health.database.status),
                  label: 'Database',
                  detail: _formatServerLatency(health.database.latencyMs),
                ),
                _ProfileServerMetricCard(
                  cardKey: 'profile-server-tmdb',
                  icon: Icons.cloud_outlined,
                  value: _serverComponentStatusLabel(health.tmdb.status),
                  label: 'TMDB',
                  detail: _serverTmdbDetail(health.tmdb),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.section),

        Text(
          'Database status',
          key: const ValueKey<String>('profile-server-database-title'),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),

        const SizedBox(height: AppSpacing.md),

        _ProfileServerDatabaseStatus(database: health.database),

        const SizedBox(height: AppSpacing.section),

        _ProfileServerSubsectionTitle(
          title: 'Environment',
          titleKey: 'profile-server-environment-title',
        ),

        const SizedBox(height: AppSpacing.md),

        _ProfileServerEnvironmentStatus(environment: health.environment),

        const SizedBox(height: AppSpacing.section),

        _ProfileServerSubsectionTitle(
          title: 'Storage',
          titleKey: 'profile-server-storage-title',
        ),

        const SizedBox(height: AppSpacing.md),

        _ProfileServerStorageStatus(storage: health.storage),

        const SizedBox(height: AppSpacing.section),

        _ProfileServerSubsectionTitle(
          title: 'Runtime',
          titleKey: 'profile-server-runtime-title',
        ),

        const SizedBox(height: AppSpacing.md),

        _ProfileServerRuntimeStatus(health: health),

        const SizedBox(height: AppSpacing.section),

        _ProfileServerSubsectionTitle(
          title: 'Providers',
          titleKey: 'profile-server-providers-title',
        ),

        const SizedBox(height: AppSpacing.md),

        _ProfileServerProvidersStatus(tmdb: health.tmdb),
      ],
    );
  }
}

class _ProfileServerOverallHealthCard extends StatelessWidget {
  const _ProfileServerOverallHealthCard({required this.health});

  final ServerHealth health;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('profile-server-overall-health'),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            health.isHealthy
                ? Icons.check_circle_outline_rounded
                : Icons.warning_amber_rounded,
            color: AppColors.textSecondary,
          ),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Health status',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: AppSpacing.xs),

                Text(
                  _serverHealthStatusLabel(health.status),
                  key: const ValueKey<String>('profile-server-health-status'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileServerMetricCard extends StatelessWidget {
  const _ProfileServerMetricCard({
    required this.cardKey,
    required this.icon,
    required this.value,
    required this.label,
    this.detail,
  });

  final String cardKey;
  final IconData icon;
  final String value;
  final String label;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey<String>(cardKey),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: 22, color: AppColors.textSecondary),

          const SizedBox(height: AppSpacing.sm),

          Text(
            value,
            key: ValueKey<String>('$cardKey-value'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: AppSpacing.xs),

          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),

          if (detail case final String detail) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),

            Text(
              detail,
              key: ValueKey<String>('$cardKey-detail'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileServerSubsectionTitle extends StatelessWidget {
  const _ProfileServerSubsectionTitle({
    required this.title,
    required this.titleKey,
  });

  final String title;
  final String titleKey;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      key: ValueKey<String>(titleKey),
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _ProfileServerEnvironmentStatus extends StatelessWidget {
  const _ProfileServerEnvironmentStatus({required this.environment});

  final ServerEnvironment environment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool useWideLayout =
            constraints.maxWidth >= AppBreakpoints.profileFourColumns;

        return GridView.count(
          key: const ValueKey<String>('profile-server-environment-status'),
          crossAxisCount: useWideLayout ? 3 : 2,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisExtent: _profileServerMetricCardExtent,
          children: <Widget>[
            _ProfileServerMetricCard(
              cardKey: 'profile-server-environment-name',
              icon: Icons.layers_outlined,
              value: environment.environment,
              label: 'Environment',
            ),
            _ProfileServerMetricCard(
              cardKey: 'profile-server-environment-debug',
              icon: Icons.bug_report_outlined,
              value: environment.debug ? 'Enabled' : 'Disabled',
              label: 'Debug',
            ),
            _ProfileServerMetricCard(
              cardKey: 'profile-server-environment-api',
              icon: Icons.lan_outlined,
              value: '${environment.apiHost}:${environment.apiPort}',
              label: 'API',
            ),
            _ProfileServerMetricCard(
              cardKey: 'profile-server-environment-language',
              icon: Icons.language_outlined,
              value: environment.defaultLanguage,
              label: 'Default language',
              detail: environment.supportedLanguages.join(', '),
            ),
            _ProfileServerMetricCard(
              cardKey: 'profile-server-environment-refresh',
              icon: Icons.sync_outlined,
              value: '${environment.metadataRefreshDays}d',
              label: 'Metadata refresh',
            ),
          ],
        );
      },
    );
  }
}

class _ProfileServerStorageStatus extends StatelessWidget {
  const _ProfileServerStorageStatus({required this.storage});

  final ServerStorage storage;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('profile-server-storage-status'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool useWideLayout =
                constraints.maxWidth >= AppBreakpoints.profileFourColumns;

            return GridView.count(
              key: const ValueKey<String>('profile-server-storage-grid'),
              crossAxisCount: useWideLayout ? 3 : 2,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisExtent: _profileServerMetricCardExtent,
              children: <Widget>[
                _ProfileServerMetricCard(
                  cardKey: 'profile-server-storage-directory',
                  icon: Icons.folder_outlined,
                  value: storage.dataDirectory,
                  label: 'Data directory',
                ),
                _ProfileServerMetricCard(
                  cardKey: 'profile-server-storage-writable',
                  icon: Icons.edit_outlined,
                  value: storage.writable ? 'Writable' : 'Read only',
                  label: 'Access',
                ),
                _ProfileServerMetricCard(
                  cardKey: 'profile-server-storage-total',
                  icon: Icons.sd_storage_outlined,
                  value: _formatBytes(storage.totalSpaceBytes),
                  label: 'Total space',
                ),
                _ProfileServerMetricCard(
                  cardKey: 'profile-server-storage-used',
                  icon: Icons.pie_chart_outline_rounded,
                  value: _formatBytes(storage.usedSpaceBytes),
                  label: 'Used space',
                  detail: _formatPercentage(storage.usagePercentage),
                ),
                _ProfileServerMetricCard(
                  cardKey: 'profile-server-storage-free',
                  icon: Icons.space_bar_rounded,
                  value: _formatBytes(storage.freeSpaceBytes),
                  label: 'Free space',
                ),
              ],
            );
          },
        ),

        const SizedBox(height: AppSpacing.md),

        _ProfileServerImageCacheStatus(cache: storage.imageCache),
      ],
    );
  }
}

class _ProfileServerImageCacheStatus extends StatelessWidget {
  const _ProfileServerImageCacheStatus({required this.cache});

  final ServerImageCache cache;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('profile-server-image-cache'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Image cache',
          key: const ValueKey<String>('profile-server-image-cache-title'),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),

        const SizedBox(height: AppSpacing.sm),

        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool useWideLayout =
                constraints.maxWidth >= AppBreakpoints.profileFourColumns;

            return GridView.count(
              key: const ValueKey<String>('profile-server-image-cache-grid'),
              crossAxisCount: useWideLayout ? 3 : 2,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisExtent: _profileServerMetricCardExtent,
              children: <Widget>[
                _ProfileServerMetricCard(
                  cardKey: 'profile-server-image-cache-total-size',
                  icon: Icons.photo_library_outlined,
                  value: _formatBytes(cache.totalSizeBytes),
                  label: 'Cache size',
                ),
                _ProfileServerMetricCard(
                  cardKey: 'profile-server-image-cache-total-files',
                  icon: Icons.insert_drive_file_outlined,
                  value: cache.totalFiles.toString(),
                  label: 'Files',
                ),
                _ProfileServerCacheCategoryCard(
                  cardKey: 'profile-server-image-cache-shows',
                  label: 'Shows',
                  category: cache.breakdown.shows,
                ),
                _ProfileServerCacheCategoryCard(
                  cardKey: 'profile-server-image-cache-seasons',
                  label: 'Seasons',
                  category: cache.breakdown.seasons,
                ),
                _ProfileServerCacheCategoryCard(
                  cardKey: 'profile-server-image-cache-episodes',
                  label: 'Episodes',
                  category: cache.breakdown.episodes,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ProfileServerCacheCategoryCard extends StatelessWidget {
  const _ProfileServerCacheCategoryCard({
    required this.cardKey,
    required this.label,
    required this.category,
  });

  final String cardKey;
  final String label;
  final ServerImageCacheCategory category;

  @override
  Widget build(BuildContext context) {
    return _ProfileServerMetricCard(
      cardKey: cardKey,
      icon: Icons.image_outlined,
      value: _formatBytes(category.sizeBytes),
      label: label,
      detail: '${category.files} files',
    );
  }
}

class _ProfileServerRuntimeStatus extends StatelessWidget {
  const _ProfileServerRuntimeStatus({required this.health});

  final ServerHealth health;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool useWideLayout =
            constraints.maxWidth >= AppBreakpoints.profileFourColumns;

        return GridView.count(
          key: const ValueKey<String>('profile-server-runtime-status'),
          crossAxisCount: useWideLayout ? 3 : 2,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisExtent: _profileServerMetricCardExtent,
          children: <Widget>[
            _ProfileServerMetricCard(
              cardKey: 'profile-server-runtime-python',
              icon: Icons.code_rounded,
              value: health.runtime.pythonVersion,
              label: 'Python',
            ),
            _ProfileServerMetricCard(
              cardKey: 'profile-server-runtime-platform',
              icon: Icons.computer_outlined,
              value: health.runtime.platform,
              label: 'Platform',
            ),
            _ProfileServerMetricCard(
              cardKey: 'profile-server-runtime-uptime',
              icon: Icons.timer_outlined,
              value: _formatServerUptime(health.uptimeSeconds),
              label: 'Process uptime',
            ),
            _ProfileServerMetricCard(
              cardKey: 'profile-server-runtime-started-at',
              icon: Icons.play_circle_outline_rounded,
              value: _formatServerCheckedAt(health.runtime.startedAt),
              label: 'Started at',
            ),
            _ProfileServerMetricCard(
              cardKey: 'profile-server-runtime-current-time',
              icon: Icons.schedule_rounded,
              value: _formatServerCheckedAt(health.checkedAt),
              label: 'Server current time',
            ),
          ],
        );
      },
    );
  }
}

class _ProfileServerProvidersStatus extends StatelessWidget {
  const _ProfileServerProvidersStatus({required this.tmdb});

  final ServerTmdbHealth tmdb;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool useWideLayout =
            constraints.maxWidth >= AppBreakpoints.profileFourColumns;

        return GridView.count(
          key: const ValueKey<String>('profile-server-providers-status'),
          crossAxisCount: useWideLayout ? 3 : 2,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisExtent: _profileServerMetricCardExtent,
          children: <Widget>[
            _ProfileServerMetricCard(
              cardKey: 'profile-server-provider-tmdb-configured',
              icon: Icons.settings_outlined,
              value: tmdb.configured ? 'Configured' : 'Not configured',
              label: 'TMDB configuration',
            ),
            _ProfileServerMetricCard(
              cardKey: 'profile-server-provider-tmdb-reachable',
              icon: Icons.cloud_done_outlined,
              value: tmdb.isHealthy ? 'Reachable' : 'Unavailable',
              label: 'TMDB connectivity',
            ),
            _ProfileServerMetricCard(
              cardKey: 'profile-server-provider-tmdb-latency',
              icon: Icons.speed_rounded,
              value: _formatServerLatency(tmdb.latencyMs) ?? 'Unavailable',
              label: 'TMDB latency',
            ),
          ],
        );
      },
    );
  }
}

class _ProfileServerDatabaseStatus extends StatelessWidget {
  const _ProfileServerDatabaseStatus({required this.database});

  final ServerDatabaseHealth database;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool useWideLayout =
            constraints.maxWidth >= AppBreakpoints.profileFourColumns;

        return Column(
          key: const ValueKey<String>('profile-server-database-status'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            GridView.count(
              key: const ValueKey<String>(
                'profile-server-database-status-grid',
              ),
              crossAxisCount: useWideLayout ? 3 : 2,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisExtent: _profileServerMetricCardExtent,
              children: <Widget>[
                _ProfileServerMetricCard(
                  cardKey: 'profile-server-database-engine',
                  icon: Icons.dns_rounded,
                  value: _formatDatabaseEngine(database.engine),
                  label: 'Engine',
                ),
                _ProfileServerMetricCard(
                  cardKey: 'profile-server-database-size',
                  icon: Icons.data_usage_rounded,
                  value: _formatBytes(database.sizeBytes),
                  label: 'Database size',
                ),
                _ProfileServerMetricCard(
                  cardKey: 'profile-server-database-wal-size',
                  icon: Icons.article_outlined,
                  value: _formatBytes(database.walSizeBytes),
                  label: 'WAL size',
                ),
                _ProfileServerMetricCard(
                  cardKey: 'profile-server-database-connectivity',
                  icon: Icons.link_rounded,
                  value: _serverComponentStatusLabel(database.status),
                  label: 'Connectivity',
                  detail: _formatServerLatency(database.latencyMs),
                ),
                _ProfileServerMetricCard(
                  cardKey: 'profile-server-database-integrity',
                  icon: Icons.verified_outlined,
                  value: _serverDatabaseCheckStatusLabel(
                    database.integrityCheck,
                  ),
                  label: 'Integrity check',
                ),
                _ProfileServerMetricCard(
                  cardKey: 'profile-server-database-foreign-keys',
                  icon: Icons.account_tree_outlined,
                  value: _serverDatabaseCheckStatusLabel(
                    database.foreignKeyCheck,
                  ),
                  label: 'Foreign key check',
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            _ProfileServerMigrationCard(migration: database.migration),
          ],
        );
      },
    );
  }
}

class _ProfileServerMigrationCard extends StatelessWidget {
  const _ProfileServerMigrationCard({required this.migration});

  final ServerDatabaseMigration migration;

  @override
  Widget build(BuildContext context) {
    final String revision = migration.revision ?? 'Unavailable';
    final String? message = migration.message;

    return Container(
      key: const ValueKey<String>('profile-server-database-migration'),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.schema_outlined,
            size: 22,
            color: AppColors.textSecondary,
          ),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  revision,
                  key: const ValueKey<String>(
                    'profile-server-database-migration-revision',
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),

                const SizedBox(height: AppSpacing.xs),

                Text(
                  'Migration revision',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                if (message != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xs),

                  Text(
                    message,
                    key: const ValueKey<String>(
                      'profile-server-database-migration-message',
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileBackgroundJobsSection extends StatelessWidget {
  const _ProfileBackgroundJobsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('profile-background-jobs'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _ProfileServerSubsectionTitle(
          title: 'Background jobs',
          titleKey: 'profile-background-jobs-title',
        ),

        const SizedBox(height: AppSpacing.md),

        BlocBuilder<BackgroundJobsCubit, BackgroundJobsState>(
          builder: (BuildContext context, BackgroundJobsState state) {
            return switch (state) {
              BackgroundJobsInitial() ||
              BackgroundJobsLoading() => const _ProfileBackgroundJobsLoading(),

              BackgroundJobsSuccess(
                :final jobs,
                :final runningJobKeys,
                :final runFailures,
              ) =>
                _ProfileBackgroundJobsContent(
                  jobs: jobs,
                  runningJobKeys: runningJobKeys,
                  runFailures: runFailures,
                ),

              BackgroundJobsFailure(:final error) => SectionFailureCard(
                failureKey: 'profile-background-jobs-failure',
                error: error,
                onRetry: context.read<BackgroundJobsCubit>().retry,
              ),
            };
          },
        ),
      ],
    );
  }
}

class _ProfileBackgroundJobsContent extends StatelessWidget {
  const _ProfileBackgroundJobsContent({
    required this.jobs,
    required this.runningJobKeys,
    required this.runFailures,
  });

  final List<BackgroundJob> jobs;
  final Set<String> runningJobKeys;
  final Map<String, AppException> runFailures;

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return Container(
        key: const ValueKey<String>('profile-background-jobs-empty'),
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: AppRadius.borderLarge,
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Text(
          'No background jobs are registered.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      key: const ValueKey<String>('profile-background-jobs-content'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int index = 0; index < jobs.length; index++) ...<Widget>[
          if (index > 0) const SizedBox(height: AppSpacing.sm),

          _ProfileBackgroundJobCard(
            job: jobs[index],
            isSubmitting: runningJobKeys.contains(jobs[index].key),
            runFailure: runFailures[jobs[index].key],
          ),
        ],
      ],
    );
  }
}

class _ProfileBackgroundJobCard extends StatelessWidget {
  const _ProfileBackgroundJobCard({
    required this.job,
    required this.isSubmitting,
    required this.runFailure,
  });

  final BackgroundJob job;
  final bool isSubmitting;
  final AppException? runFailure;

  @override
  Widget build(BuildContext context) {
    final bool useCompactLayout =
        MediaQuery.sizeOf(context).width < AppBreakpoints.tablet;

    if (useCompactLayout) {
      return _ProfileBackgroundJobCompactCard(
        job: job,
        isSubmitting: isSubmitting,
        runFailure: runFailure,
      );
    }

    return _ProfileBackgroundJobDesktopCard(
      job: job,
      isSubmitting: isSubmitting,
      runFailure: runFailure,
    );
  }
}

class _ProfileBackgroundJobCompactCard extends StatelessWidget {
  const _ProfileBackgroundJobCompactCard({
    required this.job,
    required this.isSubmitting,
    required this.runFailure,
  });

  final BackgroundJob job;
  final bool isSubmitting;
  final AppException? runFailure;

  @override
  Widget build(BuildContext context) {
    final bool isBusy = isSubmitting || job.isRunning;
    final bool supportsForceRefresh = job.key == 'metadata_sync';

    return Container(
      key: ValueKey<String>('profile-background-job-${job.key}'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.borderMedium,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.sync_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      job.name,
                      key: ValueKey<String>(
                        'profile-background-job-${job.key}-name',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      job.schedule,
                      key: ValueKey<String>(
                        'profile-background-job-${job.key}-schedule',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              _ProfileBackgroundJobStatus(job: job),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Last run: ${_formatBackgroundJobDate(job.lastStartedAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              SizedBox(
                height: 34,
                child: OutlinedButton(
                  key: ValueKey<String>(
                    'profile-background-job-${job.key}-run-now',
                  ),
                  onPressed: isBusy
                      ? null
                      : () {
                          context.read<BackgroundJobsCubit>().runNow(job.key);
                        },
                  child: isBusy
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              job.isRunning ? 'Running' : 'Starting',
                              key: ValueKey<String>(
                                'profile-background-job-${job.key}-run-state',
                              ),
                            ),
                          ],
                        )
                      : const Text('Run now'),
                ),
              ),
            ],
          ),

          if (supportsForceRefresh) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),

            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextButton(
                    key: ValueKey<String>(
                      'profile-background-job-${job.key}-force-refresh',
                    ),
                    onPressed: isBusy
                        ? null
                        : () {
                            _confirmForceRefresh(
                              context: context,
                              jobKey: job.key,
                            );
                          },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.xs,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Force refresh'),
                  ),

                  IconButton(
                    key: ValueKey<String>(
                      'profile-background-job-${job.key}-force-refresh-info',
                    ),
                    tooltip: 'About Force refresh',
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      _showForceRefreshInfo(context);
                    },
                    icon: const Icon(Icons.info_outline_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ],

          if (job.lastError case final String error) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),

            Text(
              error,
              key: ValueKey<String>(
                'profile-background-job-${job.key}-last-error',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],

          if (runFailure case final AppException error) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),

            Container(
              key: ValueKey<String>(
                'profile-background-job-${job.key}-run-failure',
              ),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.borderMedium,
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),

                  const SizedBox(width: AppSpacing.sm),

                  Expanded(
                    child: Text(
                      AppErrorMessageMapper.map(error),
                      key: ValueKey<String>(
                        'profile-background-job-${job.key}-run-failure-message',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileBackgroundJobDesktopCard extends StatelessWidget {
  const _ProfileBackgroundJobDesktopCard({
    required this.job,
    required this.isSubmitting,
    required this.runFailure,
  });

  final BackgroundJob job;
  final bool isSubmitting;
  final AppException? runFailure;

  @override
  Widget build(BuildContext context) {
    final BackgroundJobResultSummary? result = job.lastResult;

    return Container(
      key: ValueKey<String>('profile-background-job-${job.key}'),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool useStackedHeader =
                  constraints.maxWidth <
                  AppBreakpoints.profileBackgroundJobStack;

              final Widget identity = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    job.name,
                    key: ValueKey<String>(
                      'profile-background-job-${job.key}-name',
                    ),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  Text(
                    job.schedule,
                    key: ValueKey<String>(
                      'profile-background-job-${job.key}-schedule',
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              );

              final Widget actions = Column(
                crossAxisAlignment: useStackedHeader
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.end,
                children: <Widget>[
                  _ProfileBackgroundJobStatus(job: job),

                  const SizedBox(height: AppSpacing.sm),

                  _ProfileBackgroundJobRunAction(
                    job: job,
                    isSubmitting: isSubmitting,
                  ),
                ],
              );

              if (useStackedHeader) {
                return Column(
                  key: ValueKey<String>(
                    'profile-background-job-${job.key}-stacked-header',
                  ),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    identity,

                    const SizedBox(height: AppSpacing.md),

                    Align(alignment: Alignment.centerLeft, child: actions),
                  ],
                );
              }

              return Row(
                key: ValueKey<String>(
                  'profile-background-job-${job.key}-wide-header',
                ),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: identity),

                  const SizedBox(width: AppSpacing.md),

                  actions,
                ],
              );
            },
          ),

          const SizedBox(height: AppSpacing.md),

          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool useWideLayout =
                  constraints.maxWidth >= AppBreakpoints.profileFourColumns;

              return GridView.count(
                key: ValueKey<String>(
                  'profile-background-job-${job.key}-timing-grid',
                ),
                crossAxisCount: useWideLayout ? 3 : 2,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisExtent: _profileServerMetricCardExtent,
                children: <Widget>[
                  _ProfileServerMetricCard(
                    cardKey: 'profile-background-job-${job.key}-last-run',
                    icon: Icons.history_rounded,
                    value: _formatBackgroundJobDate(job.lastStartedAt),
                    label: 'Last run',
                  ),
                  _ProfileServerMetricCard(
                    cardKey: 'profile-background-job-${job.key}-next-run',
                    icon: Icons.schedule_rounded,
                    value: _formatBackgroundJobDate(job.nextRunAt),
                    label: 'Next run',
                  ),
                  _ProfileServerMetricCard(
                    cardKey: 'profile-background-job-${job.key}-duration',
                    icon: Icons.timer_outlined,
                    value: _formatBackgroundJobDuration(job.lastDurationMs),
                    label: 'Duration',
                  ),
                ],
              );
            },
          ),

          if (result != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),

            _ProfileBackgroundJobResultSummary(jobKey: job.key, result: result),
          ],

          if (job.lastError case final String error) ...<Widget>[
            const SizedBox(height: AppSpacing.md),

            Container(
              key: ValueKey<String>(
                'profile-background-job-${job.key}-last-error',
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.borderMedium,
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Text(
                error,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],

          if (runFailure case final AppException error) ...<Widget>[
            const SizedBox(height: AppSpacing.md),

            Container(
              key: ValueKey<String>(
                'profile-background-job-${job.key}-run-failure',
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.borderMedium,
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),

                  const SizedBox(width: AppSpacing.sm),

                  Expanded(
                    child: Text(
                      AppErrorMessageMapper.map(error),
                      key: ValueKey<String>(
                        'profile-background-job-${job.key}'
                        '-run-failure-message',
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileBackgroundJobStatus extends StatelessWidget {
  const _ProfileBackgroundJobStatus({required this.job});

  final BackgroundJob job;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: ValueKey<String>('profile-background-job-${job.key}-status'),
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (job.isRunning) ...<Widget>[
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),

          const SizedBox(width: AppSpacing.sm),
        ] else ...<Widget>[
          Icon(
            job.isHealthy
                ? Icons.check_circle_outline_rounded
                : Icons.warning_amber_rounded,
            size: 18,
            color: AppColors.textSecondary,
          ),

          const SizedBox(width: AppSpacing.sm),
        ],

        Text(
          _backgroundJobStatusLabel(job.status),
          key: ValueKey<String>(
            'profile-background-job-${job.key}-status-value',
          ),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _ProfileBackgroundJobRunAction extends StatelessWidget {
  const _ProfileBackgroundJobRunAction({
    required this.job,
    required this.isSubmitting,
  });

  final BackgroundJob job;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    final bool isBusy = isSubmitting || job.isRunning;
    final bool supportsForceRefresh = job.key == 'metadata_sync';

    return Wrap(
      key: ValueKey<String>('profile-background-job-${job.key}-run-action'),
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        SizedBox(
          height: 36,
          child: OutlinedButton(
            key: ValueKey<String>('profile-background-job-${job.key}-run-now'),
            onPressed: isBusy
                ? null
                : () {
                    context.read<BackgroundJobsCubit>().runNow(job.key);
                  },
            child: isBusy
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),

                      const SizedBox(width: AppSpacing.sm),

                      Text(
                        job.isRunning ? 'Running' : 'Starting',
                        key: ValueKey<String>(
                          'profile-background-job-${job.key}-run-state',
                        ),
                      ),
                    ],
                  )
                : const Text('Run now'),
          ),
        ),

        if (supportsForceRefresh) ...<Widget>[
          SizedBox(
            height: 36,
            child: OutlinedButton(
              key: ValueKey<String>(
                'profile-background-job-${job.key}-force-refresh',
              ),
              onPressed: isBusy
                  ? null
                  : () {
                      _confirmForceRefresh(context: context, jobKey: job.key);
                    },
              child: const Text('Force refresh'),
            ),
          ),

          IconButton(
            key: ValueKey<String>(
              'profile-background-job-${job.key}-force-refresh-info',
            ),
            tooltip: 'About Force refresh',
            onPressed: () {
              _showForceRefreshInfo(context);
            },
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ],
    );
  }
}

Future<void> _confirmForceRefresh({
  required BuildContext context,
  required String jobKey,
}) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        key: const ValueKey<String>(
          'profile-background-job-force-refresh-confirmation',
        ),
        title: const Text('Force metadata refresh?'),
        content: const Text(
          'This will ignore normal metadata freshness rules and request '
          'updated metadata for locally stored shows, seasons and episodes.\n\n'
          'This may make many requests to external providers.',
        ),
        actions: <Widget>[
          TextButton(
            key: const ValueKey<String>(
              'profile-background-job-force-refresh-cancel',
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey<String>(
              'profile-background-job-force-refresh-confirm',
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
            },
            child: const Text('Force refresh'),
          ),
        ],
      );
    },
  );

  if (confirmed != true || !context.mounted) {
    return;
  }

  await context.read<BackgroundJobsCubit>().runNow(jobKey, force: true);
}

Future<void> _showForceRefreshInfo(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        key: const ValueKey<String>(
          'profile-background-job-force-refresh-info-dialog',
        ),
        title: const Text('Force refresh'),
        content: const Text(
          'Force refresh requests fresh metadata from the configured '
          'providers even when locally stored metadata is still considered '
          'recent.\n\n'
          'It can recover newly available or previously missing metadata, '
          'including episode artwork.\n\n'
          'This operation may make significantly more provider requests and '
          'take longer than a normal sync.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

class _ProfileBackgroundJobResultSummary extends StatelessWidget {
  const _ProfileBackgroundJobResultSummary({
    required this.jobKey,
    required this.result,
  });

  final String jobKey;
  final BackgroundJobResultSummary result;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool useWideLayout =
            constraints.maxWidth >= AppBreakpoints.profileFourColumns;

        return GridView.count(
          key: ValueKey<String>('profile-background-job-$jobKey-result-grid'),
          crossAxisCount: useWideLayout ? 3 : 2,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisExtent: _profileServerMetricCardExtent,
          children: <Widget>[
            _ProfileServerMetricCard(
              cardKey: 'profile-background-job-$jobKey-checked',
              icon: Icons.fact_check_outlined,
              value: result.checked.toString(),
              label: 'Checked',
            ),
            _ProfileServerMetricCard(
              cardKey: 'profile-background-job-$jobKey-refreshed',
              icon: Icons.refresh_rounded,
              value: result.refreshed.toString(),
              label: 'Refreshed',
            ),
            _ProfileServerMetricCard(
              cardKey: 'profile-background-job-$jobKey-skipped',
              icon: Icons.skip_next_outlined,
              value: result.skipped.toString(),
              label: 'Skipped',
            ),
            _ProfileServerMetricCard(
              cardKey: 'profile-background-job-$jobKey-failed',
              icon: Icons.error_outline_rounded,
              value: result.failed.toString(),
              label: 'Failed',
            ),
          ],
        );
      },
    );
  }
}

class _ProfileBackgroundJobsLoading extends StatelessWidget {
  const _ProfileBackgroundJobsLoading();

  @override
  Widget build(BuildContext context) {
    final bool useCompactLayout =
        MediaQuery.sizeOf(context).width < AppBreakpoints.tablet;

    return Container(
      key: const ValueKey<String>('profile-background-jobs-loading'),
      height: useCompactLayout ? 96 : 180,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
    );
  }
}

class _ProfileServerLoading extends StatelessWidget {
  const _ProfileServerLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('profile-server-loading'),
      height: 88,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
    );
  }
}

class _ProfileServerLogsSection extends StatelessWidget {
  const _ProfileServerLogsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('profile-server-logs'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(
              child: _ProfileServerSubsectionTitle(
                title: 'Logs',
                titleKey: 'profile-server-logs-title',
              ),
            ),

            BlocBuilder<ServerLogsCubit, ServerLogsState>(
              buildWhen: (ServerLogsState previous, ServerLogsState current) {
                return previous != current;
              },
              builder: (BuildContext context, ServerLogsState state) {
                final bool isRefreshing = switch (state) {
                  ServerLogsSuccess(:final isRefreshing) => isRefreshing,
                  _ => false,
                };

                return IconButton(
                  key: const ValueKey<String>('profile-server-logs-refresh'),
                  tooltip: 'Refresh logs',
                  onPressed: isRefreshing
                      ? null
                      : () {
                          context.read<ServerLogsCubit>().refresh();
                        },
                  icon: isRefreshing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                );
              },
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        BlocBuilder<ServerLogsCubit, ServerLogsState>(
          builder: (BuildContext context, ServerLogsState state) {
            return switch (state) {
              ServerLogsInitial() ||
              ServerLogsLoading() => const _ProfileServerLogsLoading(),

              ServerLogsSuccess() => _ProfileServerLogsContent(state: state),

              ServerLogsFailure(:final error) => SectionFailureCard(
                failureKey: 'profile-server-logs-failure',
                error: error,
                onRetry: context.read<ServerLogsCubit>().retry,
              ),
            };
          },
        ),
      ],
    );
  }
}

class _ProfileServerLogsContent extends StatelessWidget {
  const _ProfileServerLogsContent({required this.state});

  final ServerLogsSuccess state;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('profile-server-logs-content'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _ProfileServerLogsFilter(selectedLevel: state.level),

        const SizedBox(height: AppSpacing.md),

        if (state.refreshError case final AppException error) ...<Widget>[
          _ProfileServerLogsInlineFailure(
            failureKey: 'profile-server-logs-refresh-failure',
            error: error,
            onRetry: context.read<ServerLogsCubit>().refresh,
          ),

          const SizedBox(height: AppSpacing.md),
        ],

        if (state.page.items.isEmpty)
          const _ProfileServerLogsEmpty()
        else
          _ProfileServerLogsList(logs: state.page.items),

        if (state.page.items.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.md),

          _ProfileServerLogsFooter(state: state),
        ],
      ],
    );
  }
}

class _ProfileServerLogsFilter extends StatelessWidget {
  const _ProfileServerLogsFilter({required this.selectedLevel});

  final ServerLogLevel? selectedLevel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const ValueKey<String>('profile-server-logs-filter'),
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        _ProfileServerLogFilterChip(
          filterKey: 'all',
          label: 'All',
          selected: selectedLevel == null,
          onSelected: () {
            context.read<ServerLogsCubit>().setLevel(null);
          },
        ),
        for (final ServerLogLevel level in ServerLogLevel.values)
          _ProfileServerLogFilterChip(
            filterKey: level.name,
            label: _serverLogLevelLabel(level),
            selected: selectedLevel == level,
            onSelected: () {
              context.read<ServerLogsCubit>().setLevel(level);
            },
          ),
      ],
    );
  }
}

class _ProfileServerLogFilterChip extends StatelessWidget {
  const _ProfileServerLogFilterChip({
    required this.filterKey,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String filterKey;
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      key: ValueKey<String>('profile-server-logs-filter-$filterKey'),
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        onSelected();
      },
    );
  }
}

class _ProfileServerLogsList extends StatelessWidget {
  const _ProfileServerLogsList({required this.logs});

  final List<ServerLogEntry> logs;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('profile-server-logs-list'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int index = 0; index < logs.length; index++) ...<Widget>[
          if (index > 0) const SizedBox(height: AppSpacing.sm),

          _ProfileServerLogEntryCard(entry: logs[index], index: index),
        ],
      ],
    );
  }
}

class _ProfileServerLogEntryCard extends StatelessWidget {
  const _ProfileServerLogEntryCard({required this.entry, required this.index});

  final ServerLogEntry entry;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey<String>('profile-server-log-$index'),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool useStackedHeader =
                  constraints.maxWidth < AppBreakpoints.profileLogHeaderStack;

              final Widget levelAndLogger = Row(
                children: <Widget>[
                  _ProfileServerLogLevelBadge(level: entry.level),

                  const SizedBox(width: AppSpacing.sm),

                  Expanded(
                    child: Text(
                      entry.logger,
                      key: ValueKey<String>('profile-server-log-$index-logger'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );

              final Widget timestamp = Text(
                _formatServerLogDate(entry.timestamp),
                key: ValueKey<String>('profile-server-log-$index-timestamp'),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              );

              if (useStackedHeader) {
                return Column(
                  key: ValueKey<String>(
                    'profile-server-log-$index-stacked-header',
                  ),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    levelAndLogger,

                    const SizedBox(height: AppSpacing.xs),

                    Align(alignment: Alignment.centerLeft, child: timestamp),
                  ],
                );
              }

              return Row(
                key: ValueKey<String>('profile-server-log-$index-wide-header'),
                children: <Widget>[
                  Expanded(child: levelAndLogger),

                  const SizedBox(width: AppSpacing.md),

                  timestamp,
                ],
              );
            },
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            entry.message,
            key: ValueKey<String>('profile-server-log-$index-message'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            _serverLogComponentLabel(entry.component),
            key: ValueKey<String>('profile-server-log-$index-component'),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ProfileServerLogLevelBadge extends StatelessWidget {
  const _ProfileServerLogLevelBadge({required this.level});

  final ServerLogLevel level;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey<String>('profile-server-log-level-${level.name}'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderMedium,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Text(
        _serverLogLevelLabel(level),
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _ProfileServerLogsEmpty extends StatelessWidget {
  const _ProfileServerLogsEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('profile-server-logs-empty'),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Text(
        'No logs match the selected filter.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _ProfileServerLogsFooter extends StatelessWidget {
  const _ProfileServerLogsFooter({required this.state});

  final ServerLogsSuccess state;

  @override
  Widget build(BuildContext context) {
    final int pageSize = state.page.limit;

    final int currentPage = state.page.total == 0
        ? 1
        : (state.page.offset ~/ pageSize) + 1;

    final int totalPages = state.page.total == 0
        ? 1
        : ((state.page.total + pageSize - 1) ~/ pageSize);

    final bool hasPrevious = state.page.offset > 0;
    final bool hasNext = state.page.hasNext;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            OutlinedButton(
              key: const ValueKey<String>('profile-server-logs-previous-page'),
              onPressed: !hasPrevious || state.isLoadingMore
                  ? null
                  : () {
                      context.read<ServerLogsCubit>().previousPage();
                    },
              child: const Text('Previous'),
            ),

            Expanded(
              child: Text(
                'Page $currentPage of $totalPages',
                key: const ValueKey<String>('profile-server-logs-page'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            OutlinedButton(
              key: const ValueKey<String>('profile-server-logs-next-page'),
              onPressed: !hasNext || state.isLoadingMore
                  ? null
                  : () {
                      context.read<ServerLogsCubit>().nextPage();
                    },
              child: state.isLoadingMore
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Next'),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.xs),

        Text(
          '${state.page.total} logs',
          key: const ValueKey<String>('profile-server-logs-count'),
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),

        if (state.paginationError case final AppException error) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          _ProfileServerLogsInlineFailure(
            failureKey: 'profile-server-logs-pagination-failure',
            error: error,
            onRetry: context.read<ServerLogsCubit>().retryPagination,
          ),
        ],
      ],
    );
  }
}

class _ProfileServerLogsInlineFailure extends StatelessWidget {
  const _ProfileServerLogsInlineFailure({
    required this.failureKey,
    required this.error,
    required this.onRetry,
  });

  final String failureKey;
  final AppException error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey<String>(failureKey),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderMedium,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: AppColors.textSecondary,
          ),

          const SizedBox(width: AppSpacing.sm),

          Expanded(
            child: Text(
              AppErrorMessageMapper.map(error),
              key: ValueKey<String>('$failureKey-message'),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          TextButton(
            key: ValueKey<String>('$failureKey-retry'),
            onPressed: () {
              onRetry();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _ProfileUsersGate extends StatelessWidget {
  const _ProfileUsersGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      buildWhen: (ProfileState previous, ProfileState current) {
        final bool previousIsAdmin = switch (previous) {
          ProfileSuccess(:final user) => user.isAdmin,
          _ => false,
        };

        final bool currentIsAdmin = switch (current) {
          ProfileSuccess(:final user) => user.isAdmin,
          _ => false,
        };

        return previousIsAdmin != currentIsAdmin;
      },
      builder: (BuildContext context, ProfileState state) {
        final bool isAdmin = switch (state) {
          ProfileSuccess(:final user) => user.isAdmin,
          _ => false,
        };

        if (!isAdmin) {
          return const SizedBox.shrink();
        }

        final bool useDesktopLayout =
            MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;

        if (!useDesktopLayout) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.section),
            child: BlocProvider<AdminUsersSummaryCubit>(
              create: (BuildContext context) {
                return AdminUsersSummaryCubit(
                  repository: context.read<AdminUsersRepository>(),
                )..load();
              },
              child: const _ProfileMobileUsersSection(),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.section),
          child: BlocProvider<AdminUsersCubit>(
            create: (BuildContext context) {
              return AdminUsersCubit(
                repository: context.read<AdminUsersRepository>(),
              )..load();
            },
            child: const _ProfileUsersSection(),
          ),
        );
      },
    );
  }
}

class _ProfileMobileUsersSection extends StatelessWidget {
  const _ProfileMobileUsersSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminUsersSummaryCubit, AdminUsersSummaryState>(
      builder: (BuildContext context, AdminUsersSummaryState state) {
        return switch (state) {
          AdminUsersSummaryInitial() ||
          AdminUsersSummaryLoading() => const _ProfileMobileAdministrationRow(
            rowKey: 'profile-users-mobile-summary',
            icon: Icons.people_outline_rounded,
            title: 'Users',
            subtitle: 'Loading users…',
            trailing: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),

          AdminUsersSummarySuccess(:final summary) =>
            _ProfileMobileAdministrationRow(
              rowKey: 'profile-users-mobile-summary',
              icon: Icons.people_outline_rounded,
              title: 'Users',
              subtitle: _formatUsersSummary(
                total: summary.total,
                active: summary.active,
                admins: summary.admins,
              ),
            ),

          AdminUsersSummaryFailure(:final error) =>
            _ProfileMobileAdministrationRow(
              rowKey: 'profile-users-mobile-summary',
              icon: Icons.people_outline_rounded,
              title: 'Users',
              subtitle: AppErrorMessageMapper.map(error),
              trailing: TextButton(
                key: const ValueKey<String>('profile-users-mobile-retry'),
                onPressed: context.read<AdminUsersSummaryCubit>().retry,
                child: const Text('Retry'),
              ),
            ),
        };
      },
    );
  }
}

class _ProfileUsersSection extends StatelessWidget {
  const _ProfileUsersSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('profile-users'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Users',
          key: const ValueKey<String>('profile-users-title'),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),

        const SizedBox(height: AppSpacing.md),

        BlocBuilder<AdminUsersCubit, AdminUsersState>(
          builder: (BuildContext context, AdminUsersState state) {
            return switch (state) {
              AdminUsersInitial() ||
              AdminUsersLoading() => const _ProfileUsersLoading(),

              AdminUsersSuccess(:final users) => _ProfileUsersContent(
                users: users,
              ),

              AdminUsersFailure(:final error) => SectionFailureCard(
                failureKey: 'profile-users-failure',
                error: error,
                onRetry: context.read<AdminUsersCubit>().retry,
              ),
            };
          },
        ),
      ],
    );
  }
}

class _ProfileUsersLoading extends StatelessWidget {
  const _ProfileUsersLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('profile-users-loading'),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: const Row(
        children: <Widget>[
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: AppSpacing.lg),
          Expanded(child: Text('Loading users…')),
        ],
      ),
    );
  }
}

class _ProfileUsersContent extends StatelessWidget {
  const _ProfileUsersContent({required this.users});

  final List<AdminUser> users;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Container(
        key: const ValueKey<String>('profile-users-empty'),
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: AppRadius.borderLarge,
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: const Text('No SofaWatch users were found.'),
      );
    }

    return Column(
      key: const ValueKey<String>('profile-users-content'),
      children: users
          .map(
            (AdminUser user) => Padding(
              padding: EdgeInsets.only(
                bottom: user == users.last ? 0 : AppSpacing.sm,
              ),
              child: _ProfileUserManagementCard(user: user),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _ProfileUserManagementCard extends StatelessWidget {
  const _ProfileUserManagementCard({required this.user});

  final AdminUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey<String>('profile-user-management-${user.id}'),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      user.displayName,
                      key: ValueKey<String>(
                        'profile-user-management-name-${user.id}',
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    if (user.username != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '@${user.username}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],

                    if (user.email != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        user.email!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              _ProfileUserStatusBadge(user: user),
            ],
          ),

          if (!user.isAdmin) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),

            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                key: ValueKey<String>(
                  'profile-user-password-recovery-${user.id}',
                ),
                onPressed: user.isActive
                    ? () {
                        _showUserPasswordRecovery(context, user);
                      }
                    : null,
                icon: const Icon(Icons.key_rounded, size: 18),
                label: const Text('Generate recovery link'),
              ),
            ),

            if (!user.isActive) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),

              Text(
                'Password recovery is unavailable while this account is inactive.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ProfileUserStatusBadge extends StatelessWidget {
  const _ProfileUserStatusBadge({required this.user});

  final AdminUser user;

  @override
  Widget build(BuildContext context) {
    final String label = switch ((user.isAdmin, user.isActive)) {
      (true, true) => 'Administrator',
      (true, false) => 'Administrator · Inactive',
      (false, true) => 'Active',
      (false, false) => 'Inactive',
    };

    return Container(
      key: ValueKey<String>('profile-user-status-${user.id}'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderMedium,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: user.isActive
              ? AppColors.textPrimary
              : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _ProfileSecurityGate extends StatelessWidget {
  const _ProfileSecurityGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      buildWhen: (ProfileState previous, ProfileState current) {
        final bool previousIsAdmin = switch (previous) {
          ProfileSuccess(:final user) => user.isAdmin,
          _ => false,
        };

        final bool currentIsAdmin = switch (current) {
          ProfileSuccess(:final user) => user.isAdmin,
          _ => false,
        };

        return previousIsAdmin != currentIsAdmin;
      },
      builder: (BuildContext context, ProfileState state) {
        final bool isAdmin = switch (state) {
          ProfileSuccess(:final user) => user.isAdmin,
          _ => false,
        };

        if (!isAdmin) {
          return const SizedBox.shrink();
        }

        final bool useDesktopLayout =
            MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.section),
          child: BlocProvider<SecuritySettingsCubit>(
            create: (BuildContext context) {
              return SecuritySettingsCubit(
                repository: context.read<SecuritySettingsRepository>(),
              )..load();
            },
            child: useDesktopLayout
                ? const _ProfileSecuritySection()
                : const _ProfileMobileSecuritySection(),
          ),
        );
      },
    );
  }
}

class _ProfileMobileSecuritySection extends StatelessWidget {
  const _ProfileMobileSecuritySection();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SecuritySettingsCubit, SecuritySettingsState>(
      listenWhen:
          (SecuritySettingsState previous, SecuritySettingsState current) {
            final AppException? previousError = switch (previous) {
              SecuritySettingsSuccess(:final updateError) => updateError,
              _ => null,
            };

            final AppException? currentError = switch (current) {
              SecuritySettingsSuccess(:final updateError) => updateError,
              _ => null,
            };

            return previousError != currentError && currentError != null;
          },
      listener: (BuildContext context, SecuritySettingsState state) {
        final AppException? error = switch (state) {
          SecuritySettingsSuccess(:final updateError) => updateError,
          _ => null,
        };

        if (error == null) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppErrorMessageMapper.map(error))),
        );

        context.read<SecuritySettingsCubit>().clearUpdateError();
      },
      builder: (BuildContext context, SecuritySettingsState state) {
        return switch (state) {
          SecuritySettingsInitial() ||
          SecuritySettingsLoading() => const _ProfileMobileAdministrationRow(
            rowKey: 'profile-security-mobile-summary',
            icon: Icons.security_rounded,
            title: 'Security',
            subtitle: 'Loading registration settings…',
            trailing: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),

          SecuritySettingsSuccess(:final settings, :final isUpdating) =>
            _ProfileMobileAdministrationRow(
              rowKey: 'profile-security-mobile-summary',
              icon: Icons.security_rounded,
              title: 'Security',
              subtitle: settings.openRegistration
                  ? 'Registration open'
                  : 'Registration closed',
              trailing: Switch(
                key: const ValueKey<String>(
                  'profile-security-mobile-open-registration',
                ),
                value: settings.openRegistration,
                onChanged: isUpdating
                    ? null
                    : context.read<SecuritySettingsCubit>().setOpenRegistration,
              ),
            ),

          SecuritySettingsFailure(:final error) =>
            _ProfileMobileSecurityFailure(error: error),
        };
      },
    );
  }
}

class _ProfileMobileSecurityFailure extends StatelessWidget {
  const _ProfileMobileSecurityFailure({required this.error});

  final AppException error;

  @override
  Widget build(BuildContext context) {
    return _ProfileMobileAdministrationRow(
      rowKey: 'profile-security-mobile-summary',
      icon: Icons.security_rounded,
      title: 'Security',
      subtitle: AppErrorMessageMapper.map(error),
      trailing: TextButton(
        key: const ValueKey<String>('profile-security-mobile-retry'),
        onPressed: context.read<SecuritySettingsCubit>().retry,
        child: const Text('Retry'),
      ),
    );
  }
}

class _ProfileSecuritySection extends StatelessWidget {
  const _ProfileSecuritySection();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('profile-security'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Security',
          key: const ValueKey<String>('profile-security-title'),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),

        const SizedBox(height: AppSpacing.md),

        BlocConsumer<SecuritySettingsCubit, SecuritySettingsState>(
          listenWhen:
              (SecuritySettingsState previous, SecuritySettingsState current) {
                final AppException? previousError = switch (previous) {
                  SecuritySettingsSuccess(:final updateError) => updateError,
                  _ => null,
                };

                final AppException? currentError = switch (current) {
                  SecuritySettingsSuccess(:final updateError) => updateError,
                  _ => null,
                };

                return previousError != currentError && currentError != null;
              },
          listener: (BuildContext context, SecuritySettingsState state) {
            final AppException? error = switch (state) {
              SecuritySettingsSuccess(:final updateError) => updateError,
              _ => null,
            };

            if (error == null) {
              return;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppErrorMessageMapper.map(error))),
            );

            context.read<SecuritySettingsCubit>().clearUpdateError();
          },
          builder: (BuildContext context, SecuritySettingsState state) {
            return switch (state) {
              SecuritySettingsInitial() ||
              SecuritySettingsLoading() => const _ProfileSecurityLoading(),

              SecuritySettingsSuccess(:final settings, :final isUpdating) =>
                _ProfileSecurityContent(
                  settings: settings,
                  isUpdating: isUpdating,
                ),

              SecuritySettingsFailure(:final error) => SectionFailureCard(
                failureKey: 'profile-security-failure',
                error: error,
                onRetry: context.read<SecuritySettingsCubit>().retry,
              ),
            };
          },
        ),
      ],
    );
  }
}

class _ProfileSecurityLoading extends StatelessWidget {
  const _ProfileSecurityLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('profile-security-loading'),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: const Row(
        children: <Widget>[
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),

          SizedBox(width: AppSpacing.lg),

          Expanded(child: Text('Loading Security settings…')),
        ],
      ),
    );
  }
}

class _ProfileSecurityContent extends StatelessWidget {
  const _ProfileSecurityContent({
    required this.settings,
    required this.isUpdating,
  });

  final SecuritySettings settings;
  final bool isUpdating;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey<String>('profile-security-settings-card'),
      color: AppColors.surfaceHigh,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderLarge,
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        key: const ValueKey<String>('profile-security-open-registration'),
        value: settings.openRegistration,
        onChanged: isUpdating
            ? null
            : (bool value) {
                context.read<SecuritySettingsCubit>().setOpenRegistration(
                  value,
                );
              },
        title: Text(
          'Open registration',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          'Allow new users to create a SofaWatch account from the sign-in screen.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        secondary: isUpdating
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.person_add_alt_1_outlined),
      ),
    );
  }
}

class _ProfileServerLogsLoading extends StatelessWidget {
  const _ProfileServerLogsLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('profile-server-logs-loading'),
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
    );
  }
}

String _serverHealthStatusLabel(ServerHealthStatus status) {
  return switch (status) {
    ServerHealthStatus.healthy => 'Healthy',
    ServerHealthStatus.degraded => 'Degraded',
    ServerHealthStatus.unavailable => 'Unavailable',
  };
}

String _serverComponentStatusLabel(ServerComponentStatus status) {
  return switch (status) {
    ServerComponentStatus.healthy => 'Healthy',
    ServerComponentStatus.unavailable => 'Unavailable',
  };
}

String _formatServerCheckedAt(DateTime value) {
  final DateTime local = value.toLocal();

  final String day = local.day.toString().padLeft(2, '0');
  final String month = local.month.toString().padLeft(2, '0');
  final String year = local.year.toString().padLeft(4, '0');

  final String hour = local.hour.toString().padLeft(2, '0');
  final String minute = local.minute.toString().padLeft(2, '0');

  return '$day/$month/$year · $hour:$minute';
}

String _formatServerUptime(int seconds) {
  final Duration duration = Duration(seconds: seconds);

  final int days = duration.inDays;
  final int hours = duration.inHours.remainder(24);
  final int minutes = duration.inMinutes.remainder(60);

  if (days > 0) {
    return hours > 0 ? '${days}d ${hours}h' : '${days}d';
  }

  if (hours > 0) {
    return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
  }

  if (minutes > 0) {
    return '${minutes}m';
  }

  return '${duration.inSeconds}s';
}

String? _formatServerLatency(double? latencyMs) {
  if (latencyMs == null) {
    return null;
  }

  final String formatted = latencyMs == latencyMs.roundToDouble()
      ? latencyMs.toStringAsFixed(0)
      : latencyMs.toStringAsFixed(1);

  return '$formatted ms';
}

String _serverTmdbDetail(ServerTmdbHealth tmdb) {
  if (!tmdb.configured) {
    return 'Not configured';
  }

  return _formatServerLatency(tmdb.latencyMs) ?? 'Configured';
}

String _formatProfileHistoryDate(DateTime value) {
  final DateTime local = value.toLocal();

  final String day = local.day.toString().padLeft(2, '0');
  final String month = local.month.toString().padLeft(2, '0');
  final String year = local.year.toString().padLeft(4, '0');

  final String hour = local.hour.toString().padLeft(2, '0');
  final String minute = local.minute.toString().padLeft(2, '0');

  return '$day/$month/$year · $hour:$minute';
}

String _serverDatabaseCheckStatusLabel(ServerDatabaseCheckStatus status) {
  return switch (status) {
    ServerDatabaseCheckStatus.ok => 'OK',
    ServerDatabaseCheckStatus.failed => 'Failed',
    ServerDatabaseCheckStatus.unavailable => 'Unavailable',
  };
}

String _formatDatabaseEngine(String engine) {
  return switch (engine.toLowerCase()) {
    'sqlite' => 'SQLite',
    _ => engine,
  };
}

String _formatBytes(int? bytes) {
  if (bytes == null) {
    return 'Unavailable';
  }

  const int kilobyte = 1024;
  const int megabyte = kilobyte * 1024;
  const int gigabyte = megabyte * 1024;

  if (bytes >= gigabyte) {
    return '${(bytes / gigabyte).toStringAsFixed(1)} GB';
  }

  if (bytes >= megabyte) {
    return '${(bytes / megabyte).toStringAsFixed(1)} MB';
  }

  if (bytes >= kilobyte) {
    return '${(bytes / kilobyte).toStringAsFixed(1)} KB';
  }

  return '$bytes B';
}

String _formatPercentage(double? value) {
  if (value == null) {
    return 'Unavailable';
  }

  final String formatted = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);

  return '$formatted%';
}

String _backgroundJobStatusLabel(BackgroundJobStatus status) {
  return switch (status) {
    BackgroundJobStatus.idle => 'Idle',
    BackgroundJobStatus.running => 'Running',
    BackgroundJobStatus.success => 'Success',
    BackgroundJobStatus.failed => 'Failed',
  };
}

String _formatBackgroundJobDate(DateTime? value) {
  if (value == null) {
    return '—';
  }

  return _formatServerCheckedAt(value);
}

String _formatBackgroundJobDuration(int? milliseconds) {
  if (milliseconds == null) {
    return '—';
  }

  if (milliseconds < 1000) {
    return '${milliseconds}ms';
  }

  final double seconds = milliseconds / 1000;

  if (seconds < 60) {
    final String formatted = seconds >= 10
        ? seconds.toStringAsFixed(0)
        : seconds.toStringAsFixed(1);

    return '${formatted}s';
  }

  final Duration duration = Duration(milliseconds: milliseconds);

  final int minutes = duration.inMinutes;
  final int secondsRemaining = duration.inSeconds.remainder(60);

  if (secondsRemaining == 0) {
    return '${minutes}m';
  }

  return '${minutes}m ${secondsRemaining}s';
}

String _serverLogLevelLabel(ServerLogLevel level) {
  return switch (level) {
    ServerLogLevel.debug => 'Debug',
    ServerLogLevel.info => 'Info',
    ServerLogLevel.warning => 'Warning',
    ServerLogLevel.error => 'Error',
    ServerLogLevel.critical => 'Critical',
  };
}

String _serverLogComponentLabel(ServerLogComponent component) {
  return switch (component) {
    ServerLogComponent.api => 'API',
    ServerLogComponent.worker => 'Worker',
  };
}

String _formatServerLogDate(DateTime value) {
  final DateTime local = value.toLocal();

  final String day = local.day.toString().padLeft(2, '0');

  final String month = local.month.toString().padLeft(2, '0');

  final String hour = local.hour.toString().padLeft(2, '0');

  final String minute = local.minute.toString().padLeft(2, '0');

  final String second = local.second.toString().padLeft(2, '0');

  return '$day/$month · $hour:$minute:$second';
}

Future<void> _openSofaWatchWeb(BuildContext context) async {
  final bool opened = await context.read<OpenWebAppService>().open();

  if (!context.mounted || opened) {
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('SofaWatch Web could not be opened.')),
  );
}

Future<void> _confirmLogout(BuildContext context) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        key: const ValueKey<String>('profile-logout-dialog'),
        title: const Text('Log out?'),
        content: const Text(
          'You will be signed out of SofaWatch on this device.',
        ),
        actions: <Widget>[
          TextButton(
            key: const ValueKey<String>('profile-logout-cancel'),
            onPressed: () {
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey<String>('profile-logout-confirm'),
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
            },
            child: const Text('Log out'),
          ),
        ],
      );
    },
  );

  if (confirmed != true || !context.mounted) {
    return;
  }

  await context.read<AuthCubit>().logout();
}

Future<void> _confirmLogoutEverywhere(BuildContext context) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        key: const ValueKey<String>('profile-logout-everywhere-dialog'),
        title: const Text('Log out everywhere?'),
        content: const Text(
          'This will end all active SofaWatch sessions on every device, '
          'including this one.',
        ),
        actions: <Widget>[
          TextButton(
            key: const ValueKey<String>('profile-logout-everywhere-cancel'),
            onPressed: () {
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey<String>('profile-logout-everywhere-confirm'),
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
            },
            child: const Text('Log out everywhere'),
          ),
        ],
      );
    },
  );

  if (confirmed != true || !context.mounted) {
    return;
  }

  await context.read<AuthCubit>().logoutEverywhere();
}

Future<void> _showEditDisplayName(
  BuildContext context,
  ProfileUser user,
) async {
  final bool useDialog =
      MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;

  if (useDialog) {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return BlocProvider<ProfileCubit>.value(
          value: context.read<ProfileCubit>(),
          child: _EditDisplayNameDialog(currentDisplayName: user.displayName),
        );
      },
    );

    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext sheetContext) {
      return BlocProvider<ProfileCubit>.value(
        value: context.read<ProfileCubit>(),
        child: _EditDisplayNameSheet(currentDisplayName: user.displayName),
      );
    },
  );
}

Future<void> _showChangePassword(BuildContext context) async {
  final bool useDialog =
      MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;

  if (useDialog) {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return BlocProvider<ProfileCubit>.value(
          value: context.read<ProfileCubit>(),
          child: const _ChangePasswordDialog(),
        );
      },
    );

    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext sheetContext) {
      return BlocProvider<ProfileCubit>.value(
        value: context.read<ProfileCubit>(),
        child: const _ChangePasswordSheet(),
      );
    },
  );
}

Future<void> _showUserPasswordRecovery(
  BuildContext context,
  AdminUser user,
) async {
  final AdminUsersRepository repository = context.read<AdminUsersRepository>();

  final ApiClient apiClient = context.read<ApiClient>();

  await showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return BlocProvider<AdminUserPasswordRecoveryCubit>(
        create: (_) {
          return AdminUserPasswordRecoveryCubit(repository: repository)
            ..start(userId: user.id);
        },
        child: _AdminUserPasswordRecoveryDialog(
          user: user,
          apiClient: apiClient,
        ),
      );
    },
  );
}

String _buildPasswordRecoveryUrl({
  required ApiClient apiClient,
  required String token,
}) {
  final Uri? serverUri = apiClient.serverUri;

  if (serverUri == null) {
    throw StateError(
      'Cannot build a password recovery URL without a configured server.',
    );
  }

  return serverUri
      .resolve(RoutePaths.passwordRecovery)
      .replace(queryParameters: <String, String>{'token': token})
      .toString();
}

String _formatPasswordRecoveryExpiration(DateTime value) {
  final DateTime local = value.toLocal();

  final String day = local.day.toString().padLeft(2, '0');

  final String month = local.month.toString().padLeft(2, '0');

  final String hour = local.hour.toString().padLeft(2, '0');

  final String minute = local.minute.toString().padLeft(2, '0');

  return '$day/$month/${local.year} at $hour:$minute';
}

class _EditDisplayNameDialog extends StatelessWidget {
  const _EditDisplayNameDialog({required this.currentDisplayName});

  final String currentDisplayName;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const ValueKey<String>('profile-edit-display-name-dialog'),
      title: const Text('Edit display name'),
      content: SizedBox(
        width: 420,
        child: _EditDisplayNameForm(currentDisplayName: currentDisplayName),
      ),
    );
  }
}

class _EditDisplayNameSheet extends StatelessWidget {
  const _EditDisplayNameSheet({required this.currentDisplayName});

  final String currentDisplayName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey<String>('profile-edit-display-name-sheet'),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.xl,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Edit display name',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: AppSpacing.xl),

          _EditDisplayNameForm(currentDisplayName: currentDisplayName),
        ],
      ),
    );
  }
}

class _EditDisplayNameForm extends StatefulWidget {
  const _EditDisplayNameForm({required this.currentDisplayName});

  final String currentDisplayName;

  @override
  State<_EditDisplayNameForm> createState() {
    return _EditDisplayNameFormState();
  }
}

class _EditDisplayNameFormState extends State<_EditDisplayNameForm> {
  late final TextEditingController _controller;

  String? _validationError;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.currentDisplayName);
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  Future<void> _submit() async {
    final String displayName = _controller.text.trim();

    if (displayName.isEmpty) {
      setState(() {
        _validationError = 'Display name is required.';
      });

      return;
    }

    if (displayName.length > 100) {
      setState(() {
        _validationError = 'Display name must be 100 characters or fewer.';
      });

      return;
    }

    if (displayName == widget.currentDisplayName) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _validationError = null;
    });

    final bool updated = await context.read<ProfileCubit>().updateDisplayName(
      displayName,
    );

    if (!mounted) {
      return;
    }

    if (updated) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listenWhen: (ProfileState previous, ProfileState current) {
        final AppException? previousError = switch (previous) {
          ProfileSuccess(:final updateDisplayNameError) =>
            updateDisplayNameError,
          _ => null,
        };

        final AppException? currentError = switch (current) {
          ProfileSuccess(:final updateDisplayNameError) =>
            updateDisplayNameError,
          _ => null,
        };

        return previousError != currentError && currentError != null;
      },
      listener: (BuildContext context, ProfileState state) {
        final AppException? error = switch (state) {
          ProfileSuccess(:final updateDisplayNameError) =>
            updateDisplayNameError,
          _ => null,
        };

        if (error == null) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppErrorMessageMapper.map(error))),
        );

        context.read<ProfileCubit>().clearUpdateDisplayNameError();
      },
      builder: (BuildContext context, ProfileState state) {
        final bool isUpdating = switch (state) {
          ProfileSuccess(:final isUpdatingDisplayName) => isUpdatingDisplayName,
          _ => false,
        };

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              key: const ValueKey<String>('profile-edit-display-name-field'),
              controller: _controller,
              autofocus: true,
              enabled: !isUpdating,
              textInputAction: TextInputAction.done,
              maxLength: 100,
              onChanged: (_) {
                if (_validationError == null) {
                  return;
                }

                setState(() {
                  _validationError = null;
                });
              },
              onSubmitted: (_) {
                if (!isUpdating) {
                  _submit();
                }
              },
              decoration: InputDecoration(
                labelText: 'Display name',
                errorText: _validationError,
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                  key: const ValueKey<String>(
                    'profile-edit-display-name-cancel',
                  ),
                  onPressed: isUpdating
                      ? null
                      : () {
                          Navigator.of(context).pop();
                        },
                  child: const Text('Cancel'),
                ),

                const SizedBox(width: AppSpacing.sm),

                FilledButton(
                  key: const ValueKey<String>('profile-edit-display-name-save'),
                  onPressed: isUpdating ? null : _submit,
                  child: isUpdating
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: AppSpacing.sm),
                            Text('Saving…'),
                          ],
                        )
                      : const Text('Save'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ChangePasswordDialog extends StatelessWidget {
  const _ChangePasswordDialog();

  @override
  Widget build(BuildContext context) {
    return const AlertDialog(
      key: ValueKey<String>('profile-change-password-dialog'),
      title: Text('Change password'),
      content: SizedBox(width: 420, child: _ChangePasswordForm()),
    );
  }
}

class _ChangePasswordSheet extends StatelessWidget {
  const _ChangePasswordSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey<String>('profile-change-password-sheet'),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.xl,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Change password',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: AppSpacing.xl),

          const _ChangePasswordForm(),
        ],
      ),
    );
  }
}

class _ChangePasswordForm extends StatefulWidget {
  const _ChangePasswordForm();

  @override
  State<_ChangePasswordForm> createState() {
    return _ChangePasswordFormState();
  }
}

class _ChangePasswordFormState extends State<_ChangePasswordForm> {
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();

    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  Future<void> _submit() async {
    final String currentPassword = _currentPasswordController.text;

    final String newPassword = _newPasswordController.text;

    final String confirmPassword = _confirmPasswordController.text;

    String? currentPasswordError;
    String? newPasswordError;
    String? confirmPasswordError;

    if (currentPassword.isEmpty) {
      currentPasswordError = 'Current password is required.';
    }

    if (newPassword.length < 8) {
      newPasswordError = 'New password must be at least 8 characters.';
    } else if (newPassword.length > 128) {
      newPasswordError = 'New password must be 128 characters or fewer.';
    }

    if (confirmPassword.isEmpty) {
      confirmPasswordError = 'Please confirm your new password.';
    } else if (confirmPassword != newPassword) {
      confirmPasswordError = 'Passwords do not match.';
    }

    if (currentPasswordError != null ||
        newPasswordError != null ||
        confirmPasswordError != null) {
      setState(() {
        _currentPasswordError = currentPasswordError;
        _newPasswordError = newPasswordError;
        _confirmPasswordError = confirmPasswordError;
      });

      return;
    }

    setState(() {
      _currentPasswordError = null;
      _newPasswordError = null;
      _confirmPasswordError = null;
    });

    final bool updated = await context.read<ProfileCubit>().updatePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );

    if (!mounted) {
      return;
    }

    if (updated) {
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully.')),
      );
    }
  }

  void _clearValidation() {
    if (_currentPasswordError == null &&
        _newPasswordError == null &&
        _confirmPasswordError == null) {
      return;
    }

    setState(() {
      _currentPasswordError = null;
      _newPasswordError = null;
      _confirmPasswordError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listenWhen: (ProfileState previous, ProfileState current) {
        final AppException? previousError = switch (previous) {
          ProfileSuccess(:final updatePasswordError) => updatePasswordError,
          _ => null,
        };

        final AppException? currentError = switch (current) {
          ProfileSuccess(:final updatePasswordError) => updatePasswordError,
          _ => null,
        };

        return previousError != currentError && currentError != null;
      },
      listener: (BuildContext context, ProfileState state) {
        final AppException? error = switch (state) {
          ProfileSuccess(:final updatePasswordError) => updatePasswordError,
          _ => null,
        };

        if (error == null) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppErrorMessageMapper.map(error))),
        );

        context.read<ProfileCubit>().clearUpdatePasswordError();
      },
      builder: (BuildContext context, ProfileState state) {
        final bool isUpdating = switch (state) {
          ProfileSuccess(:final isUpdatingPassword) => isUpdatingPassword,
          _ => false,
        };

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              key: const ValueKey<String>(
                'profile-change-password-current-field',
              ),
              controller: _currentPasswordController,
              enabled: !isUpdating,
              autofocus: true,
              obscureText: _obscureCurrentPassword,
              textInputAction: TextInputAction.next,
              autofillHints: const <String>[AutofillHints.password],
              onChanged: (_) {
                _clearValidation();
              },
              decoration: InputDecoration(
                labelText: 'Current password',
                errorText: _currentPasswordError,
                suffixIcon: IconButton(
                  key: const ValueKey<String>(
                    'profile-change-password-current-visibility',
                  ),
                  tooltip: _obscureCurrentPassword
                      ? 'Show password'
                      : 'Hide password',
                  onPressed: isUpdating
                      ? null
                      : () {
                          setState(() {
                            _obscureCurrentPassword = !_obscureCurrentPassword;
                          });
                        },
                  icon: Icon(
                    _obscureCurrentPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            TextField(
              key: const ValueKey<String>('profile-change-password-new-field'),
              controller: _newPasswordController,
              enabled: !isUpdating,
              obscureText: _obscureNewPassword,
              textInputAction: TextInputAction.next,
              autofillHints: const <String>[AutofillHints.newPassword],
              onChanged: (_) {
                _clearValidation();
              },
              decoration: InputDecoration(
                labelText: 'New password',
                errorText: _newPasswordError,
                suffixIcon: IconButton(
                  key: const ValueKey<String>(
                    'profile-change-password-new-visibility',
                  ),
                  tooltip: _obscureNewPassword
                      ? 'Show password'
                      : 'Hide password',
                  onPressed: isUpdating
                      ? null
                      : () {
                          setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          });
                        },
                  icon: Icon(
                    _obscureNewPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            TextField(
              key: const ValueKey<String>(
                'profile-change-password-confirm-field',
              ),
              controller: _confirmPasswordController,
              enabled: !isUpdating,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              autofillHints: const <String>[AutofillHints.newPassword],
              onChanged: (_) {
                _clearValidation();
              },
              onSubmitted: (_) {
                if (!isUpdating) {
                  _submit();
                }
              },
              decoration: InputDecoration(
                labelText: 'Confirm new password',
                errorText: _confirmPasswordError,
                suffixIcon: IconButton(
                  key: const ValueKey<String>(
                    'profile-change-password-confirm-visibility',
                  ),
                  tooltip: _obscureConfirmPassword
                      ? 'Show password'
                      : 'Hide password',
                  onPressed: isUpdating
                      ? null
                      : () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool useStackedActions = constraints.maxWidth < 400;

                final Widget cancelButton = TextButton(
                  key: const ValueKey<String>('profile-change-password-cancel'),
                  onPressed: isUpdating
                      ? null
                      : () {
                          Navigator.of(context).pop();
                        },
                  child: const Text('Cancel'),
                );

                final Widget saveButton = FilledButton(
                  key: const ValueKey<String>('profile-change-password-save'),
                  onPressed: isUpdating ? null : _submit,
                  child: isUpdating
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: AppSpacing.sm),
                            Text('Saving…'),
                          ],
                        )
                      : const Text('Change password'),
                );

                if (useStackedActions) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      saveButton,
                      const SizedBox(height: AppSpacing.sm),
                      cancelButton,
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    cancelButton,
                    const SizedBox(width: AppSpacing.sm),
                    saveButton,
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _AdminUserPasswordRecoveryDialog extends StatelessWidget {
  const _AdminUserPasswordRecoveryDialog({
    required this.user,
    required this.apiClient,
  });

  final AdminUser user;
  final ApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const ValueKey<String>('profile-password-recovery-dialog'),
      title: const Text('Password recovery'),
      content: SizedBox(
        width: 520,
        child: _AdminUserPasswordRecoveryContent(
          user: user,
          apiClient: apiClient,
        ),
      ),
      actions: <Widget>[
        TextButton(
          key: const ValueKey<String>('profile-password-recovery-close'),
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _AdminUserPasswordRecoveryContent extends StatelessWidget {
  const _AdminUserPasswordRecoveryContent({
    required this.user,
    required this.apiClient,
  });

  final AdminUser user;
  final ApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      AdminUserPasswordRecoveryCubit,
      AdminUserPasswordRecoveryState
    >(
      builder: (BuildContext context, AdminUserPasswordRecoveryState state) {
        return switch (state) {
          AdminUserPasswordRecoveryInitial() ||
          AdminUserPasswordRecoveryLoading() =>
            const _AdminPasswordRecoveryLoading(),

          AdminUserPasswordRecoverySuccess(:final recovery) =>
            _AdminPasswordRecoverySuccess(
              user: user,
              recovery: recovery,
              apiClient: apiClient,
            ),

          AdminUserPasswordRecoveryFailure(:final error) =>
            _AdminPasswordRecoveryFailure(user: user, error: error),
        };
      },
    );
  }
}

class _AdminPasswordRecoveryLoading extends StatelessWidget {
  const _AdminPasswordRecoveryLoading();

  @override
  Widget build(BuildContext context) {
    return const Row(
      key: ValueKey<String>('profile-password-recovery-loading'),
      children: <Widget>[
        SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),

        SizedBox(width: AppSpacing.lg),

        Expanded(child: Text('Generating recovery link…')),
      ],
    );
  }
}

class _AdminPasswordRecoveryFailure extends StatelessWidget {
  const _AdminPasswordRecoveryFailure({
    required this.user,
    required this.error,
  });

  final AdminUser user;
  final AppException error;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('profile-password-recovery-failure'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(AppErrorMessageMapper.map(error)),

        const SizedBox(height: AppSpacing.md),

        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const ValueKey<String>('profile-password-recovery-retry'),
            onPressed: () {
              context.read<AdminUserPasswordRecoveryCubit>().start(
                userId: user.id,
              );
            },
            child: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}

class _AdminPasswordRecoverySuccess extends StatelessWidget {
  const _AdminPasswordRecoverySuccess({
    required this.user,
    required this.recovery,
    required this.apiClient,
  });

  final AdminUser user;
  final PasswordRecoveryLink recovery;
  final ApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    final String recoveryUrl = _buildPasswordRecoveryUrl(
      apiClient: apiClient,
      token: recovery.token,
    );

    return Column(
      key: const ValueKey<String>('profile-password-recovery-success'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'A temporary recovery link has been generated for '
          '${user.displayName}.',
        ),

        const SizedBox(height: AppSpacing.lg),

        Container(
          key: const ValueKey<String>('profile-password-recovery-link-card'),
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.borderMedium,
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: SelectableText(
            recoveryUrl,
            key: const ValueKey<String>('profile-password-recovery-link'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        Text(
          'Expires ${_formatPasswordRecoveryExpiration(recovery.expiresAt)}',
          key: const ValueKey<String>('profile-password-recovery-expiration'),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),

        const SizedBox(height: AppSpacing.lg),

        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            key: const ValueKey<String>('profile-password-recovery-copy'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: recoveryUrl));

              if (!context.mounted) {
                return;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recovery link copied.')),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copy link'),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        Text(
          'This link can only be used once. '
          'After the password is changed, the user will be signed out from existing sessions.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _ProfileMobileServerSummary extends StatelessWidget {
  const _ProfileMobileServerSummary();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ServerHealthCubit, ServerHealthState>(
      builder: (BuildContext context, ServerHealthState state) {
        return switch (state) {
          ServerHealthInitial() ||
          ServerHealthLoading() => const _ProfileMobileAdministrationRow(
            rowKey: 'profile-server-mobile-summary',
            icon: Icons.dns_rounded,
            title: 'Server',
            subtitle: 'Checking server health…',
            trailing: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),

          ServerHealthSuccess(:final health) => _ProfileMobileAdministrationRow(
            rowKey: 'profile-server-mobile-summary',
            icon: Icons.dns_rounded,
            title: 'Server',
            subtitle:
                '${_serverHealthStatusLabel(health.status)}'
                ' · Uptime ${_formatServerUptime(health.uptimeSeconds)}',
          ),

          ServerHealthFailure(:final error) => _ProfileMobileAdministrationRow(
            rowKey: 'profile-server-mobile-summary',
            icon: Icons.dns_rounded,
            title: 'Server',
            subtitle: AppErrorMessageMapper.map(error),
            trailing: TextButton(
              key: const ValueKey<String>('profile-server-mobile-retry'),
              onPressed: context.read<ServerHealthCubit>().retry,
              child: const Text('Retry'),
            ),
          ),
        };
      },
    );
  }
}

String _formatUsersSummary({
  required int total,
  required int active,
  required int admins,
}) {
  final String usersLabel = total == 1 ? 'user' : 'users';
  final String activeLabel = active == 1 ? 'active' : 'active';
  final String adminsLabel = admins == 1 ? 'admin' : 'admins';

  return '$total $usersLabel · $active $activeLabel · $admins $adminsLabel';
}
