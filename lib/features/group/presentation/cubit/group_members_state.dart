import 'package:equatable/equatable.dart';
import '../../domain/entities/member_entity.dart';

abstract class GroupMembersState extends Equatable {
  const GroupMembersState();

  @override
  List<Object?> get props => [];
}

class GroupMembersInitial extends GroupMembersState {}

class GroupMembersLoading extends GroupMembersState {}

class GroupMembersLoaded extends GroupMembersState {
  final List<MemberEntity> members;
  final bool hasReachedMax;
  final bool isLoadingMore;

  const GroupMembersLoaded(
    this.members, {
    this.hasReachedMax = false,
    this.isLoadingMore = false,
  });

  @override
  List<Object?> get props => [members, hasReachedMax, isLoadingMore];
}

class GroupMembersError extends GroupMembersState {
  final String message;

  const GroupMembersError(this.message);

  @override
  List<Object?> get props => [message];
}
