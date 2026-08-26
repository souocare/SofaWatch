import 'package:equatable/equatable.dart';

final class PasswordRecoveryLink extends Equatable {
  const PasswordRecoveryLink({required this.token, required this.expiresAt});

  final String token;
  final DateTime expiresAt;

  @override
  List<Object?> get props => <Object?>[token, expiresAt];
}
