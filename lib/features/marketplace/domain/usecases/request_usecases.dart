import 'package:dartz/dartz.dart';
import '../entities/request_entity.dart';
import '../repositories/marketplace_repository.dart';

class GetRequestsUseCase {
  final MarketplaceRepository repository;
  GetRequestsUseCase(this.repository);

  Future<Either<String, List<RequestEntity>>> call({
    String? receiverId,
    String? groupId,
    String? status,
  }) {
    return repository.getRequests(
      receiverId: receiverId,
      groupId: groupId,
      status: status,
    );
  }
}

class CreateRequestUseCase {
  final MarketplaceRepository repository;
  CreateRequestUseCase(this.repository);

  Future<Either<String, void>> call(String listingId, String groupId, String receiverId, int quantity, String reason) {
    return repository.createRequest(listingId, groupId, receiverId, quantity, reason);
  }
}

class ApproveRequestUseCase {
  final MarketplaceRepository repository;
  ApproveRequestUseCase(this.repository);

  Future<Either<String, void>> call(String id, String reviewedBy) {
    return repository.approveRequest(id, reviewedBy);
  }
}

class RejectRequestUseCase {
  final MarketplaceRepository repository;
  RejectRequestUseCase(this.repository);

  Future<Either<String, void>> call(String id, String reviewedBy, String reason) {
    return repository.rejectRequest(id, reviewedBy, reason);
  }
}

class ScheduleRequestUseCase {
  final MarketplaceRepository repository;
  ScheduleRequestUseCase(this.repository);

  Future<Either<String, void>> call(String id, String reviewedBy, DateTime scheduledAt) {
    return repository.scheduleRequest(id, reviewedBy, scheduledAt);
  }
}

class CompleteRequestUseCase {
  final MarketplaceRepository repository;
  CompleteRequestUseCase(this.repository);

  Future<Either<String, void>> call(String id, String confirmedBy, String qrToken, String photoUrl) {
    return repository.completeRequest(id, confirmedBy, qrToken, photoUrl);
  }
}
