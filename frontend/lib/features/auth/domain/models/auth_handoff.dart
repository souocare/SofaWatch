import 'package:equatable/equatable.dart';

final class AuthHandoff extends Equatable {
  const AuthHandoff({required this.token, required this.expiresIn});

  final String token;
  final Duration expiresIn;

  @override
  List<Object?> get props => <Object?>[token, expiresIn];
}
