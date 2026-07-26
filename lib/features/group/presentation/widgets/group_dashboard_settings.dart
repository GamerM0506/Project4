import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    } catch (e) {
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
      final districtsList = province['districts'] as List<dynamic>;
      setState(() {
        _districts = districtsList;
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
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            // Refresh group detail
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
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Cài đặt nhóm',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Chỉnh sửa thông tin cơ bản và tùy chọn nâng cao.',
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),

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

                // Location Dropdowns Row
                Row(
                  children: [
                    Expanded(
                      child: _buildModernDropdown(
                        label: 'Tỉnh / Thành phố',
                        icon: Icons.location_on_outlined,
                        value: _selectedProvinceId,
                        items: _provinces.map((p) {
                          return DropdownMenuItem<String>(
                            value: p['code'].toString(),
                            child: Text(
                              p['name']?.toString() ?? '',
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: _onProvinceChanged,
                        isLoading: _isLoadingProvinces,
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModernDropdown(
                        label: 'Quận / Huyện',
                        icon: Icons.map_outlined,
                        value: _selectedDistrictId,
                        items: _districts.map((d) {
                          return DropdownMenuItem<String>(
                            value: d['code'].toString(),
                            child: Text(
                              d['name']?.toString() ?? '',
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedDistrictId = val;
                          });
                        },
                        isLoading: false,
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Address Field
                _buildModernTextField(
                  controller: _addressController,
                  label: 'Địa chỉ cụ thể (Tòa nhà, số nhà, v.v...)',
                  icon: Icons.home_outlined,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
                const SizedBox(height: 32),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Cho phép thành viên đăng bài'),
                  value: _allowMemberPost,
                  onChanged: (value) =>
                      setState(() => _allowMemberPost = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Bài viết cần được kiểm duyệt'),
                  value: _requirePostReview,
                  onChanged: (value) =>
                      setState(() => _requirePostReview = value),
                ),
                const SizedBox(height: 16),

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
                    backgroundColor: const Color(0xFFB73A41),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: state is UpdateGroupLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
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
              ],
            ),
          );
        },
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
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
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
            color: colorScheme.onSurfaceVariant.withOpacity(0.8),
          ),
          prefixIcon: maxLines == 1
              ? Icon(
                  icon,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  size: 22,
                )
              : Padding(
                  padding: const EdgeInsets.only(
                    bottom: 60,
                  ), // Align top for multiline
                  child: Icon(
                    icon,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
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

  Widget _buildModernDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
    required bool isLoading,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items,
        onChanged: onChanged,
        isExpanded: true, // Fix for overflowing text in dropdowns
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.arrow_drop_down),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant.withOpacity(0.8),
            overflow: TextOverflow.ellipsis,
          ),
          prefixIcon: Icon(
            icon,
            color: colorScheme.onSurfaceVariant.withOpacity(0.7),
            size: 22,
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
