import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/location_service.dart';
import '../../../../core/network/media_service.dart';
import '../../domain/entities/user_entity.dart';
import '../cubit/user_cubit.dart';
import '../cubit/user_state.dart';
import '../widgets/soft_input_field.dart';
import '../widgets/soft_dropdown_field.dart';
import '../widgets/gender_radio_option.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final LocationService _locationService = LocationService();
  
  List<dynamic> _provinces = [];
  List<dynamic> _districts = [];
  
  String? _selectedProvinceId;
  String? _selectedDistrictId;
  
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController(text: '+84 555 123 4567');
  final _addressDetailController = TextEditingController();
  final _bioController = TextEditingController();
  
  String? _selectedDay;
  String? _selectedMonth;
  String? _selectedYear;
  
  String _gender = 'female';
  bool _isLoadingLocation = true;

  String? _userId;
  String? _avatarUrl;

  bool _isUploadingAvatar = false;
  final MediaService _mediaService = MediaService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProvinces();
    
    // Default name from cubit if available
    final state = context.read<UserCubit>().state;
    if (state is UserLoaded) {
      _userId = state.user.id;
      _avatarUrl = state.user.avatar;
      _nameController.text = state.user.fullName;
      if (state.user.phone != null) _phoneController.text = state.user.phone!;
      if (state.user.bio != null) _bioController.text = state.user.bio!;
      if (state.user.addressDetail != null) _addressDetailController.text = state.user.addressDetail!;
      if (state.user.gender != null) _gender = state.user.gender!;
      if (state.user.provinceCode != null) _selectedProvinceId = state.user.provinceCode;
      if (state.user.districtCode != null) _selectedDistrictId = state.user.districtCode;
      if (state.user.dob != null) {
        final parts = state.user.dob!.split('-');
        if (parts.length == 3) {
          _selectedYear = parts[0];
          _selectedMonth = parts[1];
          _selectedDay = parts[2];
        }
      }
    }
  }

  Future<void> _loadProvinces() async {
    final data = await _locationService.getProvinces();
    setState(() {
      _provinces = data;
      _isLoadingLocation = false;
    });
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

  void _saveProfile() {
    if (_userId == null) return;
    
    String? dob;
    if (_selectedDay != null && _selectedMonth != null && _selectedYear != null) {
      dob = '$_selectedYear-$_selectedMonth-$_selectedDay';
    }

    final updatedUser = UserEntity(
      id: _userId!,
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      bio: _bioController.text.trim(),
      gender: _gender,
      provinceCode: _selectedProvinceId,
      districtCode: _selectedDistrictId,
      addressDetail: _addressDetailController.text.trim(),
      dob: dob,
    );

    context.read<UserCubit>().updateProfile(updatedUser);
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      
      setState(() {
        _isUploadingAvatar = true;
      });

      final bytes = await image.readAsBytes();
      String mimeType = 'image/jpeg';
      if (image.name.toLowerCase().endsWith('.png')) mimeType = 'image/png';
      else if (image.name.toLowerCase().endsWith('.webp')) mimeType = 'image/webp';

      final publicUrl = await _mediaService.uploadImage(bytes, mimeType);
      
      if (publicUrl != null && mounted) {
        setState(() {
          _avatarUrl = publicUrl;
          _isUploadingAvatar = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Tải ảnh thành công!'), backgroundColor: Theme.of(context).colorScheme.primary),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressDetailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    // For background FDFDFF approx
    final bgColor = const Color(0xFFFDFDFF); 

    return BlocConsumer<UserCubit, UserState>(
      listener: (context, state) {
        if (state is UserUpdateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Cập nhật thông tin thành công!'),
              backgroundColor: colorScheme.primary,
            ),
          );
          context.pop();
        } else if (state is UserUpdateError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final isUpdating = state is UserUpdating;
        
        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: colorScheme.surface,
            elevation: 0,
            scrolledUnderElevation: 1, // subtle shadow when scrolled
            shadowColor: Colors.black.withValues(alpha: 0.2),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: colorScheme.onSurfaceVariant),
              onPressed: isUpdating ? null : () => context.pop(),
            ),
            title: Text(
              'Đổi thông tin',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            centerTitle: true,
            actions: [
              isUpdating 
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: SizedBox(
                        width: 20, height: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary)
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: _saveProfile,
                    child: Text(
                      'Lưu',
                      style: textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avatar Section
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                    child: Stack(
                      children: [
                        Container(
                          width: 128,
                          height: 128,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.surfaceContainerHighest,
                            border: Border.all(color: colorScheme.surface, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Hero(
                            tag: 'avatar_hero',
                            child: ClipOval(
                              child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                                  ? Image.network(
                                      _avatarUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Icon(
                                        Icons.person,
                                        size: 60,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    )
                                  : Icon(
                                      Icons.person,
                                      size: 60,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: _isUploadingAvatar
                              ? Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black.withValues(alpha: 0.4),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.photo_camera, color: Colors.white, size: 32),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chạm để đổi ảnh',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Personal Info Block
            Text(
              'Thông tin cá nhân',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            SoftInputField(
              controller: _nameController,
              label: 'Họ và tên',
            ),
            const SizedBox(height: 16),
            
            SoftInputField(
              controller: _phoneController,
              label: 'Số điện thoại',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            
            // Ngày sinh (3 Dropdowns)
            Text(
              'Ngày sinh',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: SoftDropdownField(
                    label: 'Ngày',
                    value: _selectedDay,
                    items: List.generate(31, (index) {
                      final day = (index + 1).toString().padLeft(2, '0');
                      return DropdownMenuItem(value: day, child: Text(day, maxLines: 1, overflow: TextOverflow.ellipsis));
                    }),
                    onChanged: (val) => setState(() => _selectedDay = val),
                    isLoading: false,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: SoftDropdownField(
                    label: 'Tháng',
                    value: _selectedMonth,
                    items: List.generate(12, (index) {
                      final month = (index + 1).toString().padLeft(2, '0');
                      return DropdownMenuItem(value: month, child: Text(month, maxLines: 1, overflow: TextOverflow.ellipsis));
                    }),
                    onChanged: (val) => setState(() => _selectedMonth = val),
                    isLoading: false,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: SoftDropdownField(
                    label: 'Năm',
                    value: _selectedYear,
                    items: List.generate(100, (index) {
                      final year = (DateTime.now().year - index).toString();
                      return DropdownMenuItem(value: year, child: Text(year, maxLines: 1, overflow: TextOverflow.ellipsis));
                    }),
                    onChanged: (val) => setState(() => _selectedYear = val),
                    isLoading: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Gender Radio
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Giới tính',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      GenderRadioOption(
                        title: 'Nữ',
                        isSelected: _gender == 'female',
                        onTap: () => setState(() => _gender = 'female'),
                      ),
                      const SizedBox(width: 16),
                      GenderRadioOption(
                        title: 'Nam',
                        isSelected: _gender == 'male',
                        onTap: () => setState(() => _gender = 'male'),
                      ),
                      const SizedBox(width: 16),
                      GenderRadioOption(
                        title: 'Khác',
                        isSelected: _gender == 'other',
                        onTap: () => setState(() => _gender = 'other'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Address Details Block
            Text(
              'Địa chỉ liên hệ',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: SoftDropdownField(
                    label: 'Tỉnh/Thành phố',
                    value: _selectedProvinceId,
                    items: _provinces.map((p) {
                      return DropdownMenuItem<String>(
                        value: p['code'].toString(),
                        child: Text(p['name'], maxLines: 1, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: _onProvinceChanged,
                    isLoading: _isLoadingLocation,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SoftDropdownField(
                    label: 'Quận/Huyện',
                    value: _selectedDistrictId,
                    items: _districts.map((d) {
                      return DropdownMenuItem<String>(
                        value: d['code'].toString(),
                        child: Text(d['name'], maxLines: 1, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedDistrictId = val;
                      });
                    },
                    isLoading: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            SoftInputField(
              controller: _addressDetailController,
              label: 'Địa chỉ chi tiết (Số nhà, tên đường...)',
              maxLines: 3,
            ),
            
            const SizedBox(height: 32),
            
            // Bio Block
            Text(
              'Giới thiệu bản thân',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            SoftInputField(
              controller: _bioController,
              label: 'Vài dòng về bạn',
              maxLines: 4,
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
      },
    );
  }
}
