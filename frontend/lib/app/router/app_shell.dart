import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/router/app_routes.dart';
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

  void _openSearch(BuildContext context) {
    context.pushNamed(AppRoute.search.name);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          key: const ValueKey<String>('web-search-action'),
          tooltip: 'Search',
          onPressed: () {
            _openSearch(context);
          },
          icon: const Icon(Icons.search_rounded),
        ),
        const SizedBox(width: AppSpacing.sm),
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

enum _DualPillVisualState { navigation, openingSearch, search, closingSearch }

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

class _MobileAppShellState extends State<_MobileAppShell>
    with SingleTickerProviderStateMixin {
  static const double _minimumHorizontalMargin = AppSpacing.sm;
  static const double _minimumBottomMargin = AppSpacing.sm;

  static const Duration _pillTransitionDuration = Duration(milliseconds: 320);

  late final AnimationController _pillTransitionController;
  late final Animation<double> _pillTransition;

  _DualPillVisualState _visualState = _DualPillVisualState.navigation;

  final FocusNode _searchFocusNode = FocusNode();

  SearchBloc? _searchBloc;
  int? _searchOriginBranchIndex;

  bool get _isNavigationState {
    return _visualState == _DualPillVisualState.navigation;
  }

  bool get _isOpeningSearch {
    return _visualState == _DualPillVisualState.openingSearch;
  }

  bool get _isSearchState {
    return _visualState == _DualPillVisualState.search;
  }

  bool get _isClosingSearch {
    return _visualState == _DualPillVisualState.closingSearch;
  }

  bool get _isSearchExperienceVisible {
    return !_isNavigationState;
  }

  bool get _usesSearchPillLayout {
    return _isOpeningSearch || _isSearchState || _isClosingSearch;
  }

  bool get _isTransitioning {
    return _isOpeningSearch || _isClosingSearch;
  }

  int get _selectedBranchIndex {
    return _searchOriginBranchIndex ?? widget.navigationShell.currentIndex;
  }

  _NavigationItem get _selectedNavigationItem {
    return widget.navigationItems[_selectedBranchIndex];
  }

  Future<void> _handleSearchPressed() async {
    if (!_isNavigationState || _isTransitioning) {
      return;
    }

    final int originBranchIndex = widget.navigationShell.currentIndex;

    final SearchBloc searchBloc = SearchBloc(context.read<SearchRepository>());

    setState(() {
      _searchOriginBranchIndex = originBranchIndex;
      _searchBloc = searchBloc;
      _visualState = _DualPillVisualState.openingSearch;
    });

    await _pillTransitionController.forward(from: 0);

    if (!mounted || !_isOpeningSearch) {
      return;
    }

    setState(() {
      _visualState = _DualPillVisualState.search;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isSearchState) {
        return;
      }

      _searchFocusNode.requestFocus();
    });
  }

  Future<void> _closeSearch() async {
    if (!_isSearchState || _isTransitioning) {
      return;
    }

    _searchFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _visualState = _DualPillVisualState.closingSearch;
    });

    await _pillTransitionController.reverse(from: 1);

    if (!mounted || !_isClosingSearch) {
      return;
    }

    final SearchBloc? searchBloc = _searchBloc;

    setState(() {
      _visualState = _DualPillVisualState.navigation;
      _searchBloc = null;
      _searchOriginBranchIndex = null;
    });

    if (searchBloc != null && !searchBloc.isClosed) {
      unawaited(searchBloc.close());
    }
  }

  Widget _buildBody() {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        IgnorePointer(
          ignoring: _isSearchExperienceVisible,
          child: widget.navigationShell,
        ),
        if (_isSearchExperienceVisible)
          const Positioned.fill(child: SearchMobileView()),
      ],
    );
  }

  Widget _buildSearchPill({
    required double compactSize,
    required bool useCompactField,
    required String hintText,
    required double transitionProgress,
  }) {
    return _MobileSearchPill(
      isExpanded: _usesSearchPillLayout,
      transitionProgress: transitionProgress,
      compactSize: compactSize,
      compactField: useCompactField,
      hintText: hintText,
      focusNode: _searchFocusNode,
      onPressed: _handleSearchPressed,
    );
  }

  Widget _buildBottomNavigation() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isLandscape =
            MediaQuery.orientationOf(context) == Orientation.landscape;

        final bool isNarrow = constraints.maxWidth < 360 || isLandscape;

        final bool isVeryNarrow = constraints.maxWidth < 330;

        final double compactSize = isNarrow ? 48 : 54;
        final double navigationHeight = isLandscape ? 48 : 54;
        final double spacing = isNarrow ? 6 : AppSpacing.sm;

        final String hintText;

        if (isVeryNarrow) {
          hintText = 'Search';
        } else if (isNarrow) {
          hintText = 'Movies and shows';
        } else {
          hintText = 'Search movies and TV shows';
        }

        final double availableWidth = constraints.maxWidth;

        return SizedBox(
          width: availableWidth,
          height: math.max(navigationHeight, compactSize),
          child: ClipRect(
            child: AnimatedBuilder(
              animation: _pillTransition,
              builder: (BuildContext context, Widget? child) {
                final double progress = _pillTransition.value.clamp(0.0, 1.0);

                final double minimumCombinedWidth = compactSize + compactSize;

                final double effectiveSpacing = math.min(
                  spacing,
                  math.max(0, availableWidth - minimumCombinedWidth),
                );

                final double usableWidth = math.max(
                  minimumCombinedWidth,
                  availableWidth - effectiveSpacing,
                );

                final double expandedNavigationWidth = math.max(
                  compactSize,
                  usableWidth - compactSize,
                );

                final double expandedSearchWidth = math.max(
                  compactSize,
                  usableWidth - compactSize,
                );

                final double navigationPillWidth = ui.lerpDouble(
                  expandedNavigationWidth,
                  compactSize,
                  progress,
                )!;

                final double searchPillWidth = ui.lerpDouble(
                  compactSize,
                  expandedSearchWidth,
                  progress,
                )!;

                final bool showCompactNavigation = progress >= 0.48;

                return Stack(
                  clipBehavior: Clip.hardEdge,
                  children: <Widget>[
                    Positioned(
                      left: 0,
                      bottom: 0,
                      width: navigationPillWidth,
                      height: navigationHeight,
                      child: ClipRRect(
                        borderRadius: AppRadius.borderFull,
                        child: Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            IgnorePointer(
                              ignoring:
                                  _visualState !=
                                  _DualPillVisualState.navigation,
                              child: Opacity(
                                opacity: showCompactNavigation ? 0 : 1,
                                child: _MobilePrimaryNavigationPill(
                                  currentIndex:
                                      widget.navigationShell.currentIndex,
                                  navigationItems: widget.navigationItems,
                                  height: navigationHeight,
                                  visualState: _visualState,
                                  onDestinationSelected:
                                      widget.onDestinationSelected,
                                ),
                              ),
                            ),
                            IgnorePointer(
                              ignoring: !_isSearchState,
                              child: Opacity(
                                opacity: showCompactNavigation ? 1 : 0,
                                child: _MobileCompactNavigationPill(
                                  navigationItem: _selectedNavigationItem,
                                  size: compactSize,
                                  enabled: _isSearchState,
                                  onPressed: _closeSearch,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      width: searchPillWidth,
                      height: navigationHeight,
                      child: ClipRRect(
                        borderRadius: AppRadius.borderFull,
                        child: _buildSearchPill(
                          compactSize: compactSize,
                          useCompactField: isNarrow,
                          hintText: hintText,
                          transitionProgress: progress,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildScaffold() {
    final double deviceBottomPadding = MediaQuery.viewPaddingOf(context).bottom;

    final bool keyboardIsOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    final double bottomMargin = keyboardIsOpen
        ? 4
        : math.max(deviceBottomPadding, _minimumBottomMargin);

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: true,
      body: _buildBody(),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          _minimumHorizontalMargin,
          0,
          _minimumHorizontalMargin,
          bottomMargin,
        ),
        child: _buildBottomNavigation(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _pillTransitionController = AnimationController(
      vsync: this,
      duration: _pillTransitionDuration,
      reverseDuration: _pillTransitionDuration,
    );

    _pillTransition = CurvedAnimation(
      parent: _pillTransitionController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _pillTransitionController.dispose();

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

class _MobilePillVisualStyle {
  const _MobilePillVisualStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.foregroundColor,
    required this.shadows,
    required this.blurSigma,
    required this.usesBlur,
  });

  factory _MobilePillVisualStyle.resolve(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final bool isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

    final bool isDark = theme.brightness == Brightness.dark;

    if (!isIOS) {
      return _MobilePillVisualStyle(
        backgroundColor: colorScheme.surfaceContainerHigh,
        borderColor: colorScheme.outlineVariant,
        foregroundColor: colorScheme.onSurface,
        shadows: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        blurSigma: 0,
        usesBlur: false,
      );
    }

    return _MobilePillVisualStyle(
      backgroundColor: colorScheme.surface.withValues(
        alpha: isDark ? 0.58 : 0.72,
      ),
      borderColor: colorScheme.onSurface.withValues(
        alpha: isDark ? 0.14 : 0.12,
      ),
      foregroundColor: colorScheme.onSurface,
      shadows: <BoxShadow>[
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.14),
          blurRadius: 24,
          spreadRadius: -4,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: isDark ? 0.04 : 0.18),
          blurRadius: 1,
          offset: const Offset(0, -1),
        ),
      ],
      blurSigma: 22,
      usesBlur: true,
    );
  }

  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;
  final List<BoxShadow> shadows;
  final double blurSigma;
  final bool usesBlur;
}

class _MobilePillSurface extends StatelessWidget {
  const _MobilePillSurface({required this.child, this.keyValue});

  final Widget child;
  final String? keyValue;

  @override
  Widget build(BuildContext context) {
    final _MobilePillVisualStyle style = _MobilePillVisualStyle.resolve(
      context,
    );

    final Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: AppRadius.borderFull,
        border: Border.all(color: style.borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        type: MaterialType.transparency,
        child: IconTheme(
          data: IconThemeData(color: style.foregroundColor),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: style.foregroundColor),
            child: child,
          ),
        ),
      ),
    );

    return Container(
      key: keyValue == null ? null : ValueKey<String>(keyValue!),
      decoration: BoxDecoration(
        borderRadius: AppRadius.borderFull,
        boxShadow: style.shadows,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.borderFull,
        child: style.usesBlur
            ? BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: style.blurSigma,
                  sigmaY: style.blurSigma,
                ),
                child: surface,
              )
            : surface,
      ),
    );
  }
}

class _AccessiblePillAction extends StatelessWidget {
  const _AccessiblePillAction({
    required this.onPressed,
    required this.semanticLabel,
    required this.tooltip,
    required this.child,
    this.selected = false,
    this.enabled = true,
    this.keyValue,
  });

  final VoidCallback onPressed;
  final String semanticLabel;
  final String tooltip;
  final Widget child;
  final bool selected;
  final bool enabled;
  final String? keyValue;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        selected: selected,
        enabled: enabled,
        label: semanticLabel,
        child: FocusableActionDetector(
          enabled: enabled,
          mouseCursor: enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (ActivateIntent intent) {
                if (enabled) {
                  onPressed();
                }

                return null;
              },
            ),
          },
          child: InkWell(
            key: keyValue == null ? null : ValueKey<String>(keyValue!),
            onTap: enabled ? onPressed : null,
            customBorder: RoundedRectangleBorder(
              borderRadius: AppRadius.borderFull,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _MobilePrimaryNavigationPill extends StatelessWidget {
  const _MobilePrimaryNavigationPill({
    required this.currentIndex,
    required this.navigationItems,
    required this.height,
    required this.onDestinationSelected,
    required this.visualState,
  });

  final int currentIndex;
  final List<_NavigationItem> navigationItems;
  final double height;
  final ValueChanged<int> onDestinationSelected;
  final _DualPillVisualState visualState;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: _MobilePillSurface(
        keyValue: 'mobile-primary-navigation-pill',
        child: Row(
          key: const ValueKey<String>('mobile-bottom-navigation'),
          children: <Widget>[
            for (int index = 0; index < navigationItems.length; index++)
              Expanded(
                child: _MobileNavigationPillItem(
                  navigationItem: navigationItems[index],
                  selected: currentIndex == index,
                  compact: height < 54,
                  visualState: visualState,
                  onPressed: () {
                    onDestinationSelected(index);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MobileNavigationPillItem extends StatelessWidget {
  const _MobileNavigationPillItem({
    required this.navigationItem,
    required this.selected,
    required this.compact,
    required this.onPressed,
    required this.visualState,
  });

  static const double _iconSize = 22;
  static const double _iconLabelSpacing = 1;
  bool get _isOpening {
    return visualState == _DualPillVisualState.openingSearch;
  }

  bool get _isClosing {
    return visualState == _DualPillVisualState.closingSearch;
  }

  bool get _hideUnselectedIcons {
    return _isOpening;
  }

  bool get _hideLabels {
    return _isOpening;
  }

  final _NavigationItem navigationItem;
  final bool selected;
  final bool compact;
  final VoidCallback onPressed;
  final _DualPillVisualState visualState;

  @override
  Widget build(BuildContext context) {
    final Color selectedColor = AppColors.primarySoft;
    final Color unselectedColor = AppColors.onSurfaceVariant;

    final Color foregroundColor = selected ? selectedColor : unselectedColor;

    final String semanticLabel = selected
        ? '${navigationItem.label}, selected tab'
        : '${navigationItem.label} tab';

    return _AccessiblePillAction(
      keyValue: 'mobile-navigation-${navigationItem.label.toLowerCase()}',
      tooltip: navigationItem.label,
      semanticLabel: semanticLabel,
      selected: selected,
      onPressed: visualState == _DualPillVisualState.navigation
          ? onPressed
          : () {},
      child: SizedBox.expand(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                opacity: (!_hideUnselectedIcons || selected) ? 1 : 0,
                child: Icon(
                  selected ? navigationItem.selectedIcon : navigationItem.icon,
                  key: ValueKey<String>(
                    selected
                        ? 'mobile-${navigationItem.label.toLowerCase()}-selected-icon'
                        : 'mobile-${navigationItem.label.toLowerCase()}-icon',
                  ),
                  size: compact ? 20 : _iconSize,
                  color: foregroundColor,
                ),
              ),

              if (selected) ...<Widget>[
                const SizedBox(height: _iconLabelSpacing),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 140),
                    curve: Curves.easeOut,
                    opacity: _hideLabels ? 0 : 1,
                    child: Text(
                      navigationItem.label,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: foregroundColor,
                        fontWeight: FontWeight.w600,
                        height: 1,
                        fontSize: compact ? 10 : null,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileCompactNavigationPill extends StatelessWidget {
  const _MobileCompactNavigationPill({
    required this.navigationItem,
    required this.onPressed,
    required this.size,
    required this.enabled,
  });

  final _NavigationItem navigationItem;
  final VoidCallback onPressed;
  final double size;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final double effectiveSize = math.max(size, 48);

    return SizedBox.square(
      dimension: effectiveSize,
      child: _MobilePillSurface(
        keyValue: 'mobile-compact-navigation-pill',
        child: _AccessiblePillAction(
          keyValue: 'mobile-search-close-action',
          tooltip: 'Return to ${navigationItem.label}',
          semanticLabel: 'Close search and return to ${navigationItem.label}',
          enabled: enabled,
          onPressed: onPressed,
          child: Center(
            child: Icon(
              navigationItem.selectedIcon,
              key: const ValueKey<String>('mobile-compact-navigation-icon'),
              size: effectiveSize <= 48 ? 24 : 28,
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
    required this.transitionProgress,
    required this.compactSize,
    required this.compactField,
    required this.hintText,
    required this.focusNode,
    required this.onPressed,
  });

  final bool isExpanded;
  final double transitionProgress;
  final double compactSize;
  final bool compactField;
  final String hintText;
  final FocusNode focusNode;
  final VoidCallback onPressed;

  double _interval(
    double progress, {
    required double begin,
    required double end,
  }) {
    if (progress <= begin) {
      return 0;
    }

    if (progress >= end) {
      return 1;
    }

    return (progress - begin) / (end - begin);
  }

  @override
  Widget build(BuildContext context) {
    final double progress = transitionProgress.clamp(0.0, 1.0);

    final double compactIconOpacity =
        1 - _interval(progress, begin: 0, end: 0.28);

    final double fieldOpacity = _interval(progress, begin: 0.30, end: 0.66);

    final double prefixIconOpacity = _interval(
      progress,
      begin: 0.44,
      end: 0.76,
    );

    final double hintOpacity = _interval(progress, begin: 0.58, end: 0.92);

    final bool showExpandedField = isExpanded && progress >= 0.28;

    final double effectiveCompactSize = math.max(compactSize, 48);

    return SizedBox(
      height: compactField ? 48 : 54,
      child: _MobilePillSurface(
        keyValue: isExpanded
            ? 'mobile-search-expanded-pill'
            : 'mobile-search-pill',
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            IgnorePointer(
              ignoring: isExpanded,
              child: Opacity(
                opacity: compactIconOpacity,
                child: _AccessiblePillAction(
                  keyValue: 'mobile-search-pill-action',
                  tooltip: 'Search',
                  semanticLabel: 'Open search',
                  onPressed: onPressed,
                  child: Center(
                    child: Icon(
                      Icons.search_rounded,
                      key: const ValueKey<String>('mobile-search-icon'),
                      size: effectiveCompactSize <= 48 ? 24 : 28,
                    ),
                  ),
                ),
              ),
            ),
            if (showExpandedField)
              Opacity(
                opacity: fieldOpacity,
                child: Semantics(
                  container: true,
                  explicitChildNodes: true,
                  label: 'Search mode active',
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: compactField ? 4 : AppSpacing.sm,
                    ),
                    child: SearchTextField(
                      focusNode: focusNode,
                      hintText: hintText,
                      compact: compactField,
                      prefixIconOpacity: prefixIconOpacity,
                      hintOpacity: hintOpacity,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
