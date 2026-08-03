/// Ảnh đính kèm một vật phẩm trong đơn đóng góp.
///
/// `type` phân biệt ảnh người quyên góp tự khai (`declared`) với ảnh hội nhóm
/// chụp lúc kiểm tra thực tế (`actual_check`) — đây là bằng chứng cho tính
/// minh bạch của hành trình món đồ.
class ContributionImageModel {
  const ContributionImageModel({required this.imageUrl, required this.type});

  final String imageUrl;
  final String type;

  bool get isDeclared => type == 'declared';
  bool get isActualCheck => type == 'actual_check';

  factory ContributionImageModel.fromJson(Map<String, dynamic> json) {
    return ContributionImageModel(
      imageUrl: json['image_url']?.toString() ?? '',
      type: json['type']?.toString() ?? 'declared',
    );
  }

  Map<String, dynamic> toJson() => {'image_url': imageUrl, 'type': type};

  static List<ContributionImageModel> listFrom(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (item) =>
              ContributionImageModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((image) => image.imageUrl.isNotEmpty)
        .toList();
  }
}

/// Một vật phẩm người dùng gửi kèm khi tạo đơn đóng góp.
///
/// Backend nhận `items` là danh sách nên một đơn có thể gồm nhiều món khác
/// nhau, mỗi món trỏ tới một `campaign_item_id` của đợt.
class ContributionItemInput {
  const ContributionItemInput({
    required this.campaignItemId,
    required this.name,
    required this.quantity,
    required this.conditionDeclared,
    this.imageUrls = const [],
  });

  final String campaignItemId;
  final String name;
  final int quantity;
  final String conditionDeclared;
  final List<String> imageUrls;

  Map<String, dynamic> toJson() => {
    'campaign_item_id': campaignItemId,
    'name': name.trim(),
    'quantity': quantity,
    'condition_declared': conditionDeclared,
    'images': imageUrls
        .map((url) => {'image_url': url, 'type': 'declared'})
        .toList(),
  };
}

class ContributionItemModel {
  const ContributionItemModel({
    required this.id,
    required this.campaignItemId,
    required this.name,
    required this.quantity,
    required this.conditionDeclared,
    required this.status,
    this.conditionActual,
    this.checkNote,
    this.rejectReason,
    this.checkedAt,
    this.images = const [],
  });

  final String id;
  final String campaignItemId;
  final String name;
  final int quantity;
  final String conditionDeclared;
  final String status;

  /// Tình trạng hội nhóm ghi nhận khi kiểm tra thực tế, có thể khác với khai báo.
  final String? conditionActual;
  final String? checkNote;
  final String? rejectReason;
  final DateTime? checkedAt;
  final List<ContributionImageModel> images;

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';

  /// Tình trạng thực tế lệch so với khai báo — moderator cần thấy rõ điều này.
  bool get conditionMismatch =>
      conditionActual != null &&
      conditionActual!.isNotEmpty &&
      conditionActual != conditionDeclared;

  List<ContributionImageModel> get declaredImages =>
      images.where((image) => image.isDeclared).toList();

  List<ContributionImageModel> get actualCheckImages =>
      images.where((image) => image.isActualCheck).toList();

  factory ContributionItemModel.fromJson(Map<String, dynamic> json) {
    return ContributionItemModel(
      id: json['id']?.toString() ?? '',
      campaignItemId: json['campaign_item_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      conditionDeclared: json['condition_declared']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      conditionActual: json['condition_actual']?.toString(),
      checkNote: json['check_note']?.toString(),
      rejectReason: json['reject_reason']?.toString(),
      checkedAt: DateTime.tryParse(json['checked_at']?.toString() ?? ''),
      images: ContributionImageModel.listFrom(json['images']),
    );
  }
}

class ContributionModel {
  const ContributionModel({
    required this.id,
    required this.code,
    required this.campaignId,
    required this.donorId,
    required this.status,
    required this.pickupMethod,
    required this.createdAt,
    required this.items,
    this.pickupAddress,
    this.rejectedReason,
    this.reviewedBy,
    this.reviewedAt,
    this.receivedAt,
  });

  final String id;
  final String code;
  final String campaignId;
  final String donorId;
  final String status;
  final String pickupMethod;
  final DateTime createdAt;
  final List<ContributionItemModel> items;
  final String? pickupAddress;
  final String? rejectedReason;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime? receivedAt;

  bool get isPending => status == 'pending';

  /// Còn món nào chưa kiểm tra không.
  bool get hasPendingItems => items.any((item) => item.isPending);

  int get acceptedItemCount => items.where((item) => item.isAccepted).length;
  int get rejectedItemCount => items.where((item) => item.isRejected).length;

  /// Tổng số lượng vật phẩm trong đơn (không phải số dòng).
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  factory ContributionModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return ContributionModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      campaignId: json['campaign_id']?.toString() ?? '',
      donorId: json['donor_id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      pickupMethod: json['pickup_method']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map(
                  (item) => ContributionItemModel.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
      pickupAddress: json['pickup_address']?.toString(),
      rejectedReason: json['rejected_reason']?.toString(),
      reviewedBy: json['reviewed_by']?.toString(),
      reviewedAt: DateTime.tryParse(json['reviewed_at']?.toString() ?? ''),
      receivedAt: DateTime.tryParse(json['received_at']?.toString() ?? ''),
    );
  }
}
