import '../../data/models/group_model.dart';
import '../../data/models/listing_model.dart';

abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<GroupModel> groups;
  final List<ListingModel> listings;

  HomeLoaded({required this.groups, required this.listings});
}


class HomeError extends HomeState {
  final String message;

  HomeError(this.message);
}
