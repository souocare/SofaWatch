import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/router/app_routes.dart';
import 'package:sofawatch/app/router/app_shell.dart';
import 'package:sofawatch/app/router/details_modal_page.dart';
import 'package:sofawatch/app/router/details_placeholder_page.dart';
import 'package:sofawatch/app/router/not_found_page.dart';
import 'package:sofawatch/app/router/route_paths.dart';
import 'package:sofawatch/app/theme/tokens/app_breakpoints.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/server/repositories/server_configuration_repository.dart';
import 'package:sofawatch/features/explore/presentation/pages/explore_page.dart';
import 'package:sofawatch/features/home/presentation/pages/home_page.dart';
import 'package:sofawatch/features/library/domain/models/library_media_key.dart';
import 'package:sofawatch/features/library/domain/models/library_media_type.dart';
import 'package:sofawatch/features/movie_details/application/cubit/movie_details_cubit.dart';
import 'package:sofawatch/features/movie_details/data/repositories/api_movie_details_repository.dart';
import 'package:sofawatch/features/movie_details/presentation/pages/movie_details_page.dart';
import 'package:sofawatch/features/movies/presentation/pages/movies_page.dart';
import 'package:sofawatch/features/profile/presentation/pages/profile_page.dart';
import 'package:sofawatch/features/search/application/bloc/search_bloc.dart';
import 'package:sofawatch/features/search/domain/repositories/search_repository.dart';
import 'package:sofawatch/features/search/presentation/pages/search_page.dart';
import 'package:sofawatch/features/server_setup/application/cubit/server_setup_cubit.dart';
import 'package:sofawatch/features/server_setup/domain/services/server_connection_tester.dart';
import 'package:sofawatch/features/server_setup/presentation/pages/server_setup_page.dart';
import 'package:sofawatch/features/show_details/application/cubit/show_details_cubit.dart';
import 'package:sofawatch/features/show_details/data/repositories/api_show_details_repository.dart';
import 'package:sofawatch/features/show_details/presentation/pages/show_details_page.dart';
import 'package:sofawatch/features/shows/presentation/pages/shows_page.dart';
import 'package:sofawatch/features/show_details/application/cubit/show_details_seasons_cubit.dart';
import 'package:sofawatch/features/show_details/data/repositories/api_show_details_seasons_repository.dart';
import 'package:sofawatch/features/library/application/cubit/library_cubit.dart';
import 'package:sofawatch/features/library/data/repositories/api_library_repository.dart';
import 'package:sofawatch/features/shows/application/cubit/shows_cubit.dart';
import 'package:sofawatch/features/shows/data/repositories/api_shows_repository.dart';

GoRouter createAppRouter({required ApiClient apiClient}) {
  final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'root',
  );

  final GlobalKey<NavigatorState> homeNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'home',
  );

  final GlobalKey<NavigatorState> showsNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'shows',
  );

  final GlobalKey<NavigatorState> moviesNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'movies');

  final GlobalKey<NavigatorState> exploreNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'explore');

  final GlobalKey<NavigatorState> profileNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'profile');

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RoutePaths.root,
    overridePlatformDefaultLocation: true,
    redirect: (BuildContext context, GoRouterState state) {
      if (kIsWeb) {
        return null;
      }

      final bool isServerSetupRoute =
          state.matchedLocation == RoutePaths.serverSetup;

      if (!apiClient.isConfigured) {
        if (isServerSetupRoute) {
          return null;
        }

        return RoutePaths.serverSetup;
      }

      if (isServerSetupRoute) {
        return RoutePaths.home;
      }

      return null;
    },
    errorBuilder: (BuildContext context, GoRouterState state) {
      return NotFoundPage(location: state.uri.toString());
    },
    routes: <RouteBase>[
      GoRoute(
        path: RoutePaths.root,
        redirect: (BuildContext context, GoRouterState state) {
          return RoutePaths.home;
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        name: AppRoute.serverSetup.name,
        path: RoutePaths.serverSetup,
        builder: (BuildContext context, GoRouterState state) {
          return BlocProvider<ServerSetupCubit>(
            create: (BuildContext context) {
              return ServerSetupCubit(
                context.read<ServerConfigurationRepository>(),
                context.read<ServerConnectionTester>(),
                context.read<ApiClient>(),
              );
            },
            child: const ServerSetupPage(),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        name: AppRoute.search.name,
        path: RoutePaths.search,
        pageBuilder: (BuildContext context, GoRouterState state) {
          final Widget searchPage = BlocProvider<SearchBloc>(
            create: (BuildContext context) {
              return SearchBloc(context.read<SearchRepository>());
            },
            child: const SearchPage(),
          );

          final double screenWidth = MediaQuery.sizeOf(context).width;

          final bool useDesktopModal = screenWidth >= AppBreakpoints.tablet;

          if (!useDesktopModal) {
            return MaterialPage<void>(key: state.pageKey, child: searchPage);
          }

          return CustomTransitionPage<void>(
            key: state.pageKey,
            opaque: false,
            barrierDismissible: true,
            barrierColor: Colors.black.withValues(alpha: 0.48),
            barrierLabel: 'Dismiss search',
            transitionDuration: const Duration(milliseconds: 220),
            reverseTransitionDuration: const Duration(milliseconds: 180),
            child: searchPage,
            transitionsBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                  Widget child,
                ) {
                  final Animation<double> curvedAnimation = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                    reverseCurve: Curves.easeInCubic,
                  );

                  return FadeTransition(
                    opacity: curvedAnimation,
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.985,
                        end: 1,
                      ).animate(curvedAnimation),
                      child: child,
                    ),
                  );
                },
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell navigationShell,
            ) {
              return AppShell(navigationShell: navigationShell);
            },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            navigatorKey: homeNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                name: AppRoute.home.name,
                path: RoutePaths.home,
                builder: (BuildContext context, GoRouterState state) {
                  return const HomePage();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: showsNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                name: AppRoute.shows.name,
                path: RoutePaths.shows,
                builder: (BuildContext context, GoRouterState state) {
                  return BlocProvider<ShowsCubit>(
                    create: (BuildContext context) {
                      return ShowsCubit(
                        repository: ApiShowsRepository(
                          context.read<ApiClient>(),
                        ),
                      )..load();
                    },
                    child: const ShowsPage(),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: moviesNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                name: AppRoute.movies.name,
                path: RoutePaths.movies,
                builder: (BuildContext context, GoRouterState state) {
                  return const MoviesPage();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: exploreNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                name: AppRoute.explore.name,
                path: RoutePaths.explore,
                builder: (BuildContext context, GoRouterState state) {
                  return const ExplorePage();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: profileNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                name: AppRoute.profile.name,
                path: RoutePaths.profile,
                builder: (BuildContext context, GoRouterState state) {
                  return const ProfilePage();
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        name: AppRoute.showDetails.name,
        path: RoutePaths.showDetails,
        pageBuilder: (BuildContext context, GoRouterState state) {
          final String rawTmdbId = state.pathParameters['showId']!;
          final int? tmdbId = int.tryParse(rawTmdbId);

          if (tmdbId == null || tmdbId <= 0) {
            return buildDetailsModalPage(
              state: state,
              child: NotFoundPage(location: state.uri.toString()),
            );
          }

          return buildDetailsModalPage(
            state: state,
            child: MultiBlocProvider(
              providers: <BlocProvider<dynamic>>[
                BlocProvider<ShowDetailsCubit>(
                  create: (BuildContext context) {
                    return ShowDetailsCubit(
                      repository: ApiShowDetailsRepository(
                        context.read<ApiClient>(),
                      ),
                      tmdbId: tmdbId,
                    )..load();
                  },
                ),
                BlocProvider<ShowDetailsSeasonsCubit>(
                  create: (BuildContext context) {
                    return ShowDetailsSeasonsCubit(
                      repository: ApiShowDetailsSeasonsRepository(
                        context.read<ApiClient>(),
                      ),
                      showTmdbId: tmdbId,
                    )..loadInitialProgress();
                  },
                ),
                BlocProvider<LibraryCubit>(
                  create: (BuildContext context) {
                    final LibraryCubit cubit = LibraryCubit(
                      ApiLibraryRepository(apiClient),
                    );

                    cubit.loadShowState(
                      LibraryMediaKey(
                        mediaType: LibraryMediaType.show,
                        tmdbId: tmdbId,
                      ),
                    );

                    return cubit;
                  },
                ),
              ],
              child: const ShowDetailsPage(),
            ),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        name: AppRoute.movieDetails.name,
        path: RoutePaths.movieDetails,
        pageBuilder: (BuildContext context, GoRouterState state) {
          final String rawTmdbId = state.pathParameters['movieId']!;
          final int? tmdbId = int.tryParse(rawTmdbId);

          if (tmdbId == null || tmdbId <= 0) {
            return buildDetailsModalPage(
              state: state,
              child: NotFoundPage(location: state.uri.toString()),
            );
          }

          return buildDetailsModalPage(
            state: state,
            child: MultiBlocProvider(
              providers: <BlocProvider<dynamic>>[
                BlocProvider<MovieDetailsCubit>(
                  create: (BuildContext context) {
                    return MovieDetailsCubit(
                      repository: ApiMovieDetailsRepository(apiClient),
                      tmdbId: tmdbId,
                    )..load();
                  },
                ),
                BlocProvider<LibraryCubit>(
                  create: (BuildContext context) {
                    final LibraryCubit cubit = LibraryCubit(
                      ApiLibraryRepository(apiClient),
                    );

                    cubit.loadMovieState(
                      LibraryMediaKey(
                        mediaType: LibraryMediaType.movie,
                        tmdbId: tmdbId,
                      ),
                    );

                    return cubit;
                  },
                ),
              ],
              child: const MovieDetailsPage(),
            ),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        name: AppRoute.episodeDetails.name,
        path: RoutePaths.episodeDetails,
        pageBuilder: (BuildContext context, GoRouterState state) {
          final String episodeId = state.pathParameters['episodeId']!;

          return buildDetailsModalPage(
            state: state,
            child: DetailsPlaceholderPage(
              title: 'Episode Details',
              resourceId: episodeId,
            ),
          );
        },
      ),
    ],
  );
}
