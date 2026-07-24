import 'package:equatable/equatable.dart';
import '../../domain/entities/listing_entity.dart';
import '../../domain/entities/category_entity.dart';

abstract class MarketplaceState extends Equatable {
  const MarketplaceState();
  
  @override
  List<Object?> get props => [];
}

class MarketplaceInitial extends MarketplaceState {}

class MarketplaceLoading extends MarketplaceState {}

class MarketplaceLoaded extends MarketplaceState {
  final List<ListingEntity> listings;
  final List<CategoryEntity> categories;

  const MarketplaceLoaded({required this.listings, this.categories = const []});

  @override
  List<Object?> get props => [listings, categories];
}

class MarketplaceError extends MarketplaceState {
  final String message;

  const MarketplaceError({required this.message});

  @override
  List<Object?> get props => [message];
}
