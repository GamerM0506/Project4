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

  /// Tạo một lần trong initState, không tạo trong build: mỗi setState (bật
  /// switch, đổi tỉnh, chọn ảnh) sẽ dựng lại cubit và làm mất state đang có,
  /// khiến kết quả lưu không bao giờ tới listener.
  late final UpdateGroupCubit _updateCubit;

  final LocationService _locationService = sl<LocationService>();
  List<Map<String, dynamic>> _provinces = [];
  List<Map<String, dynamic>> _districts = [];

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
    _updateCubit = sl<UpdateGroupCubit>();
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

  /// Đọc danh sách tỉnh và nạp sẵn quận/huyện của tỉnh đang chọn.
  Future<void> _loadProvinces() async {
    try {
      final data = await _locationService.getProvinces();
      if (!mounted) return;
      final provinces = _asMapList(data);
      setState(() {
        _provinces = provinces;
        _isLoadingProvinces = false;
        _districts = _districtsOf(_selectedProvinceId);
        // Mã quận cũ không còn thuộc tỉnh đang chọn thì bỏ, tránh
        // DropdownButton ném lỗi vì value không có trong items.
        if (!_districts.any(
          (d) => d['code']?.toString() == _selectedDistrictId,
        )) {
          _selectedDistrictId = null;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingProvinces = false);
    }
  }

  List<Map<String, dynamic>> _asMapList(List<dynamic> raw) => raw
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();

  /// Quận/huyện của một tỉnh; trả rỗng nếu không tìm thấy.
  List<Map<String, dynamic>> _districtsOf(String? provinceCode) {
    if (provinceCode == null || provinceCode.isEmpty) return const [];
    for (final province in _provinces) {
      if (province['code']?.toString() == provinceCode) {
        final districts = province['districts'];
        return districts is List ? _asMapList(districts) : const [];
      }
    }
    return const [];
  }

  void _onProvinceChanged(String? provinceCode) {
    if (provinceCode == null) return;
    setState(() {
      _selectedProvinceId = provinceCode;
      _selectedDistrictId = null;
      _districts = _districtsOf(provinceCode);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _updateCubit.close();
    super.dispose();
  }

  void _submit() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tên nhóm không được để trống.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    _updateCubit.updateGroup(
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

    return BlocProvider.value(
      value: _updateCubit,
      child: BlocConsumer<UpdateGroupCubit, UpdateGroupState>(
        bloc: _updateCubit,
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
                        initialValue: _provinces.any(
                              (p) =>
                                  p['code']?.toString() == _selectedProvinceId,
                            )
                            ? _selectedProvinceId
                            : null,
                        items: _provinces
                            .map(
                              (p) => DropdownMenuItem<String>(
                                value: p['code']?.toString() ?? '',
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
                        initialValue: _districts.any(
                              (d) =>
                                  d['code']?.toString() == _selectedDistrictId,
                            )
                            ? _selectedDistrictId
                            : null,
                        items: _districts
                            .map(
                              (d) => DropdownMenuItem<String>(
                                value: d['code']?.toString() ?? '',
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
                        decoration: InputDecoration(
                          labelText: 'Quận / Huyện',
                          prefixIcon: const Icon(Icons.map_outlined),
                          helperText: _selectedProvinceId == null
                              ? 'Chọn tỉnh trước'
                              : null,
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
                    refType: 'avatar',
                    refId: widget.group.id,
                    onImageUploaded: (url) {
                      setState(() => _avatarUrl = url);
                    },
                  ),
                ),
                const SizedBox(height: 20),
                ImagePickerWidget(
                  label: 'Ảnh bìa',
                  initialUrl: _coverUrl,
                  refType: 'avatar',
                  refId: widget.group.id,
                  onImageUploaded: (url) {
                    setState(() => _coverUrl = url);
                  },
                ),
                const SizedBox(height: 36),

                AppButton(
                  label: 'Lưu thay đổi',
                  icon: Icons.save_rounded,
                  loading: state is UpdateGroupLoading,
                  onPressed: _submit,
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
