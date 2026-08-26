import 'package:equatable/equatable.dart';

final class ProfileUser extends Equatable {
  const ProfileUser({
    required this.id,
    required this.username,
    required this.email,
    required this.displayName,
    required this.isAdmin,
  });

  final String id;
  final String? username;
  final String? email;
  final String displayName;

  /// Whether this user may access administrative SofaWatch functionality.
  ///
  /// Administrative authorization is owned and enforced by the backend.
  /// This value is used only to decide whether admin UI should be visible.
  final bool isAdmin;

  ProfileUser copyWith({
    String? id,
    String? username,
    bool clearUsername = false,
    String? email,
    bool clearEmail = false,
    String? displayName,
    bool? isAdmin,
  }) {
    return ProfileUser(
      id: id ?? this.id,
      username: clearUsername ? null : username ?? this.username,
      email: clearEmail ? null : email ?? this.email,
      displayName: displayName ?? this.displayName,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    username,
    email,
    displayName,
    isAdmin,
  ];
}
