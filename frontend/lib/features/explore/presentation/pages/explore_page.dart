import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/features/explore/application/cubit/explore_cubit.dart';
import 'package:sofawatch/features/explore/data/repositories/api_explore_repository.dart';
import 'package:sofawatch/features/explore/presentation/views/explore_view.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ExploreCubit>(
      create: (BuildContext context) {
        return ExploreCubit(ApiExploreRepository(context.read<ApiClient>()))
          ..load();
      },
      child: const ExploreView(),
    );
  }
}
