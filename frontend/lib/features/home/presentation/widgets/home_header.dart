import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/router/app_routes.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_cubit.dart';

enum HomeUserMenuAction { profile, settings, logout }

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    this.now,
    this.showRefreshAction = false,
    this.onRefresh,
    super.key,
  });

  final DateTime Function()? now;

  final bool showRefreshAction;

  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final DateTime current = (now ?? DateTime.now)();

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < AppBreakpoints.mobile;

        return Row(
          key: const ValueKey<String>('home-header'),
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _greetingFor(current),
                    key: const ValueKey<String>('home-greeting'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        (compact
                                ? Theme.of(context).textTheme.titleLarge
                                : Theme.of(context).textTheme.headlineMedium)
                            ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
                  Text(
                    _formatHomeDate(current),
                    key: const ValueKey<String>('home-date'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        (compact
                                ? Theme.of(context).textTheme.bodyMedium
                                : Theme.of(context).textTheme.bodyLarge)
                            ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            SizedBox(width: compact ? AppSpacing.md : AppSpacing.lg),

            if (showRefreshAction) ...<Widget>[
              IconButton(
                key: const ValueKey<String>('home-refresh-action'),
                tooltip: 'Refresh Home',
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],

            _HomeUserMenu(
              compact: compact,
              onSelected: (HomeUserMenuAction action) {
                _handleUserAction(context, action);
              },
            ),
          ],
        );
      },
    );
  }
}

class _HomeUserMenu extends StatelessWidget {
  const _HomeUserMenu({required this.compact, required this.onSelected});

  final bool compact;
  final ValueChanged<HomeUserMenuAction> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<HomeUserMenuAction>(
      key: const ValueKey<String>('home-user-menu'),
      tooltip: 'User menu',
      onSelected: onSelected,
      itemBuilder: (BuildContext context) {
        return const <PopupMenuEntry<HomeUserMenuAction>>[
          PopupMenuItem<HomeUserMenuAction>(
            value: HomeUserMenuAction.profile,
            child: _HomeUserMenuItem(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
            ),
          ),
          PopupMenuItem<HomeUserMenuAction>(
            value: HomeUserMenuAction.settings,
            child: _HomeUserMenuItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
            ),
          ),
          PopupMenuDivider(),
          PopupMenuItem<HomeUserMenuAction>(
            value: HomeUserMenuAction.logout,
            child: _HomeUserMenuItem(
              icon: Icons.logout_rounded,
              label: 'Log out',
            ),
          ),
        ];
      },
      child: Container(
        key: const ValueKey<String>('home-user-avatar'),
        width: compact ? 40 : 44,
        height: compact ? 40 : 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceHigh,
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: const Icon(
          Icons.person_outline_rounded,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _HomeUserMenuItem extends StatelessWidget {
  const _HomeUserMenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 20),
        const SizedBox(width: AppSpacing.md),
        Text(label),
      ],
    );
  }
}

void _handleUserAction(BuildContext context, HomeUserMenuAction action) {
  switch (action) {
    case HomeUserMenuAction.profile:
      context.goNamed(AppRoute.profile.name);

    case HomeUserMenuAction.settings:
      _showTemporaryMessage(context, 'Settings are not available yet.');

    case HomeUserMenuAction.logout:
      context.read<AuthCubit>().logout();
  }
}

void _showTemporaryMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

String _greetingFor(DateTime value) {
  final int hour = value.hour;

  if (hour < 12) {
    return 'Good morning';
  }

  if (hour < 18) {
    return 'Good afternoon';
  }

  return 'Good evening';
}

String _formatHomeDate(DateTime value) {
  const List<String> weekdays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  const List<String> months = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  final String weekday = weekdays[value.weekday - 1];
  final String month = months[value.month - 1];

  return '$weekday, $month ${value.day}';
}
