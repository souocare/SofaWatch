import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/app/theme/tokens/app_breakpoints.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/features/library/application/cubit/library_cubit.dart';
import 'package:sofawatch/features/library/data/repositories/api_library_repository.dart';
import 'package:sofawatch/features/search/presentation/views/search_desktop_view.dart';
import 'package:sofawatch/features/search/presentation/views/search_mobile_view.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LibraryCubit>(
      create: (BuildContext context) {
        return LibraryCubit(ApiLibraryRepository(context.read<ApiClient>()));
      },
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool desktop = constraints.maxWidth >= AppBreakpoints.tablet;

          if (desktop) {
            return const SearchDesktopView();
          }

          return const SearchMobileView();
        },
      ),
    );
  }
}
