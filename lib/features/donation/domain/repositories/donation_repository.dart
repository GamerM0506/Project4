import 'package:dartz/dartz.dart';
import '../entities/donation_entity.dart';

abstract class DonationRepository {
  Future<Either<String, List<DonationEntity>>> getDonations({
    String? groupId,
    bool mine = false,
    String? status,
  });

  Future<Either<String, DonationEntity>> getDonationDetail(String id);

  Future<Either<String, DonationEntity>> createDonation({
    required String groupId,
    required String title,
    String? description,
    String pickupMethod,
    String? pickupAddress,
    required List<Map<String, dynamic>> items,
  });

  Future<Either<String, void>> reviewDonation({
    required String id,
    required String action,
    String? reason,
  });

  Future<Either<String, void>> checkItem({
    required String donationId,
    required String itemId,
    required String action,
    String? conditionActual,
    String? checkNote,
    String? rejectReason,
  });

  Future<Either<String, List<DonationTimelineEntry>>> getTimeline(String id);
}
