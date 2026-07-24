import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MyItemsPage extends StatelessWidget {
  const MyItemsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vật phẩm của tôi'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) {
          final items = [
            {'title': 'Áo khoác mùa đông', 'status': 'Đang tặng', 'date': '17/07/2026'},
            {'title': 'Sách giáo khoa Toán cao cấp', 'status': 'Đã tặng xong', 'date': '15/07/2026'},
            {'title': 'Bàn phím cơ', 'status': 'Đang tặng', 'date': '10/07/2026'},
          ];
          final item = items[index];
          final isGiven = item['status'] == 'Đã tặng xong';

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  color: colorScheme.surfaceContainerHighest,
                  child: Icon(Icons.image, color: colorScheme.onSurfaceVariant),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title']!,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text('Đăng ngày: ${item['date']}', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isGiven ? colorScheme.surfaceContainerHighest : colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item['status']!,
                            style: TextStyle(
                              color: isGiven ? colorScheme.onSurfaceVariant : colorScheme.onPrimaryContainer,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
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
