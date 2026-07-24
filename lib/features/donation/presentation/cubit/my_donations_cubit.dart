import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/donation_entity.dart';
import '../../domain/usecases/donation_usecases.dart';

class MyDonationsState {
  final bool isLoading;
  final List<DonationEntity> donations;
  final String? error;

  const MyDonationsState({
    this.isLoading = false,
    this.donations = const [],
    this.error,
  });
}

class MyDonationsCubit extends Cubit<MyDonationsState> {
  final GetDonationsUseCase getDonationsUseCase;

  MyDonationsCubit({required this.getDonationsUseCase})
      : super(const MyDonationsState());

  Future<void> load() async {
    emit(const MyDonationsState(isLoading: true));
    final result = await getDonationsUseCase(mine: true);
    result.fold(
      (err) => emit(MyDonationsState(error: err)),
      (items) => emit(MyDonationsState(donations: items)),
    );
  }
}
