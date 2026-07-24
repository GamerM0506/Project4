import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/donation_entity.dart';
import '../../domain/usecases/donation_usecases.dart';

class GroupDonationsState {
  final bool isLoading;
  final List<DonationEntity> donations;
  final String? error;
  final String? actionId;
  final String? message;

  const GroupDonationsState({
    this.isLoading = false,
    this.donations = const [],
    this.error,
    this.actionId,
    this.message,
  });

  GroupDonationsState copyWith({
    bool? isLoading,
    List<DonationEntity>? donations,
    String? error,
    String? actionId,
    String? message,
    bool clearMessage = false,
  }) {
    return GroupDonationsState(
      isLoading: isLoading ?? this.isLoading,
      donations: donations ?? this.donations,
      error: error,
      actionId: actionId,
      message: clearMessage ? null : message,
    );
  }
}

class GroupDonationsCubit extends Cubit<GroupDonationsState> {
  final GetDonationsUseCase getDonationsUseCase;
  final ReviewDonationUseCase reviewDonationUseCase;
  final CheckDonationItemUseCase checkDonationItemUseCase;

  GroupDonationsCubit({
    required this.getDonationsUseCase,
    required this.reviewDonationUseCase,
    required this.checkDonationItemUseCase,
  }) : super(const GroupDonationsState());

  Future<void> load(String groupId) async {
    emit(state.copyWith(isLoading: true, error: null, clearMessage: true));
    final result = await getDonationsUseCase(groupId: groupId);
    result.fold(
      (err) => emit(state.copyWith(isLoading: false, error: err)),
      (items) => emit(state.copyWith(isLoading: false, donations: items)),
    );
  }

  Future<void> review(String id, String action, {String? reason}) async {
    emit(state.copyWith(actionId: id, clearMessage: true));
    final result = await reviewDonationUseCase(
      id: id,
      action: action,
      reason: reason,
    );
    await result.fold(
      (err) async =>
          emit(state.copyWith(actionId: null, message: err)),
      (_) async {
        final updated = state.donations
            .map((d) => d.id == id
                ? DonationEntity(
                    id: d.id,
                    code: d.code,
                    donorId: d.donorId,
                    groupId: d.groupId,
                    title: d.title,
                    description: d.description,
                    status: action == 'accepted' ? 'accepted' : 'rejected',
                    pickupMethod: d.pickupMethod,
                    pickupAddress: d.pickupAddress,
                    scheduledAt: d.scheduledAt,
                    rejectedReason: reason,
                    createdAt: d.createdAt,
                    items: d.items,
                  )
                : d)
            .toList();
        emit(state.copyWith(
          donations: updated,
          actionId: null,
          message: action == 'accepted' ? 'Đã chấp nhận' : 'Đã từ chối',
        ));
      },
    );
  }

  Future<void> checkItem({
    required String donationId,
    required String itemId,
    required String action,
  }) async {
    emit(state.copyWith(actionId: itemId, clearMessage: true));
    final result = await checkDonationItemUseCase(
      donationId: donationId,
      itemId: itemId,
      action: action,
      conditionActual: action == 'accepted' ? 'good' : null,
      rejectReason: action == 'rejected' ? 'Không đạt' : null,
    );
    await result.fold(
      (err) async =>
          emit(state.copyWith(actionId: null, message: err)),
      (_) async {
        emit(state.copyWith(
          actionId: null,
          message: action == 'accepted'
              ? 'Đã nhập kho món đồ'
              : 'Đã từ chối món đồ',
        ));
        // reload parent list if we know group
        String? groupId;
        for (final d in state.donations) {
          if (d.id == donationId) {
            groupId = d.groupId;
            break;
          }
        }
        if (groupId != null && groupId.isNotEmpty) {
          await load(groupId);
        }
      },
    );
  }
}
