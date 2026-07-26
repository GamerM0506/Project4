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
  final bool hasRequested;

  const ListingDetailLoaded({required this.listing, this.hasRequested = false});

  @override
  List<Object?> get props => [listing, hasRequested];
}

class ListingRequestSubmitting extends ListingDetailState {
  final ListingEntity listing;
  final bool hasRequested;

  const ListingRequestSubmitting({
    required this.listing,
    this.hasRequested = false,
  });

  @override
  List<Object?> get props => [listing, hasRequested];
}

class ListingRequestSuccess extends ListingDetailState {
  final ListingEntity listing;
  final bool hasRequested;

  const ListingRequestSuccess({
    required this.listing,
    this.hasRequested = true,
  });

  @override
  List<Object?> get props => [listing, hasRequested];
}

class ListingRequestFailure extends ListingDetailState {
  final ListingEntity listing;
  final String message;
  final bool hasRequested;

  const ListingRequestFailure({
    required this.listing,
    required this.message,
    this.hasRequested = false,
  });

  @override
  List<Object?> get props => [listing, message, hasRequested];
}

class ListingDetailError extends ListingDetailState {
  final String message;

  const ListingDetailError({required this.message});

  @override
  List<Object?> get props => [message];
}
