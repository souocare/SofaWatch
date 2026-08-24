import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/app/theme/tokens/app_colors.dart';
import 'package:sofawatch/app/theme/tokens/app_radius.dart';
import 'package:sofawatch/app/theme/tokens/app_spacing.dart';
import 'package:sofawatch/app/theme/tokens/app_typography.dart';
import 'package:sofawatch/core/server/validation/server_url_validation_messages.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_cubit.dart';
import 'package:sofawatch/features/server_setup/application/cubit/server_setup_cubit.dart';
import 'package:sofawatch/features/server_setup/application/cubit/server_setup_state.dart';

class ServerSetupPage extends StatefulWidget {
  const ServerSetupPage({super.key});

  @override
  State<ServerSetupPage> createState() {
    return _ServerSetupPageState();
  }
}

class _ServerSetupPageState extends State<ServerSetupPage> {
  late final TextEditingController _serverNameController;
  late final TextEditingController _serverAddressController;

  @override
  void initState() {
    super.initState();

    final ServerSetupState state = context.read<ServerSetupCubit>().state;

    _serverNameController = TextEditingController(text: state.serverName);

    _serverAddressController = TextEditingController(text: state.serverAddress);
  }

  @override
  void dispose() {
    _serverNameController.dispose();
    _serverAddressController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ServerSetupCubit, ServerSetupState>(
      listenWhen: (ServerSetupState previous, ServerSetupState current) {
        return previous.status != current.status;
      },
      listener: (BuildContext context, ServerSetupState state) {
        if (state.status == ServerSetupStatus.success) {
          context.read<AuthCubit>().restore();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLow,
                    borderRadius: AppRadius.detailsModal,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxxl),
                    child: BlocBuilder<ServerSetupCubit, ServerSetupState>(
                      builder: (BuildContext context, ServerSetupState state) {
                        return _ServerSetupForm(
                          serverNameController: _serverNameController,
                          serverAddressController: _serverAddressController,
                          state: state,
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

class _ServerSetupForm extends StatelessWidget {
  const _ServerSetupForm({
    required this.serverNameController,
    required this.serverAddressController,
    required this.state,
  });

  final TextEditingController serverNameController;
  final TextEditingController serverAddressController;
  final ServerSetupState state;

  @override
  Widget build(BuildContext context) {
    final ServerSetupCubit cubit = context.read<ServerSetupCubit>();

    final String? serverAddressError = state.serverUrlError == null
        ? null
        : ServerUrlValidationMessages.forError(state.serverUrlError!);

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _ServerSetupHeader(),
          const SizedBox(height: AppSpacing.xxxl),
          TextField(
            key: const ValueKey<String>('server-name-field'),
            controller: serverNameController,
            enabled: !state.isSubmitting,
            textInputAction: TextInputAction.next,
            autofillHints: const <String>[AutofillHints.organizationName],
            onChanged: cubit.serverNameChanged,
            decoration: InputDecoration(
              labelText: 'Server name',
              hintText: 'Home Server',
              errorText: state.serverNameError,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          TextField(
            key: const ValueKey<String>('server-address-field'),
            controller: serverAddressController,
            enabled: !state.isSubmitting,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const <String>[AutofillHints.url],
            onChanged: cubit.serverAddressChanged,
            onSubmitted: (_) {
              cubit.submit();
            },
            decoration: InputDecoration(
              labelText: 'Server address',
              hintText: 'https://sofawatch.example.com',
              errorText: serverAddressError,
            ),
          ),
          if (state.failureMessage != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xxl),
            _ConnectionFailureMessage(message: state.failureMessage!),
          ],
          const SizedBox(height: AppSpacing.xxxl),
          FilledButton(
            key: const ValueKey<String>('server-setup-submit-button'),
            onPressed: state.isSubmitting ? null : cubit.submit,
            child: _SubmitButtonContent(status: state.status),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'The server address is stored only on this device.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ServerSetupHeader extends StatelessWidget {
  const _ServerSetupHeader();

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
          'Connect to SofaWatch',
          key: const ValueKey<String>('server-setup-page-title'),
          textAlign: TextAlign.center,
          style: AppTypography.headlineLargeMobile,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Enter the address of your self-hosted SofaWatch server.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ConnectionFailureMessage extends StatelessWidget {
  const _ConnectionFailureMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('server-setup-failure-message'),
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

class _SubmitButtonContent extends StatelessWidget {
  const _SubmitButtonContent({required this.status});

  final ServerSetupStatus status;

  @override
  Widget build(BuildContext context) {
    final bool isLoading =
        status == ServerSetupStatus.testing ||
        status == ServerSetupStatus.saving;

    if (!isLoading) {
      return const Text('Connect');
    }

    final String label = status == ServerSetupStatus.testing
        ? 'Testing connection…'
        : 'Saving server…';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const CupertinoActivityIndicator(color: AppColors.onPrimary),
        const SizedBox(width: AppSpacing.md),
        Text(label),
      ],
    );
  }
}
