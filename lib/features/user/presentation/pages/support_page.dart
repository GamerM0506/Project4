import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final List<Map<String, String>> faqs = [
      {
        'question': 'Làm thế nào để đăng tin tặng đồ?',
        'answer': 'Bạn có thể vào mục "Gian hàng", nhấn nút (+) ở góc dưới bên phải, sau đó điền thông tin (hình ảnh, tên món đồ, số lượng, tình trạng) và chọn "Gửi" để hoàn tất đăng tin.'
      },
      {
        'question': 'Tôi muốn xin đồ thì phải làm sao?',
        'answer': 'Tại mục "Gian hàng", chọn món đồ bạn muốn xin, nhấn vào nút "Nhận món này" và điền lý do xin. Người đăng sẽ xem xét và phê duyệt yêu cầu của bạn.'
      },
      {
        'question': 'Làm sao để tham gia vào một Hội nhóm (Group)?',
        'answer': 'Bạn vào mục "Hội nhóm", tìm kiếm nhóm bạn quan tâm và nhấn "Tham gia". Một số nhóm sẽ yêu cầu quản trị viên phê duyệt trước khi bạn trở thành thành viên chính thức.'
      },
      {
        'question': 'Tại sao tài khoản của tôi bị khóa?',
        'answer': 'Tài khoản có thể bị khóa nếu vi phạm các tiêu chuẩn cộng đồng (spam, lừa đảo, đăng nội dung phản cảm). Bạn vui lòng liên hệ trực tiếp với admin qua email admin@chosv.com để được hỗ trợ.'
      },
      {
        'question': 'Tôi có thể đổi thông tin cá nhân ở đâu?',
        'answer': 'Vào mục "Cá nhân", chọn "Cài đặt tài khoản" -> "Chỉnh sửa thông tin cá nhân" để cập nhật họ tên, avatar và thông tin liên hệ.'
      },
    ];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.primary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Trợ giúp & Hỗ trợ',
          style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: faqs.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final faq = faqs[index];
          return Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.surfaceContainerHighest),
            ),
            child: ExpansionTile(
              title: Text(
                faq['question']!,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              expandedAlignment: Alignment.centerLeft,
              children: [
                Text(
                  faq['answer']!,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
