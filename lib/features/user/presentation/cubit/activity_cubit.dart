import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/activity_entity.dart';
import '../../domain/usecases/get_activities_usecase.dart';
import 'activity_state.dart';

class ActivityCubit extends Cubit<ActivityState> {
  static const pageSize = 20;
  final GetActivitiesUseCase getActivitiesUseCase;

  ActivityCubit({required this.getActivitiesUseCase})
    : super(const ActivityInitial());

  Future<void> load({bool refresh = false}) async {
    if (refresh || state is ActivityInitial || state is ActivityError) {
      emit(const ActivityLoading());
    }

    final result = await getActivitiesUseCase(page: 1, limit: pageSize);
    if (isClosed) return;
    result.fold(
      (failure) => emit(ActivityError(message: failure)),
      (result) => emit(
        ActivityLoaded(
          activities: result.items,
          page: result.page,
          hasMore: result.hasMore,
        ),
      ),
    );
  }

  Future<void> refresh() => load(refresh: true);

  Future<void> loadMore() async {
    final current = state;
    if (current is ActivityLoadingMore) return;

    final activities = switch (current) {
      ActivityLoaded() => current.activities,
      ActivityError() => current.activities,
      _ => const <ActivityEntity>[],
    };
    final page = switch (current) {
      ActivityLoaded() => current.page,
      ActivityError() => current.page,
      _ => 0,
    };
    final hasMore = switch (current) {
      ActivityLoaded() => current.hasMore,
      ActivityError() => current.hasMore,
      _ => false,
    };
    if (activities.isEmpty || !hasMore) {
      return;
    }

    emit(
      ActivityLoadingMore(activities: activities, page: page, hasMore: hasMore),
    );
    final result = await getActivitiesUseCase(page: page + 1, limit: pageSize);
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        ActivityError(
          message: failure,
          activities: activities,
          page: page,
          hasMore: hasMore,
        ),
      ),
      (result) {
        final seen = <int>{};
        final merged = <ActivityEntity>[];
        for (final item in [...activities, ...result.items]) {
          if (seen.add(item.id)) merged.add(item);
        }
        emit(
          ActivityLoaded(
            activities: merged,
            page: result.page,
            hasMore: result.hasMore,
          ),
        );
      },
    );
  }
}
