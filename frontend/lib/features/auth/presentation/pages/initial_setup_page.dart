import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/app/theme/tokens/app_colors.dart';
import 'package:sofawatch/app/theme/tokens/app_radius.dart';
import 'package:sofawatch/app/theme/tokens/app_spacing.dart';
import 'package:sofawatch/app/theme/tokens/app_typography.dart';
import 'package:sofawatch/core/errors/app_error_message_mapper.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_cubit.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_entry_cubit.dart';
import 'package:sofawatch/features/auth/application/cubit/initial_setup_cubit.dart';
import 'package:sofawatch/features/auth/application/cubit/initial_setup_state.dart';

class InitialSetupPage extends StatefulWidget {
  const InitialSetupPage({super.key});

  @override
  State<InitialSetupPage> createState() {
    return _InitialSetupPageState();
  }
}

class _InitialSetupPageState extends State<InitialSetupPage> {
  late final TextEditingController _displayNameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  late final FocusNode _displayNameFocusNode;
  late final FocusNode _usernameFocusNode;
  late final FocusNode _emailFocusNode;
  late final FocusNode _passwordFocusNode;
  late final FocusNode _confirmPasswordFocusNode;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();

    _displayNameController = TextEditingController();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    _displayNameFocusNode = FocusNode();
    _usernameFocusNode = FocusNode();
    _emailFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();
    _confirmPasswordFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _displayNameFocusNode.dispose();
    _usernameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();

    super.dispose();
  }

  void _submit() {
    context.read<InitialSetupCubit>().submit(
      displayName: _displayNameController.text,
      username: _usernameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );
  }

  void _clearFeedback() {
    context.read<InitialSetupCubit>().clearFeedback();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<InitialSetupCubit, InitialSetupState>(
      listenWhen: (InitialSetupState previous, InitialSetupState current) {
        return previous != current;
      },
      listener: (BuildContext context, InitialSetupState state) {
        if (state case InitialSetupSuccess(:final session)) {
          context.read<AuthEntryCubit>().authenticationRequired();
          context.read<AuthCubit>().authenticated(session);
        }

        if (state is InitialSetupAlreadyCompleted) {
          context.read<AuthEntryCubit>().authenticationRequired();
        }
      },
      child: Scaffold(
        key: const ValueKey<String>('auth-initial-setup-page'),
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
                    child: BlocBuilder<InitialSetupCubit, InitialSetupState>(
                      builder: (BuildContext context, InitialSetupState state) {
                        return _InitialSetupForm(
                          displayNameController: _displayNameController,
                          usernameController: _usernameController,
                          emailController: _emailController,
                          passwordController: _passwordController,
                          confirmPasswordController: _confirmPasswordController,
                          displayNameFocusNode: _displayNameFocusNode,
                          usernameFocusNode: _usernameFocusNode,
                          emailFocusNode: _emailFocusNode,
                          passwordFocusNode: _passwordFocusNode,
                          confirmPasswordFocusNode: _confirmPasswordFocusNode,
                          obscurePassword: _obscurePassword,
                          obscureConfirmPassword: _obscureConfirmPassword,
                          state: state,
                          onChanged: _clearFeedback,
                          onSubmit: _submit,
                          onTogglePasswordVisibility: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          onToggleConfirmPasswordVisibility: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
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

class _InitialSetupForm extends StatelessWidget {
  const _InitialSetupForm({
    required this.displayNameController,
    required this.usernameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.displayNameFocusNode,
    required this.usernameFocusNode,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.confirmPasswordFocusNode,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.state,
    required this.onChanged,
    required this.onSubmit,
    required this.onTogglePasswordVisibility,
    required this.onToggleConfirmPasswordVisibility,
  });

  final TextEditingController displayNameController;
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  final FocusNode displayNameFocusNode;
  final FocusNode usernameFocusNode;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final FocusNode confirmPasswordFocusNode;

  final bool obscurePassword;
  final bool obscureConfirmPassword;

  final InitialSetupState state;

  final VoidCallback onChanged;
  final VoidCallback onSubmit;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onToggleConfirmPasswordVisibility;

  @override
  Widget build(BuildContext context) {
    final bool isSubmitting = state.isSubmitting;

    final InitialSetupValidationFailure? validationFailure =
        state is InitialSetupValidationFailure
        ? state as InitialSetupValidationFailure
        : null;

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _InitialSetupHeader(),
          const SizedBox(height: AppSpacing.xxxl),

          TextField(
            key: const ValueKey<String>(
              'auth-initial-setup-display-name-field',
            ),
            controller: displayNameController,
            focusNode: displayNameFocusNode,
            enabled: !isSubmitting,
            autofocus: true,
            textInputAction: TextInputAction.next,
            autofillHints: const <String>[AutofillHints.name],
            onChanged: (_) => onChanged(),
            onSubmitted: (_) => usernameFocusNode.requestFocus(),
            decoration: InputDecoration(
              labelText: 'Display name',
              hintText: 'How SofaWatch should address you',
              errorText: validationFailure?.displayNameError,
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          TextField(
            key: const ValueKey<String>('auth-initial-setup-username-field'),
            controller: usernameController,
            focusNode: usernameFocusNode,
            enabled: !isSubmitting,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const <String>[AutofillHints.newUsername],
            onChanged: (_) => onChanged(),
            onSubmitted: (_) => emailFocusNode.requestFocus(),
            decoration: InputDecoration(
              labelText: 'Username',
              hintText: 'Choose a username',
              errorText: validationFailure?.usernameError,
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          TextField(
            key: const ValueKey<String>('auth-initial-setup-email-field'),
            controller: emailController,
            focusNode: emailFocusNode,
            enabled: !isSubmitting,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            autofillHints: const <String>[AutofillHints.email],
            onChanged: (_) => onChanged(),
            onSubmitted: (_) => passwordFocusNode.requestFocus(),
            decoration: InputDecoration(
              labelText: 'Email (optional)',
              hintText: 'Used for account recovery',
              errorText: validationFailure?.emailError,
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          TextField(
            key: const ValueKey<String>('auth-initial-setup-password-field'),
            controller: passwordController,
            focusNode: passwordFocusNode,
            enabled: !isSubmitting,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const <String>[AutofillHints.newPassword],
            onChanged: (_) => onChanged(),
            onSubmitted: (_) => confirmPasswordFocusNode.requestFocus(),
            decoration: InputDecoration(
              labelText: 'Password',
              errorText: validationFailure?.passwordError,
              suffixIcon: IconButton(
                key: const ValueKey<String>(
                  'auth-initial-setup-password-visibility',
                ),
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

          const SizedBox(height: AppSpacing.xxl),

          TextField(
            key: const ValueKey<String>(
              'auth-initial-setup-confirm-password-field',
            ),
            controller: confirmPasswordController,
            focusNode: confirmPasswordFocusNode,
            enabled: !isSubmitting,
            obscureText: obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const <String>[AutofillHints.newPassword],
            onChanged: (_) => onChanged(),
            onSubmitted: (_) {
              if (!isSubmitting) {
                onSubmit();
              }
            },
            decoration: InputDecoration(
              labelText: 'Confirm password',
              errorText: validationFailure?.confirmPasswordError,
              suffixIcon: IconButton(
                key: const ValueKey<String>(
                  'auth-initial-setup-confirm-password-visibility',
                ),
                tooltip: obscureConfirmPassword
                    ? 'Show password'
                    : 'Hide password',
                onPressed: isSubmitting
                    ? null
                    : onToggleConfirmPasswordVisibility,
                icon: Icon(
                  obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),

          if (state case InitialSetupFailure(:final error)) ...<Widget>[
            const SizedBox(height: AppSpacing.xxl),
            _InitialSetupMessage(
              key: const ValueKey<String>('auth-initial-setup-failure'),
              message: AppErrorMessageMapper.map(error),
            ),
          ],

          const SizedBox(height: AppSpacing.xxxl),

          FilledButton(
            key: const ValueKey<String>('auth-initial-setup-submit-button'),
            onPressed: isSubmitting ? null : onSubmit,
            child: isSubmitting
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Text('Creating account…'),
                    ],
                  )
                : const Text('Create administrator account'),
          ),

          const SizedBox(height: AppSpacing.xl),

          Text(
            'This first account will be the administrator of this SofaWatch server.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InitialSetupHeader extends StatelessWidget {
  const _InitialSetupHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
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
          'Set up SofaWatch',
          key: const ValueKey<String>('auth-initial-setup-page-title'),
          textAlign: TextAlign.center,
          style: AppTypography.headlineLargeMobile,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Create the administrator account for this SofaWatch server.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _InitialSetupMessage extends StatelessWidget {
  const _InitialSetupMessage({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.35),
        borderRadius: AppRadius.borderMedium,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTypography.bodySmall.copyWith(color: AppColors.error),
      ),
    );
  }
}
