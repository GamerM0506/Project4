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
  Future<Either<String, List<ConversationEntity>>> getConversations() async {
    try {
      final conversations = await remoteDataSource.getConversations();
      return Right(conversations);
    } on DioException catch (e) {
      return Left(_mapDioError(e, 'Lỗi khi tải danh sách tin nhắn'));
    } catch (e) {
      return Left('Đã xảy ra lỗi: $e');
    }
  }

  @override
  Future<Either<String, List<ChatMessage>>> getMessages(String conversationId) async {
    try {
      final messages = await remoteDataSource.getMessages(conversationId);
      return Right(messages);
    } on DioException catch (e) {
      return Left(_mapDioError(e, 'Lỗi khi tải lịch sử tin nhắn'));
    } catch (e) {
      return Left('Đã xảy ra lỗi: $e');
    }
  }

  @override
  Future<Either<String, ChatMessage>> sendMessage(String conversationId, String content, {String type = 'text', Map<String, dynamic>? metadata}) async {
    try {
      final msg = await remoteDataSource.sendMessage(conversationId, content, type: type, metadata: metadata);
      return Right(msg);
    } catch (e) {
      return Left(e.toString());
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
    return fallback;
  }
}
