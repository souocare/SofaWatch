import 'package:bloc/bloc.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_error_message_mapper.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/core/server/models/server_configuration.dart';
import 'package:sofawatch/core/server/repositories/server_configuration_repository.dart';
import 'package:sofawatch/core/server/validation/server_url_validation_result.dart';
import 'package:sofawatch/core/server/validation/server_url_validator.dart';
import 'package:sofawatch/features/server_setup/application/cubit/server_setup_state.dart';
import 'package:sofawatch/features/server_setup/domain/services/server_connection_tester.dart';

class ServerSetupCubit extends Cubit<ServerSetupState> {
  ServerSetupCubit(
    this._serverConfigurationRepository,
    this._serverConnectionTester,
    this._apiClient,
  ) : super(const ServerSetupState());

  final ServerConfigurationRepository _serverConfigurationRepository;
  final ServerConnectionTester _serverConnectionTester;
  final ApiClient _apiClient;

  void serverNameChanged(String value) {
    emit(
      state.copyWith(
        serverName: value,
        status: ServerSetupStatus.initial,
        clearServerNameError: true,
        clearFailureMessage: true,
        clearFailureType: true,
        clearConfiguration: true,
      ),
    );
  }

  void serverAddressChanged(String value) {
    emit(
      state.copyWith(
        serverAddress: value,
        status: ServerSetupStatus.initial,
        clearServerUrlError: true,
        clearFailureMessage: true,
        clearFailureType: true,
        clearConfiguration: true,
      ),
    );
  }

  void acceptSelfSignedCertificatesChanged(bool value) {
    emit(
      state.copyWith(
        acceptSelfSignedCertificates: value,
        status: ServerSetupStatus.initial,
        clearFailureMessage: true,
        clearFailureType: true,
        clearConfiguration: true,
      ),
    );
  }

  Future<void> submit() async {
    if (state.isSubmitting) {
      return;
    }

    final String normalizedName = state.serverName.trim();

    final ServerUrlValidationResult urlResult = ServerUrlValidator.validate(
      state.serverAddress,
    );

    final String? serverNameError = normalizedName.isEmpty
        ? 'Enter a name for this server.'
        : null;

    if (serverNameError != null || !urlResult.isValid) {
      emit(
        state.copyWith(
          status: ServerSetupStatus.initial,
          serverNameError: serverNameError,
          clearServerNameError: serverNameError == null,
          serverUrlError: urlResult.error,
          clearServerUrlError: urlResult.error == null,
          clearFailureMessage: true,
          clearFailureType: true,
          clearConfiguration: true,
        ),
      );

      return;
    }

    final Uri serverUrl = urlResult.uri!;

    emit(
      state.copyWith(
        status: ServerSetupStatus.testing,
        serverName: normalizedName,
        serverAddress: serverUrl.toString(),
        clearServerNameError: true,
        clearServerUrlError: true,
        clearFailureMessage: true,
        clearFailureType: true,
        clearConfiguration: true,
      ),
    );

    try {
      await _serverConnectionTester.testConnection(serverUrl);

      final ServerConfiguration configuration = ServerConfiguration(
        serverName: normalizedName,
        serverUrl: serverUrl,
        acceptSelfSignedCertificates: state.acceptSelfSignedCertificates,
      );

      emit(
        state.copyWith(
          status: ServerSetupStatus.saving,
          configuration: configuration,
        ),
      );

      await _serverConfigurationRepository.save(configuration);

      _apiClient.configureBaseUrl(configuration.serverUrl);

      emit(
        state.copyWith(
          status: ServerSetupStatus.success,
          configuration: configuration,
          clearFailureMessage: true,
          clearFailureType: true,
        ),
      );
    } on AppException catch (exception) {
      _emitFailure(exception);
    } on Exception catch (exception) {
      _emitFailure(AppException.unknown(originalError: exception));
    }
  }

  void _emitFailure(AppException exception) {
    emit(
      state.copyWith(
        status: ServerSetupStatus.failure,
        failureType: exception.type,
        failureMessage: AppErrorMessageMapper.map(exception),
        clearConfiguration: true,
      ),
    );
  }
}
