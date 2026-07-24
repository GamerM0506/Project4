import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/media_service.dart';
import '../../../donation/domain/usecases/donation_usecases.dart';
import '../../../donation/data/models/donation_model.dart';
import '../../../group/data/models/group_model.dart';
import '../../../group/domain/usecases/get_my_groups_usecase.dart';
import '../../domain/usecases/listing_usecases.dart';
import 'create_listing_state.dart';

class CreateListingCubit extends Cubit<CreateListingState> {
  final CreateListingUseCase createListingUseCase;
  final CreateDonationUseCase? createDonationUseCase;
  final GetInventoryUseCase? getInventoryUseCase;
  final AcceptDonationUseCase? acceptDonationUseCase;
  final GetDonationCategoriesUseCase getDonationCategoriesUseCase;
  final GetMyGroupsUseCase getMyGroupsUseCase;
  final MediaService mediaService;
  final SharedPreferences? prefs;

  CreateListingCubit({
    required this.createListingUseCase,
    this.createDonationUseCase,
    this.getInventoryUseCase,
    this.acceptDonationUseCase,
    required this.getDonationCategoriesUseCase,
    required this.getMyGroupsUseCase,
    required this.mediaService,
    this.prefs,
  }) : super(CreateListingInitial());

  List<InventoryItemModel> inventoryItems = [];
  List<GroupModel> groups = [];
  List<DonationCategoryModel> categories = [];

  Future<void> loadForm({String? preferredGroupId}) async {
    emit(CreateListingLoading());
    final results = await Future.wait([
      getMyGroupsUseCase(memberStatus: 'approved', limit: 100),
      getDonationCategoriesUseCase(),
    ]);

    String? error;
    results[0].fold(
      (value) => error = value,
      (value) => groups = value as List<GroupModel>,
    );
    results[1].fold(
      (value) => error ??= value,
      (value) => categories = value as List<DonationCategoryModel>,
    );
    if (error != null) {
      emit(CreateListingError(message: error!));
      return;
    }

    final selectedGroupId = groups.any((group) => group.id == preferredGroupId)
        ? preferredGroupId
        : null;
    emit(
      CreateListingFormReady(
        groups: groups,
        categories: categories,
        selectedGroupId: selectedGroupId,
      ),
    );
  }

  Future<void> loadInventory(String groupId) async {
    if (getInventoryUseCase == null || groupId.isEmpty) return;
    final result = await getInventoryUseCase!(
      groupId: groupId,
      status: 'in_stock',
      limit: 50,
    );
    result.fold((_) {}, (items) {
      inventoryItems = items;
    });
  }

  /// Donor path: POST /api/donation/donations
  Future<void> createDonation({
    required String groupId,
    required String title,
    required String description,
    required String condition,
    required int quantity,
    String? categoryId,
    Uint8List? imageBytes,
    String? imageMimeType,
  }) async {
    if (createDonationUseCase == null) {
      emit(const CreateListingError(message: 'Donation service chưa cấu hình'));
      return;
    }

    if (!_isUuid(groupId)) {
      emit(
        const CreateListingError(
          message: 'Group ID phải là UUID hợp lệ (mở form từ nhóm)',
        ),
      );
      return;
    }

    emit(CreateListingLoading());

    String? imageUrl;
    if (imageBytes != null && imageBytes.isNotEmpty) {
      try {
        imageUrl = await mediaService.uploadImage(
          imageBytes,
          imageMimeType ?? 'image/jpeg',
          refType: 'donation',
        );
      } catch (error) {
        emit(
          CreateListingError(
            message: error.toString().replaceFirst('Exception: ', ''),
          ),
        );
        return;
      }
    }

    final item = <String, dynamic>{
      'name': title,
      'quantity': quantity < 1 ? 1 : quantity,
      'condition_declared': _mapCondition(condition),
      'images': [
        if (imageUrl != null) {'image_url': imageUrl, 'type': 'declared'},
      ],
    };
    if (categoryId != null && _isUuid(categoryId)) {
      item['category_id'] = categoryId;
    }

    final result = await createDonationUseCase!(
      groupId: groupId,
      title: title,
      description: description.isEmpty ? null : description,
      items: [item],
    );

    result.fold(
      (error) => emit(CreateListingError(message: error)),
      (_) => emit(CreateListingSuccess()),
    );
  }

  /// Moderator path: POST /api/marketplace/listings with real inventory UUID
  Future<void> createListing({
    required String inventoryItemId,
    required String groupId,
    required String title,
    required String description,
    required String categoryId,
    required String condition,
    required int quantityTotal,
    String? createdBy,
  }) async {
    if (!_isUuid(inventoryItemId)) {
      emit(
        const CreateListingError(
          message:
              'Cần chọn vật phẩm kho (inventory UUID). '
              'Nếu chưa có trong kho, hãy tạo đơn quyên góp trước.',
        ),
      );
      return;
    }
    if (!_isUuid(groupId)) {
      emit(const CreateListingError(message: 'Group ID phải là UUID hợp lệ'));
      return;
    }

    emit(CreateListingLoading());

    final userId = createdBy ?? prefs?.getString(AppConstants.keyUserId) ?? '';

    final result = await createListingUseCase(
      inventoryItemId,
      groupId,
      title,
      description,
      _isUuid(categoryId) ? categoryId : '',
      _mapCondition(condition),
      quantityTotal,
      userId,
      imageUrls: const [],
    );

    result.fold(
      (error) => emit(CreateListingError(message: error)),
      (_) => emit(CreateListingSuccess()),
    );
  }

  bool _isUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }

  String _mapCondition(String raw) {
    final v = raw.toLowerCase().trim().replaceAll(' ', '_');
    const allowed = {'new', 'like_new', 'good', 'used', 'worn'};
    if (allowed.contains(v)) return v;
    switch (raw.toLowerCase()) {
      case 'excellent':
      case 'like new':
        return 'like_new';
      case 'fair':
        return 'used';
      default:
        return 'used';
    }
  }
}
