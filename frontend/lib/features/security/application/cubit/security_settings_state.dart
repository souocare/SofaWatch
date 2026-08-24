import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/security/domain/models/security_settings.dart';

sealed class SecuritySettingsState extends Equatable {
  const SecuritySettingsState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class SecuritySettingsInitial extends SecuritySettingsState {
  const SecuritySettingsInitial();
}

final class SecuritySettingsLoading extends SecuritySettingsState {
  const SecuritySettingsLoading();
}

final class SecuritySettingsSuccess extends SecuritySettingsState {
  const SecuritySettingsSuccess({
    required this.settings,
    this.isUpdating = false,
    this.updateError,
  });

  final SecuritySettings settings;
  final bool isUpdating;
  final AppException? updateError;

  SecuritySettingsSuccess copyWith({
    SecuritySettings? settings,
    bool? isUpdating,
    AppException? updateError,
    bool clearUpdateError = false,
  }) {
    return SecuritySettingsSuccess(
      settings: settings ?? this.settings,
      isUpdating: isUpdating ?? this.isUpdating,
      updateError: clearUpdateError ? null : updateError ?? this.updateError,
    );
  }

  @override
  List<Object?> get props => <Object?>[settings, isUpdating, updateError];
}

final class SecuritySettingsFailure extends SecuritySettingsState {
  const SecuritySettingsFailure(this.error);

  final AppException error;

  @override
  List<Object?> get props => <Object?>[error];
}
