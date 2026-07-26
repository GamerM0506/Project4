import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../marketplace/domain/usecases/request_usecases.dart';
import '../../../marketplace/domain/usecases/listing_usecases.dart';
import '../../domain/usecases/get_members_usecase.dart';
import 'group_requests_state.dart';

class GroupRequestsCubit extends Cubit<GroupRequestsState> {
  final GetRequestsUseCase getRequestsUseCase;
  final ApproveRequestUseCase approveRequestUseCase;
  final RejectRequestUseCase rejectRequestUseCase;
  final ScheduleRequestUseCase scheduleRequestUseCase;
  final CompleteRequestUseCase completeRequestUseCase;
  final NoShowRequestUseCase noShowRequestUseCase;
  final GetDeliveryConfirmationUseCase getDeliveryConfirmationUseCase;
  final GetListingDetailUseCase getListingDetailUseCase;
  final GetMembersUseCase getMembersUseCase;

  GroupRequestsCubit({
    required this.getRequestsUseCase,
    required this.approveRequestUseCase,
    required this.rejectRequestUseCase,
    required this.scheduleRequestUseCase,
    required this.completeRequestUseCase,
    required this.noShowRequestUseCase,
    required this.getDeliveryConfirmationUseCase,
    required this.getListingDetailUseCase,
    required this.getMembersUseCase,
  }) : super(GroupRequestsInitial());

  Future<void> fetchRequests(String groupId) async {
    emit(GroupRequestsLoading());
    final result = await getRequestsUseCase(groupId: groupId, limit: 100);

    result.fold((error) => emit(GroupRequestsError(message: error)), (
      requests,
    ) async {
      final Map<String, String> userNames = {};
      final Map<String, String> listingTitles = {};

      // Fetch members to get names
      final membersResult = await getMembersUseCase(groupId, limit: 1000);
      membersResult.fold((_) {}, (members) {
        for (var m in members) {
          userNames[m.userId] = m.userName?.trim().isNotEmpty == true
              ? m.userName!
              : m.userId;
        }
      });

      // Fetch listing titles
      final listingIds = requests.items.map((r) => r.listingId).toSet();
      for (var lId in listingIds) {
        final lResult = await getListingDetailUseCase(lId);
        lResult.fold((_) {}, (listing) {
          listingTitles[lId] = listing.title;
        });
      }

      emit(
        GroupRequestsLoaded(
          requests: requests.items,
          userNames: userNames,
          listingTitles: listingTitles,
        ),
      );
    });
  }

  Future<void> approveRequest(String groupId, String requestId) =>
      _run(groupId, requestId, () => approveRequestUseCase(requestId));

  Future<void> rejectRequest(String groupId, String requestId, String reason) =>
      _run(groupId, requestId, () => rejectRequestUseCase(requestId, reason));

  Future<void> scheduleRequest(
    String groupId,
    String requestId,
    DateTime date,
  ) => _run(groupId, requestId, () => scheduleRequestUseCase(requestId, date));

  Future<void> completeRequest(
    String groupId,
    String requestId,
    String qrToken, {
    String? photoUrl,
    String? note,
  }) => _run(
    groupId,
    requestId,
    () => completeRequestUseCase(
      requestId,
      qrToken,
      photoUrl: photoUrl,
      note: note,
    ),
  );

  Future<void> noShowRequest(String groupId, String requestId) =>
      _run(groupId, requestId, () => noShowRequestUseCase(requestId));

  Future<String> confirmation(String requestId) async {
    final result = await getDeliveryConfirmationUseCase(requestId);
    return result.fold(
      (error) => error,
      (value) => [
        'Người xác nhận: ${value.confirmedBy}',
        if (value.confirmedAt != null)
          'Thời gian: ${value.confirmedAt!.toLocal()}',
        if (value.photoUrl?.isNotEmpty ?? false) 'Ảnh: ${value.photoUrl}',
        if (value.note?.isNotEmpty ?? false) 'Ghi chú: ${value.note}',
      ].join('\n'),
    );
  }

  Future<void> _run(
    String groupId,
    String requestId,
    Future<dynamic> Function() action,
  ) async {
    final current = state;
    if (current is! GroupRequestsLoaded || current.processingId != null) return;
    emit(
      GroupRequestsLoaded(
        requests: current.requests,
        userNames: current.userNames,
        listingTitles: current.listingTitles,
        processingId: requestId,
      ),
    );
    final result = await action();
    await result.fold(
      (error) async => emit(
        GroupRequestsLoaded(
          requests: current.requests,
          userNames: current.userNames,
          listingTitles: current.listingTitles,
          actionError: error.toString(),
        ),
      ),
      (_) async => fetchRequests(groupId),
    );
  }
}
