import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/media_service.dart';
import '../../../donation/data/models/donation_model.dart';
import '../../../group/data/models/group_model.dart';
import '../../../../injection_container.dart';
import '../cubit/create_listing_cubit.dart';
import '../cubit/create_listing_state.dart';
import '../../../ai/data/ai_service.dart';

class CreateListingPage extends StatefulWidget {
  final String? groupId;

  const CreateListingPage({super.key, this.groupId});

  @override
  State<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends State<CreateListingPage> {
  final _cubit = sl<CreateListingCubit>();
  final AiService _aiService = sl<AiService>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedGroupId;
  List<DonationCategoryModel> _categories = [];
  List<GroupModel> _groups = [];
  String _condition = 'Good';
  int _quantity = 1;
  XFile? _imageFile;
  bool _isDetecting = false;
  bool _isGeneratingDesc = false;
  bool _aiDetected = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _cubit.loadForm(preferredGroupId: widget.groupId);
  }

  @override
  void dispose() {
    _cubit.close();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      _showSnackBar('Vui lòng nhập tên món đồ quyên góp', isError: true);
      return;
    }

    if (_selectedGroupId == null) {
      _showSnackBar('Vui lòng chọn hội nhóm tiếp nhận', isError: true);
      return;
    }

    final imageBytes = await _imageFile?.readAsBytes();
    final imageMimeType = _imageFile == null
        ? null
        : MediaService.mimeFromFileName(_imageFile!.name);
    _cubit.createDonation(
      groupId: _selectedGroupId!,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      condition: _condition,
      quantity: _quantity,
      categoryId: _selectedCategoryId,
      imageBytes: imageBytes,
      imageMimeType: imageMimeType,
    );
  }

  void _showSnackBar(
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess
                  ? Icons.check_circle_outline
                  : (isError ? Icons.error_outline : Icons.info_outline),
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess
            ? Colors.green.shade700
            : (isError ? Colors.red.shade700 : const Color(0xFF1E88E5)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
          _aiDetected = false;
        });
        _detectItem();
      }
    } catch (e) {
      _showSnackBar('Lỗi khi chọn ảnh: $e', isError: true);
    }
  }

  Future<void> _detectItem() async {
    if (_imageFile == null) return;

    setState(() => _isDetecting = true);
    try {
      final bytes = await _imageFile!.readAsBytes();
      final data = await _aiService.detectItem(bytes);
      if (data.isNotEmpty) {
        setState(() {
          if (data['name'] != null && data['name'].toString().isNotEmpty) {
            _titleController.text = data['name'];
          }

          if (data['categoryId'] != null) {
            final candidate = data['categoryId'].toString().toLowerCase();
            final matches = _categories.where(
              (category) =>
                  category.id.toLowerCase() == candidate ||
                  category.slug.toLowerCase() == candidate,
            );
            if (matches.isNotEmpty) {
              _selectedCategoryId = matches.first.id;
            }
          }

          if (data['condition'] != null) {
            final cond = data['condition'].toString();
            if (['New', 'Good', 'Used'].contains(cond)) {
              _condition = cond;
            } else if (cond == 'Fair' || cond == 'Poor') {
              _condition = 'Used';
            }
          }

          if (data['suggestedDescription'] != null &&
              data['suggestedDescription'].toString().isNotEmpty) {
            _descController.text = data['suggestedDescription'];
          }

          _aiDetected = true;
        });

        _showSnackBar(
          '✨ AI đã tự động điền thông tin món đồ!',
          isSuccess: true,
        );
      } else {
        _showSnackBar('AI không thể nhận diện được hình ảnh', isError: true);
      }
    } catch (e) {
      _showSnackBar(
        'Không kết nối được máy chủ AI (${AppConstants.apiHost}). Bạn có thể tự điền biểu mẫu.',
        isError: true,
      );
    } finally {
      setState(() => _isDetecting = false);
    }
  }

  Future<void> _generateDescriptionWithAI() async {
    if (_titleController.text.trim().isEmpty) {
      _showSnackBar(
        'Vui lòng nhập tên món đồ trước khi sinh mô tả',
        isError: true,
      );
      return;
    }

    setState(() => _isGeneratingDesc = true);
    try {
      final desc = await _aiService.generateDescription(
        name: _titleController.text.trim(),
        condition: _condition,
      );
      setState(() => _descController.text = desc);
      _showSnackBar(
        'AI đã tạo mô tả. Vui lòng kiểm tra trước khi đăng.',
        isSuccess: true,
      );
    } catch (e) {
      _showSnackBar('Lỗi khi sinh mô tả tự động', isError: true);
    } finally {
      setState(() => _isGeneratingDesc = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          elevation: 0,
          scrolledUnderElevation: 2,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: colorScheme.onSurface,
              size: 20,
            ),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Tạo đơn quyên góp',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: BlocConsumer<CreateListingCubit, CreateListingState>(
          listener: (context, state) {
            if (state is CreateListingFormReady) {
              setState(() {
                _groups = state.groups;
                _categories = state.categories;
                _selectedGroupId =
                    state.selectedGroupId ??
                    (_groups.length == 1 ? _groups.first.id : null);
                _selectedCategoryId ??= _categories.isEmpty
                    ? null
                    : _categories.first.id;
              });
            } else if (state is CreateListingSuccess) {
              _showSnackBar(
                'Đã tạo đơn quyên góp (chờ nhóm duyệt)!',
                isSuccess: true,
              );
              context.pop();
            } else if (state is CreateListingError) {
              _showSnackBar(state.message, isError: true);
            }
          },
          builder: (context, state) {
            if (state is CreateListingLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                // 1. Image Header Upload Card
                _buildImagePickerHeader(colorScheme),

                const SizedBox(height: 16),

                // 2. AI Auto-fill Banner / Magic Action
                _buildAiBanner(colorScheme),

                const SizedBox(height: 20),

                // 3. Form Content Container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withOpacity(0.4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Hội nhóm tiếp nhận', Icons.groups_outlined),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedGroupId,
                        items: _groups
                            .map(
                              (group) => DropdownMenuItem(
                                value: group.id,
                                child: Text(group.name),
                              ),
                            )
                            .toList(),
                        onChanged: widget.groupId != null
                            ? null
                            : (value) =>
                                  setState(() => _selectedGroupId = value),
                        decoration: InputDecoration(
                          hintText: _groups.isEmpty
                              ? 'Bạn chưa tham gia nhóm nào'
                              : 'Chọn nhóm thiện nguyện tiếp nhận',
                          prefixIcon: Icon(
                            Icons.group_outlined,
                            color: colorScheme.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          filled: true,
                          fillColor: colorScheme.surface,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Item Name Field
                      _buildLabel(
                        'Tên món đồ quyên góp *',
                        Icons.card_giftcard,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _titleController,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ví dụ: Áo khoác gió nam, Cây lau nhà...',
                          prefixIcon: Icon(
                            Icons.edit_outlined,
                            color: colorScheme.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: colorScheme.outlineVariant.withOpacity(
                                0.6,
                              ),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: colorScheme.surface,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Category Selector Chips
                      _buildLabel('Danh mục món đồ', Icons.grid_view_rounded),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categories.map((category) {
                          final isSelected = _selectedCategoryId == category.id;

                          return ChoiceChip(
                            avatar: Icon(
                              _categoryIcon(category.slug),
                              size: 18,
                              color: isSelected
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurfaceVariant,
                            ),
                            label: Text(category.name),
                            selected: isSelected,
                            selectedColor: colorScheme.primary,
                            backgroundColor: colorScheme.surfaceContainerHighest
                                .withOpacity(0.5),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.outlineVariant.withOpacity(
                                        0.3,
                                      ),
                              ),
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(
                                  () => _selectedCategoryId = category.id,
                                );
                              }
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      // Quantity and Condition Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quantity
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Số lượng', Icons.numbers),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest
                                        .withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: colorScheme.outlineVariant
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                          size: 22,
                                        ),
                                        onPressed: () {
                                          if (_quantity > 1) {
                                            setState(() => _quantity--);
                                          }
                                        },
                                        color: colorScheme.primary,
                                      ),
                                      Text(
                                        '$_quantity',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                          size: 22,
                                        ),
                                        onPressed: () =>
                                            setState(() => _quantity++),
                                        color: colorScheme.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Condition Segmented Pills
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel(
                                  'Tình trạng đồ',
                                  Icons.stars_outlined,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest
                                        .withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: colorScheme.outlineVariant
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      _buildConditionPill(
                                        'New',
                                        'Mới',
                                        colorScheme,
                                      ),
                                      _buildConditionPill(
                                        'Good',
                                        'Tốt',
                                        colorScheme,
                                      ),
                                      _buildConditionPill(
                                        'Used',
                                        'Cũ',
                                        colorScheme,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Description Field with Magic AI Assistant Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildLabel(
                            'Mô tả chi tiết',
                            Icons.description_outlined,
                          ),
                          InkWell(
                            onTap: _isGeneratingDesc
                                ? null
                                : _generateDescriptionWithAI,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Row(
                                children: [
                                  if (_isGeneratingDesc)
                                    const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  else
                                    Icon(
                                      Icons.auto_awesome,
                                      size: 14,
                                      color: colorScheme.primary,
                                    ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Sinh bằng AI',
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descController,
                        maxLines: 4,
                        style: TextStyle(color: colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText:
                              'Nhập mô tả về kiểu dáng, màu sắc, địa điểm nhận đồ...',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: colorScheme.outlineVariant.withOpacity(
                                0.6,
                              ),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: colorScheme.surface,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 100),
              ],
            );
          },
        ),
        bottomSheet: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: colorScheme.outlineVariant.withOpacity(0.3),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                offset: const Offset(0, -4),
                blurRadius: 10,
              ),
            ],
          ),
          child: SafeArea(
            child: ElevatedButton(
              onPressed: _groups.isEmpty ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Gửi đơn quyên góp',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  IconData _categoryIcon(String slug) {
    return switch (slug.toLowerCase()) {
      'clothing' => Icons.checkroom_outlined,
      'food' => Icons.restaurant_outlined,
      'furniture' || 'household' => Icons.chair_outlined,
      'electronics' => Icons.devices_outlined,
      _ => Icons.category_outlined,
    };
  }

  Widget _buildImagePickerHeader(ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Wrap(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.photo_library,
                        color: colorScheme.primary,
                      ),
                    ),
                    title: const Text(
                      'Chọn ảnh từ thư viện',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      context.pop();
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: colorScheme.secondary,
                      ),
                    ),
                    title: const Text(
                      'Chụp ảnh mới',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      context.pop();
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _imageFile != null
                ? colorScheme.primary
                : colorScheme.outlineVariant.withOpacity(0.5),
            width: _imageFile != null ? 2 : 1.5,
          ),
          image: _imageFile != null
              ? DecorationImage(
                  image: kIsWeb
                      ? NetworkImage(_imageFile!.path) as ImageProvider
                      : FileImage(File(_imageFile!.path)) as ImageProvider,
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _imageFile == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_a_photo_outlined,
                      size: 36,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Chụp hoặc tải ảnh món đồ quyên góp',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'AI sẽ tự động đọc ảnh và điền biểu mẫu giúp bạn',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            : Stack(
                children: [
                  Positioned(
                    top: 12,
                    right: 12,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 18,
                        ),
                        onPressed: () => _pickImage(ImageSource.gallery),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAiBanner(ColorScheme colorScheme) {
    if (_imageFile == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.tertiaryContainer.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: _isDetecting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: colorScheme.primary,
                    ),
                  )
                : Icon(
                    Icons.auto_awesome,
                    color: colorScheme.primary,
                    size: 22,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isDetecting
                      ? 'AI đang đọc hình ảnh...'
                      : (_aiDetected
                            ? '✨ AI đã điền biểu mẫu thành công'
                            : 'Phân tích hình ảnh với AI'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isDetecting
                      ? 'Đang gửi ảnh sang AI (${AppConstants.apiHost})...'
                      : (_aiDetected
                            ? 'Bạn có thể chỉnh sửa lại thông tin nếu cần'
                            : 'Bấm nút để AI tự nhận diện lại'),
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (!_isDetecting)
            TextButton.icon(
              onPressed: _detectItem,
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(_aiDetected ? 'Phân tích lại' : 'Chạy AI'),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConditionPill(
    String value,
    String label,
    ColorScheme colorScheme,
  ) {
    final isSelected = _condition == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _condition = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
