abstract interface class AuthenticatedRequestRecovery {
  /// Attempts to restore authentication after an authenticated request fails.
  ///
  /// Returns `true` when authentication was successfully restored and the
  /// original request may be retried.
  ///
  /// Returns `false` when authentication could not be restored.
  Future<bool> recover();
}
