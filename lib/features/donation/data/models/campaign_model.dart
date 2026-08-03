class CampaignItemModel {
  const CampaignItemModel({
    required this.id,
    required this.name,
    required this.targetQuantity,
    required this.receivedQuantity,
    this.unit,
    this.conditionRequired,
    this.note,
    this.categoryId,
  });

  final String id;
  final String name;
  final int targetQuantity;
  final int receivedQuantity;
  final String? unit;
  final String? conditionRequired;
  final String? note;
  final String? categoryId;

  int get remaining =>
      (targetQuantity - receivedQuantity).clamp(0, targetQuantity);
  double get progress =>
      targetQuantity == 0 ? 0 : (receivedQuantity / targetQuantity).clamp(0, 1);

  factory CampaignItemModel.fromJson(Map<String, dynamic> json) {
    return CampaignItemModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      targetQuantity: (json['target_quantity'] as num?)?.toInt() ?? 0,
      receivedQuantity: (json['received_quantity'] as num?)?.toInt() ?? 0,
      unit: json['unit']?.toString(),
      conditionRequired: json['condition_required']?.toString(),
      note: json['note']?.toString(),
      categoryId: json['category_id']?.toString(),
    );
  }
}

class CampaignModel {
  const CampaignModel({
    required this.id,
    required this.code,
    required this.groupId,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.items,
    this.description,
    this.beneficiaryDescription,
    this.provinceCode,
    this.districtCode,
    this.deadline,
    this.fulfilledAt,
    this.closedAt,
  });

  final String id;
  final String code;
  final String groupId;
  final String title;
  final String status;
  final DateTime createdAt;
  final List<CampaignItemModel> items;
  final String? description;
  final String? beneficiaryDescription;
  final String? provinceCode;
  final String? districtCode;
  final DateTime? deadline;
  final DateTime? fulfilledAt;
  final DateTime? closedAt;

  int get totalTarget =>
      items.fold(0, (sum, item) => sum + item.targetQuantity);
  int get totalReceived =>
      items.fold(0, (sum, item) => sum + item.receivedQuantity);
  double get progress =>
      totalTarget == 0 ? 0 : (totalReceived / totalTarget).clamp(0, 1);

  bool get isActive => status == 'active';

  /// Đợt đã chốt kết quả, không nhận thêm đóng góp.
  bool get isFinished => status == 'fulfilled' || status == 'cancelled';

  /// Số loại vật phẩm đã nhận đủ mục tiêu.
  int get fulfilledTargets => items.where((item) => item.remaining == 0).length;

  bool get isOverdue =>
      isActive && deadline != null && deadline!.isBefore(DateTime.now());

  factory CampaignModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return CampaignModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      groupId: json['group_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map(
                  (item) => CampaignItemModel.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
      description: json['description']?.toString(),
      beneficiaryDescription: json['beneficiary_description']?.toString(),
      provinceCode: json['province_code']?.toString(),
      districtCode: json['district_code']?.toString(),
      deadline: DateTime.tryParse(json['deadline']?.toString() ?? ''),
      fulfilledAt: DateTime.tryParse(json['fulfilled_at']?.toString() ?? ''),
      closedAt: DateTime.tryParse(json['closed_at']?.toString() ?? ''),
    );
  }
}

/// Kết quả `GET /donation/campaigns/{id}/progress`.
///
/// Backend tính sẵn `remaining` và `fulfilled` cho từng mục tiêu nên donor thấy
/// đúng con số hội nhóm đang ghi nhận, không phải ước lượng phía client.
class CampaignProgressItem {
  const CampaignProgressItem({
    required this.id,
    required this.name,
    required this.targetQuantity,
    required this.receivedQuantity,
    required this.remaining,
    required this.fulfilled,
    this.unit,
  });

  final String id;
  final String name;
  final int targetQuantity;
  final int receivedQuantity;
  final int remaining;
  final bool fulfilled;
  final String? unit;

  double get progress => targetQuantity == 0
      ? 0
      : (receivedQuantity / targetQuantity).clamp(0, 1);

  factory CampaignProgressItem.fromJson(Map<String, dynamic> json) {
    final target = (json['target_quantity'] as num?)?.toInt() ?? 0;
    final received = (json['received_quantity'] as num?)?.toInt() ?? 0;
    return CampaignProgressItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      targetQuantity: target,
      receivedQuantity: received,
      // Chỉ tự tính khi backend không trả, tránh lệch với số liệu máy chủ.
      remaining:
          (json['remaining'] as num?)?.toInt() ??
          (target - received).clamp(0, target),
      fulfilled: json['fulfilled'] == true || (received >= target && target > 0),
      unit: json['unit']?.toString(),
    );
  }
}

class CampaignProgress {
  const CampaignProgress({
    required this.campaignId,
    required this.code,
    required this.title,
    required this.status,
    required this.totalTargets,
    required this.fulfilledTargets,
    required this.items,
  });

  final String campaignId;
  final String code;
  final String title;
  final String status;
  final int totalTargets;
  final int fulfilledTargets;
  final List<CampaignProgressItem> items;

  int get totalTarget =>
      items.fold(0, (sum, item) => sum + item.targetQuantity);
  int get totalReceived =>
      items.fold(0, (sum, item) => sum + item.receivedQuantity);
  double get progress =>
      totalTarget == 0 ? 0 : (totalReceived / totalTarget).clamp(0, 1);

  factory CampaignProgress.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map(
                (item) => CampaignProgressItem.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
        : <CampaignProgressItem>[];
    return CampaignProgress(
      campaignId: json['campaign_id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      totalTargets: (json['total_targets'] as num?)?.toInt() ?? items.length,
      fulfilledTargets:
          (json['fulfilled_targets'] as num?)?.toInt() ??
          items.where((item) => item.fulfilled).length,
      items: items,
    );
  }
}
