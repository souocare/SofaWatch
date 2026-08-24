import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/router/route_paths.dart';
import 'package:sofawatch/app/theme/tokens/app_colors.dart';
import 'package:sofawatch/app/theme/tokens/app_radius.dart';
import 'package:sofawatch/app/theme/tokens/app_spacing.dart';
import 'package:sofawatch/app/theme/tokens/app_typography.dart';
import 'package:sofawatch/core/errors/app_error_message_mapper.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_cubit.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_handoff_exchange_cubit.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_handoff_exchange_state.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_state.dart';

class AuthHandoffExchangePage extends StatefulWidget {
  const AuthHandoffExchangePage({required this.token, super.key});

  final String? token;

  @override
  State<AuthHandoffExchangePage> createState() {
    return _AuthHandoffExchangePageState();
  }
}

class _AuthHandoffExchangePageState extends State<AuthHandoffExchangePage> {
  bool _exchangeStarted = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _handleAuthState(context.read<AuthCubit>().state);
    });
  }

  void _handleAuthState(AuthState state) {
    if (_exchangeStarted) {
      return;
    }

    //
    // A Web session may already exist. In that case the router will
    // redirect the authenticated user away from the handoff route.
    //
    if (state is AuthAuthenticated) {
      return;
    }

    //
    // Wait for the application's initial session restoration to finish.
    //
    // Starting the handoff exchange while AuthCubit.restore() is still
    // running could allow that older restore request to overwrite the
    // newly-authenticated state afterwards.
    //
    if (state is AuthInitial || state is AuthChecking) {
      return;
    }

    _exchangeStarted = true;

    context.read<AuthHandoffExchangeCubit>().exchange(widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (BuildContext context, AuthState state) {
        _handleAuthState(state);
      },
      child: BlocListener<AuthHandoffExchangeCubit, AuthHandoffExchangeState>(
        listener: (BuildContext context, AuthHandoffExchangeState state) {
          if (state case AuthHandoffExchangeSuccess(:final session)) {
            context.read<AuthCubit>().authenticated(session);
          }
        },
        child: Scaffold(
          key: const ValueKey<String>('auth-handoff-page'),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLow,
                      borderRadius: AppRadius.detailsModal,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(AppSpacing.xxxl),
                      child: _AuthHandoffContent(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthHandoffContent extends StatelessWidget {
  const _AuthHandoffContent();

  @override
  Widget build(BuildContext context) {
    final AuthState authState = context.watch<AuthCubit>().state;

    return BlocBuilder<AuthHandoffExchangeCubit, AuthHandoffExchangeState>(
      builder: (BuildContext context, AuthHandoffExchangeState state) {
        if (authState is AuthInitial || authState is AuthChecking) {
          return const _AuthHandoffLoading();
        }

        return switch (state) {
          AuthHandoffExchangeInitial() ||
          AuthHandoffExchangeLoading() ||
          AuthHandoffExchangeSuccess() => const _AuthHandoffLoading(),

          AuthHandoffExchangeInvalid() => const _AuthHandoffInvalid(),

          AuthHandoffExchangeFailure(:final error) => _AuthHandoffFailure(
            error: error,
          ),
        };
      },
    );
  }
}

class _AuthHandoffLoading extends StatelessWidget {
  const _AuthHandoffLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('auth-handoff-loading'),
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(),
        ),

        const SizedBox(height: AppSpacing.xxl),

        Text(
          'Opening SofaWatch',
          textAlign: TextAlign.center,
          style: AppTypography.headlineLargeMobile,
        ),

        const SizedBox(height: AppSpacing.md),

        Text(
          'Signing you in securely…',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _AuthHandoffInvalid extends StatelessWidget {
  const _AuthHandoffInvalid();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('auth-handoff-invalid'),
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(Icons.link_off_rounded, size: 42, color: AppColors.error),

        const SizedBox(height: AppSpacing.xxl),

        Text(
          'This link is no longer valid',
          textAlign: TextAlign.center,
          style: AppTypography.headlineLargeMobile,
        ),

        const SizedBox(height: AppSpacing.md),

        Text(
          'The authentication link may have expired or already been used. '
          'Open SofaWatch Web again from the mobile app or sign in manually.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),

        const SizedBox(height: AppSpacing.xxxl),

        FilledButton(
          key: const ValueKey<String>('auth-handoff-sign-in'),
          onPressed: () {
            context.go(RoutePaths.login);
          },
          child: const Text('Sign in'),
        ),
      ],
    );
  }
}

class _AuthHandoffFailure extends StatelessWidget {
  const _AuthHandoffFailure({required this.error});

  final AppException error;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('auth-handoff-failure'),
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(
          Icons.error_outline_rounded,
          size: 42,
          color: AppColors.error,
        ),

        const SizedBox(height: AppSpacing.xxl),

        Text(
          'Could not open SofaWatch',
          textAlign: TextAlign.center,
          style: AppTypography.headlineLargeMobile,
        ),

        const SizedBox(height: AppSpacing.md),

        Text(
          AppErrorMessageMapper.map(error),
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),

        const SizedBox(height: AppSpacing.xxxl),

        FilledButton(
          key: const ValueKey<String>('auth-handoff-retry'),
          onPressed: () {
            context.read<AuthHandoffExchangeCubit>().retry();
          },
          child: const Text('Retry'),
        ),
      ],
    );
  }
}
