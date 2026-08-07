import 'package:flutter/material.dart';
import 'package:sofawatch/app/theme/tokens/app_breakpoints.dart';
import 'package:sofawatch/features/search/presentation/views/search_desktop_view.dart';
import 'package:sofawatch/features/search/presentation/views/search_mobile_view.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool useDesktopLayout =
            constraints.maxWidth >= AppBreakpoints.tablet;

        if (useDesktopLayout) {
          return const SearchDesktopView();
        }

        return const SearchMobileView();
      },
    );
  }
}
