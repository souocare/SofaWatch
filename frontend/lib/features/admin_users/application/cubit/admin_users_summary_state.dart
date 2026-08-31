import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/admin_users/domain/models/admin_users_summary.dart';

sealed class AdminUsersSummaryState extends Equatable {
  const AdminUsersSummaryState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class AdminUsersSummaryInitial extends AdminUsersSummaryState {
  const AdminUsersSummaryInitial();
}

final class AdminUsersSummaryLoading extends AdminUsersSummaryState {
  const AdminUsersSummaryLoading();
}

final class AdminUsersSummarySuccess extends AdminUsersSummaryState {
  const AdminUsersSummarySuccess(this.summary);

  final AdminUsersSummary summary;

  @override
  List<Object?> get props => <Object?>[summary];
}

final class AdminUsersSummaryFailure extends AdminUsersSummaryState {
  const AdminUsersSummaryFailure(this.error);

  final AppException error;

  @override
  List<Object?> get props => <Object?>[error];
}
