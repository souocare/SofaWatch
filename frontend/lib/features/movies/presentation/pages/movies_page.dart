import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/router/app_routes.dart';
import 'package:sofawatch/app/theme/tokens/app_breakpoints.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
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
        child: BlocConsumer<MoviesCubit, MoviesState>(
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

            if (state.watched.isNotEmpty)
              SliverToBoxAdapter(
                child: _MoviesContentBounds(
                  child: _MovieSection(
                    title: 'Watched',
                    movies: state.watched,
                    sectionKey: 'movies-watched',
                  ),
                ),
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
  });

  final String title;
  final List<LibraryMovie> movies;
  final String sectionKey;

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
                _ => 2,
              };

              return GridView.builder(
                key: ValueKey<String>('$sectionKey-grid'),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: movies.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.lg,
                  childAspectRatio: 0.58,
                ),
                itemBuilder: (BuildContext context, int index) {
                  return _MovieCard(movie: movies[index]);
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
  const _MovieCard({required this.movie});

  final LibraryMovie movie;

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
          Expanded(
            child: ClipRRect(
              borderRadius: AppRadius.borderLarge,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: SizedBox.expand(
                  child: movie.posterUrl == null
                      ? const _MoviePosterPlaceholder()
                      : Image.network(
                          movie.posterUrl!,
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
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            movie.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
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
