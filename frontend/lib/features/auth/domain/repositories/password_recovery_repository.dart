abstract interface class PasswordRecoveryRepository {
  Future<void> complete({required String token, required String newPassword});
}
