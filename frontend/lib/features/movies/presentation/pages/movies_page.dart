import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/router/app_routes.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/core/widgets/server_network_image.dart';
import 'package:sofawatch/features/history/domain/models/history_movie_item.dart';
import 'package:sofawatch/features/movies/application/cubit/movie_history_cubit.dart';
import 'package:sofawatch/features/movies/application/cubit/movie_history_state.dart';
import 'package:sofawatch/features/movies/application/cubit/movies_cubit.dart';
import 'package:sofawatch/features/movies/application/cubit/movies_state.dart';
import 'package:sofawatch/features/movies/application/models/movies_filter.dart';
import 'package:sofawatch/features/movies/application/models/movies_sort.dart';
import 'package:sofawatch/features/movies/domain/models/library_movie.dart';

class MoviesPage extends StatelessWidget {
  const MoviesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey<String>('movies-page'),
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: MultiBlocListener(
          listeners: <BlocListener<dynamic, dynamic>>[
            BlocListener<MoviesCubit, MoviesState>(
              listenWhen: (MoviesState previous, MoviesState current) {
                return previous.refreshError != current.refreshError &&
                    current.refreshError != null;
              },
              listener: (BuildContext context, MoviesState state) {
                final AppException? error = state.refreshError;

                if (error == null) {
                  return;
                }

                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(
                        error.isTimeout
                            ? 'Refreshing your movies took too long.'
                            : 'Could not refresh your movies.',
                      ),
                    ),
                  );
              },
            ),
            BlocListener<MovieHistoryCubit, MovieHistoryState>(
              listenWhen:
                  (MovieHistoryState previous, MovieHistoryState current) {
                    return previous.mutationError != current.mutationError &&
                        current.mutationError != null;
                  },
              listener: (BuildContext context, MovieHistoryState state) {
                final AppException? error = state.mutationError;

                if (error == null) {
                  return;
                }

                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(
                        error.isTimeout
                            ? 'Updating this viewing took too long.'
                            : 'Could not update this viewing.',
                      ),
                    ),
                  );

                context.read<MovieHistoryCubit>().clearMutationError();
              },
            ),
          ],
          child: BlocBuilder<MoviesCubit, MoviesState>(
            builder: (BuildContext context, MoviesState state) {
              if (state.isLoading &&
                  state.libraryMovies.isEmpty &&
                  state.error == null) {
                return const _MoviesLoading();
              }

              final AppException? error = state.error;

              if (error != null && state.libraryMovies.isEmpty) {
                return _MoviesFailure(
                  message: error.isTimeout
                      ? 'Loading your movies took too long.'
                      : 'Could not load your movies.',
                  onRetry: context.read<MoviesCubit>().retry,
                );
              }

              return _MoviesContent(state: state);
            },
          ),
        ),
      ),
    );
  }
}

class _MoviesContent extends StatelessWidget {
  const _MoviesContent({required this.state});

  final MoviesState state;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: context.read<MoviesCubit>().refresh,
      child: CustomScrollView(
        key: const ValueKey<String>('movies-scroll-view'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: _MoviesContentBounds(
              contentKey: const ValueKey<String>('movies-header-content'),
              child: _MoviesHeader(
                state: state,
                isRefreshing: state.isRefreshing,
                onRefresh: context.read<MoviesCubit>().refresh,
              ),
            ),
          ),

          if (state.libraryMovies.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _MoviesEmpty(),
            )
          else if (!state.hasVisibleMovies)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _MoviesNoResults(
                hasSearchQuery: state.hasSearchQuery,
                hasActiveFilter: state.hasActiveFilter,
                onClear: context.read<MoviesCubit>().clearLocalFilters,
              ),
            )
          else ...<Widget>[
            if (state.watchlist.isNotEmpty)
              SliverToBoxAdapter(
                child: _MoviesContentBounds(
                  child: _MovieSection(
                    title: 'Watchlist',
                    movies: state.watchlist,
                    sectionKey: 'movies-watchlist',
                    mobileColumns: 3,
                    showWatchAction: true,
                  ),
                ),
              ),

            if (state.comingSoon.isNotEmpty)
              SliverToBoxAdapter(
                child: _MoviesContentBounds(
                  child: _MovieSection(
                    title: 'Coming Soon',
                    movies: state.comingSoon,
                    sectionKey: 'movies-coming-soon',
                  ),
                ),
              ),

            const SliverToBoxAdapter(
              child: _MoviesContentBounds(child: _MovieHistorySection()),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          ],
        ],
      ),
    );
  }
}

class _MoviesContentBounds extends StatelessWidget {
  const _MoviesContentBounds({required this.child, this.contentKey});

  final Widget child;
  final Key? contentKey;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        key: contentKey,
        constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
        child: child,
      ),
    );
  }
}

class _MoviesHeader extends StatelessWidget {
  const _MoviesHeader({
    required this.state,
    required this.isRefreshing,
    required this.onRefresh,
  });

  final MoviesState state;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final bool isDesktop =
        MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isDesktop
            ? AppSpacing.desktopHorizontalPadding
            : AppSpacing.mobileHorizontalPadding,
        AppSpacing.lg,
        isDesktop
            ? AppSpacing.desktopHorizontalPadding
            : AppSpacing.mobileHorizontalPadding,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Movies',
                  key: const ValueKey<String>('movies-page-title'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey<String>('movies-refresh'),
                tooltip: 'Refresh movies',
                onPressed: isRefreshing ? null : onRefresh,
                icon: isRefreshing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          if (isDesktop)
            _MoviesDesktopControls(state: state)
          else
            _MoviesMobileControls(state: state),
        ],
      ),
    );
  }
}

class _MoviesDesktopControls extends StatelessWidget {
  const _MoviesDesktopControls({required this.state});

  final MoviesState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(child: _MoviesSearchField(query: state.searchQuery)),
        const SizedBox(width: AppSpacing.md),
        _MoviesFilterMenu(selected: state.filter),
        const SizedBox(width: AppSpacing.sm),
        _MoviesSortMenu(selected: state.sort),
      ],
    );
  }
}

class _MoviesMobileControls extends StatelessWidget {
  const _MoviesMobileControls({required this.state});

  final MoviesState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _MoviesSearchField(query: state.searchQuery),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: <Widget>[
            Expanded(
              child: _MoviesFilterMenu(selected: state.filter, expand: true),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MoviesSortMenu(selected: state.sort, expand: true),
            ),
          ],
        ),
      ],
    );
  }
}

class _MoviesSearchField extends StatefulWidget {
  const _MoviesSearchField({required this.query});

  final String query;

  @override
  State<_MoviesSearchField> createState() {
    return _MoviesSearchFieldState();
  }
}

class _MoviesSearchFieldState extends State<_MoviesSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant _MoviesSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.query == oldWidget.query || _controller.text == widget.query) {
      return;
    }

    _controller.value = TextEditingValue(
      text: widget.query,
      selection: TextSelection.collapsed(offset: widget.query.length),
    );
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const ValueKey<String>('movies-search-field'),
      controller: _controller,
      textInputAction: TextInputAction.search,
      onChanged: (String value) {
        context.read<MoviesCubit>().setSearchQuery(value);

        setState(() {});
      },
      decoration: InputDecoration(
        hintText: 'Search your movies',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                key: const ValueKey<String>('movies-search-clear'),
                tooltip: 'Clear search',
                onPressed: () {
                  _controller.clear();

                  context.read<MoviesCubit>().setSearchQuery('');

                  setState(() {});
                },
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: AppColors.surfaceHigh,
        border: OutlineInputBorder(
          borderRadius: AppRadius.borderLarge,
          borderSide: BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderLarge,
          borderSide: BorderSide(color: AppColors.outlineVariant),
        ),
      ),
    );
  }
}

class _MoviesFilterMenu extends StatelessWidget {
  const _MoviesFilterMenu({required this.selected, this.expand = false});

  final MoviesFilter selected;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final Widget child = PopupMenuButton<MoviesFilter>(
      key: const ValueKey<String>('movies-filter-menu'),
      tooltip: 'Filter movies',
      initialValue: selected,
      onSelected: context.read<MoviesCubit>().setFilter,
      itemBuilder: (BuildContext context) {
        return MoviesFilter.values
            .map((MoviesFilter filter) {
              return PopupMenuItem<MoviesFilter>(
                value: filter,
                child: Row(
                  children: <Widget>[
                    if (filter == selected) ...<Widget>[
                      const Icon(Icons.check_rounded, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Text(_moviesFilterLabel(filter)),
                  ],
                ),
              );
            })
            .toList(growable: false);
      },
      child: _MoviesControlButton(
        icon: Icons.filter_list_rounded,
        label: _moviesFilterLabel(selected),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: child) : child;
  }
}

class _MoviesSortMenu extends StatelessWidget {
  const _MoviesSortMenu({required this.selected, this.expand = false});

  final MoviesSort selected;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final Widget child = PopupMenuButton<MoviesSort>(
      key: const ValueKey<String>('movies-sort-menu'),
      tooltip: 'Sort movies',
      initialValue: selected,
      onSelected: context.read<MoviesCubit>().setSort,
      itemBuilder: (BuildContext context) {
        return MoviesSort.values
            .map((MoviesSort sort) {
              return PopupMenuItem<MoviesSort>(
                value: sort,
                child: Row(
                  children: <Widget>[
                    if (sort == selected) ...<Widget>[
                      const Icon(Icons.check_rounded, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Text(_moviesSortLabel(sort)),
                  ],
                ),
              );
            })
            .toList(growable: false);
      },
      child: _MoviesControlButton(
        icon: Icons.swap_vert_rounded,
        label: _moviesSortLabel(selected),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: child) : child;
  }
}

class _MoviesControlButton extends StatelessWidget {
  const _MoviesControlButton({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.keyboard_arrow_down_rounded),
          ],
        ),
      ),
    );
  }
}

class _MovieSection extends StatelessWidget {
  const _MovieSection({
    required this.title,
    required this.movies,
    required this.sectionKey,
    this.mobileColumns,
    this.showWatchAction = false,
  });

  final String title;
  final List<LibraryMovie> movies;
  final String sectionKey;
  final int? mobileColumns;
  final bool showWatchAction;

  @override
  Widget build(BuildContext context) {
    final bool isDesktop =
        MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop;

    return Padding(
      key: ValueKey<String>(sectionKey),
      padding: EdgeInsets.fromLTRB(
        isDesktop
            ? AppSpacing.desktopHorizontalPadding
            : AppSpacing.mobileHorizontalPadding,
        0,
        isDesktop
            ? AppSpacing.desktopHorizontalPadding
            : AppSpacing.mobileHorizontalPadding,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final int columns = switch (constraints.maxWidth) {
                >= 1200 => 6,
                >= 900 => 5,
                >= 650 => 4,
                >= 480 => 3,
                _ => mobileColumns ?? 2,
              };

              final double totalSpacing = AppSpacing.md * (columns - 1);
              final double cardWidth =
                  (constraints.maxWidth - totalSpacing) / columns;

              final double posterHeight = cardWidth * 1.5;

              /*
     * Fixed metadata area prevents long titles from changing
     * the poster height of neighbouring cards.
     */
              const double titleHeight = 42;
              const double metadataHeight = 20;

              final double cardHeight =
                  posterHeight +
                  AppSpacing.sm +
                  titleHeight +
                  AppSpacing.xs +
                  metadataHeight;

              return GridView.builder(
                key: ValueKey<String>('$sectionKey-grid'),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: movies.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.lg,
                  mainAxisExtent: cardHeight,
                ),
                itemBuilder: (BuildContext context, int index) {
                  return _MovieCard(
                    movie: movies[index],
                    showWatchAction: showWatchAction,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MovieCard extends StatelessWidget {
  const _MovieCard({required this.movie, this.showWatchAction = false});

  final LibraryMovie movie;
  final bool showWatchAction;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey<String>('movies-card-${movie.movieId}'),
      borderRadius: AppRadius.borderLarge,
      onTap: () {
        context.pushNamed(
          AppRoute.movieDetails.name,
          pathParameters: <String, String>{'movieId': movie.tmdbId.toString()},
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AspectRatio(
            aspectRatio: 2 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                ClipRRect(
                  borderRadius: AppRadius.borderLarge,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh,
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: SizedBox.expand(
                      child: movie.posterUrl == null
                          ? const _MoviePosterPlaceholder()
                          : ServerNetworkImage(
                              imageUrl: movie.posterUrl!,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (
                                    BuildContext context,
                                    Object error,
                                    StackTrace? stackTrace,
                                  ) {
                                    return const _MoviePosterPlaceholder();
                                  },
                            ),
                    ),
                  ),
                ),
                if (showWatchAction)
                  Positioned(
                    top: AppSpacing.xs,
                    right: AppSpacing.xs,
                    child: BlocBuilder<MovieHistoryCubit, MovieHistoryState>(
                      buildWhen:
                          (
                            MovieHistoryState previous,
                            MovieHistoryState current,
                          ) {
                            return previous.mutatingMovieIds !=
                                current.mutatingMovieIds;
                          },
                      builder: (BuildContext context, MovieHistoryState state) {
                        final bool isMutating = state.isMovieMutating(
                          movie.movieId,
                        );

                        return _MovieWatchButton(
                          key: ValueKey<String>(
                            'movies-watch-${movie.movieId}',
                          ),
                          isLoading: isMutating,
                          onPressed: isMutating
                              ? null
                              : () {
                                  context.read<MovieHistoryCubit>().recordWatch(
                                    movie.movieId,
                                  );
                                },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 42,
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                movie.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _movieMetadata(movie),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _MovieWatchButton extends StatelessWidget {
  const _MovieWatchButton({
    required this.isLoading,
    required this.onPressed,
    super.key,
  });

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface.withValues(alpha: 0.88),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.check_rounded,
                    size: 19,
                    color: AppColors.textSecondary,
                  ),
          ),
        ),
      ),
    );
  }
}

class _MovieHistorySection extends StatefulWidget {
  const _MovieHistorySection();

  @override
  State<_MovieHistorySection> createState() {
    return _MovieHistorySectionState();
  }
}

class _MovieHistorySectionState extends State<_MovieHistorySection> {
  static const int _itemsPerPage = 6;

  late final PageController _pageController;

  int _currentPage = 0;

  @override
  void initState() {
    super.initState();

    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop =
        MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop;

    return BlocBuilder<MovieHistoryCubit, MovieHistoryState>(
      builder: (BuildContext context, MovieHistoryState state) {
        if (state.isLoading && state.items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.error != null && state.items.isEmpty) {
          return _MovieHistoryFailure(
            onRetry: context.read<MovieHistoryCubit>().retry,
          );
        }

        if (state.items.isEmpty) {
          return const SizedBox.shrink();
        }

        final int historyPageCount = (state.items.length / _itemsPerPage)
            .ceil();

        /*
         * See All is intentionally an extra page.
         *
         * The preview therefore still contains up to all 18 history
         * events. No viewing event is sacrificed to make room for
         * the navigation tile.
         */
        final int totalPageCount = historyPageCount + 1;

        final int lastPage = totalPageCount - 1;

        if (_currentPage > lastPage) {
          _currentPage = lastPage;

          if (_pageController.hasClients) {
            _pageController.jumpToPage(lastPage);
          }
        }

        return Padding(
          key: const ValueKey<String>('movies-watched'),
          padding: EdgeInsets.fromLTRB(
            isDesktop
                ? AppSpacing.desktopHorizontalPadding
                : AppSpacing.mobileHorizontalPadding,
            0,
            isDesktop
                ? AppSpacing.desktopHorizontalPadding
                : AppSpacing.mobileHorizontalPadding,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Divider(height: 1),

              const SizedBox(height: AppSpacing.xl),

              Text(
                'Watched',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: AppSpacing.md),

              _MovieHistoryPager(
                items: state.items,
                pageController: _pageController,
                historyPageCount: historyPageCount,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
              ),

              if (totalPageCount > 1) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                _MovieHistoryPageIndicator(
                  currentPage: _currentPage,
                  pageCount: totalPageCount,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MovieHistoryPager extends StatelessWidget {
  const _MovieHistoryPager({
    required this.items,
    required this.pageController,
    required this.historyPageCount,
    required this.onPageChanged,
  });

  static const int _itemsPerPage = 6;
  static const int _columns = 3;
  static const int _rows = 2;

  final List<HistoryMovieItem> items;
  final PageController pageController;
  final int historyPageCount;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double cardWidth =
            (constraints.maxWidth - (AppSpacing.md * (_columns - 1))) /
            _columns;

        final double posterHeight = cardWidth * 1.5;

        /*
         * Fixed metadata height:
         * title + date + time.
         */
        const double titleHeight = 20;
        const double dateHeight = 18;
        const double timeHeight = 18;

        final double cardHeight =
            posterHeight +
            AppSpacing.sm +
            titleHeight +
            AppSpacing.xs +
            dateHeight +
            timeHeight;

        final double pageHeight =
            (cardHeight * _rows) + (AppSpacing.lg * (_rows - 1));

        return SizedBox(
          height: pageHeight,
          child: PageView.builder(
            key: const ValueKey<String>('movies-watched-pager'),
            controller: pageController,
            physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
            itemCount: historyPageCount + 1,
            onPageChanged: onPageChanged,
            itemBuilder: (BuildContext context, int pageIndex) {
              if (pageIndex == historyPageCount) {
                return _MovieHistorySeeAllPage(
                  cardWidth: cardWidth,
                  pageHeight: pageHeight,
                );
              }

              final int startIndex = pageIndex * _itemsPerPage;

              final int endIndex = (startIndex + _itemsPerPage).clamp(
                0,
                items.length,
              );

              final List<HistoryMovieItem> pageItems = items.sublist(
                startIndex,
                endIndex,
              );

              return GridView.builder(
                key: ValueKey<String>('movies-watched-page-$pageIndex'),
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: pageItems.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _columns,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.lg,
                  mainAxisExtent: cardHeight,
                ),
                itemBuilder: (BuildContext context, int index) {
                  return _MovieHistoryCard(item: pageItems[index]);
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _MovieHistoryPageIndicator extends StatelessWidget {
  const _MovieHistoryPageIndicator({
    required this.currentPage,
    required this.pageCount,
  });

  final int currentPage;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey<String>('movies-watched-page-indicator'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(pageCount, (int index) {
        final bool isSelected = index == currentPage;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: isSelected ? 18 : 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.textPrimary
                : AppColors.outlineVariant,
            borderRadius: AppRadius.borderFull,
          ),
        );
      }),
    );
  }
}

class _MovieHistorySeeAllPage extends StatelessWidget {
  const _MovieHistorySeeAllPage({
    required this.cardWidth,
    required this.pageHeight,
  });

  final double cardWidth;
  final double pageHeight;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: cardWidth,
        height: pageHeight,
        child: Material(
          color: AppColors.surfaceHigh,
          borderRadius: AppRadius.borderLarge,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: const ValueKey<String>('movies-watched-see-all'),
            onTap: () {
              context.pushNamed(
                AppRoute.history.name,
                queryParameters: const <String, String>{'type': 'movie'},
              );
            },
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: AppRadius.borderLarge,
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Icon(Icons.history_rounded, size: 32),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'See All',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Movie history',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
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

class _MovieHistoryFailure extends StatelessWidget {
  const _MovieHistoryFailure({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final bool isDesktop =
        MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop;

    return Padding(
      key: const ValueKey<String>('movies-watched-failure'),
      padding: EdgeInsets.fromLTRB(
        isDesktop
            ? AppSpacing.desktopHorizontalPadding
            : AppSpacing.mobileHorizontalPadding,
        0,
        isDesktop
            ? AppSpacing.desktopHorizontalPadding
            : AppSpacing.mobileHorizontalPadding,
        AppSpacing.xl,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: AppRadius.borderLarge,
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Padding(
          padding: AppSpacing.cardPaddingLarge,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.history_toggle_off_rounded,
                size: 36,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Could not load watched movies',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Your library is still available. Retry loading only the watched history.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.tonalIcon(
                key: const ValueKey<String>('movies-watched-retry'),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MovieHistoryCard extends StatelessWidget {
  const _MovieHistoryCard({required this.item});

  final HistoryMovieItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey<String>('movies-watched-event-${item.eventId}'),
      borderRadius: AppRadius.borderLarge,
      onTap: () {
        context.pushNamed(
          AppRoute.movieDetails.name,
          pathParameters: <String, String>{
            'movieId': item.movieTmdbId.toString(),
          },
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AspectRatio(
            aspectRatio: 2 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                ClipRRect(
                  borderRadius: AppRadius.borderLarge,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh,
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: item.posterUrl == null
                        ? const _MoviePosterPlaceholder()
                        : ServerNetworkImage(
                            imageUrl: item.posterUrl!,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (
                                  BuildContext context,
                                  Object error,
                                  StackTrace? stackTrace,
                                ) {
                                  return const _MoviePosterPlaceholder();
                                },
                          ),
                  ),
                ),
                Positioned(
                  top: AppSpacing.xs,
                  right: AppSpacing.xs,
                  child: BlocBuilder<MovieHistoryCubit, MovieHistoryState>(
                    buildWhen:
                        (
                          MovieHistoryState previous,
                          MovieHistoryState current,
                        ) {
                          return previous.mutatingEventIds !=
                                  current.mutatingEventIds ||
                              previous.mutatingMovieIds !=
                                  current.mutatingMovieIds;
                        },
                    builder: (BuildContext context, MovieHistoryState state) {
                      final bool isLoading =
                          state.isEventMutating(item.eventId) ||
                          state.isMovieMutating(item.movieId);

                      return _MovieHistoryActionButton(
                        eventId: item.eventId,
                        isLoading: isLoading,
                        onPressed: isLoading
                            ? null
                            : () {
                                _showMovieHistoryActions(context, item);
                              },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          SizedBox(
            height: 20,
            child: Text(
              item.movieTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          SizedBox(
            height: 18,
            child: Text(
              _formatMovieWatchedDate(item.watchedAt),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),

          SizedBox(
            height: 18,
            child: Text(
              _formatMovieWatchedTime(item.watchedAt),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _MovieHistoryActionButton extends StatelessWidget {
  const _MovieHistoryActionButton({
    required this.eventId,
    required this.isLoading,
    required this.onPressed,
  });

  final String eventId;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: ValueKey<String>('movies-watched-action-$eventId'),
      color: AppColors.surface.withValues(alpha: 0.88),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_rounded, size: 20),
          ),
        ),
      ),
    );
  }
}

class _MoviePosterPlaceholder extends StatelessWidget {
  const _MoviePosterPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.movie_outlined, size: 36, color: AppColors.textMuted),
    );
  }
}

class _MoviesLoading extends StatelessWidget {
  const _MoviesLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: ValueKey<String>('movies-loading'),
      child: CircularProgressIndicator(),
    );
  }
}

class _MoviesFailure extends StatelessWidget {
  const _MoviesFailure({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey<String>('movies-failure'),
      child: Padding(
        padding: AppSpacing.cardPaddingLarge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.tonalIcon(
              key: const ValueKey<String>('movies-retry'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoviesEmpty extends StatelessWidget {
  const _MoviesEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey<String>('movies-empty'),
      child: Padding(
        padding: AppSpacing.cardPaddingLarge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.movie_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Your movie library is empty',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add movies from Search or Explore to build your Watchlist.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoviesNoResults extends StatelessWidget {
  const _MoviesNoResults({
    required this.hasSearchQuery,
    required this.hasActiveFilter,
    required this.onClear,
  });

  final bool hasSearchQuery;
  final bool hasActiveFilter;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final String message;

    if (hasSearchQuery && hasActiveFilter) {
      message = 'No movies match your search and selected filter.';
    } else if (hasSearchQuery) {
      message = 'No movies match your search.';
    } else {
      message = 'No movies match the selected filter.';
    }

    return Center(
      key: const ValueKey<String>('movies-no-results'),
      child: Padding(
        padding: AppSpacing.cardPaddingLarge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No movies found',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.tonalIcon(
              key: const ValueKey<String>('movies-clear-filters'),
              onPressed: onClear,
              icon: const Icon(Icons.filter_alt_off_rounded),
              label: const Text('Clear search and filters'),
            ),
          ],
        ),
      ),
    );
  }
}

String _movieMetadata(LibraryMovie movie) {
  final List<String> parts = <String>[];

  final DateTime? releaseDate = movie.releaseDate;

  if (releaseDate != null) {
    parts.add(releaseDate.year.toString());
  }

  if (movie.voteAverage > 0) {
    parts.add(movie.voteAverage.toStringAsFixed(1));
  }

  return parts.isEmpty ? movie.movieStatus : parts.join(' • ');
}

String _moviesFilterLabel(MoviesFilter filter) {
  return switch (filter) {
    MoviesFilter.all => 'All',
    MoviesFilter.watchlist => 'Watchlist',
    MoviesFilter.watched => 'Watched',
    MoviesFilter.comingSoon => 'Coming Soon',
  };
}

String _moviesSortLabel(MoviesSort sort) {
  return switch (sort) {
    MoviesSort.recentlyUpdated => 'Recently updated',
    MoviesSort.title => 'Title',
    MoviesSort.releaseDateNewest => 'Newest release',
    MoviesSort.releaseDateOldest => 'Oldest release',
    MoviesSort.ratingHighest => 'Highest rated',
  };
}

Future<void> _showMovieHistoryActions(
  BuildContext context,
  HistoryMovieItem item,
) async {
  final MovieHistoryCubit cubit = context.read<MovieHistoryCubit>();

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppColors.surfaceHigh,
    builder: (BuildContext sheetContext) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: AppSpacing.cardPaddingLarge,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                item.movieTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Watched ${_formatMovieWatchedAt(item.watchedAt)}',
                style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.tonalIcon(
                key: ValueKey<String>('movies-watched-rewatch-${item.eventId}'),
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  cubit.recordWatch(item.movieId);
                },
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Watched again'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                key: ValueKey<String>('movies-watched-remove-${item.eventId}'),
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  cubit.deleteWatchEvent(
                    movieId: item.movieId,
                    eventId: item.eventId,
                  );
                },
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Remove this watch'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

String _formatMovieWatchedDate(DateTime watchedAt) {
  final DateTime local = watchedAt.toLocal();

  final String day = local.day.toString().padLeft(2, '0');
  final String month = local.month.toString().padLeft(2, '0');

  return '$day/$month/${local.year}';
}

String _formatMovieWatchedTime(DateTime watchedAt) {
  final DateTime local = watchedAt.toLocal();

  final String hour = local.hour.toString().padLeft(2, '0');
  final String minute = local.minute.toString().padLeft(2, '0');

  return '$hour:$minute';
}

String _formatMovieWatchedAt(DateTime watchedAt) {
  return '${_formatMovieWatchedDate(watchedAt)} · '
      '${_formatMovieWatchedTime(watchedAt)}';
}
