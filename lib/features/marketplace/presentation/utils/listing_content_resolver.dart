import '../../../../injection_container.dart';
import '../../../donation/data/models/donation_model.dart';
import '../../../donation/domain/usecases/donation_usecases.dart';
import '../../domain/entities/listing_entity.dart';

class ListingContent {
  final String? imageUrl;
  final String description;

  const ListingContent({this.imageUrl, required this.description});
}

class ListingContentResolver {
  static final Map<String, Future<ListingContent>> _cache = {};

  static Future<ListingContent> resolve(ListingEntity listing) {
    return _cache.putIfAbsent(listing.id, () => _resolve(listing));
  }

  static Future<ListingContent> _resolve(ListingEntity listing) async {
    var imageUrl = _clean(listing.imageUrl);
    var description = listing.description.trim();
    if (imageUrl != null && description.isNotEmpty) {
      return ListingContent(imageUrl: imageUrl, description: description);
    }

    final inventoryResult = await sl<GetInventoryItemUseCase>()(
      listing.inventoryItemId,
    );
    InventoryItemModel? inventory;
    inventoryResult.fold((_) {}, (value) => inventory = value);

    final donationItemId = inventory?.donationItemId;
    if (donationItemId != null && donationItemId.isNotEmpty) {
      final donationsResult = await sl<GetDonationsUseCase>()(
        groupId: listing.groupId,
        limit: 100,
      );
      donationsResult.fold((_) {}, (donations) {
        for (final donation in donations) {
          for (final item in donation.items) {
            if (item.id != donationItemId) continue;
            for (final image in item.images) {
              imageUrl ??= _clean(image.imageUrl);
              if (imageUrl != null) break;
            }
            if (description.isEmpty) {
              description = donation.description?.trim().isNotEmpty == true
                  ? donation.description!.trim()
                  : 'Vật phẩm ${item.name} được trao tặng qua ${donation.title}.';
            }
            return;
          }
        }
      });
    }

    if (description.isEmpty && inventory?.note?.trim().isNotEmpty == true) {
      description = inventory!.note!.trim();
    }
    return ListingContent(imageUrl: imageUrl, description: description);
  }

  static String? _clean(String? value) {
    final result = value?.trim();
    return result == null || result.isEmpty ? null : result;
  }
}
