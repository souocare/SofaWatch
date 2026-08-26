import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/router/app_routes.dart';
import 'package:sofawatch/app/theme/tokens/app_colors.dart';
import 'package:sofawatch/app/theme/tokens/app_radius.dart';
import 'package:sofawatch/app/theme/tokens/app_spacing.dart';
import 'package:sofawatch/core/errors/app_error_message_mapper.dart';
import 'package:sofawatch/features/auth/application/cubit/password_recovery_cubit.dart';
import 'package:sofawatch/features/auth/application/cubit/password_recovery_state.dart';

class PasswordRecoveryPage extends StatefulWidget {
  const PasswordRecoveryPage({required this.token, super.key});

  final String? token;

  @override
  State<PasswordRecoveryPage> createState() {
    return _PasswordRecoveryPageState();
  }
}

class _PasswordRecoveryPageState extends State<PasswordRecoveryPage> {
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  late final FocusNode _newPasswordFocusNode;
  late final FocusNode _confirmPasswordFocusNode;

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();

    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    _newPasswordFocusNode = FocusNode();
    _confirmPasswordFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();

    _newPasswordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();

    super.dispose();
  }

  void _submit() {
    context.read<PasswordRecoveryCubit>().submit(
      token: widget.token,
      newPassword: _newPasswordController.text,
      confirmPassword: _confirmPasswordController.text,
    );
  }

  void _clearFeedback() {
    context.read<PasswordRecoveryCubit>().clearFeedback();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey<String>('password-recovery-page'),
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
                  child:
                      BlocBuilder<PasswordRecoveryCubit, PasswordRecoveryState>(
                        builder:
                            (
                              BuildContext context,
                              PasswordRecoveryState state,
                            ) {
                              return _PasswordRecoveryContent(
                                state: state,
                                token: widget.token,
                                newPasswordController: _newPasswordController,
                                confirmPasswordController:
                                    _confirmPasswordController,
                                newPasswordFocusNode: _newPasswordFocusNode,
                                confirmPasswordFocusNode:
                                    _confirmPasswordFocusNode,
                                obscureNewPassword: _obscureNewPassword,
                                obscureConfirmPassword: _obscureConfirmPassword,
                                onChanged: _clearFeedback,
                                onSubmit: _submit,
                                onToggleNewPasswordVisibility: () {
                                  setState(() {
                                    _obscureNewPassword = !_obscureNewPassword;
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
    );
  }
}

class _PasswordRecoveryContent extends StatelessWidget {
  const _PasswordRecoveryContent({
    required this.state,
    required this.token,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.newPasswordFocusNode,
    required this.confirmPasswordFocusNode,
    required this.obscureNewPassword,
    required this.obscureConfirmPassword,
    required this.onChanged,
    required this.onSubmit,
    required this.onToggleNewPasswordVisibility,
    required this.onToggleConfirmPasswordVisibility,
  });

  final PasswordRecoveryState state;
  final String? token;

  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;

  final FocusNode newPasswordFocusNode;
  final FocusNode confirmPasswordFocusNode;

  final bool obscureNewPassword;
  final bool obscureConfirmPassword;

  final VoidCallback onChanged;
  final VoidCallback onSubmit;
  final VoidCallback onToggleNewPasswordVisibility;
  final VoidCallback onToggleConfirmPasswordVisibility;

  @override
  Widget build(BuildContext context) {
    if ((token?.trim().isEmpty ?? true) || state is PasswordRecoveryInvalid) {
      return const _PasswordRecoveryInvalidContent();
    }

    if (state is PasswordRecoverySuccess) {
      return const _PasswordRecoverySuccessContent();
    }

    final bool isSubmitting = state.isSubmitting;

    final PasswordRecoveryValidationFailure? validationFailure =
        state is PasswordRecoveryValidationFailure
        ? state as PasswordRecoveryValidationFailure
        : null;

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _PasswordRecoveryHeader(),

          const SizedBox(height: AppSpacing.xxxl),

          TextField(
            key: const ValueKey<String>('password-recovery-new-password-field'),
            controller: newPasswordController,
            focusNode: newPasswordFocusNode,
            enabled: !isSubmitting,
            autofocus: true,
            obscureText: obscureNewPassword,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const <String>[AutofillHints.newPassword],
            onChanged: (_) {
              onChanged();
            },
            onSubmitted: (_) {
              confirmPasswordFocusNode.requestFocus();
            },
            decoration: InputDecoration(
              labelText: 'New password',
              errorText: validationFailure?.newPasswordError,
              suffixIcon: IconButton(
                key: const ValueKey<String>(
                  'password-recovery-new-password-visibility',
                ),
                tooltip: obscureNewPassword ? 'Show password' : 'Hide password',
                onPressed: isSubmitting ? null : onToggleNewPasswordVisibility,
                icon: Icon(
                  obscureNewPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          TextField(
            key: const ValueKey<String>(
              'password-recovery-confirm-password-field',
            ),
            controller: confirmPasswordController,
            focusNode: confirmPasswordFocusNode,
            enabled: !isSubmitting,
            obscureText: obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const <String>[AutofillHints.newPassword],
            onChanged: (_) {
              onChanged();
            },
            onSubmitted: (_) {
              if (!isSubmitting) {
                onSubmit();
              }
            },
            decoration: InputDecoration(
              labelText: 'Confirm new password',
              errorText: validationFailure?.confirmPasswordError,
              suffixIcon: IconButton(
                key: const ValueKey<String>(
                  'password-recovery-confirm-password-visibility',
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

          if (state case PasswordRecoveryFailure(:final error)) ...<Widget>[
            const SizedBox(height: AppSpacing.xxl),

            _PasswordRecoveryMessage(
              key: const ValueKey<String>('password-recovery-failure'),
              message: AppErrorMessageMapper.map(error),
            ),
          ],

          const SizedBox(height: AppSpacing.xxxl),

          FilledButton(
            key: const ValueKey<String>('password-recovery-submit-button'),
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
                      Text('Changing password…'),
                    ],
                  )
                : const Text('Change password'),
          ),
        ],
      ),
    );
  }
}

class _PasswordRecoveryHeader extends StatelessWidget {
  const _PasswordRecoveryHeader();

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
          alignment: Alignment.center,
          child: const Icon(
            Icons.lock_reset_rounded,
            size: 32,
            color: AppColors.primary,
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        Text(
          'Reset your password',
          key: const ValueKey<String>('password-recovery-title'),
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),

        const SizedBox(height: AppSpacing.sm),

        Text(
          'Choose a new password for your SofaWatch account.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _PasswordRecoveryInvalidContent extends StatelessWidget {
  const _PasswordRecoveryInvalidContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('password-recovery-invalid'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Icon(
          Icons.link_off_rounded,
          size: 48,
          color: AppColors.textSecondary,
        ),

        const SizedBox(height: AppSpacing.xl),

        Text(
          'Recovery link unavailable',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),

        const SizedBox(height: AppSpacing.md),

        Text(
          'This password recovery link is invalid, expired, '
          'or has already been used.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),

        const SizedBox(height: AppSpacing.xxxl),

        OutlinedButton(
          key: const ValueKey<String>('password-recovery-invalid-login'),
          onPressed: () {
            context.goNamed(AppRoute.login.name);
          },
          child: const Text('Back to sign in'),
        ),
      ],
    );
  }
}

class _PasswordRecoverySuccessContent extends StatelessWidget {
  const _PasswordRecoverySuccessContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('password-recovery-success'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Icon(
          Icons.check_circle_outline_rounded,
          size: 48,
          color: AppColors.primary,
        ),

        const SizedBox(height: AppSpacing.xl),

        Text(
          'Password changed',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),

        const SizedBox(height: AppSpacing.md),

        Text(
          'Your password has been changed successfully. '
          'You can now sign in with your new password.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),

        const SizedBox(height: AppSpacing.xxxl),

        FilledButton(
          key: const ValueKey<String>('password-recovery-success-login'),
          onPressed: () {
            context.goNamed(AppRoute.login.name);
          },
          child: const Text('Sign in'),
        ),
      ],
    );
  }
}

class _PasswordRecoveryMessage extends StatelessWidget {
  const _PasswordRecoveryMessage({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
