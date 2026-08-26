import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/features/auth/domain/repositories/password_recovery_repository.dart';

final class ApiPasswordRecoveryRepository
    implements PasswordRecoveryRepository {
  const ApiPasswordRecoveryRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<void> complete({
    required String token,
    required String newPassword,
  }) async {
    await _apiClient.post<void>(
      '/auth/password-recovery/complete',
      data: <String, dynamic>{'token': token, 'new_password': newPassword},
    );
  }
}
