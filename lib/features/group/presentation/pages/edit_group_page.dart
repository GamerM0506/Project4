import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../injection_container.dart';
import '../cubit/update_group_cubit.dart';
import '../../data/models/group_model.dart';
import '../../../../core/widgets/image_picker_widget.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EditGroupPage extends StatefulWidget {
  final GroupModel group;

  const EditGroupPage({super.key, required this.group});

  @override
  State<EditGroupPage> createState() => _EditGroupPageState();
}

class _EditGroupPageState extends State<EditGroupPage> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _addressController;
  late TextEditingController _provinceCodeController;
  late TextEditingController _districtCodeController;
  String? _avatarUrl;
  String? _coverUrl;
  late bool _allowMemberPost;
  late bool _requirePostReview;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group.name);
    _descriptionController = TextEditingController(
      text: widget.group.description,
    );
    _addressController = TextEditingController(text: widget.group.address);
    _provinceCodeController = TextEditingController(
      text: widget.group.provinceCode,
    );
    _districtCodeController = TextEditingController(
      text: widget.group.districtCode,
    );
    _avatarUrl = widget.group.avatarUrl;
    _coverUrl = widget.group.coverUrl;
    _allowMemberPost = widget.group.allowMemberPost;
    _requirePostReview = widget.group.requirePostReview;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _provinceCodeController.dispose();
    _districtCodeController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tên nhóm không được để trống.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    context.read<UpdateGroupCubit>().updateGroup(
      widget.group.id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      avatarUrl: _avatarUrl,
      coverUrl: _coverUrl,
      address: _addressController.text.trim(),
      provinceCode: _provinceCodeController.text.trim(),
      districtCode: _districtCodeController.text.trim(),
      allowMemberPost: _allowMemberPost,
      requirePostReview: _requirePostReview,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocProvider(
      create: (_) => sl<UpdateGroupCubit>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chỉnh sửa hội nhóm'),
          centerTitle: true,
        ),
        body: BlocConsumer<UpdateGroupCubit, UpdateGroupState>(
          listener: (context, state) {
            if (state is UpdateGroupSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: colorScheme.secondary,
                ),
              );
              // Return updated group to previous screen
              context.pop(state.group);
            } else if (state is UpdateGroupError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: colorScheme.error,
                ),
              );
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children:
                    [
                          Text(
                            'Thông tin cơ bản',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Cập nhật tên và mô tả để mọi người dễ dàng nhận ra nhóm của bạn.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Name Field
                          _buildModernTextField(
                            controller: _nameController,
                            label: 'Tên nhóm',
                            icon: Icons.groups_outlined,
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                          ),
                          const SizedBox(height: 16),

                          // Description Field
                          _buildModernTextField(
                            controller: _descriptionController,
                            label: 'Mô tả chi tiết',
                            icon: Icons.description_outlined,
                            maxLines: 4,
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _addressController,
                            label: 'Địa chỉ',
                            icon: Icons.location_on_outlined,
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildModernTextField(
                                  controller: _provinceCodeController,
                                  label: 'Mã tỉnh/thành',
                                  icon: Icons.map_outlined,
                                  colorScheme: colorScheme,
                                  textTheme: textTheme,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildModernTextField(
                                  controller: _districtCodeController,
                                  label: 'Mã quận/huyện',
                                  icon: Icons.location_city_outlined,
                                  colorScheme: colorScheme,
                                  textTheme: textTheme,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Cho phép thành viên đăng bài'),
                            value: _allowMemberPost,
                            onChanged: (value) =>
                                setState(() => _allowMemberPost = value),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Yêu cầu duyệt bài đăng'),
                            value: _requirePostReview,
                            onChanged: (value) =>
                                setState(() => _requirePostReview = value),
                          ),
                          const SizedBox(height: 32),

                          Text(
                            'Hình ảnh hiển thị',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Avatar Picker
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ImagePickerWidget(
                                label: 'Ảnh biểu trưng',
                                isAvatar: true,
                                initialUrl: _avatarUrl,
                                onImageUploaded: (url) {
                                  setState(() {
                                    _avatarUrl = url;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Cover Picker
                          ImagePickerWidget(
                            label: 'Ảnh bìa',
                            initialUrl: _coverUrl,
                            onImageUploaded: (url) {
                              setState(() {
                                _coverUrl = url;
                              });
                            },
                          ),
                          const SizedBox(height: 48),

                          // Save Button
                          ElevatedButton(
                            onPressed: state is UpdateGroupLoading
                                ? null
                                : () => _submit(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 2,
                              shadowColor: colorScheme.primary.withValues(
                                alpha: 0.4,
                              ),
                            ),
                            child: state is UpdateGroupLoading
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: colorScheme.onPrimary,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'Lưu Thay Đổi',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ]
                        .animate(interval: 50.ms)
                        .fade(duration: 400.ms)
                        .slideY(begin: 0.1, curve: Curves.easeOutQuart),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
          ),
          prefixIcon: maxLines == 1
              ? Icon(
                  icon,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  size: 22,
                )
              : Padding(
                  padding: const EdgeInsets.only(
                    bottom: 60,
                  ), // Align top for multiline
                  child: Icon(
                    icon,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    size: 22,
                  ),
                ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colorScheme.secondary, width: 1.5),
          ),
        ),
      ),
    );
  }
}
