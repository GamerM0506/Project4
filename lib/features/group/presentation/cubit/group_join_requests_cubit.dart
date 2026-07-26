import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_join_requests_usecase.dart';
import '../../domain/usecases/approve_join_usecase.dart';
import '../../domain/usecases/reject_join_usecase.dart';
import 'group_join_requests_state.dart';

class GroupJoinRequestsCubit extends Cubit<GroupJoinRequestsState> {
  final GetJoinRequestsUseCase getJoinRequestsUseCase;
  final ApproveJoinUseCase approveJoinUseCase;
  final RejectJoinUseCase rejectJoinUseCase;
  static const _limit = 20;
  String? _status;

  GroupJoinRequestsCubit({
    required this.getJoinRequestsUseCase,
    required this.approveJoinUseCase,
    required this.rejectJoinUseCase,
  }) : super(GroupJoinRequestsInitial());

  Future<void> fetchRequests(String groupId, {String? status}) async {
    _status = status;
    emit(GroupJoinRequestsLoading());
    final result = await getJoinRequestsUseCase(
      groupId,
      status: status,
      limit: _limit,
    );

    result.fold(
      (failure) => emit(GroupJoinRequestsError(failure)),
      (requests) => emit(
        GroupJoinRequestsLoaded(
          requests,
          hasReachedMax: requests.length < _limit,
        ),
      ),
    );
  }

  Future<void> loadMore(String groupId) async {
    final current = state;
    if (current is! GroupJoinRequestsLoaded ||
        current.hasReachedMax ||
        current.isLoadingMore) {
      return;
    }
    emit(
      GroupJoinRequestsLoaded(
        current.requests,
        hasReachedMax: current.hasReachedMax,
        isLoadingMore: true,
      ),
    );
    final result = await getJoinRequestsUseCase(
      groupId,
      status: _status,
      limit: _limit,
      offset: current.requests.length,
    );
    result.fold(
      (failure) => emit(GroupJoinRequestsError(failure)),
      (requests) => emit(
        GroupJoinRequestsLoaded([
          ...current.requests,
          ...requests,
        ], hasReachedMax: requests.length < _limit),
      ),
    );
  }

  Future<void> approveRequest(String groupId, String requestId) async {
    if (state is GroupJoinRequestsLoaded) {
      final currentState = state as GroupJoinRequestsLoaded;
      final currentRequests = currentState.requests;

      emit(GroupJoinRequestActionLoading(requestId));

      final result = await approveJoinUseCase(groupId, requestId);

      result.fold(
        (failure) {
          emit(GroupJoinRequestsError(failure));
          emit(currentState); // Revert
        },
        (request) {
          // Remove from list or update status
          final updatedRequests = currentRequests
              .where((r) => r.id != requestId)
              .toList();
          emit(
            GroupJoinRequestsLoaded(
              updatedRequests,
              hasReachedMax: currentState.hasReachedMax,
            ),
          );
        },
      );
    }
  }

  Future<void> rejectRequest(String groupId, String requestId) async {
    if (state is GroupJoinRequestsLoaded) {
      final currentState = state as GroupJoinRequestsLoaded;
      final currentRequests = currentState.requests;

      emit(GroupJoinRequestActionLoading(requestId));

      final result = await rejectJoinUseCase(groupId, requestId);

      result.fold(
        (failure) {
          emit(GroupJoinRequestsError(failure));
          emit(currentState); // Revert
        },
        (request) {
          // Remove from list
          final updatedRequests = currentRequests
              .where((r) => r.id != requestId)
              .toList();
          emit(
            GroupJoinRequestsLoaded(
              updatedRequests,
              hasReachedMax: currentState.hasReachedMax,
            ),
          );
        },
      );
    }
  }
}
