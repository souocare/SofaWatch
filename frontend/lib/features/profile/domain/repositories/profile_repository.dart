import 'package:sofawatch/features/profile/domain/models/profile_user.dart';

abstract interface class ProfileRepository {
  Future<ProfileUser> getCurrentUser();

  Future<ProfileUser> updateDisplayName({required String displayName});
}
