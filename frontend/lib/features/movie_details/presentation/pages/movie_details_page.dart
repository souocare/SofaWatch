import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/features/movie_details/application/cubit/movie_details_cubit.dart';
import 'package:sofawatch/features/movie_details/application/cubit/movie_details_state.dart';
import 'package:sofawatch/features/movie_details/presentation/widgets/movie_details_content.dart';
import 'package:sofawatch/features/movie_details/presentation/widgets/movie_details_state_views.dart';

class MovieDetailsPage extends StatelessWidget {
  const MovieDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocBuilder<MovieDetailsCubit, MovieDetailsState>(
        builder: (BuildContext context, MovieDetailsState state) {
          return switch (state) {
            MovieDetailsInitial() ||
            MovieDetailsLoading() => const MovieDetailsLoadingView(),
            MovieDetailsSuccess(:final details) => MovieDetailsContent(
              details: details,
            ),

            MovieDetailsFailure(:final error) => SafeArea(
              child: MovieDetailsFailureView(
                isTimeout: error.isTimeout,
                onRetry: context.read<MovieDetailsCubit>().retry,
              ),
            ),
          };
        },
      ),
    );
  }
}
