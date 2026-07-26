import 'package:equatable/equatable.dart';
import '../../../marketplace/domain/entities/request_entity.dart';

abstract class GroupRequestsState extends Equatable {
  const GroupRequestsState();

  @override
  List<Object?> get props => [];
}

class GroupRequestsInitial extends GroupRequestsState {}

class GroupRequestsLoading extends GroupRequestsState {}

class GroupRequestsLoaded extends GroupRequestsState {
  final List<RequestEntity> requests;
  final Map<String, String> userNames;
  final Map<String, String> listingTitles;
  final String? processingId;
  final String? actionError;

  const GroupRequestsLoaded({
    required this.requests,
    required this.userNames,
    required this.listingTitles,
    this.processingId,
    this.actionError,
  });

  @override
  List<Object?> get props => [
    requests,
    userNames,
    listingTitles,
    processingId,
    actionError,
  ];
}

class GroupRequestsError extends GroupRequestsState {
  final String message;

  const GroupRequestsError({required this.message});

  @override
  List<Object?> get props => [message];
}
