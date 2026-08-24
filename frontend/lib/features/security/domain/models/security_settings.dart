import 'package:equatable/equatable.dart';

final class SecuritySettings extends Equatable {
  const SecuritySettings({required this.openRegistration});

  final bool openRegistration;

  SecuritySettings copyWith({bool? openRegistration}) {
    return SecuritySettings(
      openRegistration: openRegistration ?? this.openRegistration,
    );
  }

  @override
  List<Object?> get props => <Object?>[openRegistration];
}
