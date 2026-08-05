import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/theme/tokens/app_colors.dart';
import 'package:sofawatch/app/theme/tokens/app_durations.dart';
import 'package:sofawatch/app/theme/tokens/app_radius.dart';
import 'package:sofawatch/app/theme/tokens/app_spacing.dart';
import 'package:sofawatch/app/theme/tokens/app_typography.dart';
import 'package:sofawatch/features/search/application/bloc/search_bloc.dart';
import 'package:sofawatch/features/search/domain/repositories/search_repository.dart';
import 'package:sofawatch/features/search/presentation/views/search_mobile_view.dart';
import 'package:sofawatch/features/search/presentation/widgets/search_text_field.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  static const List<_NavigationItem> _navigationItems = <_NavigationItem>[
    _NavigationItem(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    _NavigationItem(
      label: 'Shows',
      icon: Icons.tv_outlined,
      selectedIcon: Icons.tv,
    ),
    _NavigationItem(
      label: 'Movies',
      icon: Icons.movie_outlined,
      selectedIcon: Icons.movie,
    ),
    _NavigationItem(
      label: 'Explore',
      icon: Icons.explore_outlined,
      selectedIcon: Icons.explore,
    ),
    _NavigationItem(
      label: 'Profile',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
  ];

  final StatefulNavigationShell navigationShell;

  void _selectDestination(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _WebAppShell(
        navigationShell: navigationShell,
        navigationItems: _navigationItems,
        onDestinationSelected: _selectDestination,
      );
    }

    return _MobileAppShell(
      navigationShell: navigationShell,
      navigationItems: _navigationItems,
      onDestinationSelected: _selectDestination,
    );
  }
}

class _WebNavigationTabs extends StatelessWidget {
  const _WebNavigationTabs({
    required this.currentIndex,
    required this.navigationItems,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final List<_NavigationItem> navigationItems;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int index = 0; index < navigationItems.length; index++)
          _WebNavigationTab(
            label: navigationItems[index].label,
            selected: currentIndex == index,
            onPressed: () {
              onDestinationSelected(index);
            },
          ),
      ],
    );
  }
}

class _WebNavigationTab extends StatelessWidget {
  const _WebNavigationTab({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: AppRadius.borderSmall,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: AppTypography.titleSmall.copyWith(
                color: selected
                    ? AppColors.primarySoft
                    : AppColors.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AnimatedContainer(
              duration: AppDurations.fast,
              curve: AppDurations.standardCurve,
              width: selected ? 48 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: AppRadius.borderFull,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WebNavigationActions extends StatelessWidget {
  const _WebNavigationActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          tooltip: 'Notifications',
          onPressed: () {
            // Implementação futura.
          },
          icon: const Icon(Icons.notifications_none_rounded),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton(
          tooltip: 'Settings',
          onPressed: () {
            // Implementação futura.
          },
          icon: const Icon(Icons.settings_outlined),
        ),
        const SizedBox(width: AppSpacing.lg),
        const _WebProfileAvatar(),
      ],
    );
  }
}

class _WebProfileAvatar extends StatelessWidget {
  const _WebProfileAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('web-profile-avatar'),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceHigh,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: const Icon(Icons.person_outline, color: AppColors.textSecondary),
    );
  }
}

class _WebAppShell extends StatelessWidget {
  const _WebAppShell({
    required this.navigationShell,
    required this.navigationItems,
    required this.onDestinationSelected,
  });

  final StatefulNavigationShell navigationShell;
  final List<_NavigationItem> navigationItems;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Container(
            key: const ValueKey<String>('web-top-navigation'),
            height: 92,
            decoration: const BoxDecoration(
              color: AppColors.surfaceLowest,
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.desktopHorizontalPadding,
              ),
              child: Row(
                children: <Widget>[
                  _WebBrand(
                    onPressed: () {
                      onDestinationSelected(0);
                    },
                  ),
                  Expanded(
                    child: Center(
                      child: _WebNavigationTabs(
                        currentIndex: navigationShell.currentIndex,
                        navigationItems: navigationItems,
                        onDestinationSelected: onDestinationSelected,
                      ),
                    ),
                  ),
                  const _WebNavigationActions(),
                ],
              ),
            ),
          ),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

class _WebBrand extends StatelessWidget {
  const _WebBrand({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: AppRadius.borderMedium,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const _BrandLogoPlaceholder(),
            const SizedBox(width: AppSpacing.md),
            Text(
              'SofaWatch',
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.primarySoft,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _DualPillMode { navigation, search }

class _MobileAppShell extends StatefulWidget {
  const _MobileAppShell({
    required this.navigationShell,
    required this.navigationItems,
    required this.onDestinationSelected,
  });

  final StatefulNavigationShell navigationShell;
  final List<_NavigationItem> navigationItems;
  final ValueChanged<int> onDestinationSelected;

  @override
  State<_MobileAppShell> createState() {
    return _MobileAppShellState();
  }
}

class _MobileAppShellState extends State<_MobileAppShell> {
  _DualPillMode _mode = _DualPillMode.navigation;

  final FocusNode _searchFocusNode = FocusNode();

  SearchBloc? _searchBloc;

  bool get _isSearchMode {
    return _mode == _DualPillMode.search;
  }

  _NavigationItem get _selectedNavigationItem {
    return widget.navigationItems[widget.navigationShell.currentIndex];
  }

  void _handleSearchPressed() {
    if (_isSearchMode) {
      return;
    }

    final SearchBloc searchBloc = SearchBloc(context.read<SearchRepository>());

    setState(() {
      _searchBloc = searchBloc;
      _mode = _DualPillMode.search;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isSearchMode) {
        return;
      }

      _searchFocusNode.requestFocus();
    });
  }

  void _closeSearch() {
    if (!_isSearchMode) {
      return;
    }

    final SearchBloc? searchBloc = _searchBloc;

    _searchFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _mode = _DualPillMode.navigation;
      _searchBloc = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (searchBloc == null || searchBloc.isClosed) {
        return;
      }

      unawaited(searchBloc.close());
    });
  }

  Widget _buildBody() {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        IgnorePointer(ignoring: _isSearchMode, child: widget.navigationShell),
        if (_isSearchMode) const Positioned.fill(child: SearchMobileView()),
      ],
    );
  }

  Widget _buildNavigationPill() {
    if (_isSearchMode) {
      return _MobileCompactNavigationPill(
        navigationItem: _selectedNavigationItem,
        onPressed: _closeSearch,
      );
    }

    return _MobilePrimaryNavigationPill(
      currentIndex: widget.navigationShell.currentIndex,
      navigationItems: widget.navigationItems,
      onDestinationSelected: widget.onDestinationSelected,
    );
  }

  Widget _buildSearchPill() {
    return _MobileSearchPill(
      isExpanded: _isSearchMode,
      focusNode: _searchFocusNode,
      onPressed: _handleSearchPressed,
    );
  }

  Widget _buildBottomNavigation() {
    if (_isSearchMode) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          _buildNavigationPill(),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: _buildSearchPill()),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(child: _buildNavigationPill()),
        const SizedBox(width: AppSpacing.md),
        _buildSearchPill(),
      ],
    );
  }

  Widget _buildScaffold() {
    return Scaffold(
      extendBody: true,
      body: _buildBody(),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: _buildBottomNavigation(),
      ),
    );
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();

    final SearchBloc? searchBloc = _searchBloc;

    if (searchBloc != null && !searchBloc.isClosed) {
      unawaited(searchBloc.close());
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SearchBloc? searchBloc = _searchBloc;

    if (searchBloc == null) {
      return _buildScaffold();
    }

    return BlocProvider<SearchBloc>.value(
      value: searchBloc,
      child: _buildScaffold(),
    );
  }
}

class _NavigationItem {
  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _BrandLogoPlaceholder extends StatelessWidget {
  const _BrandLogoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('web-brand-logo-placeholder'),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.14),
        borderRadius: AppRadius.borderMedium,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: const Icon(
        Icons.live_tv_outlined,
        color: AppColors.primarySoft,
        size: 24,
      ),
    );
  }
}

class _MobilePrimaryNavigationPill extends StatelessWidget {
  const _MobilePrimaryNavigationPill({
    required this.currentIndex,
    required this.navigationItems,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final List<_NavigationItem> navigationItems;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: AppRadius.borderFull,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: AppRadius.borderFull,
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: NavigationBar(
          key: const ValueKey<String>('mobile-bottom-navigation'),
          selectedIndex: currentIndex,
          onDestinationSelected: onDestinationSelected,
          height: 72,
          elevation: 0,
          backgroundColor: Colors.transparent,
          indicatorColor: colorScheme.primaryContainer,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: <NavigationDestination>[
            for (final _NavigationItem item in navigationItems)
              NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: item.label,
                tooltip: item.label,
              ),
          ],
        ),
      ),
    );
  }
}

class _MobileCompactNavigationPill extends StatelessWidget {
  const _MobileCompactNavigationPill({
    required this.navigationItem,
    required this.onPressed,
  });

  static const double _size = 72;

  final _NavigationItem navigationItem;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return SizedBox.square(
      dimension: _size,
      child: Material(
        key: const ValueKey<String>('mobile-compact-navigation-pill'),
        color: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderFull,
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Tooltip(
          message: 'Return to ${navigationItem.label}',
          child: Semantics(
            button: true,
            label: 'Close search and return to ${navigationItem.label}',
            child: InkWell(
              key: const ValueKey<String>('mobile-search-close-action'),
              onTap: onPressed,
              customBorder: RoundedRectangleBorder(
                borderRadius: AppRadius.borderFull,
              ),
              child: Center(
                child: Icon(
                  navigationItem.selectedIcon,
                  key: const ValueKey<String>('mobile-compact-navigation-icon'),
                  size: 28,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileSearchPill extends StatelessWidget {
  const _MobileSearchPill({
    required this.isExpanded,
    required this.focusNode,
    required this.onPressed,
  });

  static const double _compactSize = 72;

  final bool isExpanded;
  final FocusNode focusNode;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    if (!isExpanded) {
      return SizedBox.square(
        dimension: _compactSize,
        child: Material(
          key: const ValueKey<String>('mobile-search-pill'),
          color: colorScheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.borderFull,
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Tooltip(
            message: 'Search',
            child: Semantics(
              button: true,
              label: 'Open search',
              child: InkWell(
                key: const ValueKey<String>('mobile-search-pill-action'),
                onTap: onPressed,
                customBorder: RoundedRectangleBorder(
                  borderRadius: AppRadius.borderFull,
                ),
                child: Center(
                  child: Icon(
                    Icons.search_rounded,
                    key: const ValueKey<String>('mobile-search-icon'),
                    size: 28,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      key: const ValueKey<String>('mobile-search-expanded-pill'),
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderFull,
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: SearchTextField(focusNode: focusNode),
      ),
    );
  }
}
