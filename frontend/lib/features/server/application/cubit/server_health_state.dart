import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/server/domain/models/server_health.dart';

sealed class ServerHealthState extends Equatable {
  const ServerHealthState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class ServerHealthInitial extends ServerHealthState {
  const ServerHealthInitial();
}

final class ServerHealthLoading extends ServerHealthState {
  const ServerHealthLoading();
}

final class ServerHealthSuccess extends ServerHealthState {
  const ServerHealthSuccess(this.health);

  final ServerHealth health;

  @override
  List<Object?> get props => <Object?>[health];
}

final class ServerHealthFailure extends ServerHealthState {
  const ServerHealthFailure(this.error);

  final AppException error;

  @override
  List<Object?> get props => <Object?>[error];
}
