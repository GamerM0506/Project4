import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/listing_usecases.dart';
import 'create_listing_state.dart';

class CreateListingCubit extends Cubit<CreateListingState> {
  final CreateListingUseCase createListingUseCase;

  CreateListingCubit({required this.createListingUseCase}) : super(CreateListingInitial());

  Future<void> createListing({
    required String inventoryItemId,
    required String groupId,
    required String title,
    required String description,
    required String categoryId,
    required String condition,
    required int quantityTotal,
    required String createdBy,
  }) async {
    emit(CreateListingLoading());

    final result = await createListingUseCase(
      inventoryItemId,
      groupId,
      title,
      description,
      categoryId,
      condition,
      quantityTotal,
      createdBy,
    );

    result.fold(
      (error) => emit(CreateListingError(message: error)),
      (_) => emit(CreateListingSuccess()),
    );
  }
}
