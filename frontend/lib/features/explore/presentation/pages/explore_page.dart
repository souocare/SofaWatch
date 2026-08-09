import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/features/explore/application/cubit/explore_cubit.dart';
import 'package:sofawatch/features/explore/data/repositories/api_explore_repository.dart';
import 'package:sofawatch/features/explore/presentation/views/explore_view.dart';
import 'package:sofawatch/features/library/application/cubit/library_cubit.dart';
import 'package:sofawatch/features/library/data/repositories/api_library_repository.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ApiClient apiClient = context.read<ApiClient>();

    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<ExploreCubit>(
          create: (BuildContext context) {
            return ExploreCubit(ApiExploreRepository(apiClient))..load();
          },
        ),
        BlocProvider<LibraryCubit>(
          create: (BuildContext context) {
            return LibraryCubit(ApiLibraryRepository(apiClient));
          },
        ),
      ],
      child: const ExploreView(),
    );
  }
}
