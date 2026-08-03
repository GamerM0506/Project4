/// Design tokens dùng chung cho toàn bộ giao diện.
///
/// Trước đây mỗi màn tự đặt số: khảo sát cho thấy 18 giá trị bo góc khác nhau
/// và hàng trăm `EdgeInsets` rời rạc, nên cùng một thẻ card lại có 4 kiểu bo
/// góc ở 4 trang. Gom về đây để chỉnh một chỗ là cả app đổi theo.
///
/// Thang chính là bội số của 4, bám theo giá trị đã phổ biến sẵn trong dự án
/// (8 · 12 · 16 · 24) thay vì áp một thang mới.
library;

import 'package:flutter/widgets.dart';

/// Khoảng cách: lề, padding, giãn cách giữa các phần tử.
abstract final class AppSpacing {
  /// 2 — sát nhau, dùng cho hai dòng chữ liền kề.
  static const double xxs = 2;

  /// 4 — giữa nhãn và giá trị.
  static const double xs = 4;

  /// 8 — giữa các phần tử cùng nhóm.
  static const double sm = 8;

  /// 12 — giữa các dòng trong một thẻ.
  static const double md = 12;

  /// 16 — lề chuẩn của màn hình và padding trong thẻ.
  static const double lg = 16;

  /// 24 — giữa hai nhóm nội dung.
  static const double xl = 24;

  /// 32 — giữa hai khối lớn.
  static const double xxl = 32;

  /// 48 — khoảng trống lớn, thường ở trạng thái rỗng.
  static const double xxxl = 48;

  /// Lề ngang chuẩn của mọi màn hình.
  static const EdgeInsets screenH = EdgeInsets.symmetric(horizontal: lg);

  /// Padding chuẩn bên trong một thẻ.
  static const EdgeInsets card = EdgeInsets.all(lg);

  /// Padding danh sách: chừa đáy để nội dung cuối không bị nút che.
  static const EdgeInsets list = EdgeInsets.fromLTRB(lg, md, lg, xxxl);

  /// Padding cho bottom sheet, đã trừ phần tay cầm phía trên.
  static const EdgeInsets sheet = EdgeInsets.fromLTRB(xl, lg, xl, xl);

  /// Khoảng đệm đáy cho màn có thanh hành động cố định.
  static const double bottomBarInset = 120;
}

/// Bo góc. Ba mức là đủ; dùng [pill] cho thanh tiến độ và chip tròn.
abstract final class AppRadius {
  /// 8 — chip, badge, ô nhập nhỏ.
  static const double sm = 8;

  /// 12 — nút, ô nhập, phần tử trong thẻ.
  static const double md = 12;

  /// 16 — thẻ, hộp thoại, ảnh xem trước.
  static const double lg = 16;

  /// 24 — bottom sheet, thẻ nổi bật, khối hero.
  static const double xl = 24;

  /// Bo tròn hoàn toàn.
  static const double pill = 999;

  static const BorderRadius brSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius brMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius brLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius brXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius brPill = BorderRadius.all(Radius.circular(pill));

  /// Bo góc trên cho bottom sheet.
  static const BorderRadius sheetTop = BorderRadius.vertical(
    top: Radius.circular(xl),
  );
}

/// Thời lượng hoạt ảnh. Giữ ngắn để thao tác không bị cảm giác chậm.
abstract final class AppDurations {
  /// 150ms — đổi trạng thái nút, chip.
  static const Duration fast = Duration(milliseconds: 150);

  /// 250ms — mở rộng/thu gọn, chuyển tab.
  static const Duration normal = Duration(milliseconds: 250);

  /// 400ms — chuyển trang, hiệu ứng lớn.
  static const Duration slow = Duration(milliseconds: 400);
}

/// Kích thước cố định hay lặp lại.
abstract final class AppSizes {
  /// Chiều cao nút chính.
  static const double buttonHeight = 52;

  /// Chiều cao nút phụ, nút trong thẻ.
  static const double buttonHeightCompact = 40;

  /// Cạnh của ô ảnh xem trước trong dải ảnh ngang.
  static const double thumb = 96;

  /// Cỡ icon đi kèm chữ.
  static const double iconSm = 16;

  /// Cỡ icon tiêu chuẩn.
  static const double iconMd = 20;

  /// Độ dày thanh tiến độ.
  static const double progressBar = 8;
}
