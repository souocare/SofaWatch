import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/app/theme/tokens/app_colors.dart';
import 'package:sofawatch/app/theme/tokens/app_radius.dart';
import 'package:sofawatch/app/theme/tokens/app_spacing.dart';
import 'package:sofawatch/app/theme/tokens/app_typography.dart';
import 'package:sofawatch/core/errors/app_error_message_mapper.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_cubit.dart';
import 'package:sofawatch/features/auth/application/cubit/login_cubit.dart';
import 'package:sofawatch/features/auth/application/cubit/login_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() {
    return _LoginPageState();
  }
}

class _LoginPageState extends State<LoginPage> {
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;

  late final FocusNode _usernameFocusNode;
  late final FocusNode _passwordFocusNode;

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();

    _usernameController = TextEditingController();
    _passwordController = TextEditingController();

    _usernameFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();

    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();

    super.dispose();
  }

  void _submit() {
    context.read<LoginCubit>().submit(
      username: _usernameController.text,
      password: _passwordController.text,
    );
  }

  void _clearFeedback() {
    context.read<LoginCubit>().clearFeedback();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginCubit, LoginState>(
      listenWhen: (LoginState previous, LoginState current) {
        return previous != current;
      },
      listener: (BuildContext context, LoginState state) {
        if (state case LoginSuccess(:final session)) {
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
                    child: BlocBuilder<LoginCubit, LoginState>(
                      builder: (BuildContext context, LoginState state) {
                        return _LoginForm(
                          usernameController: _usernameController,
                          passwordController: _passwordController,
                          usernameFocusNode: _usernameFocusNode,
                          passwordFocusNode: _passwordFocusNode,
                          obscurePassword: _obscurePassword,
                          state: state,
                          onChanged: _clearFeedback,
                          onSubmit: _submit,
                          onTogglePasswordVisibility: _togglePasswordVisibility,
                        );
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
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.usernameController,
    required this.passwordController,
    required this.usernameFocusNode,
    required this.passwordFocusNode,
    required this.obscurePassword,
    required this.state,
    required this.onChanged,
    required this.onSubmit,
    required this.onTogglePasswordVisibility,
  });

  final TextEditingController usernameController;
  final TextEditingController passwordController;

  final FocusNode usernameFocusNode;
  final FocusNode passwordFocusNode;

  final bool obscurePassword;

  final LoginState state;

  final VoidCallback onChanged;
  final VoidCallback onSubmit;
  final VoidCallback onTogglePasswordVisibility;

  @override
  Widget build(BuildContext context) {
    final bool isSubmitting = state.isSubmitting;

    final LoginValidationFailure? validationFailure =
        state is LoginValidationFailure
        ? state as LoginValidationFailure
        : null;

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _LoginHeader(),
          const SizedBox(height: AppSpacing.xxxl),
          TextField(
            key: const ValueKey<String>('auth-login-username-field'),
            controller: usernameController,
            focusNode: usernameFocusNode,
            enabled: !isSubmitting,
            autofocus: true,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const <String>[AutofillHints.username],
            onChanged: (_) {
              onChanged();
            },
            onSubmitted: (_) {
              passwordFocusNode.requestFocus();
            },
            decoration: InputDecoration(
              labelText: 'Username or email',
              hintText: 'Enter your username or email',
              errorText: validationFailure?.usernameError,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          TextField(
            key: const ValueKey<String>('auth-login-password-field'),
            controller: passwordController,
            focusNode: passwordFocusNode,
            enabled: !isSubmitting,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const <String>[AutofillHints.password],
            onChanged: (_) {
              onChanged();
            },
            onSubmitted: (_) {
              if (!isSubmitting) {
                onSubmit();
              }
            },
            decoration: InputDecoration(
              labelText: 'Password',
              errorText: validationFailure?.passwordError,
              suffixIcon: IconButton(
                key: const ValueKey<String>('auth-login-password-visibility'),
                tooltip: obscurePassword ? 'Show password' : 'Hide password',
                onPressed: isSubmitting ? null : onTogglePasswordVisibility,
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          if (state is LoginInvalidCredentials) ...<Widget>[
            const SizedBox(height: AppSpacing.xxl),
            const _LoginMessage(
              key: ValueKey<String>('auth-login-invalid-credentials'),
              message: 'The username or password is incorrect.',
            ),
          ],
          if (state case LoginFailure(:final error)) ...<Widget>[
            const SizedBox(height: AppSpacing.xxl),
            _LoginMessage(
              key: const ValueKey<String>('auth-login-failure'),
              message: AppErrorMessageMapper.map(error),
            ),
          ],
          const SizedBox(height: AppSpacing.xxxl),
          FilledButton(
            key: const ValueKey<String>('auth-login-submit-button'),
            onPressed: isSubmitting ? null : onSubmit,
            child: _LoginSubmitContent(isSubmitting: isSubmitting),
          ),
        ],
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.14),
            borderRadius: AppRadius.borderExtraLarge,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.35),
            ),
          ),
          child: const Icon(
            Icons.live_tv_outlined,
            color: AppColors.primarySoft,
            size: 34,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          'Sign in',
          key: const ValueKey<String>('auth-login-page-title'),
          textAlign: TextAlign.center,
          style: AppTypography.headlineLargeMobile,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Sign in to your SofaWatch account.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _LoginMessage extends StatelessWidget {
  const _LoginMessage({required this.message, super.key});

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            CupertinoIcons.exclamationmark_triangle,
            color: AppColors.error,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginSubmitContent extends StatelessWidget {
  const _LoginSubmitContent({required this.isSubmitting});

  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    if (!isSubmitting) {
      return const Text('Sign in');
    }

    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CupertinoActivityIndicator(color: AppColors.onPrimary),
        SizedBox(width: AppSpacing.md),
        Text('Signing in…'),
      ],
    );
  }
}
