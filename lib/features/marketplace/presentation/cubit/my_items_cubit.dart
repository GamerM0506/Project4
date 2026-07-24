import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/listing_entity.dart';
import '../../domain/usecases/listing_usecases.dart';

class MyItemsState {
  final bool isLoading;
  final List<ListingEntity> items;
  final String? error;

  const MyItemsState({
    this.isLoading = false,
    this.items = const [],
    this.error,
  });

  MyItemsState copyWith({
    bool? isLoading,
    List<ListingEntity>? items,
    String? error,
  }) {
    return MyItemsState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      error: error,
    );
  }
}

class MyItemsCubit extends Cubit<MyItemsState> {
  final GetCatalogUseCase getCatalogUseCase;
  final GetListingsUseCase getListingsUseCase;

  MyItemsCubit({
    required this.getCatalogUseCase,
    required this.getListingsUseCase,
  }) : super(const MyItemsState());

  /// Shows active catalog items the user can browse as "related gifts".
  /// Prefer listings API; fall back to catalog if empty/error.
  Future<void> load() async {
    emit(state.copyWith(isLoading: true, error: null));

    final listings = await getListingsUseCase();
    await listings.fold(
      (err) async {
        final catalog = await getCatalogUseCase();
        catalog.fold(
          (cErr) => emit(state.copyWith(isLoading: false, error: cErr)),
          (items) => emit(state.copyWith(isLoading: false, items: items)),
        );
      },
      (items) async {
        if (items.isEmpty) {
          final catalog = await getCatalogUseCase();
          catalog.fold(
            (_) => emit(state.copyWith(isLoading: false, items: items)),
            (cItems) =>
                emit(state.copyWith(isLoading: false, items: cItems)),
          );
        } else {
          emit(state.copyWith(isLoading: false, items: items));
        }
      },
    );
  }
}
