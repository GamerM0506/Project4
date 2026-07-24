import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../donation/data/models/donation_model.dart';
import '../../../donation/domain/usecases/donation_usecases.dart';
import '../../../marketplace/domain/usecases/listing_usecases.dart';
import 'group_inventory_state.dart';

class GroupInventoryCubit extends Cubit<GroupInventoryState> {
  final GetDonationsUseCase getDonationsUseCase;
  final GetInventoryUseCase getInventoryUseCase;
  final ReviewDonationUseCase reviewDonationUseCase;
  final CheckDonationItemUseCase checkDonationItemUseCase;
  final CreateListingUseCase createListingUseCase;

  GroupInventoryCubit({
    required this.getDonationsUseCase,
    required this.getInventoryUseCase,
    required this.reviewDonationUseCase,
    required this.checkDonationItemUseCase,
    required this.createListingUseCase,
  }) : super(GroupInventoryInitial());

  Future<void> fetchInventory(String groupId) async {
    emit(GroupInventoryLoading());
    final donationResult = await getDonationsUseCase(
      groupId: groupId,
      limit: 100,
    );
    final inventoryResult = await getInventoryUseCase(
      groupId: groupId,
      limit: 100,
    );

    String? error;
    var donations = <DonationModel>[];
    var items = <InventoryItemModel>[];
    donationResult.fold((value) => error = value, (value) => donations = value);
    inventoryResult.fold((value) => error ??= value, (value) => items = value);
    if (error != null) {
      emit(GroupInventoryError(error!));
      return;
    }
    emit(GroupInventoryLoaded(donations: donations, items: items));
  }

  Future<void> review(
    String groupId,
    String donationId,
    String action, {
    String? reason,
  }) async {
    final current = state;
    if (current is! GroupInventoryLoaded) return;
    emit(
      GroupInventoryLoaded(
        donations: current.donations,
        items: current.items,
        isProcessing: true,
      ),
    );
    final result = await reviewDonationUseCase(
      donationId,
      action,
      reason: reason,
    );
    await result.fold(
      (error) async => emit(GroupInventoryError(error)),
      (_) async => fetchInventory(groupId),
    );
  }

  Future<void> checkItem({
    required String groupId,
    required String donationId,
    required String itemId,
    required String action,
    String? conditionActual,
    String? note,
  }) async {
    final result = await checkDonationItemUseCase(
      donationId: donationId,
      itemId: itemId,
      action: action,
      conditionActual: conditionActual,
      checkNote: action == 'accepted' ? note : null,
      rejectReason: action == 'rejected' ? note : null,
    );
    await result.fold(
      (error) async => emit(GroupInventoryError(error)),
      (_) async => fetchInventory(groupId),
    );
  }

  Future<void> publish(String groupId, InventoryItemModel item) async {
    final current = state;
    final imageUrls = current is GroupInventoryLoaded
        ? current.donations
              .expand((donation) => donation.items)
              .where((donationItem) => donationItem.id == item.donationItemId)
              .expand((donationItem) => donationItem.images)
              .map((image) => image.imageUrl)
              .where((url) => url.isNotEmpty)
              .toList()
        : <String>[];
    final result = await createListingUseCase(
      item.id,
      groupId,
      item.name,
      '',
      item.categoryId ?? '',
      item.condition,
      item.quantity,
      '',
      imageUrls: imageUrls,
    );
    await result.fold(
      (error) async => emit(GroupInventoryError(error)),
      (_) async => fetchInventory(groupId),
    );
  }
}
