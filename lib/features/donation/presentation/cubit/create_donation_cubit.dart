import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/donation_usecases.dart';

class CreateDonationState {
  final bool isSubmitting;
  final String? error;
  final bool success;

  const CreateDonationState({
    this.isSubmitting = false,
    this.error,
    this.success = false,
  });
}

class CreateDonationCubit extends Cubit<CreateDonationState> {
  final CreateDonationUseCase createDonationUseCase;

  CreateDonationCubit({required this.createDonationUseCase})
      : super(const CreateDonationState());

  Future<void> submit({
    required String groupId,
    required String title,
    String? description,
    String pickupMethod = 'drop_off',
    String? pickupAddress,
    required String itemName,
    required int quantity,
    required String condition,
    List<String> imageUrls = const [],
  }) async {
    if (groupId.isEmpty || title.trim().isEmpty || itemName.trim().isEmpty) {
      emit(const CreateDonationState(
          error: 'Vui lòng nhập đủ nhóm, tiêu đề và tên món đồ.'));
      return;
    }

    emit(const CreateDonationState(isSubmitting: true));

    final items = [
      {
        'name': itemName.trim(),
        'quantity': quantity < 1 ? 1 : quantity,
        'condition_declared': condition,
        'images': imageUrls
            .map((u) => {'image_url': u, 'type': 'declared'})
            .toList(),
      },
    ];

    final result = await createDonationUseCase(
      groupId: groupId,
      title: title.trim(),
      description: description,
      pickupMethod: pickupMethod,
      pickupAddress: pickupAddress,
      items: items,
    );

    result.fold(
      (err) => emit(CreateDonationState(error: err)),
      (_) => emit(const CreateDonationState(success: true)),
    );
  }
}
