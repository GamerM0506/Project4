import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/home_repository.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final HomeRepository repository;

  HomeCubit({required this.repository}) : super(HomeInitial());

  Future<void> fetchHomeData() async {
    emit(HomeLoading());
    try {
      final groups = await repository.getFeaturedGroups(limit: 5);
      final listings = await repository.getRecentItems(limit: 5);
      
      emit(HomeLoaded(groups: groups, listings: listings));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }
}
