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
  final bool hasReachedMax;
  final bool isLoadingMore;

  const GroupJoinRequestsLoaded(
    this.requests, {
    this.hasReachedMax = false,
    this.isLoadingMore = false,
  });

  @override
  List<Object?> get props => [requests, hasReachedMax, isLoadingMore];
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
