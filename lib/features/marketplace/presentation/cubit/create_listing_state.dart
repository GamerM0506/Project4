import 'package:equatable/equatable.dart';
import '../../domain/entities/category_entity.dart';

abstract class CreateListingState extends Equatable {
  const CreateListingState();

  @override
  List<Object?> get props => [];
}

class CreateListingInitial extends CreateListingState {
  final List<CategoryEntity> categories;
  const CreateListingInitial({this.categories = const []});

  @override
  List<Object?> get props => [categories];
}

class CreateListingLoading extends CreateListingState {}

class CreateListingSuccess extends CreateListingState {}

class CreateListingError extends CreateListingState {
  final String message;

  const CreateListingError({required this.message});

  @override
  List<Object?> get props => [message];
}
