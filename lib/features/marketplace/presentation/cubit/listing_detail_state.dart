import 'package:equatable/equatable.dart';
import '../../domain/entities/listing_entity.dart';

abstract class ListingDetailState extends Equatable {
  const ListingDetailState();
  
  @override
  List<Object?> get props => [];
}

class ListingDetailInitial extends ListingDetailState {}

class ListingDetailLoading extends ListingDetailState {}

class ListingDetailLoaded extends ListingDetailState {
  final ListingEntity listing;

  const ListingDetailLoaded({required this.listing});

  @override
  List<Object?> get props => [listing];
}

class ListingDetailError extends ListingDetailState {
  final String message;

  const ListingDetailError({required this.message});

  @override
  List<Object?> get props => [message];
}
