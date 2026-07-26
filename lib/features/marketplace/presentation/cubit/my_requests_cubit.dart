import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/usecases/listing_usecases.dart';
import '../../domain/usecases/request_usecases.dart';
import 'my_requests_state.dart';

class MyRequestsCubit extends Cubit<MyRequestsState> {
  final GetRequestsUseCase getRequestsUseCase;
  final CancelRequestUseCase cancelRequestUseCase;
  final GetListingDetailUseCase getListingDetailUseCase;
  final SharedPreferences prefs;

  MyRequestsCubit({
    required this.getRequestsUseCase,
    required this.cancelRequestUseCase,
    required this.getListingDetailUseCase,
    required this.prefs,
  }) : super(const MyRequestsState());

  Future<void> load() async {
    final userId = prefs.getString(AppConstants.keyUserId);
    if (userId == null || userId.isEmpty) {
      emit(const MyRequestsState(error: 'Không xác định được người dùng.'));
      return;
    }
    emit(MyRequestsState(requests: state.requests, isLoading: true));
    final result = await getRequestsUseCase(receiverId: userId, limit: 100);
    await result.fold((error) async => emit(MyRequestsState(error: error)), (
      page,
    ) async {
      final titles = <String, String>{};
      for (final listingId in page.items.map((e) => e.listingId).toSet()) {
        final listing = await getListingDetailUseCase(listingId);
        listing.fold((_) {}, (value) => titles[listingId] = value.title);
      }
      if (!isClosed) {
        emit(MyRequestsState(requests: page.items, listingTitles: titles));
      }
    });
  }

  Future<void> cancel(String id) async {
    if (state.processingId != null) return;
    emit(
      MyRequestsState(
        requests: state.requests,
        listingTitles: state.listingTitles,
        processingId: id,
      ),
    );
    final result = await cancelRequestUseCase(id);
    await result.fold(
      (error) async => emit(
        MyRequestsState(
          requests: state.requests,
          listingTitles: state.listingTitles,
          error: error,
        ),
      ),
      (_) async => load(),
    );
  }
}
