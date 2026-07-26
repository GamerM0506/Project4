import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/usecases/listing_usecases.dart';
import '../../domain/usecases/request_usecases.dart';
import 'listing_detail_state.dart';

class ListingDetailCubit extends Cubit<ListingDetailState> {
  final GetListingDetailUseCase getListingDetailUseCase;
  final CreateRequestUseCase createRequestUseCase;
  final GetRequestsUseCase getRequestsUseCase;
  final SharedPreferences prefs;

  ListingDetailCubit({
    required this.getListingDetailUseCase,
    required this.createRequestUseCase,
    required this.getRequestsUseCase,
    required this.prefs,
  }) : super(ListingDetailInitial());

  Future<void> loadDetail(String id) async {
    emit(ListingDetailLoading());

    final result = await getListingDetailUseCase(id);

    await result.fold(
      (error) async => emit(ListingDetailError(message: error)),
      (listing) async {
        var hasRequested = false;
        final userId = prefs.getString(AppConstants.keyUserId);
        if (userId?.isNotEmpty ?? false) {
          final requests = await getRequestsUseCase(
            listingId: id,
            receiverId: userId,
            limit: 20,
          );
          requests.fold((_) {}, (page) {
            hasRequested = page.items.any(
              (request) => const {
                'pending',
                'approved',
                'scheduled',
                'completed',
              }.contains(request.status),
            );
          });
        }
        if (!isClosed) {
          emit(
            ListingDetailLoaded(listing: listing, hasRequested: hasRequested),
          );
        }
      },
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
    final hasRequested = switch (currentState) {
      ListingDetailLoaded(:final hasRequested) => hasRequested,
      ListingRequestSubmitting(:final hasRequested) => hasRequested,
      ListingRequestSuccess(:final hasRequested) => hasRequested,
      ListingRequestFailure(:final hasRequested) => hasRequested,
      _ => false,
    };
    if (hasRequested) return false;

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
