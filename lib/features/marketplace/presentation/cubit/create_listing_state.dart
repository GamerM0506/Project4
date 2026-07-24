import 'package:equatable/equatable.dart';
import '../../../donation/data/models/donation_model.dart';
import '../../../group/data/models/group_model.dart';

abstract class CreateListingState extends Equatable {
  const CreateListingState();

  @override
  List<Object?> get props => [];
}

class CreateListingInitial extends CreateListingState {}

class CreateListingLoading extends CreateListingState {}

class CreateListingFormReady extends CreateListingState {
  final List<GroupModel> groups;
  final List<DonationCategoryModel> categories;
  final String? selectedGroupId;

  const CreateListingFormReady({
    required this.groups,
    required this.categories,
    this.selectedGroupId,
  });

  @override
  List<Object?> get props => [groups, categories, selectedGroupId];
}

class CreateListingSuccess extends CreateListingState {}

class CreateListingError extends CreateListingState {
  final String message;

  const CreateListingError({required this.message});

  @override
  List<Object?> get props => [message];
}
