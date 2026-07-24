import 'package:dartz/dartz.dart';
import '../../data/models/donation_model.dart';
import '../repositories/donation_repository.dart';

class GetDonationCategoriesUseCase {
  final DonationRepository repository;
  GetDonationCategoriesUseCase(this.repository);

  Future<Either<String, List<DonationCategoryModel>>> call() {
    return repository.getCategories();
  }
}

class GetDonationsUseCase {
  final DonationRepository repository;
  GetDonationsUseCase(this.repository);

  Future<Either<String, List<DonationModel>>> call({
    String? groupId,
    String? status,
    bool mine = false,
    int limit = 50,
    int offset = 0,
  }) {
    return repository.getDonations(
      groupId: groupId,
      status: status,
      mine: mine,
      limit: limit,
      offset: offset,
    );
  }
}

class ReviewDonationUseCase {
  final DonationRepository repository;
  ReviewDonationUseCase(this.repository);

  Future<Either<String, DonationModel>> call(
    String donationId,
    String action, {
    String? reason,
  }) {
    return repository.reviewDonation(donationId, action, reason: reason);
  }
}

class CheckDonationItemUseCase {
  final DonationRepository repository;
  CheckDonationItemUseCase(this.repository);

  Future<Either<String, DonationModel>> call({
    required String donationId,
    required String itemId,
    required String action,
    String? conditionActual,
    String? checkNote,
    String? rejectReason,
  }) {
    return repository.checkItem(
      donationId: donationId,
      itemId: itemId,
      action: action,
      conditionActual: conditionActual,
      checkNote: checkNote,
      rejectReason: rejectReason,
    );
  }
}

class CreateDonationUseCase {
  final DonationRepository repository;
  CreateDonationUseCase(this.repository);

  Future<Either<String, DonationModel>> call({
    required String groupId,
    required String title,
    String? description,
    String pickupMethod = 'drop_off',
    String? pickupAddress,
    required List<Map<String, dynamic>> items,
  }) {
    return repository.createDonation(
      groupId: groupId,
      title: title,
      description: description,
      pickupMethod: pickupMethod,
      pickupAddress: pickupAddress,
      items: items,
    );
  }
}

class AcceptDonationUseCase {
  final DonationRepository repository;
  AcceptDonationUseCase(this.repository);

  Future<Either<String, DonationModel>> call({
    required String donationId,
    String defaultCondition = 'used',
  }) {
    return repository.acceptDonationToInventory(
      donationId: donationId,
      defaultCondition: defaultCondition,
    );
  }
}

class GetInventoryUseCase {
  final DonationRepository repository;
  GetInventoryUseCase(this.repository);

  Future<Either<String, List<InventoryItemModel>>> call({
    String? groupId,
    String? status,
    bool mine = false,
    int limit = 50,
    int offset = 0,
  }) {
    return repository.getInventory(
      groupId: groupId,
      status: status,
      mine: mine,
      limit: limit,
      offset: offset,
    );
  }
}
