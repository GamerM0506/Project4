import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/listing_usecases.dart';
import '../../domain/usecases/request_usecases.dart';
import 'listing_detail_state.dart';

class ListingDetailCubit extends Cubit<ListingDetailState> {
  final GetListingDetailUseCase getListingDetailUseCase;
  final CreateRequestUseCase createRequestUseCase;

  ListingDetailCubit({
    required this.getListingDetailUseCase,
    required this.createRequestUseCase,
  }) : super(ListingDetailInitial());

  Future<void> loadDetail(String id) async {
    emit(ListingDetailLoading());

    final result = await getListingDetailUseCase(id);

    result.fold(
      (error) => emit(ListingDetailError(message: error)),
      (listing) => emit(ListingDetailLoaded(listing: listing)),
    );
  }

  Future<String?> requestItem({
    required String listingId,
    required String groupId,
    required String receiverId,
    required int quantity,
    required String reason,
  }) async {
    final currentState = state;
    if (currentState is! ListingDetailLoaded) return 'Chưa tải được chi tiết món đồ.';

    final result = await createRequestUseCase(
      listingId,
      groupId,
      receiverId,
      quantity,
      reason,
    );

    return result.fold(
      (error) => error,
      (_) => null,
    );
  }
}
