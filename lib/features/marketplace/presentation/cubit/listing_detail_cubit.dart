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

  Future<void> requestItem(String listingId, String groupId, String receiverId, int quantity, String reason) async {
    final currentState = state;
    if (currentState is ListingDetailLoaded) {
      // Show loading somehow or just fire and forget (or emit new state)
      // For simplicity, we just fire the request.
      final result = await createRequestUseCase(listingId, groupId, receiverId, quantity, reason);
      result.fold(
        (error) => emit(ListingDetailError(message: error)), // could revert back if needed
        (_) {
          // Success
          emit(ListingDetailLoaded(listing: currentState.listing)); // trigger rebuild
        }
      );
    }
  }
}
