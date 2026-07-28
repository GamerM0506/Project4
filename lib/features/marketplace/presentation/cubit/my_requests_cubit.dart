import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/media_service.dart';
import '../../domain/usecases/listing_usecases.dart';
import '../../domain/usecases/request_usecases.dart';
import 'my_requests_state.dart';

class MyRequestsCubit extends Cubit<MyRequestsState> {
  final GetRequestsUseCase getRequestsUseCase;
  final CancelRequestUseCase cancelRequestUseCase;
  final GetListingDetailUseCase getListingDetailUseCase;
  final SharedPreferences prefs;
  final AddReceiverConfirmationUseCase addReceiverConfirmationUseCase;
  final MediaService mediaService;

  MyRequestsCubit({
    required this.getRequestsUseCase,
    required this.cancelRequestUseCase,
    required this.getListingDetailUseCase,
    required this.prefs,
    required this.addReceiverConfirmationUseCase,
    required this.mediaService,
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

  Future<String?> confirmReceived(
    String requestId,
    Uint8List bytes,
    String mimeType,
    String note,
  ) async {
    if (state.processingId != null) return 'Đang xử lý...';
    emit(
      MyRequestsState(
        requests: state.requests,
        listingTitles: state.listingTitles,
        processingId: requestId,
      ),
    );
    try {
      final uploaded = await mediaService.uploadImageResult(
        bytes,
        mimeType,
        refType: 'delivery',
      );
      final result = await addReceiverConfirmationUseCase(
        requestId,
        uploaded.publicUrl,
        note,
      );
      return result.fold(
        (error) {
          emit(MyRequestsState(
            requests: state.requests,
            listingTitles: state.listingTitles,
            error: error,
          ));
          return error;
        },
        (_) {
          load();
          return null;
        },
      );
    } catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '');
      emit(MyRequestsState(
        requests: state.requests,
        listingTitles: state.listingTitles,
        error: message,
      ));
      return message;
    }
  }
}
