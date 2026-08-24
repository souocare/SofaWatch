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
  });

  final ProfileUser user;

  final bool isUpdatingDisplayName;

  final AppException? updateDisplayNameError;

  ProfileSuccess copyWith({
    ProfileUser? user,
    bool? isUpdatingDisplayName,
    AppException? updateDisplayNameError,
    bool clearUpdateDisplayNameError = false,
  }) {
    return ProfileSuccess(
      user: user ?? this.user,
      isUpdatingDisplayName:
          isUpdatingDisplayName ?? this.isUpdatingDisplayName,
      updateDisplayNameError: clearUpdateDisplayNameError
          ? null
          : updateDisplayNameError ?? this.updateDisplayNameError,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    user,
    isUpdatingDisplayName,
    updateDisplayNameError,
  ];
}

final class ProfileFailure extends ProfileState {
  const ProfileFailure(this.error);

  final AppException error;

  @override
  List<Object?> get props => <Object?>[error];
}
