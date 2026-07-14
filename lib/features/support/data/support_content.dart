import 'package:flutter/material.dart';

import '../domain/entities/faq_entity.dart';
import '../domain/entities/support_resource_entity.dart';

class SupportContent {
  SupportContent._();

  static const List<FaqEntity> faqs = [
    FaqEntity(
      question: 'ChoSV là gì?',
      answer:
          'ChoSV là nền tảng kết nối cộng đồng, giúp bạn cho tặng vật phẩm còn sử dụng tốt, '
          'tìm kiếm đồ miễn phí và tham gia các hội nhóm thiện nguyện gần bạn.',
    ),
    FaqEntity(
      question: 'Làm sao để đăng vật phẩm cho tặng?',
      answer:
          'Nhấn nút "+" ở thanh điều hướng dưới cùng, điền tên, mô tả, hình ảnh và địa điểm nhận. '
          'Sau khi đăng, vật phẩm sẽ hiển thị trên Gian hàng để người khác xem và liên hệ.',
    ),
    FaqEntity(
      question: 'Làm sao để nhận vật phẩm miễn phí?',
      answer:
          'Vào Gian hàng hoặc Trang chủ để xem danh sách vật phẩm. Nhấn vào vật phẩm bạn quan tâm, '
          'sau đó nhắn tin trực tiếp với người cho để thỏa thuận thời gian và địa điểm nhận.',
    ),
    FaqEntity(
      question: 'Tôi quên mật khẩu, phải làm gì?',
      answer:
          'Tại màn hình Đăng nhập, chọn "Quên mật khẩu", nhập email đã đăng ký '
          'và làm theo hướng dẫn xác thực OTP để đặt lại mật khẩu mới.',
    ),
    FaqEntity(
      question: 'Làm sao để tham gia hội nhóm?',
      answer:
          'Vào tab Hội nhóm, duyệt danh sách các nhóm thiện nguyện và nhấn "Tham gia". '
          'Bạn cũng có thể lưu nhóm yêu thích từ Trang chủ để xem lại sau.',
    ),
    FaqEntity(
      question: 'Tôi gặp vấn đề với giao dịch, cần báo cáo ai?',
      answer:
          'Nếu gặp hành vi lừa đảo, spam hoặc nội dung không phù hợp, hãy dùng mục "Gửi yêu cầu hỗ trợ" '
          'bên dưới hoặc gửi email đến đội hỗ trợ. Chúng tôi sẽ xử lý trong vòng 24–48 giờ.',
    ),
  ];

  static const List<SupportResourceEntity> resources = [
    SupportResourceEntity(
      icon: Icons.description_outlined,
      title: 'Điều khoản sử dụng',
    ),
    SupportResourceEntity(
      icon: Icons.privacy_tip_outlined,
      title: 'Chính sách bảo mật',
    ),
    SupportResourceEntity(
      icon: Icons.groups_outlined,
      title: 'Quy tắc cộng đồng',
    ),
  ];
}
