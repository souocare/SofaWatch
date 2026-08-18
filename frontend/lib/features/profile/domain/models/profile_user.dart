import 'package:equatable/equatable.dart';

final class ProfileUser extends Equatable {
  const ProfileUser({
    required this.id,
    required this.displayName,
    required this.isLocal,
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

  @override
  List<Object?> get props => <Object?>[id, displayName, isLocal];
}
