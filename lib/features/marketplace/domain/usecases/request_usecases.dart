import 'package:dartz/dartz.dart';

import '../entities/delivery_confirmation_entity.dart';
import '../entities/paginated_result.dart';
import '../entities/request_entity.dart';
import '../repositories/marketplace_repository.dart';

class GetRequestsUseCase {
  final MarketplaceRepository repository;
  GetRequestsUseCase(this.repository);

  Future<Either<String, PaginatedResult<RequestEntity>>> call({
    String? groupId,
    String? listingId,
    String? receiverId,
    String? status,
    int page = 1,
    int limit = 20,
  }) => repository.getRequests(
    groupId: groupId,
    listingId: listingId,
    receiverId: receiverId,
    status: status,
    page: page,
    limit: limit,
  );
}

class CreateRequestUseCase {
  final MarketplaceRepository repository;
  CreateRequestUseCase(this.repository);

  Future<Either<String, void>> call(
    String listingId,
    int quantity,
    String reason,
  ) => repository.createRequest(listingId, quantity, reason);
}

class ApproveRequestUseCase {
  final MarketplaceRepository repository;
  ApproveRequestUseCase(this.repository);
  Future<Either<String, void>> call(String id) => repository.approveRequest(id);
}

class RejectRequestUseCase {
  final MarketplaceRepository repository;
  RejectRequestUseCase(this.repository);
  Future<Either<String, void>> call(String id, String reason) =>
      repository.rejectRequest(id, reason);
}

class ScheduleRequestUseCase {
  final MarketplaceRepository repository;
  ScheduleRequestUseCase(this.repository);
  Future<Either<String, void>> call(String id, DateTime scheduledAt) =>
      repository.scheduleRequest(id, scheduledAt);
}

class CompleteRequestUseCase {
  final MarketplaceRepository repository;
  CompleteRequestUseCase(this.repository);
  Future<Either<String, void>> call(
    String id,
    String qrToken, {
    String? photoUrl,
    String? note,
  }) => repository.completeRequest(id, qrToken, photoUrl, note);
}

class CancelRequestUseCase {
  final MarketplaceRepository repository;
  CancelRequestUseCase(this.repository);
  Future<Either<String, void>> call(String id) => repository.cancelRequest(id);
}

class NoShowRequestUseCase {
  final MarketplaceRepository repository;
  NoShowRequestUseCase(this.repository);
  Future<Either<String, void>> call(String id) => repository.noShowRequest(id);
}

class GetDeliveryConfirmationUseCase {
  final MarketplaceRepository repository;
  GetDeliveryConfirmationUseCase(this.repository);
  Future<Either<String, DeliveryConfirmationEntity>> call(String id) =>
      repository.getDeliveryConfirmation(id);
}
