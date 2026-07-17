import 'package:equatable/equatable.dart';
import '../../domain/entities/listing_entity.dart';

abstract class MarketplaceState extends Equatable {
  const MarketplaceState();
  
  @override
  List<Object?> get props => [];
}

class MarketplaceInitial extends MarketplaceState {}

class MarketplaceLoading extends MarketplaceState {}

class MarketplaceLoaded extends MarketplaceState {
  final List<ListingEntity> listings;

  const MarketplaceLoaded({required this.listings});

  @override
  List<Object?> get props => [listings];
}

class MarketplaceError extends MarketplaceState {
  final String message;

  const MarketplaceError({required this.message});

  @override
  List<Object?> get props => [message];
}
