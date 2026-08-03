/// Một vật phẩm cần nhận khi tạo đợt quyên góp.
///
/// Backend nhận `items` là danh sách (tối thiểu 1, không giới hạn trên), nên
/// một đợt có thể kêu gọi nhiều loại vật phẩm khác nhau.
class CampaignItemInput {
  const CampaignItemInput({
    required this.name,
    required this.targetQuantity,
    this.unit,
    this.categoryId,
    this.conditionRequired,
    this.note,
  });

  final String name;
  final int targetQuantity;
  final String? unit;
  final String? categoryId;

  /// Tình trạng tối thiểu chấp nhận: new | like_new | good | used | worn.
  final String? conditionRequired;
  final String? note;

  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'target_quantity': targetQuantity,
    if (unit?.trim().isNotEmpty == true) 'unit': unit!.trim(),
    if (categoryId?.trim().isNotEmpty == true) 'category_id': categoryId!.trim(),
    if (conditionRequired?.trim().isNotEmpty == true)
      'condition_required': conditionRequired!.trim(),
    if (note?.trim().isNotEmpty == true) 'note': note!.trim(),
  };
}

/// Nhãn tiếng Việt cho `condition_required` / `condition_declared`.
const kItemConditions = <({String value, String label})>[
  (value: 'new', label: 'Mới'),
  (value: 'like_new', label: 'Như mới'),
  (value: 'good', label: 'Còn tốt'),
  (value: 'used', label: 'Đã qua sử dụng'),
  (value: 'worn', label: 'Cũ, còn dùng được'),
];

String itemConditionLabel(String? value) {
  if (value == null || value.trim().isEmpty) return 'Không yêu cầu';
  for (final c in kItemConditions) {
    if (c.value == value) return c.label;
  }
  return value;
}
