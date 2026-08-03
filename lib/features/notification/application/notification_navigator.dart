import '../../../core/router/app_router.dart';
import '../../../core/router/app_routes.dart';

class NotificationNavigator {
  const NotificationNavigator();

  Future<bool> open({
    required String? refType,
    required String? refId,
    String? title,
  }) async {
    final normalizedType = refType?.trim().toLowerCase();
    final normalizedId = refId?.trim();

    switch (normalizedType) {
      case 'conversation' when normalizedId != null && normalizedId.isNotEmpty:
        await appRouter.push(
          AppRoutes.chatRoom,
          extra: {'conversationId': normalizedId, 'name': title ?? 'Tin nhắn'},
        );
        return true;
      case 'group' when normalizedId != null && normalizedId.isNotEmpty:
        await appRouter.push(
          '${AppRoutes.groupDetail}/${Uri.encodeComponent(normalizedId)}',
        );
        return true;
      case 'listing' when normalizedId != null && normalizedId.isNotEmpty:
      case 'campaign' when normalizedId != null && normalizedId.isNotEmpty:
        await appRouter.push(
          '${AppRoutes.campaigns}/detail/${Uri.encodeComponent(normalizedId)}',
        );
        return true;
      case 'contribution':
      case 'request':
      case 'donation':
        await appRouter.push(AppRoutes.myItems);
        return true;
      default:
        return false;
    }
  }
}
