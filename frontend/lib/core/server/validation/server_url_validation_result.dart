import 'package:equatable/equatable.dart';

enum ServerUrlValidationError {
  empty,
  invalidFormat,
  unsupportedScheme,
  missingHost,
  containsCredentials,
  containsQuery,
  containsFragment,
}

class ServerUrlValidationResult extends Equatable {
  const ServerUrlValidationResult._({required this.uri, required this.error});

  const ServerUrlValidationResult.valid(Uri uri)
    : this._(uri: uri, error: null);

  const ServerUrlValidationResult.invalid(ServerUrlValidationError error)
    : this._(uri: null, error: error);

  final Uri? uri;
  final ServerUrlValidationError? error;

  bool get isValid => uri != null && error == null;

  @override
  List<Object?> get props => <Object?>[uri, error];
}
