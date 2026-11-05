import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:sofawatch/app/router/route_paths.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/core/errors/app_error_message_mapper.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_cubit.dart';
import 'package:sofawatch/features/auth/application/cubit/registration_cubit.dart';
import 'package:sofawatch/features/auth/application/cubit/registration_state.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void initState() {
    super.initState();
    context.read<RegistrationCubit>().loadAvailability();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<RegistrationCubit>().submit(
      username: _usernameController.text,
      displayName: _displayNameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );
  }

  void _clearFeedback() {
    context.read<RegistrationCubit>().clearFeedback();
  }

  void _goToLogin() {
    final String? returnLocation = GoRouterState.of(
      context,
    ).uri.queryParameters['from'];

    context.go(
      Uri(
        path: RoutePaths.login,
        queryParameters: returnLocation == null
            ? null
            : <String, String>{'from': returnLocation},
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RegistrationCubit, RegistrationState>(
      listenWhen: (previous, current) => previous != current,
      listener: (context, state) {
        if (state case RegistrationSuccess(:final session)) {
          context.read<AuthCubit>().authenticated(session);
        }
      },
      child: Scaffold(
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
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxxl),
                    child: BlocBuilder<RegistrationCubit, RegistrationState>(
                      builder: (context, state) {
                        return _buildContent(state);
                      },
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

  Widget _buildContent(RegistrationState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Image.asset(
          'assets/branding/sofawatch_logo.png',
          width: 96,
          height: 96,
          fit: BoxFit.contain,
          semanticLabel: 'SofaWatch logo',
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          'Create an account',
          key: const ValueKey<String>('auth-registration-title'),
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Join SofaWatch and start tracking what you watch.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xxxl),
        if (state is RegistrationInitial || state is RegistrationChecking)
          const Center(
            child: CircularProgressIndicator(
              key: ValueKey<String>('auth-registration-loading'),
            ),
          )
        else if (state is RegistrationClosed)
          _buildClosedState()
        else if (state is RegistrationAvailabilityFailure)
          _buildAvailabilityError(state)
        else
          _buildForm(state),
        const SizedBox(height: AppSpacing.xxl),
        TextButton(
          key: const ValueKey<String>('auth-registration-login-link'),
          onPressed: _goToLogin,
          child: const Text('Already have an account? Sign in'),
        ),
      ],
    );
  }

  Widget _buildClosedState() {
    return const _RegistrationMessage(
      key: ValueKey<String>('auth-registration-closed'),
      message:
          'Account registration is currently closed. '
          'Please contact the administrator.',
    );
  }

  Widget _buildAvailabilityError(RegistrationAvailabilityFailure state) {
    return Column(
      children: <Widget>[
        _RegistrationMessage(
          key: const ValueKey<String>('auth-registration-availability-error'),
          message: AppErrorMessageMapper.map(state.error),
        ),
        const SizedBox(height: AppSpacing.lg),
        OutlinedButton(
          key: const ValueKey<String>('auth-registration-retry'),
          onPressed: () {
            context.read<RegistrationCubit>().loadAvailability();
          },
          child: const Text('Try again'),
        ),
      ],
    );
  }

  Widget _buildForm(RegistrationState state) {
    final bool isSubmitting = state.isSubmitting;

    final RegistrationValidationFailure? validation =
        state is RegistrationValidationFailure ? state : null;

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            key: const ValueKey<String>('auth-registration-username'),
            controller: _usernameController,
            enabled: !isSubmitting,
            autofocus: true,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const <String>[AutofillHints.newUsername],
            onChanged: (_) => _clearFeedback(),
            decoration: InputDecoration(
              labelText: 'Username',
              hintText: 'Choose a username',
              errorText: validation?.usernameError,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          TextField(
            key: const ValueKey<String>('auth-registration-display-name'),
            controller: _displayNameController,
            enabled: !isSubmitting,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => _clearFeedback(),
            decoration: InputDecoration(
              labelText: 'Display name',
              hintText: 'How should we call you?',
              errorText: validation?.displayNameError,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          TextField(
            key: const ValueKey<String>('auth-registration-email'),
            controller: _emailController,
            enabled: !isSubmitting,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            autofillHints: const <String>[AutofillHints.email],
            onChanged: (_) => _clearFeedback(),
            decoration: InputDecoration(
              labelText: 'Email (optional)',
              hintText: 'you@example.com',
              errorText: validation?.emailError,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          TextField(
            key: const ValueKey<String>('auth-registration-password'),
            controller: _passwordController,
            enabled: !isSubmitting,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const <String>[AutofillHints.newPassword],
            onChanged: (_) => _clearFeedback(),
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'At least 8 characters',
              errorText: validation?.passwordError,
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                onPressed: isSubmitting
                    ? null
                    : () => setState(() {
                        _obscurePassword = !_obscurePassword;
                      }),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          TextField(
            key: const ValueKey<String>('auth-registration-confirm-password'),
            controller: _confirmPasswordController,
            enabled: !isSubmitting,
            obscureText: _obscureConfirmation,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enableSuggestions: false,
            onChanged: (_) => _clearFeedback(),
            onSubmitted: (_) {
              if (!isSubmitting) {
                _submit();
              }
            },
            decoration: InputDecoration(
              labelText: 'Confirm password',
              hintText: 'Enter your password again',
              errorText: validation?.confirmPasswordError,
              suffixIcon: IconButton(
                tooltip: _obscureConfirmation
                    ? 'Show confirmation'
                    : 'Hide confirmation',
                onPressed: isSubmitting
                    ? null
                    : () => setState(() {
                        _obscureConfirmation = !_obscureConfirmation;
                      }),
                icon: Icon(
                  _obscureConfirmation
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          if (state case RegistrationFailure(:final error)) ...<Widget>[
            const SizedBox(height: AppSpacing.xxl),
            _RegistrationMessage(
              key: const ValueKey<String>('auth-registration-error'),
              message: AppErrorMessageMapper.map(error),
            ),
          ],
          const SizedBox(height: AppSpacing.xxxl),
          FilledButton(
            key: const ValueKey<String>('auth-registration-submit'),
            onPressed: isSubmitting ? null : _submit,
            child: isSubmitting
                ? const Text('Creating account…')
                : const Text('Create account'),
          ),
        ],
      ),
    );
  }
}

class _RegistrationMessage extends StatelessWidget {
  const _RegistrationMessage({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.35),
        borderRadius: AppRadius.borderMedium,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.info_outline_rounded, color: AppColors.error),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
