import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/router/app_routes.dart';
import 'package:sofawatch/app/router/app_shell.dart';
import 'package:sofawatch/app/router/details_modal_page.dart';
import 'package:sofawatch/app/router/not_found_page.dart';
import 'package:sofawatch/app/router/route_paths.dart';
import 'package:sofawatch/app/theme/tokens/app_breakpoints.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/navigation/web_app_launcher.dart';
import 'package:sofawatch/core/server/repositories/server_configuration_repository.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_cubit.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_state.dart';
import 'package:sofawatch/features/auth/domain/repositories/auth_handoff_repository.dart';
import 'package:sofawatch/features/auth/presentation/pages/auth_checking_page.dart';
import 'package:sofawatch/features/episode_details/application/cubit/episode_details_cubit.dart';
import 'package:sofawatch/features/episode_details/data/repositories/api_episode_details_repository.dart';
import 'package:sofawatch/features/episode_details/presentation/pages/episode_details_page.dart';
import 'package:sofawatch/features/episode_progress/data/repositories/api_episode_progress_repository.dart';
import 'package:sofawatch/features/explore/presentation/pages/explore_page.dart';
import 'package:sofawatch/features/history/application/cubit/history_cubit.dart';
import 'package:sofawatch/features/history/application/cubit/history_preview_cubit.dart';
import 'package:sofawatch/features/history/data/repositories/api_history_repository.dart';
import 'package:sofawatch/features/history/presentation/pages/history_page.dart';
import 'package:sofawatch/features/home/application/cubit/home_cubit.dart';
import 'package:sofawatch/features/home/presentation/pages/home_page.dart';
import 'package:sofawatch/features/library/application/cubit/library_collection_cubit.dart';
import 'package:sofawatch/features/library/application/cubit/library_cubit.dart';
import 'package:sofawatch/features/library/application/cubit/library_preview_cubit.dart';
import 'package:sofawatch/features/library/data/repositories/api_library_repository.dart';
import 'package:sofawatch/features/library/domain/models/library_media_key.dart';
import 'package:sofawatch/features/library/domain/models/library_media_type.dart';
import 'package:sofawatch/features/library/presentation/pages/library_collection_page.dart';
import 'package:sofawatch/features/movie_details/application/cubit/movie_details_cubit.dart';
import 'package:sofawatch/features/movie_details/data/repositories/api_movie_details_repository.dart';
import 'package:sofawatch/features/movie_details/presentation/pages/movie_details_page.dart';
import 'package:sofawatch/features/movies/application/cubit/movies_cubit.dart';
import 'package:sofawatch/features/movies/data/repositories/api_movies_repository.dart';
import 'package:sofawatch/features/movies/presentation/pages/movies_page.dart';
import 'package:sofawatch/features/profile/application/cubit/data_transfer_cubit.dart';
import 'package:sofawatch/features/profile/application/cubit/profile_cubit.dart';
import 'package:sofawatch/features/profile/application/services/open_web_app_service.dart';
import 'package:sofawatch/features/profile/data/repositories/api_data_transfer_repository.dart';
import 'package:sofawatch/features/profile/data/repositories/api_profile_repository.dart';
import 'package:sofawatch/features/profile/presentation/pages/profile_page.dart';
import 'package:sofawatch/features/search/application/bloc/search_bloc.dart';
import 'package:sofawatch/features/search/domain/repositories/search_repository.dart';
import 'package:sofawatch/features/search/presentation/pages/search_page.dart';
import 'package:sofawatch/features/server/data/repositories/api_server_repository.dart';
import 'package:sofawatch/features/server/domain/repositories/server_repository.dart';
import 'package:sofawatch/features/server_setup/application/cubit/server_setup_cubit.dart';
import 'package:sofawatch/features/server_setup/domain/services/server_connection_tester.dart';
import 'package:sofawatch/features/server_setup/presentation/pages/server_setup_page.dart';
import 'package:sofawatch/features/show_details/application/cubit/show_details_cubit.dart';
import 'package:sofawatch/features/show_details/application/cubit/show_details_seasons_cubit.dart';
import 'package:sofawatch/features/show_details/data/repositories/api_show_details_repository.dart';
import 'package:sofawatch/features/show_details/data/repositories/api_show_details_seasons_repository.dart';
import 'package:sofawatch/features/show_details/presentation/pages/show_details_page.dart';
import 'package:sofawatch/features/shows/application/cubit/shows_cubit.dart';
import 'package:sofawatch/features/shows/data/repositories/api_shows_repository.dart';
import 'package:sofawatch/features/shows/presentation/pages/shows_page.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_activity_cubit.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_backlog_cubit.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_content_insights_cubit.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_cubit.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_habits_cubit.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_library_cubit.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_summary_cubit.dart';
import 'package:sofawatch/features/statistics/data/repositories/api_statistics_repository.dart';
import 'package:sofawatch/features/statistics/presentation/pages/detailed_statistics_page.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_entry_cubit.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_entry_state.dart';
import 'package:sofawatch/features/auth/presentation/pages/initial_setup_page.dart';
import 'package:sofawatch/features/auth/presentation/pages/login_page.dart';
import 'package:sofawatch/features/auth/application/cubit/login_cubit.dart';
import 'package:sofawatch/features/auth/domain/repositories/auth_repository.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_handoff_exchange_cubit.dart';
import 'package:sofawatch/features/auth/presentation/pages/auth_handoff_exchange_page.dart';
import 'package:sofawatch/features/security/data/repositories/api_security_settings_repository.dart';
import 'package:sofawatch/features/security/domain/repositories/security_settings_repository.dart';
import 'package:sofawatch/features/auth/application/cubit/password_recovery_cubit.dart';
import 'package:sofawatch/features/auth/data/repositories/api_password_recovery_repository.dart';
import 'package:sofawatch/features/auth/presentation/pages/password_recovery_page.dart';
import 'package:sofawatch/features/admin_users/data/repositories/api_admin_users_repository.dart';
import 'package:sofawatch/features/admin_users/domain/repositories/admin_users_repository.dart';

GoRouter createAppRouter({
  required ApiClient apiClient,
  AuthCubit? authCubit,
  AuthEntryCubit? authEntryCubit,
  Listenable? refreshListenable,
}) {
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
    refreshListenable: refreshListenable,
    redirect: (BuildContext context, GoRouterState state) {
      final String matchedLocation = state.matchedLocation;

      final bool isServerSetupRoute = matchedLocation == RoutePaths.serverSetup;

      final bool isAuthCheckingRoute =
          matchedLocation == RoutePaths.authChecking;

      final bool isLoginRoute = matchedLocation == RoutePaths.login;

      final bool isInitialSetupRoute =
          matchedLocation == RoutePaths.initialSetup;

      final bool isAuthHandoffRoute = matchedLocation == RoutePaths.authHandoff;
      final bool isPasswordRecoveryRoute =
          matchedLocation == RoutePaths.passwordRecovery;

      final bool isAuthFlowRoute =
          isAuthCheckingRoute ||
          isLoginRoute ||
          isInitialSetupRoute ||
          isAuthHandoffRoute ||
          isPasswordRecoveryRoute;

      final String? requestedReturnLocation = state.uri.queryParameters['from'];

      final bool hasUnsafeAuthReturnLocation =
          requestedReturnLocation != null &&
          !_isSafeAuthReturnLocation(requestedReturnLocation);

      if (!isAuthHandoffRoute &&
          !isPasswordRecoveryRoute &&
          isAuthFlowRoute &&
          hasUnsafeAuthReturnLocation) {
        return _buildAuthFlowLocation(matchedLocation, RoutePaths.home);
      }

      //
      // Native clients need a configured SofaWatch server before
      // authentication can be resolved.
      //
      if (!kIsWeb && !apiClient.isConfigured) {
        if (isServerSetupRoute) {
          return null;
        }

        return RoutePaths.serverSetup;
      }

      //
      // Password recovery must remain publicly reachable regardless
      // of the current authentication state.
      //
      if (isPasswordRecoveryRoute) {
        return null;
      }

      final AuthState? authState = authCubit?.state;

      //
      // Router-isolated tests that do not provide an AuthCubit retain
      // their existing behaviour.
      //
      if (authState == null) {
        if (!kIsWeb && isServerSetupRoute) {
          return RoutePaths.home;
        }

        return null;
      }

      final String returnLocation = _resolveAuthReturnLocation(state);

      if (authState is AuthInitial ||
          authState is AuthChecking ||
          authState is AuthFailure) {
        if (isAuthCheckingRoute || isAuthHandoffRoute) {
          return null;
        }

        return _buildAuthFlowLocation(RoutePaths.authChecking, returnLocation);
      }

      if (authState is AuthAuthenticated) {
        if (isAuthFlowRoute) {
          return returnLocation;
        }

        if (!kIsWeb && isServerSetupRoute) {
          return RoutePaths.home;
        }

        return null;
      }

      if (authState is AuthUnauthenticated) {
        if (isAuthHandoffRoute) {
          return null;
        }
        final AuthEntryState? entryState = authEntryCubit?.state;

        if (entryState == null ||
            entryState is AuthEntryInitial ||
            entryState is AuthEntryChecking ||
            entryState is AuthEntryFailure) {
          if (isAuthCheckingRoute) {
            return null;
          }

          return _buildAuthFlowLocation(
            RoutePaths.authChecking,
            returnLocation,
          );
        }

        if (entryState is AuthEntrySetupRequired) {
          if (isInitialSetupRoute) {
            return null;
          }

          return _buildAuthFlowLocation(
            RoutePaths.initialSetup,
            returnLocation,
          );
        }

        if (entryState is AuthEntryLoginRequired) {
          if (isLoginRoute) {
            return null;
          }

          return _buildAuthFlowLocation(RoutePaths.login, returnLocation);
        }
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
        name: AppRoute.authChecking.name,
        path: RoutePaths.authChecking,
        builder: (BuildContext context, GoRouterState state) {
          return const AuthCheckingPage();
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        name: AppRoute.login.name,
        path: RoutePaths.login,
        builder: (BuildContext context, GoRouterState state) {
          return BlocProvider<LoginCubit>(
            create: (BuildContext context) {
              return LoginCubit(repository: context.read<AuthRepository>());
            },
            child: const LoginPage(),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        name: AppRoute.initialSetup.name,
        path: RoutePaths.initialSetup,
        builder: (BuildContext context, GoRouterState state) {
          return const InitialSetupPage();
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.authHandoff,
        builder: (BuildContext context, GoRouterState state) {
          return BlocProvider<AuthHandoffExchangeCubit>(
            create: (BuildContext context) {
              return AuthHandoffExchangeCubit(
                repository: context.read<AuthHandoffRepository>(),
              );
            },
            child: AuthHandoffExchangePage(
              token: state.uri.queryParameters['token'],
            ),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        name: AppRoute.passwordRecovery.name,
        path: RoutePaths.passwordRecovery,
        builder: (BuildContext context, GoRouterState state) {
          return BlocProvider<PasswordRecoveryCubit>(
            create: (BuildContext context) {
              return PasswordRecoveryCubit(
                repository: ApiPasswordRecoveryRepository(
                  apiClient: context.read<ApiClient>(),
                ),
              );
            },
            child: PasswordRecoveryPage(
              token: state.uri.queryParameters['token'],
            ),
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
                  final ApiClient apiClient = context.read<ApiClient>();

                  return MultiBlocProvider(
                    providers: [
                      BlocProvider<HomeCubit>(
                        create: (BuildContext context) {
                          return HomeCubit(
                            repository: ApiShowsRepository(
                              context.read<ApiClient>(),
                            ),
                          )..load();
                        },
                      ),
                      BlocProvider<StatisticsCubit>(
                        create: (BuildContext context) {
                          return StatisticsCubit(
                            repository: ApiStatisticsRepository(apiClient),
                          )..loadWeeklyStatistics();
                        },
                      ),
                    ],
                    child: const HomePage(),
                  );
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
                  final ApiClient apiClient = context.read<ApiClient>();

                  return BlocProvider<MoviesCubit>(
                    create: (BuildContext context) {
                      return MoviesCubit(
                        repository: ApiMoviesRepository(apiClient),
                      )..load();
                    },
                    child: const MoviesPage(),
                  );
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
                  final ApiClient apiClient = context.read<ApiClient>();

                  return MultiRepositoryProvider(
                    providers: <RepositoryProvider<dynamic>>[
                      RepositoryProvider<ServerRepository>(
                        create: (BuildContext context) {
                          return ApiServerRepository(apiClient);
                        },
                      ),
                      RepositoryProvider<SecuritySettingsRepository>(
                        create: (BuildContext context) {
                          return ApiSecuritySettingsRepository(
                            apiClient: apiClient,
                          );
                        },
                      ),
                      RepositoryProvider<AdminUsersRepository>(
                        create: (BuildContext context) {
                          return ApiAdminUsersRepository(apiClient: apiClient);
                        },
                      ),
                      RepositoryProvider<OpenWebAppService>(
                        create: (BuildContext context) {
                          return OpenWebAppService(
                            apiClient: apiClient,
                            authHandoffRepository: context
                                .read<AuthHandoffRepository>(),
                            launcher: const ExternalWebAppLauncher(),
                          );
                        },
                      ),
                    ],
                    child: MultiBlocProvider(
                      providers: <BlocProvider<dynamic>>[
                        BlocProvider<ProfileCubit>(
                          create: (BuildContext context) {
                            return ProfileCubit(
                              repository: ApiProfileRepository(
                                context.read<ApiClient>(),
                              ),
                            )..load();
                          },
                        ),
                        if (kIsWeb)
                          BlocProvider<DataTransferCubit>(
                            create: (BuildContext context) {
                              return DataTransferCubit(
                                repository: ApiDataTransferRepository(
                                  context.read<ApiClient>(),
                                ),
                              );
                            },
                          ),
                        BlocProvider<StatisticsSummaryCubit>(
                          create: (BuildContext context) {
                            return StatisticsSummaryCubit(
                              repository: ApiStatisticsRepository(
                                context.read<ApiClient>(),
                              ),
                            )..load();
                          },
                        ),
                        BlocProvider<LibraryPreviewCubit>(
                          create: (BuildContext context) {
                            return LibraryPreviewCubit(
                              repository: ApiLibraryRepository(
                                context.read<ApiClient>(),
                              ),
                            )..load();
                          },
                        ),
                        BlocProvider<HistoryPreviewCubit>(
                          create: (BuildContext context) {
                            return HistoryPreviewCubit(
                              repository: ApiHistoryRepository(
                                context.read<ApiClient>(),
                              ),
                            )..load();
                          },
                        ),
                      ],
                      child: const ProfilePage(),
                    ),
                  );
                },
                routes: <RouteBase>[
                  GoRoute(
                    name: AppRoute.detailedStatistics.name,
                    path: RoutePaths.detailedStatistics,
                    builder: (BuildContext context, GoRouterState state) {
                      final ApiClient apiClient = context.read<ApiClient>();

                      return MultiBlocProvider(
                        providers: <BlocProvider<dynamic>>[
                          BlocProvider<StatisticsSummaryCubit>(
                            create: (BuildContext context) {
                              return StatisticsSummaryCubit(
                                repository: ApiStatisticsRepository(apiClient),
                              )..load();
                            },
                          ),
                          BlocProvider<StatisticsActivityCubit>(
                            create: (BuildContext context) {
                              return StatisticsActivityCubit(
                                repository: ApiStatisticsRepository(apiClient),
                              )..load();
                            },
                          ),
                          BlocProvider<StatisticsHabitsCubit>(
                            create: (BuildContext context) {
                              return StatisticsHabitsCubit(
                                repository: ApiStatisticsRepository(apiClient),
                              )..load();
                            },
                          ),
                          BlocProvider<StatisticsContentInsightsCubit>(
                            create: (BuildContext context) {
                              return StatisticsContentInsightsCubit(
                                repository: ApiStatisticsRepository(apiClient),
                              )..load();
                            },
                          ),
                          BlocProvider<StatisticsLibraryCubit>(
                            create: (BuildContext context) {
                              return StatisticsLibraryCubit(
                                repository: ApiStatisticsRepository(apiClient),
                              )..load();
                            },
                          ),
                          BlocProvider<StatisticsBacklogCubit>(
                            create: (BuildContext context) {
                              return StatisticsBacklogCubit(
                                repository: ApiStatisticsRepository(apiClient),
                              )..load();
                            },
                          ),
                        ],
                        child: const DetailedStatisticsPage(),
                      );
                    },
                  ),
                  GoRoute(
                    name: AppRoute.libraryCollection.name,
                    path: RoutePaths.libraryCollection,
                    builder: (BuildContext context, GoRouterState state) {
                      final String? rawTab = state.uri.queryParameters['tab'];

                      final LibraryCollectionTab initialTab = switch (rawTab) {
                        'movies' => LibraryCollectionTab.movies,
                        _ => LibraryCollectionTab.shows,
                      };

                      return BlocProvider<LibraryCollectionCubit>(
                        create: (BuildContext context) {
                          final ApiClient apiClient = context.read<ApiClient>();

                          return LibraryCollectionCubit(
                            showsRepository: ApiShowsRepository(apiClient),
                            moviesRepository: ApiMoviesRepository(apiClient),
                          )..load();
                        },
                        child: LibraryCollectionPage(initialTab: initialTab),
                      );
                    },
                  ),
                  GoRoute(
                    name: AppRoute.history.name,
                    path: RoutePaths.history,
                    builder: (BuildContext context, GoRouterState state) {
                      return BlocProvider<HistoryCubit>(
                        create: (BuildContext context) {
                          return HistoryCubit(
                            repository: ApiHistoryRepository(
                              context.read<ApiClient>(),
                            ),
                          )..load();
                        },
                        child: const HistoryPage(),
                      );
                    },
                  ),
                ],
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
            child: BlocProvider<EpisodeDetailsCubit>(
              create: (BuildContext context) {
                return EpisodeDetailsCubit(
                  repository: ApiEpisodeDetailsRepository(apiClient),
                  progressRepository: ApiEpisodeProgressRepository(apiClient),
                  episodeId: episodeId,
                )..load();
              },
              child: const EpisodeDetailsPage(),
            ),
          );
        },
      ),
    ],
  );
}

String _resolveAuthReturnLocation(GoRouterState state) {
  final String? requestedReturnLocation = state.uri.queryParameters['from'];

  if (_isSafeAuthReturnLocation(requestedReturnLocation)) {
    return requestedReturnLocation!;
  }

  final String currentLocation = state.uri.toString();

  if (_isSafeAuthReturnLocation(currentLocation)) {
    return currentLocation;
  }

  return RoutePaths.home;
}

bool _isSafeAuthReturnLocation(String? location) {
  if (location == null ||
      location.isEmpty ||
      !location.startsWith('/') ||
      location.startsWith('//')) {
    return false;
  }

  final Uri? uri = Uri.tryParse(location);

  if (uri == null) {
    return false;
  }

  final String path = uri.path;

  return path != RoutePaths.authChecking &&
      path != RoutePaths.login &&
      path != RoutePaths.initialSetup &&
      path != RoutePaths.authHandoff &&
      path != RoutePaths.serverSetup;
}

String _buildAuthFlowLocation(String path, String returnLocation) {
  return Uri(
    path: path,
    queryParameters: <String, String>{'from': returnLocation},
  ).toString();
}
