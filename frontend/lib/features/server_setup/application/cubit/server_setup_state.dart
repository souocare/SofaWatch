import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/core/server/models/server_configuration.dart';
import 'package:sofawatch/core/server/validation/server_url_validation_result.dart';

enum ServerSetupStatus { initial, testing, saving, success, failure }

class ServerSetupState extends Equatable {
  const ServerSetupState({
    this.status = ServerSetupStatus.initial,
    this.serverName = '',
    this.serverAddress = '',
    this.acceptSelfSignedCertificates = false,
    this.serverNameError,
    this.serverUrlError,
    this.failureMessage,
    this.failureType,
    this.configuration,
  });

  final ServerSetupStatus status;

  final String serverName;
  final String serverAddress;
  final bool acceptSelfSignedCertificates;

  final String? serverNameError;
  final ServerUrlValidationError? serverUrlError;

  final String? failureMessage;
  final AppExceptionType? failureType;

  final ServerConfiguration? configuration;

  bool get isSubmitting {
    return status == ServerSetupStatus.testing ||
        status == ServerSetupStatus.saving;
  }

  bool get hasValidationErrors {
    return serverNameError != null || serverUrlError != null;
  }

  ServerSetupState copyWith({
    ServerSetupStatus? status,
    String? serverName,
    String? serverAddress,
    bool? acceptSelfSignedCertificates,
    String? serverNameError,
    bool clearServerNameError = false,
    ServerUrlValidationError? serverUrlError,
    bool clearServerUrlError = false,
    String? failureMessage,
    bool clearFailureMessage = false,
    AppExceptionType? failureType,
    bool clearFailureType = false,
    ServerConfiguration? configuration,
    bool clearConfiguration = false,
  }) {
    return ServerSetupState(
      status: status ?? this.status,
      serverName: serverName ?? this.serverName,
      serverAddress: serverAddress ?? this.serverAddress,
      acceptSelfSignedCertificates:
          acceptSelfSignedCertificates ?? this.acceptSelfSignedCertificates,
      serverNameError: clearServerNameError
          ? null
          : serverNameError ?? this.serverNameError,
      serverUrlError: clearServerUrlError
          ? null
          : serverUrlError ?? this.serverUrlError,
      failureMessage: clearFailureMessage
          ? null
          : failureMessage ?? this.failureMessage,
      failureType: clearFailureType ? null : failureType ?? this.failureType,
      configuration: clearConfiguration
          ? null
          : configuration ?? this.configuration,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    serverName,
    serverAddress,
    acceptSelfSignedCertificates,
    serverNameError,
    serverUrlError,
    failureMessage,
    failureType,
    configuration,
  ];
}
