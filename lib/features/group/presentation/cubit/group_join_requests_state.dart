import 'package:equatable/equatable.dart';
import '../../domain/entities/join_request_entity.dart';

abstract class GroupJoinRequestsState extends Equatable {
  const GroupJoinRequestsState();

  @override
  List<Object?> get props => [];
}

class GroupJoinRequestsInitial extends GroupJoinRequestsState {}

class GroupJoinRequestsLoading extends GroupJoinRequestsState {}

class GroupJoinRequestsLoaded extends GroupJoinRequestsState {
  final List<JoinRequestEntity> requests;

  const GroupJoinRequestsLoaded(this.requests);

  @override
  List<Object?> get props => [requests];
}

class GroupJoinRequestsError extends GroupJoinRequestsState {
  final String message;

  const GroupJoinRequestsError(this.message);

  @override
  List<Object?> get props => [message];
}

class GroupJoinRequestActionLoading extends GroupJoinRequestsState {
  final String requestId;

  const GroupJoinRequestActionLoading(this.requestId);

  @override
  List<Object?> get props => [requestId];
}
