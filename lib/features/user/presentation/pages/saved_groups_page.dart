import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SavedGroupsPage extends StatelessWidget {
  const SavedGroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhóm đã lưu'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Tính năng lưu nhóm chưa được API hỗ trợ.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
