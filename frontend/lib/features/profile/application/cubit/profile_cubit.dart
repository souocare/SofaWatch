import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/profile/application/cubit/profile_state.dart';
import 'package:sofawatch/features/profile/domain/models/profile_user.dart';
import 'package:sofawatch/features/profile/domain/repositories/profile_repository.dart';

final class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({required this._repository}) : super(const ProfileInitial());

  final ProfileRepository _repository;

  Future<void> load() async {
    if (state is ProfileLoading) {
      return;
    }

    emit(const ProfileLoading());

    try {
      final ProfileUser user = await _repository.getCurrentUser();

      if (isClosed) {
        return;
      }

      emit(ProfileSuccess(user: user));
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(ProfileFailure(error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(ProfileFailure(AppException.unknown(originalError: error)));
    }
  }

  Future<bool> updateDisplayName(String displayName) async {
    final ProfileState currentState = state;

    if (currentState is! ProfileSuccess || currentState.isUpdatingDisplayName) {
      return false;
    }

    final String normalizedDisplayName = displayName.trim();

    if (normalizedDisplayName.isEmpty ||
        normalizedDisplayName == currentState.user.displayName) {
      return false;
    }

    emit(
      currentState.copyWith(
        isUpdatingDisplayName: true,
        clearUpdateDisplayNameError: true,
      ),
    );

    try {
      final ProfileUser user = await _repository.updateDisplayName(
        displayName: normalizedDisplayName,
      );

      if (isClosed) {
        return false;
      }

      emit(ProfileSuccess(user: user));

      return true;
    } on AppException catch (error) {
      if (isClosed) {
        return false;
      }

      emit(
        currentState.copyWith(
          isUpdatingDisplayName: false,
          updateDisplayNameError: error,
        ),
      );

      return false;
    } on Object catch (error) {
      if (isClosed) {
        return false;
      }

      emit(
        currentState.copyWith(
          isUpdatingDisplayName: false,
          updateDisplayNameError: AppException.unknown(originalError: error),
        ),
      );

      return false;
    }
  }

  void clearUpdateDisplayNameError() {
    final ProfileState currentState = state;

    if (currentState is! ProfileSuccess ||
        currentState.updateDisplayNameError == null) {
      return;
    }

    emit(currentState.copyWith(clearUpdateDisplayNameError: true));
  }

  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final ProfileState currentState = state;

    if (currentState is! ProfileSuccess || currentState.isUpdatingPassword) {
      return false;
    }

    if (currentPassword.isEmpty ||
        newPassword.length < 8 ||
        newPassword.length > 128) {
      return false;
    }

    emit(
      currentState.copyWith(
        isUpdatingPassword: true,
        clearUpdatePasswordError: true,
      ),
    );

    try {
      await _repository.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (isClosed) {
        return false;
      }

      emit(
        currentState.copyWith(
          isUpdatingPassword: false,
          clearUpdatePasswordError: true,
        ),
      );

      return true;
    } on AppException catch (error) {
      if (isClosed) {
        return false;
      }

      emit(
        currentState.copyWith(
          isUpdatingPassword: false,
          updatePasswordError: error,
        ),
      );

      return false;
    } on Object catch (error) {
      if (isClosed) {
        return false;
      }

      emit(
        currentState.copyWith(
          isUpdatingPassword: false,
          updatePasswordError: AppException.unknown(originalError: error),
        ),
      );

      return false;
    }
  }

  void clearUpdatePasswordError() {
    final ProfileState currentState = state;

    if (currentState is! ProfileSuccess ||
        currentState.updatePasswordError == null) {
      return;
    }

    emit(currentState.copyWith(clearUpdatePasswordError: true));
  }

  Future<void> retry() {
    return load();
  }
}
