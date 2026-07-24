import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/request_entity.dart';
import '../../domain/usecases/request_usecases.dart';

class GroupRequestsState {
  final bool isLoading;
  final List<RequestEntity> requests;
  final String? error;
  final String? actionId;
  final String? actionError;
  final String? actionSuccess;

  const GroupRequestsState({
    this.isLoading = false,
    this.requests = const [],
    this.error,
    this.actionId,
    this.actionError,
    this.actionSuccess,
  });

  GroupRequestsState copyWith({
    bool? isLoading,
    List<RequestEntity>? requests,
    String? error,
    String? actionId,
    String? actionError,
    String? actionSuccess,
    bool clearAction = false,
  }) {
    return GroupRequestsState(
      isLoading: isLoading ?? this.isLoading,
      requests: requests ?? this.requests,
      error: error,
      actionId: clearAction ? null : (actionId ?? this.actionId),
      actionError: clearAction ? null : actionError,
      actionSuccess: clearAction ? null : actionSuccess,
    );
  }
}

class GroupRequestsCubit extends Cubit<GroupRequestsState> {
  final GetRequestsUseCase getRequestsUseCase;
  final ApproveRequestUseCase approveRequestUseCase;
  final RejectRequestUseCase rejectRequestUseCase;
  final CompleteRequestUseCase completeRequestUseCase;
  final SharedPreferences prefs;

  GroupRequestsCubit({
    required this.getRequestsUseCase,
    required this.approveRequestUseCase,
    required this.rejectRequestUseCase,
    required this.completeRequestUseCase,
    required this.prefs,
  }) : super(const GroupRequestsState());

  String get _userId => prefs.getString(AppConstants.keyUserId) ?? '';

  Future<void> load(String groupId) async {
    emit(state.copyWith(isLoading: true, error: null, clearAction: true));
    final result = await getRequestsUseCase(groupId: groupId);
    result.fold(
      (err) => emit(state.copyWith(isLoading: false, error: err)),
      (items) => emit(state.copyWith(isLoading: false, requests: items)),
    );
  }

  Future<void> approve(String requestId) async {
    final reviewer = _userId;
    if (reviewer.isEmpty) {
      emit(state.copyWith(actionError: 'Thiếu user id. Đăng nhập lại.'));
      return;
    }
    emit(state.copyWith(actionId: requestId, clearAction: false));
    final result = await approveRequestUseCase(requestId, reviewer);
    await result.fold(
      (err) async => emit(state.copyWith(
        actionId: null,
        actionError: err,
      )),
      (_) async {
        final updated = state.requests
            .map((r) => r.id == requestId
                ? _copyStatus(r, 'approved')
                : r)
            .toList();
        emit(state.copyWith(
          requests: updated,
          actionId: null,
          actionSuccess: 'Đã duyệt yêu cầu',
        ));
      },
    );
  }

  Future<void> reject(String requestId, String reason) async {
    final reviewer = _userId;
    if (reviewer.isEmpty) {
      emit(state.copyWith(actionError: 'Thiếu user id. Đăng nhập lại.'));
      return;
    }
    emit(state.copyWith(actionId: requestId));
    final result =
        await rejectRequestUseCase(requestId, reviewer, reason);
    await result.fold(
      (err) async => emit(state.copyWith(actionId: null, actionError: err)),
      (_) async {
        final updated = state.requests
            .map((r) => r.id == requestId
                ? _copyStatus(r, 'rejected')
                : r)
            .toList();
        emit(state.copyWith(
          requests: updated,
          actionId: null,
          actionSuccess: 'Đã từ chối yêu cầu',
        ));
      },
    );
  }

  Future<void> complete({
    required String requestId,
    required String qrToken,
    String photoUrl = '',
  }) async {
    final confirmedBy = _userId;
    if (confirmedBy.isEmpty) {
      emit(state.copyWith(actionError: 'Thiếu user id. Đăng nhập lại.'));
      return;
    }
    if (qrToken.trim().isEmpty) {
      emit(state.copyWith(actionError: 'Vui lòng nhập / quét mã QR.'));
      return;
    }
    emit(state.copyWith(actionId: requestId));
    final result = await completeRequestUseCase(
      requestId,
      confirmedBy,
      qrToken.trim(),
      photoUrl,
    );
    await result.fold(
      (err) async => emit(state.copyWith(actionId: null, actionError: err)),
      (_) async {
        final updated = state.requests
            .map((r) => r.id == requestId
                ? _copyStatus(r, 'completed')
                : r)
            .toList();
        emit(state.copyWith(
          requests: updated,
          actionId: null,
          actionSuccess: 'Đã xác nhận trao tặng',
        ));
      },
    );
  }

  RequestEntity _copyStatus(RequestEntity r, String status) {
    return RequestEntity(
      id: r.id,
      listingId: r.listingId,
      groupId: r.groupId,
      receiverId: r.receiverId,
      quantity: r.quantity,
      reason: r.reason,
      status: status,
      reviewedBy: r.reviewedBy,
      scheduledAt: r.scheduledAt,
      confirmedBy: r.confirmedBy,
      qrToken: r.qrToken,
      photoUrl: r.photoUrl,
      createdAt: r.createdAt,
    );
  }
}
