import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SavedGroupsPage extends StatelessWidget {
  const SavedGroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhóm đã lưu'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(8),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.groups, color: colorScheme.onPrimaryContainer),
              ),
              title: Text(
                'Nhóm từ thiện sinh viên ${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${1200 + index * 50} thành viên'),
              trailing: IconButton(
                icon: Icon(Icons.bookmark, color: colorScheme.primary),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã bỏ lưu nhóm này')),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
