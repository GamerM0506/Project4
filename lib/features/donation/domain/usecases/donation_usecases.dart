import 'package:dartz/dartz.dart';
import '../entities/donation_entity.dart';
import '../repositories/donation_repository.dart';

class GetDonationsUseCase {
  final DonationRepository repository;
  GetDonationsUseCase(this.repository);

  Future<Either<String, List<DonationEntity>>> call({
    String? groupId,
    bool mine = false,
    String? status,
  }) {
    return repository.getDonations(
      groupId: groupId,
      mine: mine,
      status: status,
    );
  }
}

class GetDonationDetailUseCase {
  final DonationRepository repository;
  GetDonationDetailUseCase(this.repository);

  Future<Either<String, DonationEntity>> call(String id) {
    return repository.getDonationDetail(id);
  }
}

class CreateDonationUseCase {
  final DonationRepository repository;
  CreateDonationUseCase(this.repository);

  Future<Either<String, DonationEntity>> call({
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

class ReviewDonationUseCase {
  final DonationRepository repository;
  ReviewDonationUseCase(this.repository);

  Future<Either<String, void>> call({
    required String id,
    required String action,
    String? reason,
  }) {
    return repository.reviewDonation(id: id, action: action, reason: reason);
  }
}

class CheckDonationItemUseCase {
  final DonationRepository repository;
  CheckDonationItemUseCase(this.repository);

  Future<Either<String, void>> call({
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

class GetDonationTimelineUseCase {
  final DonationRepository repository;
  GetDonationTimelineUseCase(this.repository);

  Future<Either<String, List<DonationTimelineEntry>>> call(String id) {
    return repository.getTimeline(id);
  }
}
