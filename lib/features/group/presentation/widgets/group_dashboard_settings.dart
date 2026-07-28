import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../injection_container.dart';
import '../cubit/update_group_cubit.dart';
import '../cubit/group_detail_cubit.dart';
import '../../data/models/group_model.dart';
import '../../../../core/widgets/image_picker_widget.dart';
import '../../../../core/network/location_service.dart';

class GroupDashboardSettings extends StatefulWidget {
  final GroupModel group;

  const GroupDashboardSettings({super.key, required this.group});

  @override
  State<GroupDashboardSettings> createState() => _GroupDashboardSettingsState();
}

class _GroupDashboardSettingsState extends State<GroupDashboardSettings> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _addressController;

  final LocationService _locationService = LocationService();
  List<dynamic> _provinces = [];
  List<dynamic> _districts = [];

  String? _selectedProvinceId;
  String? _selectedDistrictId;
  bool _isLoadingProvinces = true;
  late bool _allowMemberPost;
  late bool _requirePostReview;

  String? _avatarUrl;
  String? _coverUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group.name);
    _descriptionController = TextEditingController(
      text: widget.group.description,
    );
    _addressController = TextEditingController(text: widget.group.address);
    _selectedProvinceId = widget.group.provinceCode;
    _selectedDistrictId = widget.group.districtCode;

    _avatarUrl = widget.group.avatarUrl;
    _coverUrl = widget.group.coverUrl;
    _allowMemberPost = widget.group.allowMemberPost;
    _requirePostReview = widget.group.requirePostReview;

    _loadProvinces();
  }

  Future<void> _loadProvinces() async {
    try {
      final data = await _locationService.getProvinces();
      if (!mounted) return;
      setState(() {
        _provinces = data;
        _isLoadingProvinces = false;
      });

      if (_selectedProvinceId != null) {
        Map<String, dynamic>? province;
        for (final p in _provinces) {
          if (p is Map && p['code']?.toString() == _selectedProvinceId) {
            province = Map<String, dynamic>.from(p);
            break;
          }
        }
        if (province != null && province['districts'] != null) {
          final districtsList = province['districts'] as List<dynamic>;
          setState(() {
            _districts = districtsList;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingProvinces = false;
        });
      }
    }
  }

  void _onProvinceChanged(String? provinceCode) {
    if (provinceCode == null) return;

    setState(() {
      _selectedProvinceId = provinceCode;
      _selectedDistrictId = null;
      _districts = [];
    });

    final province = _provinces.firstWhere(
      (p) => p['code'].toString() == provinceCode,
      orElse: () => null,
    );

    if (province != null && province['districts'] != null) {
      setState(() {
        _districts = province['districts'] as List<dynamic>;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
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
      provinceCode: _selectedProvinceId,
      districtCode: _selectedDistrictId,
      address: _addressController.text.trim(),
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
      child: BlocConsumer<UpdateGroupCubit, UpdateGroupState>(
        listener: (context, state) {
          if (state is UpdateGroupSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            context.read<GroupDetailCubit>().fetchGroupDetail(widget.group.id);
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ---- Thông tin cơ bản ----
                Text('Thông tin cơ bản', style: textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên nhóm',
                    prefixIcon: Icon(Icons.groups_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả chi tiết',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedProvinceId,
                        items: _provinces
                            .map(
                              (p) => DropdownMenuItem<String>(
                                value: p['code'].toString(),
                                child: Text(
                                  p['name']?.toString() ?? '',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: _onProvinceChanged,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Tỉnh / Thành phố',
                          prefixIcon: _isLoadingProvinces
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.location_on_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedDistrictId,
                        items: _districts
                            .map(
                              (d) => DropdownMenuItem<String>(
                                value: d['code'].toString(),
                                child: Text(
                                  d['name']?.toString() ?? '',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() => _selectedDistrictId = val);
                        },
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Quận / Huyện',
                          prefixIcon: Icon(Icons.map_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ cụ thể',
                    hintText: 'Tòa nhà, số nhà, đường...',
                    prefixIcon: Icon(Icons.home_outlined),
                  ),
                ),
                const SizedBox(height: 28),

                // ---- Quyền đăng bài ----
                Text('Quyền đăng bài', style: textTheme.titleMedium),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: Icon(
                          Icons.edit_note_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        title: const Text('Thành viên được đăng bài'),
                        subtitle: const Text(
                          'Cho phép thành viên tạo bài viết trong nhóm',
                        ),
                        value: _allowMemberPost,
                        onChanged: (value) =>
                            setState(() => _allowMemberPost = value),
                      ),
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: colorScheme.outlineVariant,
                      ),
                      SwitchListTile(
                        secondary: Icon(
                          Icons.fact_check_outlined,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        title: const Text('Kiểm duyệt bài viết'),
                        subtitle: const Text(
                          'Bài viết cần được duyệt trước khi hiển thị',
                        ),
                        value: _requirePostReview,
                        onChanged: (value) =>
                            setState(() => _requirePostReview = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ---- Hình ảnh ----
                Text('Hình ảnh hiển thị', style: textTheme.titleMedium),
                const SizedBox(height: 16),
                Center(
                  child: ImagePickerWidget(
                    label: 'Ảnh biểu trưng',
                    isAvatar: true,
                    initialUrl: _avatarUrl,
                    onImageUploaded: (url) {
                      setState(() => _avatarUrl = url);
                    },
                  ),
                ),
                const SizedBox(height: 20),
                ImagePickerWidget(
                  label: 'Ảnh bìa',
                  initialUrl: _coverUrl,
                  onImageUploaded: (url) {
                    setState(() => _coverUrl = url);
                  },
                ),
                const SizedBox(height: 36),

                AppButton(
                  label: 'Lưu thay đổi',
                  icon: Icons.save_rounded,
                  loading: state is UpdateGroupLoading,
                  onPressed: () => _submit(context),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}
