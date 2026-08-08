import 'package:flutter/material.dart';
import 'package:sofawatch/app/theme/tokens/app_spacing.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/search/domain/entities/search_result.dart';
import 'package:sofawatch/features/search/presentation/widgets/search_result_row.dart';

class SearchResultsSection extends StatefulWidget {
  const SearchResultsSection({
    required this.results,
    required this.onResultPressed,
    required this.scrollable,
    this.onResultActionPressed,
    this.compact = false,
    this.onLoadMore,
    this.isLoadingMore = false,
    this.paginationError,
    this.onPaginationRetry,
    this.isActionAvailable,
    this.isActionLoading,
    this.isActionAdded,
    super.key,
  });

  final List<SearchResult> results;
  final ValueChanged<SearchResult> onResultPressed;
  final ValueChanged<SearchResult>? onResultActionPressed;

  /// Mobile usa uma lista com scroll próprio.
  ///
  /// Desktop usa uma lista não scrollável porque já está dentro de um
  /// SingleChildScrollView.
  final bool scrollable;

  final bool compact;

  /// Chamado quando a lista se aproxima do fim.
  ///
  /// No mobile, esta secção gere o próprio ScrollController.
  /// No desktop, o scroll é gerido pelo contentor exterior.
  final VoidCallback? onLoadMore;

  /// Indica que uma página adicional está a ser carregada.
  final bool isLoadingMore;

  /// Erro não bloqueante ocorrido durante paginação.
  ///
  /// Os resultados existentes continuam visíveis.
  final AppException? paginationError;

  /// Repete apenas a tentativa de carregar a próxima página.
  final VoidCallback? onPaginationRetry;
  final bool Function(SearchResult)? isActionAvailable;
  final bool Function(SearchResult)? isActionLoading;
  final bool Function(SearchResult)? isActionAdded;

  @override
  State<SearchResultsSection> createState() {
    return _SearchResultsSectionState();
  }
}

class _SearchResultsSectionState extends State<SearchResultsSection> {
  static const double _loadMoreThreshold = 240;

  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();

    _configureScrollController();
  }

  @override
  void didUpdateWidget(SearchResultsSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.scrollable != widget.scrollable) {
      _disposeScrollController();
      _configureScrollController();
    }
  }

  void _configureScrollController() {
    if (!widget.scrollable) {
      return;
    }

    _scrollController = ScrollController()..addListener(_handleScroll);
  }

  void _handleScroll() {
    final ScrollController? controller = _scrollController;

    if (controller == null ||
        !controller.hasClients ||
        widget.onLoadMore == null ||
        widget.isLoadingMore ||
        widget.paginationError != null) {
      return;
    }

    final ScrollPosition position = controller.position;

    final double distanceFromEnd = position.maxScrollExtent - position.pixels;

    if (distanceFromEnd <= _loadMoreThreshold) {
      widget.onLoadMore!();
    }
  }

  void _disposeScrollController() {
    _scrollController?.removeListener(_handleScroll);
    _scrollController?.dispose();
    _scrollController = null;
  }

  @override
  void dispose() {
    _disposeScrollController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.results.isEmpty) {
      return const SizedBox.shrink();
    }

    if (widget.scrollable) {
      return _buildScrollableResults();
    }

    return _buildNonScrollableResults();
  }

  Widget _buildScrollableResults() {
    return CustomScrollView(
      key: const ValueKey<String>('search-results-scroll-view'),
      controller: _scrollController,
      slivers: <Widget>[
        const SliverToBoxAdapter(child: _SearchResultsHeader()),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
        SliverList.separated(
          itemCount: widget.results.length,
          itemBuilder: (BuildContext context, int index) {
            return _buildResultRow(widget.results[index]);
          },
          separatorBuilder: (BuildContext context, int index) {
            return const Divider(height: 1);
          },
        ),
        SliverToBoxAdapter(child: _buildPaginationFooter()),
      ],
    );
  }

  Widget _buildNonScrollableResults() {
    return Column(
      key: const ValueKey<String>('search-results-column'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _SearchResultsHeader(),
        const SizedBox(height: AppSpacing.md),
        for (int index = 0; index < widget.results.length; index++) ...<Widget>[
          _buildResultRow(widget.results[index]),
          if (index < widget.results.length - 1) const Divider(height: 1),
        ],
        _buildPaginationFooter(),
      ],
    );
  }

  Widget _buildResultRow(SearchResult result) {
    final bool actionAvailable = widget.isActionAvailable?.call(result) ?? true;

    final bool actionLoading = widget.isActionLoading?.call(result) ?? false;

    final bool actionAdded = widget.isActionAdded?.call(result) ?? false;

    return SearchResultRow(
      result: result,
      compact: widget.compact,
      actionLoading: actionLoading,
      actionAdded: actionAdded,
      onPressed: () {
        widget.onResultPressed(result);
      },
      onActionPressed: widget.onResultActionPressed == null || !actionAvailable
          ? null
          : () {
              widget.onResultActionPressed!(result);
            },
    );
  }

  Widget _buildPaginationFooter() {
    if (widget.isLoadingMore) {
      return const Padding(
        key: ValueKey<String>('search-pagination-loading'),
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (widget.paginationError != null) {
      return Padding(
        key: const ValueKey<String>('search-pagination-error'),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.lg,
          horizontal: AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Could not load more results.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              key: const ValueKey<String>('search-pagination-retry'),
              onPressed: widget.onPaginationRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _SearchResultsHeader extends StatelessWidget {
  const _SearchResultsHeader();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Top Results',
      key: const ValueKey<String>('search-top-results-title'),
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}
