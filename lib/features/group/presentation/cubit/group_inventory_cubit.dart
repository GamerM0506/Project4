import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../marketplace/domain/usecases/listing_usecases.dart';
import 'group_inventory_state.dart';

class GroupInventoryCubit extends Cubit<GroupInventoryState> {
  final GetCatalogUseCase getCatalogUseCase;

  GroupInventoryCubit({
    required this.getCatalogUseCase,
  }) : super(GroupInventoryInitial());

  Future<void> fetchInventory(String groupId) async {
    emit(GroupInventoryLoading());

    final result = await getCatalogUseCase(groupId: groupId);

    result.fold(
      (failure) => emit(GroupInventoryError(failure)),
      (items) => emit(GroupInventoryLoaded(items)),
    );
  }
}
