import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/request_entity.dart';
import '../../domain/usecases/request_usecases.dart';

class MyRequestsState {
  final bool isLoading;
  final List<RequestEntity> requests;
  final String? error;

  const MyRequestsState({
    this.isLoading = false,
    this.requests = const [],
    this.error,
  });

  MyRequestsState copyWith({
    bool? isLoading,
    List<RequestEntity>? requests,
    String? error,
  }) {
    return MyRequestsState(
      isLoading: isLoading ?? this.isLoading,
      requests: requests ?? this.requests,
      error: error,
    );
  }
}

class MyRequestsCubit extends Cubit<MyRequestsState> {
  final GetRequestsUseCase getRequestsUseCase;
  final SharedPreferences prefs;

  MyRequestsCubit({
    required this.getRequestsUseCase,
    required this.prefs,
  }) : super(const MyRequestsState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, error: null));
    final receiverId = prefs.getString(AppConstants.keyUserId);
    final result = await getRequestsUseCase(receiverId: receiverId);

    result.fold(
      (err) => emit(state.copyWith(isLoading: false, error: err)),
      (items) => emit(state.copyWith(isLoading: false, requests: items)),
    );
  }
}
