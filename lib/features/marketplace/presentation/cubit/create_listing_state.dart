import 'package:equatable/equatable.dart';

abstract class CreateListingState extends Equatable {
  const CreateListingState();

  @override
  List<Object?> get props => [];
}

class CreateListingInitial extends CreateListingState {}

class CreateListingLoading extends CreateListingState {}

class CreateListingSuccess extends CreateListingState {}

class CreateListingError extends CreateListingState {
  final String message;

  const CreateListingError({required this.message});

  @override
  List<Object?> get props => [message];
}
