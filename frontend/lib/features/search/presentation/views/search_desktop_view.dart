import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/router/app_routes.dart';
import 'package:sofawatch/app/router/route_paths.dart';
import 'package:sofawatch/app/theme/tokens/app_spacing.dart';
import 'package:sofawatch/features/search/application/bloc/search_bloc.dart';
import 'package:sofawatch/features/search/application/bloc/search_event.dart';
import 'package:sofawatch/features/search/application/bloc/search_state.dart';
import 'package:sofawatch/features/search/domain/entities/search_result.dart';
import 'package:sofawatch/features/search/presentation/widgets/search_failure_state.dart';
import 'package:sofawatch/features/search/presentation/widgets/search_loading_state.dart';
import 'package:sofawatch/features/search/presentation/widgets/search_media_type_filter_bar.dart';
import 'package:sofawatch/features/search/presentation/widgets/search_minimum_characters_hint.dart';
import 'package:sofawatch/features/search/presentation/widgets/search_results_section.dart';
import 'package:sofawatch/features/search/presentation/widgets/search_text_field.dart';

class SearchDesktopView extends StatelessWidget {
  const SearchDesktopView({super.key});

  static const double _maximumModalWidth = 780;
  static const double _maximumModalHeight = 720;
  static const double _minimumModalHeight = 420;
  static const double _backdropBlurSigma = 7;

  static const double _minimumViewportMargin = AppSpacing.lg;

  void _closeSearch(BuildContext context) {
    final GoRouter router = GoRouter.of(context);

    if (router.canPop()) {
      router.pop();
      return;
    }

    router.go(RoutePaths.home);
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets viewInsets = MediaQuery.viewInsetsOf(context);

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): () {
          _closeSearch(context);
        },
      },
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // Camada visual: aplica blur, mas não recebe eventos.
            IgnorePointer(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(
                    sigmaX: _backdropBlurSigma,
                    sigmaY: _backdropBlurSigma,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),

            // Área exterior clicável.
            GestureDetector(
              key: const ValueKey<String>('search-desktop-backdrop'),
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _closeSearch(context);
              },
              child: const SizedBox.expand(),
            ),

            // Modal colocado por cima do backdrop.
            SafeArea(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool hasLimitedHeight = constraints.maxHeight < 560;

                  final double viewportMargin = hasLimitedHeight
                      ? AppSpacing.sm
                      : _minimumViewportMargin;

                  final double availableWidth = math.max(
                    0,
                    constraints.maxWidth - (viewportMargin * 2),
                  );

                  final double availableHeight = math.max(
                    0,
                    constraints.maxHeight - (viewportMargin * 2),
                  );

                  final double modalWidth = math.min(
                    _maximumModalWidth,
                    availableWidth,
                  );

                  final double modalMaximumHeight = math.min(
                    _maximumModalHeight,
                    availableHeight,
                  );

                  final double modalMinimumHeight = math.min(
                    _minimumModalHeight,
                    modalMaximumHeight,
                  );

                  return Center(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,

                      // Impede o clique dentro do modal de chegar ao backdrop.
                      onTap: () {},

                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: modalWidth,
                          maxWidth: modalWidth,
                          minHeight: modalMinimumHeight,
                          maxHeight: modalMaximumHeight,
                        ),
                        child: _SearchDesktopModal(
                          onClose: () {
                            _closeSearch(context);
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchDesktopModal extends StatelessWidget {
  const _SearchDesktopModal({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Material(
      key: const ValueKey<String>('search-desktop-modal'),
      color: colorScheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      elevation: 28,
      shadowColor: Colors.black.withValues(alpha: 0.48),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.lg,
              0,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Search',
                    key: const ValueKey<String>('search-desktop-title'),
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Close search',
                  child: IconButton(
                    key: const ValueKey<String>('search-desktop-close-button'),
                    tooltip: 'Close search',
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              0,
            ),
            child: SearchTextField(autofocus: true),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: BlocBuilder<SearchBloc, SearchState>(
              buildWhen: (SearchState previous, SearchState current) {
                return previous.mediaType != current.mediaType;
              },
              builder: (BuildContext context, SearchState state) {
                return SearchMediaTypeFilterBar(
                  selectedFilter: state.mediaType,
                  onFilterChanged: (filter) {
                    context.read<SearchBloc>().add(
                      SearchMediaTypeChanged(filter),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Divider(height: 1, color: colorScheme.outlineVariant),
          const Expanded(child: _SearchDesktopScrollableContent()),
        ],
      ),
    );
  }
}

class _SearchDesktopScrollableContent extends StatefulWidget {
  const _SearchDesktopScrollableContent();

  @override
  State<_SearchDesktopScrollableContent> createState() {
    return _SearchDesktopScrollableContentState();
  }
}

class _SearchDesktopScrollableContentState
    extends State<_SearchDesktopScrollableContent> {
  static const double _loadMoreThreshold = 240;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final SearchState state = context.read<SearchBloc>().state;

    if (!state.hasResults ||
        state.isLoadingMore ||
        state.paginationError != null ||
        state.results.data?.hasNextPage != true) {
      return;
    }

    final ScrollPosition position = _scrollController.position;

    final double distanceFromEnd = position.maxScrollExtent - position.pixels;

    if (distanceFromEnd <= _loadMoreThreshold) {
      context.read<SearchBloc>().add(const SearchNextPageRequested());
    }
  }

  void _openResult(BuildContext context, SearchResult result) {
    if (result.isShow) {
      context.pushNamed(
        AppRoute.showDetails.name,
        pathParameters: <String, String>{'showId': result.tmdbId.toString()},
      );

      return;
    }

    context.pushNamed(
      AppRoute.movieDetails.name,
      pathParameters: <String, String>{'movieId': result.tmdbId.toString()},
    );
  }

  void _handleResultAction(SearchResult result) {
    // A ação de Watchlist/Biblioteca será implementada no ponto 13.14.
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey<String>('search-desktop-scrollable-content'),
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 220),
        child: BlocBuilder<SearchBloc, SearchState>(
          buildWhen: (SearchState previous, SearchState current) {
            return previous.query != current.query ||
                previous.mediaType != current.mediaType ||
                previous.results != current.results ||
                previous.isLoadingMore != current.isLoadingMore ||
                previous.paginationError != current.paginationError;
          },
          builder: (BuildContext context, SearchState state) {
            if (state.needsMoreCharacters) {
              return SearchMinimumCharactersHint(
                remainingCharacters: state.remainingCharacters,
              );
            }

            if (state.results.isLoading) {
              return const SearchLoadingState();
            }

            if (state.results.isFailure) {
              return SearchFailureState(
                error: state.results.error!,
                onRetry: () {
                  context.read<SearchBloc>().add(const SearchRetryRequested());
                },
              );
            }

            if (state.hasNoResults) {
              return SearchEmptyState(query: state.normalizedQuery);
            }

            if (state.hasResults) {
              return SearchResultsSection(
                results: state.results.data!.results,
                scrollable: false,
                isLoadingMore: state.isLoadingMore,
                paginationError: state.paginationError,
                onPaginationRetry: () {
                  context.read<SearchBloc>().add(const SearchRetryRequested());
                },
                onResultPressed: (SearchResult result) {
                  _openResult(context, result);
                },
                onResultActionPressed: _handleResultAction,
              );
            }

            return const _SearchDesktopPlaceholder();
          },
        ),
      ),
    );
  }
}

class _SearchDesktopPlaceholder extends StatelessWidget {
  const _SearchDesktopPlaceholder();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Text(
        'Search for movies and TV shows.',
        key: const ValueKey<String>('search-desktop-placeholder'),
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}
