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

  Future<bool> requestItem(int quantity, String reason) async {
    final currentState = state;
    final listing = switch (currentState) {
      ListingDetailLoaded(:final listing) => listing,
      ListingRequestFailure(:final listing) => listing,
      ListingRequestSuccess(:final listing) => listing,
      _ => null,
    };
    if (listing == null) return false;

    if (quantity <= 0 || quantity > listing.quantityAvailable) {
      emit(
        ListingRequestFailure(
          listing: listing,
          message: 'Số lượng yêu cầu không hợp lệ.',
        ),
      );
      return false;
    }

    emit(ListingRequestSubmitting(listing: listing));
    final result = await createRequestUseCase(listing.id, quantity, reason);
    return result.fold(
      (error) {
        emit(ListingRequestFailure(listing: listing, message: error));
        return false;
      },
      (_) {
        emit(ListingRequestSuccess(listing: listing));
        return true;
      },
    );
  }
}
