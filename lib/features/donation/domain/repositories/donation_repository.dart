import 'package:dartz/dartz.dart';
import '../../data/models/donation_model.dart';

abstract class DonationRepository {
  Future<Either<String, List<DonationCategoryModel>>> getCategories();

  Future<Either<String, List<DonationModel>>> getDonations({
    String? groupId,
    String? status,
    bool mine,
    int limit,
    int offset,
  });

  Future<Either<String, DonationModel>> createDonation({
    required String groupId,
    required String title,
    String? description,
    String pickupMethod,
    String? pickupAddress,
    required List<Map<String, dynamic>> items,
  });

  Future<Either<String, DonationModel>> reviewDonation(
    String donationId,
    String action, {
    String? reason,
  });

  Future<Either<String, DonationModel>> checkItem({
    required String donationId,
    required String itemId,
    required String action,
    String? conditionActual,
    String? checkNote,
    String? rejectReason,
  });

  Future<Either<String, DonationModel>> getDonation(String donationId);

  Future<Either<String, List<InventoryItemModel>>> getInventory({
    String? groupId,
    String? status,
    bool mine,
    int limit,
    int offset,
  });

  /// Moderator: accept donation + check all items → import inventory.
  Future<Either<String, DonationModel>> acceptDonationToInventory({
    required String donationId,
    String defaultCondition,
  });
}
