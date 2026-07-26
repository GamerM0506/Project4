import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/location_service.dart';
import '../../../../core/network/media_service.dart';
import '../../../../injection_container.dart';
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
  final _addressDetailController = TextEditingController();
  final _bioController = TextEditingController();

  String? _selectedDay;
  String? _selectedMonth;
  String? _selectedYear;

  String _gender = 'other';
  bool _isLoadingLocation = true;

  String? _userId;
  String? _avatarUrl;
  String? _avatarMediaId;
  int _reputationScore = 0;
  int _donationCount = 0;
  int _receivedCount = 0;

  bool _isUploadingAvatar = false;
  bool _avatarOnlyUpdate = false;
  bool _hasUserEdits = false;
  bool _isHydrating = false;
  late final MediaService _mediaService;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _mediaService = sl<MediaService>();
    _hydrateFromCubit();
    _nameController.addListener(_markEdited);
    _addressDetailController.addListener(_markEdited);
    _bioController.addListener(_markEdited);
    _loadProvinces();
  }

  void _markEdited() {
    if (!_isHydrating) _hasUserEdits = true;
  }

  void _hydrateFromCubit({bool preserveEdits = false}) {
    final user = context.read<UserCubit>().state.userOrNull;
    if (user == null) return;

    _isHydrating = true;
    _userId = user.id;
    _avatarUrl = user.avatar;
    _reputationScore = user.reputationScore;
    _donationCount = user.donationCount;
    _receivedCount = user.receivedCount;

    if (!preserveEdits) {
      _nameController.text = user.fullName;
      if (user.bio != null) _bioController.text = user.bio!;
      if (user.addressDetail != null) {
        _addressDetailController.text = user.addressDetail!;
      }
      if (user.gender != null && user.gender!.isNotEmpty) {
        _gender = user.gender!;
      }
      if (user.provinceCode != null) _selectedProvinceId = user.provinceCode;
      if (user.districtCode != null) _selectedDistrictId = user.districtCode;

      if (user.dob != null && user.dob!.isNotEmpty) {
        final parts = user.dob!.split('-');
        if (parts.length >= 3) {
          _selectedYear = parts[0];
          _selectedMonth = parts[1].padLeft(2, '0');
          _selectedDay = parts[2].padLeft(2, '0');
        }
      }
    }
    _isHydrating = false;
  }

  Future<void> _loadProvinces() async {
    final data = await _locationService.getProvinces();
    if (!mounted) return;
    setState(() {
      _provinces = data;
      _isLoadingLocation = false;
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
        setState(() {
          _districts = province!['districts'] as List<dynamic>;
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

  void _saveProfile() {
    if (_userId == null) {
      context.read<UserCubit>().fetchProfile();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đang tải hồ sơ, vui lòng thử lưu lại.'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng nhập họ và tên.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    String? dob;
    if (_selectedDay != null &&
        _selectedMonth != null &&
        _selectedYear != null) {
      dob = '$_selectedYear-$_selectedMonth-$_selectedDay';
    }

    final updatedUser = UserEntity(
      id: _userId!,
      fullName: name,
      avatar: _avatarUrl,
      bio: _bioController.text.trim(),
      gender: _gender,
      provinceCode: _selectedProvinceId,
      districtCode: _selectedDistrictId,
      addressDetail: _addressDetailController.text.trim(),
      dob: dob,
      reputationScore: _reputationScore,
      donationCount: _donationCount,
      receivedCount: _receivedCount,
    );

    context.read<UserCubit>().updateProfile(updatedUser);
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (image == null) return;

      setState(() => _isUploadingAvatar = true);

      final bytes = await image.readAsBytes();
      final mimeType = MediaService.mimeFromFileName(image.name);

      final uploaded = await _mediaService.uploadImageResult(bytes, mimeType);

      if (!mounted) return;
      setState(() {
        _avatarUrl = uploaded.publicUrl;
        _avatarMediaId = uploaded.mediaId;
        _isUploadingAvatar = false;
      });

      if (_userId != null) {
        final current = context.read<UserCubit>().state.userOrNull;
        _avatarOnlyUpdate = true;
        await context.read<UserCubit>().updateProfile(
          UserEntity(
            id: _userId!,
            fullName: current?.fullName ?? _nameController.text.trim(),
            avatar: uploaded.publicUrl,
            bio: current?.bio ?? _bioController.text.trim(),
            gender: current?.gender ?? _gender,
            provinceCode: current?.provinceCode ?? _selectedProvinceId,
            districtCode: current?.districtCode ?? _selectedDistrictId,
            addressDetail:
                current?.addressDetail ?? _addressDetailController.text.trim(),
            dob: current?.dob,
            reputationScore: current?.reputationScore ?? _reputationScore,
            donationCount: current?.donationCount ?? _donationCount,
            receivedCount: current?.receivedCount ?? _receivedCount,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingAvatar = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressDetailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bgColor = const Color(0xFFFDFDFF);

    return BlocConsumer<UserCubit, UserState>(
      listener: (context, state) {
        if (state is UserLoaded && _userId == null) {
          setState(() => _hydrateFromCubit(preserveEdits: _hasUserEdits));
        } else if (state is UserUpdateSuccess) {
          if (_avatarMediaId != null && _userId != null) {
            _mediaService
                .linkMedia([_avatarMediaId!], 'avatar', _userId!)
                .catchError((error) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Cập nhật hồ sơ thành công nhưng chưa liên kết được ảnh: $error',
                        ),
                      ),
                    );
                  }
                });
            _avatarMediaId = null;
          }
          final avatarOnly = _avatarOnlyUpdate;
          _avatarOnlyUpdate = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                avatarOnly
                    ? 'Cập nhật ảnh đại diện thành công!'
                    : 'Cập nhật thông tin thành công!',
              ),
              backgroundColor: colorScheme.primary,
            ),
          );
          if (!avatarOnly) {
            context.pop();
          }
        } else if (state is UserUpdateError) {
          _avatarOnlyUpdate = false;
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
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
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
                                border: Border.all(
                                  color: colorScheme.surface,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primaryContainer
                                        .withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Hero(
                                tag: 'avatar_hero',
                                child: ClipOval(
                                  child:
                                      _avatarUrl != null &&
                                          _avatarUrl!.isNotEmpty
                                      ? Image.network(
                                          _avatarUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Icon(
                                                    Icons.person,
                                                    size: 60,
                                                    color: colorScheme
                                                        .onSurfaceVariant,
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
                                        color: Colors.white.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.black.withValues(
                                          alpha: 0.4,
                                        ),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.photo_camera,
                                          color: Colors.white,
                                          size: 32,
                                        ),
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

                Text(
                  'Thông tin cá nhân',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                SoftInputField(controller: _nameController, label: 'Họ và tên'),
                const SizedBox(height: 16),

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
                          return DropdownMenuItem(
                            value: day,
                            child: Text(
                              day,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
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
                          return DropdownMenuItem(
                            value: month,
                            child: Text(
                              month,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                        onChanged: (val) =>
                            setState(() => _selectedMonth = val),
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
                          return DropdownMenuItem(
                            value: year,
                            child: Text(
                              year,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                        onChanged: (val) => setState(() => _selectedYear = val),
                        isLoading: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
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
                            child: Text(
                              p['name'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
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
                            child: Text(
                              d['name'],
                              maxLines: 1,
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
