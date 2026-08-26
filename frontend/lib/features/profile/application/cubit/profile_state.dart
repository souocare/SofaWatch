import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/profile/domain/models/profile_user.dart';

sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

final class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

final class ProfileSuccess extends ProfileState {
  const ProfileSuccess({
    required this.user,
    this.isUpdatingDisplayName = false,
    this.updateDisplayNameError,
    this.isUpdatingPassword = false,
    this.updatePasswordError,
  });

  final ProfileUser user;

  final bool isUpdatingDisplayName;
  final AppException? updateDisplayNameError;

  final bool isUpdatingPassword;
  final AppException? updatePasswordError;

  ProfileSuccess copyWith({
    ProfileUser? user,
    bool? isUpdatingDisplayName,
    AppException? updateDisplayNameError,
    bool clearUpdateDisplayNameError = false,
    bool? isUpdatingPassword,
    AppException? updatePasswordError,
    bool clearUpdatePasswordError = false,
  }) {
    return ProfileSuccess(
      user: user ?? this.user,
      isUpdatingDisplayName:
          isUpdatingDisplayName ?? this.isUpdatingDisplayName,
      updateDisplayNameError: clearUpdateDisplayNameError
          ? null
          : updateDisplayNameError ?? this.updateDisplayNameError,
      isUpdatingPassword: isUpdatingPassword ?? this.isUpdatingPassword,
      updatePasswordError: clearUpdatePasswordError
          ? null
          : updatePasswordError ?? this.updatePasswordError,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    user,
    isUpdatingDisplayName,
    updateDisplayNameError,
    isUpdatingPassword,
    updatePasswordError,
  ];
}

final class ProfileFailure extends ProfileState {
  const ProfileFailure(this.error);

  final AppException error;

  @override
  List<Object?> get props => <Object?>[error];
}
