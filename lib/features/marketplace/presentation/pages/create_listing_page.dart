import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:io';
import '../../../../injection_container.dart';
import '../cubit/create_listing_cubit.dart';
import '../cubit/create_listing_state.dart';

class CreateListingPage extends StatefulWidget {
  const CreateListingPage({super.key});

  @override
  State<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends State<CreateListingPage> {
  final _cubit = sl<CreateListingCubit>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  
  String _category = 'clothing';
  String _condition = 'New';
  int _quantity = 1;
  XFile? _imageFile;
  bool _isDetecting = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _cubit.close();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên sản phẩm')),
      );
      return;
    }
    
    // In a real app, these ID would come from the current user and selection
    _cubit.createListing(
      inventoryItemId: 'inv_123',
      groupId: 'grp_123',
      title: _titleController.text,
      description: _descController.text,
      categoryId: _category,
      condition: _condition,
      quantityTotal: _quantity,
      createdBy: 'user_123',
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024);
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _detectItem() async {
    if (_imageFile == null) return;

    setState(() => _isDetecting = true);
    try {
      final bytes = await File(_imageFile!.path).readAsBytes();
      final base64Image = base64Encode(bytes);
      final dataUri = 'data:image/jpeg;base64,$base64Image';

      final dio = Dio();
      final response = await dio.post(
        'http://10.0.2.2:3007/ai/detect-item',
        data: {'imageUrl': dataUri},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        setState(() {
          if (data['name'] != null) _titleController.text = data['name'];
          if (data['categoryId'] != null) {
            final cat = data['categoryId'].toString().toLowerCase();
            if (['clothing', 'food', 'furniture', 'electronics'].contains(cat)) {
              _category = cat;
            } else {
              _category = 'others';
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
          if (data['suggestedDescription'] != null) {
            _descController.text = data['suggestedDescription'];
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI nhận diện thành công!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI không nhận diện được')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi gọi AI: $e')));
    } finally {
      setState(() => _isDetecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colorScheme.onSurfaceVariant),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Add Item Details',
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Text(
                  'Step 2 of 3',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: BlocConsumer<CreateListingCubit, CreateListingState>(
          listener: (context, state) {
            if (state is CreateListingSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tạo tin thành công!')),
              );
              context.pop();
            } else if (state is CreateListingError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            if (state is CreateListingLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Image Upload Area
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (_) => SafeArea(
                        child: Wrap(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.photo_library),
                              title: const Text('Chọn từ thư viện'),
                              onTap: () {
                                context.pop();
                                _pickImage(ImageSource.gallery);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.camera_alt),
                              title: const Text('Chụp ảnh mới'),
                              onTap: () {
                                context.pop();
                                _pickImage(ImageSource.camera);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outlineVariant,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                      image: _imageFile != null
                          ? DecorationImage(
                              image: FileImage(File(_imageFile!.path)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _imageFile == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 40, color: colorScheme.primary),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to take a photo or upload',
                                style: TextStyle(color: colorScheme.onSurfaceVariant),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
                if (_imageFile != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isDetecting ? null : _detectItem,
                      icon: _isDetecting 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.auto_awesome),
                      label: Text(_isDetecting ? 'Đang phân tích...' : 'AI Tự động Điền Form'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primaryContainer,
                        foregroundColor: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildSmallPhotoSlot(colorScheme),
                    const SizedBox(width: 12),
                    _buildSmallPhotoSlot(colorScheme),
                    const SizedBox(width: 12),
                    _buildSmallPhotoSlot(colorScheme),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Form
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.surfaceContainerHighest),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item Name
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Item Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colorScheme.outlineVariant),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colorScheme.primary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Category
                      DropdownButtonFormField<String>(
                        value: _category,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colorScheme.outlineVariant),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'clothing', child: Text('Clothing')),
                          DropdownMenuItem(value: 'food', child: Text('Food')),
                          DropdownMenuItem(value: 'furniture', child: Text('Furniture')),
                          DropdownMenuItem(value: 'electronics', child: Text('Electronics')),
                          DropdownMenuItem(value: 'others', child: Text('Others')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _category = val);
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, size: 16, color: colorScheme.secondary),
                          const SizedBox(width: 4),
                          Text(
                            'AI suggests: Clothing / Winter Gear',
                            style: TextStyle(color: colorScheme.secondary, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Quantity & Condition
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quantity
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Quantity', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14)),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove),
                                        onPressed: () {
                                          if (_quantity > 1) setState(() => _quantity--);
                                        },
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed: () {
                                          setState(() => _quantity++);
                                        },
                                        color: colorScheme.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Condition
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Condition', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14)),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      _buildConditionOption('New', colorScheme),
                                      _buildConditionOption('Good', colorScheme),
                                      _buildConditionOption('Used', colorScheme),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Description
                      TextField(
                        controller: _descController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Description & Notes',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colorScheme.outlineVariant),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colorScheme.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 100), // Bottom padding
              ],
            );
          },
        ),
        bottomSheet: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, -4),
                blurRadius: 12,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Next: Delivery Method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallPhotoSlot(ColorScheme colorScheme) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
          ),
          child: Icon(Icons.add, color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _buildConditionOption(String text, ColorScheme colorScheme) {
    final isSelected = _condition == text;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _condition = text),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
