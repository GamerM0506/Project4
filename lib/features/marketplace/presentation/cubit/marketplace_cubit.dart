import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/listing_usecases.dart';
import 'marketplace_state.dart';

class MarketplaceCubit extends Cubit<MarketplaceState> {
  final GetCatalogUseCase getCatalogUseCase;

  MarketplaceCubit({required this.getCatalogUseCase}) : super(MarketplaceInitial());

  Future<void> loadCatalog({String? category, String? province, String? groupId}) async {
    emit(MarketplaceLoading());

    final result = await getCatalogUseCase(category: category, province: province, groupId: groupId);

    result.fold(
      (error) => emit(MarketplaceError(message: error)),
      (listings) => emit(MarketplaceLoaded(listings: listings)),
    );
  }
}
