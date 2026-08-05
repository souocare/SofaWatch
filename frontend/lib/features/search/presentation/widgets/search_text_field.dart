import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/features/search/application/bloc/search_bloc.dart';
import 'package:sofawatch/features/search/application/bloc/search_event.dart';

class SearchTextField extends StatefulWidget {
  const SearchTextField({super.key});

  @override
  State<SearchTextField> createState() {
    return _SearchTextFieldState();
  }
}

class _SearchTextFieldState extends State<SearchTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    final String initialQuery = context.read<SearchBloc>().state.query;

    _controller = TextEditingController(text: initialQuery);

    _controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleControllerChanged)
      ..dispose();

    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleQueryChanged(String value) {
    context.read<SearchBloc>().add(SearchQueryChanged(value));
  }

  void _handleSubmitted(String value) {
    context.read<SearchBloc>().add(const SearchSubmitted());
  }

  void _clearQuery() {
    _controller.clear();

    context.read<SearchBloc>().add(const SearchQueryChanged(''));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return TextField(
      key: const ValueKey<String>('search-text-field'),
      controller: _controller,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
      autocorrect: false,
      enableSuggestions: true,
      onChanged: _handleQueryChanged,
      onSubmitted: _handleSubmitted,
      decoration: InputDecoration(
        hintText: 'Search movies and TV shows',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                key: const ValueKey<String>('search-clear-button'),
                tooltip: 'Clear search',
                onPressed: _clearQuery,
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
    );
  }
}
