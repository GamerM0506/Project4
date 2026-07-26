import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:project4_chosv/features/user/domain/entities/activity_entity.dart';
import 'package:project4_chosv/features/user/domain/usecases/get_activities_usecase.dart';
import 'package:project4_chosv/features/user/presentation/cubit/activity_cubit.dart';
import 'package:project4_chosv/features/user/presentation/cubit/activity_state.dart';

class MockGetActivitiesUseCase extends Mock implements GetActivitiesUseCase {}

void main() {
  test(
    'loads more in backend order and deduplicates overlapping items',
    () async {
      final useCase = MockGetActivitiesUseCase();
      final first = ActivityEntity(
        id: 2,
        action: 'login',
        createdAt: DateTime.utc(2026, 7, 26),
      );
      final second = ActivityEntity(
        id: 1,
        action: 'change_password',
        createdAt: DateTime.utc(2026, 7, 25),
      );
      when(() => useCase(page: 1, limit: ActivityCubit.pageSize)).thenAnswer(
        (_) async => Right(
          ActivityPageEntity(
            items: [first],
            page: 1,
            limit: ActivityCubit.pageSize,
            total: 21,
          ),
        ),
      );
      when(() => useCase(page: 2, limit: ActivityCubit.pageSize)).thenAnswer(
        (_) async => Right(
          ActivityPageEntity(
            items: [first, second],
            page: 2,
            limit: ActivityCubit.pageSize,
            total: 21,
          ),
        ),
      );
      final cubit = ActivityCubit(getActivitiesUseCase: useCase);

      await cubit.load();
      await cubit.loadMore();

      final state = cubit.state as ActivityLoaded;
      expect(state.activities.map((item) => item.id), [2, 1]);
      expect(state.hasMore, isFalse);
      await cubit.close();
    },
  );
}
