import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/admin_users/application/cubit/admin_users_summary_state.dart';
import 'package:sofawatch/features/admin_users/domain/models/admin_users_summary.dart';
import 'package:sofawatch/features/admin_users/domain/repositories/admin_users_repository.dart';

final class AdminUsersSummaryCubit extends Cubit<AdminUsersSummaryState> {
  AdminUsersSummaryCubit({required this._repository})
    : super(const AdminUsersSummaryInitial());

  final AdminUsersRepository _repository;

  Future<void> load() async {
    if (state is AdminUsersSummaryLoading) {
      return;
    }

    emit(const AdminUsersSummaryLoading());

    try {
      final AdminUsersSummary summary = await _repository.getSummary();

      if (isClosed) {
        return;
      }

      emit(AdminUsersSummarySuccess(summary));
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(AdminUsersSummaryFailure(error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        AdminUsersSummaryFailure(AppException.unknown(originalError: error)),
      );
    }
  }

  Future<void> retry() {
    return load();
  }
}
