import 'package:equatable/equatable.dart';

final class ProfileUser extends Equatable {
  const ProfileUser({
    required this.id,
    required this.displayName,
    required this.isLocal,
    required this.isAdmin,
  });

  final String id;
  final String displayName;

  /*
   * Transitional backend information.
   *
   * SofaWatch currently operates with a single local user. When real
   * authentication is introduced, Profile will continue consuming the
   * current-user endpoint without needing to know how that user was resolved.
   */
  final bool isLocal;

  /// Whether this user may access administrative SofaWatch functionality.
  ///
  /// Administrative authorization is owned and enforced by the backend.
  /// This value is used only to decide whether admin UI should be visible.
  final bool isAdmin;

  @override
  List<Object?> get props => <Object?>[id, displayName, isLocal];
}
