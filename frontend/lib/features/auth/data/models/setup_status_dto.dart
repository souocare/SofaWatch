import 'package:sofawatch/features/auth/domain/models/setup_status.dart';

final class SetupStatusDto {
  const SetupStatusDto({required this.setupRequired});

  factory SetupStatusDto.fromJson(Map<String, dynamic> json) {
    final Object? setupRequiredValue = json['setup_required'];

    if (setupRequiredValue is! bool) {
      throw const FormatException(
        'Setup status response contains an invalid setup_required value.',
      );
    }

    return SetupStatusDto(setupRequired: setupRequiredValue);
  }

  final bool setupRequired;

  SetupStatus toDomain() {
    return SetupStatus(setupRequired: setupRequired);
  }
}
