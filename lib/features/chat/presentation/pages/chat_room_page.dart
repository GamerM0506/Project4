import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/media_service.dart';
import '../../domain/usecases/chat_usecases.dart';
import '../widgets/donation_bottom_sheet.dart';
import '../widgets/listing_message_bubble.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';
import '../../../../injection_container.dart';

class ChatRoomPage extends StatefulWidget {
  final String? conversationId;
  final String? groupId;
  final String name;

  const ChatRoomPage({
    super.key,
    this.conversationId,
    this.groupId,
    required this.name,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  late ChatCubit _chatCubit;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _chatCubit = sl<ChatCubit>();
    _openConversation();
  }

  Future<void> _openConversation() async {
    final conversationId = widget.conversationId;
    if (conversationId != null && conversationId.isNotEmpty) {
      await _chatCubit.connect(conversationId);
      return;
    }

    final groupId = widget.groupId;
    if (groupId == null || groupId.isEmpty) {
      _chatCubit.setError('Thiếu thông tin cuộc trò chuyện.');
      return;
    }

    final result = await sl<GetConversationsUseCase>()(groupId: groupId);
    result.fold(_chatCubit.setError, (conversations) {
      final matches = conversations
          .where((item) => item.groupId == groupId)
          .toList();
      if (matches.isEmpty) {
        _chatCubit.setError(
          'Nhóm chưa có cuộc trò chuyện. Hãy tạo yêu cầu quyên góp trước.',
        );
        return;
      }
      final currentUserId = sl<SharedPreferences>().getString(
        AppConstants.keyUserId,
      );
      final ownMatches = matches
          .where((item) => item.userId == currentUserId)
          .toList();
      final selected = ownMatches.isNotEmpty ? ownMatches.first : matches.first;
      _chatCubit.connect(selected.id);
    });
  }

  @override
  void dispose() {
    _chatCubit.close();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final text = _textController.text;
    if (text.trim().isNotEmpty) {
      _chatCubit.sendMessage(text);
      _textController.clear();
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  Future<void> _pickAndSendImage() async {
    if (_chatCubit.state.activeConversationId == null || _isUploadingImage) {
      return;
    }

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (image == null || !mounted) return;

      setState(() => _isUploadingImage = true);
      final bytes = await image.readAsBytes();
      final mimeType =
          image.mimeType ?? MediaService.mimeFromFileName(image.name);
      final publicUrl = await sl<MediaService>().uploadImage(
        bytes,
        mimeType,
        refType: 'chat',
      );
      await _chatCubit.sendMessage(publicUrl, type: 'image');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_imageErrorMessage(error))));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  String _imageErrorMessage(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    return message.isEmpty ? 'Không thể gửi hình ảnh.' : message;
  }

  void _openDonateFormWithAI() {
    context.push('/marketplace/create', extra: {'groupId': widget.groupId});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocProvider.value(
      value: _chatCubit,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 70,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.surfaceContainerLow,
              ),
              icon: Icon(Icons.arrow_back, color: colorScheme.primary),
              onPressed: () => context.pop(),
            ),
          ),
          title: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      widget.name.isNotEmpty
                          ? widget.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.greenAccent[400],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.surface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Hội nhóm tiếp nhận',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            // Nút "🎁 Gửi đồ AI" nổi bật trên AppBar
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: FilledButton.icon(
                onPressed: _openDonateFormWithAI,
                icon: const Icon(Icons.card_giftcard, size: 16),
                label: const Text(
                  'Gửi đồ quyên góp',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Quick Banner for AI Donation
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: colorScheme.secondaryContainer.withOpacity(0.4),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: colorScheme.secondary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bạn có đồ muốn gửi cho ${widget.name}? Dùng AI để điền nhanh biểu mẫu quyên góp!',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _openDonateFormWithAI,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Điền AI',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocConsumer<ChatCubit, ChatState>(
                listener: (context, state) {
                  if (state.error != null && state.error!.isNotEmpty) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(state.error!)));
                    context.read<ChatCubit>().clearError();
                  }
                  Future.delayed(
                    const Duration(milliseconds: 100),
                    _scrollToBottom,
                  );
                },
                builder: (context, state) {
                  if (state.messages.isEmpty) {
                    return Center(
                      child: Text(
                        'Chưa có tin nhắn nào trong hội nhóm này',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final msg = state.messages[index];
                      final isMine = msg.isMine;

                      if (msg.type == 'donation_proposal') {
                        return ListingMessageBubble(
                          message: msg,
                          isAdmin: true,
                        );
                      }

                      return Align(
                        alignment: isMine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: isMine
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (!isMine) ...[
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundImage: msg.senderAvatar != null && msg.senderAvatar!.isNotEmpty
                                        ? NetworkImage(msg.senderAvatar!)
                                        : null,
                                    backgroundColor:
                                        colorScheme.secondaryContainer,
                                    child: msg.senderAvatar == null || msg.senderAvatar!.isEmpty
                                        ? Text(
                                            msg.senderName != null &&
                                                    msg.senderName!.isNotEmpty
                                                ? msg.senderName![0]
                                                      .toUpperCase()
                                                : '?',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: colorScheme
                                                  .onSecondaryContainer,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                        0.75,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMine
                                        ? colorScheme.primary
                                        : colorScheme.surfaceContainerHigh,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: Radius.circular(
                                        isMine ? 16 : 4,
                                      ),
                                      bottomRight: Radius.circular(
                                        isMine ? 4 : 16,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: msg.type == 'image'
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Image.network(
                                            msg.content,
                                            width: 220,
                                            height: 220,
                                            fit: BoxFit.cover,
                                            loadingBuilder:
                                                (context, child, progress) {
                                                  if (progress == null) {
                                                    return child;
                                                  }
                                                  return const SizedBox(
                                                    width: 220,
                                                    height: 220,
                                                    child: Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    ),
                                                  );
                                                },
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return const SizedBox(
                                                    width: 220,
                                                    height: 120,
                                                    child: Center(
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .broken_image_outlined,
                                                          ),
                                                          SizedBox(height: 8),
                                                          Text(
                                                            'Không tải được ảnh',
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                          ),
                                        )
                                      : Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          child: Text(
                                            msg.content,
                                            style: TextStyle(
                                              color: isMine
                                                  ? colorScheme.onPrimary
                                                  : colorScheme.onSurface,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: EdgeInsets.only(
                                top: 4,
                                bottom: 12,
                                left: isMine ? 0 : 40,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (isMine) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.done_all,
                                      size: 14,
                                      color: Colors.teal[400],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            BlocBuilder<ChatCubit, ChatState>(
              builder: (context, state) => _buildChatInput(
                colorScheme,
                enabled: state.activeConversationId != null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInput(ColorScheme colorScheme, {required bool enabled}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.surfaceContainerHighest),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 12,
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Row(
            children: [
              IconButton(
                icon: _isUploadingImage
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.add_circle, color: colorScheme.primary),
                onPressed: enabled && !_isUploadingImage
                    ? () => _showAttachmentOptions(context)
                    : null,
              ),
              Expanded(
                child: TextField(
                  enabled: enabled,
                  controller: _textController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: enabled
                        ? 'Nhập tin nhắn với nhóm...'
                        : 'Chưa có cuộc trò chuyện',
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 15,
                    ),
                  ),
                  style: TextStyle(color: colorScheme.onSurface, fontSize: 15),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.send,
                    color: colorScheme.onPrimary,
                    size: 20,
                  ),
                  onPressed: enabled ? _sendMessage : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Wrap(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.orange),
                  ),
                  title: const Text(
                    'Quyên góp đồ bằng AI',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Chụp/chọn ảnh để AI tự động điền biểu mẫu và gửi cho nhóm',
                  ),
                  onTap: () {
                    context.pop();
                    _openDonateFormWithAI();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.card_giftcard, color: Colors.green),
                  ),
                  title: const Text('Tạo thẻ quyên góp thủ công'),
                  subtitle: const Text(
                    'Điền thông tin và gửi yêu cầu vào cuộc trò chuyện',
                  ),
                  onTap: () {
                    context.pop();
                    _showDonationForm(context);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.image, color: Colors.blue),
                  ),
                  title: const Text('Gửi hình ảnh'),
                  onTap: () {
                    context.pop();
                    _pickAndSendImage();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDonationForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DonationBottomSheet(
          onSubmit: (title, description, quantity) {
            _chatCubit.submitDonationProposal(
              groupId: widget.groupId ?? '',
              title: title,
              description: description,
              quantity: quantity,
              condition: 'used',
            );
          },
        );
      },
    );
  }
}
