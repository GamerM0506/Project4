/// Nhãn tiếng Việt dùng chung cho luồng quyên góp.
///
/// Trước đây mỗi trang tự khai báo một bản `_statusLabel` / `_conditionLabel`
/// riêng và chúng đã lệch nhau ("Đã sử dụng" vs "Đã qua sử dụng"). Gộp về một
/// nơi để trang donor và trang moderator luôn nói cùng một ngôn ngữ.
library;

/// Trạng thái đợt quyên góp (`campaigns.status`).
String campaignStatusLabel(String status) => switch (status) {
  'active' => 'Đang mở',
  'fulfilled' => 'Đã trao tặng',
  'closed' => 'Đã đóng',
  'cancelled' => 'Đã hủy',
  _ => status,
};

/// Trạng thái đơn đóng góp (`contributions.status`).
String contributionStatusLabel(String status) => switch (status) {
  'pending' => 'Chờ duyệt',
  'accepted' => 'Đã duyệt',
  'received' => 'Đang kiểm tra',
  'completed' => 'Hoàn tất',
  'rejected' => 'Từ chối',
  'cancelled' => 'Đã hủy',
  _ => status,
};

/// Trạng thái từng vật phẩm trong đơn (`contribution_items.status`).
String contributionItemStatusLabel(String status) => switch (status) {
  'pending' => 'Chờ kiểm tra',
  'accepted' => 'Đạt',
  'rejected' => 'Không đạt',
  _ => status,
};

/// Cách bàn giao (`contributions.pickup_method`).
String pickupMethodLabel(String method) => switch (method) {
  'pickup' => 'Hội nhóm đến nhận',
  'drop_off' => 'Tự mang đến',
  _ => method,
};

/// Đơn đóng góp còn hủy được không.
///
/// Backend chỉ cho hủy khi chưa chốt kết quả; `completed` / `rejected` /
/// `cancelled` là trạng thái cuối.
bool canCancelContribution(String status) =>
    const {'pending', 'accepted', 'received'}.contains(status);

/// Moderator còn kiểm tra được từng món khi đơn ở các trạng thái này.
bool canCheckItems(String contributionStatus) =>
    const {'accepted', 'received'}.contains(contributionStatus);
