import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';
import '../../presentation/cubit/chat_state.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  ChatRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<String, List<ConversationEntity>>> getConversations({
    String? groupId,
  }) async {
    try {
      final conversations = await remoteDataSource.getConversations(
        groupId: groupId,
      );
      return Right(conversations);
    } on DioException catch (e) {
      return Left(_mapDioError(e, 'Lỗi khi tải danh sách tin nhắn'));
    } catch (e) {
      return Left('Đã xảy ra lỗi: $e');
    }
  }

  @override
  Future<Either<String, List<ChatMessage>>> getMessages(
    String conversationId, {
    int limit = 50,
    int offset = 0,
    bool asUserSide = true,
  }) async {
    try {
      final messages = await remoteDataSource.getMessages(
        conversationId,
        limit: limit,
        offset: offset,
        asUserSide: asUserSide,
      );
      return Right(messages);
    } on DioException catch (e) {
      return Left(_mapDioError(e, 'Lỗi khi tải lịch sử tin nhắn'));
    } catch (e) {
      return Left('Đã xảy ra lỗi: $e');
    }
  }

  @override
  Future<Either<String, ChatMessage>> sendMessage(
    String conversationId,
    String content, {
    String type = 'text',
    Map<String, dynamic>? metadata,
    bool asGroup = false,
  }) async {
    try {
      final msg = await remoteDataSource.sendMessage(
        conversationId,
        content,
        type: type,
        metadata: metadata,
        asGroup: asGroup,
      );
      return Right(msg);
    } on DioException catch (e) {
      return Left(_mapDioError(e, 'Không thể gửi tin nhắn'));
    } catch (_) {
      return const Left('Không thể gửi tin nhắn');
    }
  }

  @override
  Future<Either<String, void>> markAsRead(String conversationId) async {
    try {
      await remoteDataSource.markAsRead(conversationId);
      return const Right(null);
    } catch (e) {
      return Left('Đã xảy ra lỗi: $e');
    }
  }

  String _mapDioError(DioException e, String fallback) {
    if (e.response?.statusCode == 401) {
      return 'Phiên đăng nhập hết hạn.';
    }
    if (e.response?.statusCode == 404) {
      return 'Cuộc trò chuyện không tồn tại.';
    }
    if (e.response?.statusCode == 403) {
      return 'Bạn không có quyền truy cập cuộc trò chuyện này.';
    }
    final body = e.response?.data;
    if (body is Map && body['error'] is String) {
      return body['error'] as String;
    }
    return fallback;
  }
}
