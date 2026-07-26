import 'package:equatable/equatable.dart';

import '../../domain/entities/category_entity.dart';
import '../../domain/entities/listing_entity.dart';

class MarketplaceState extends Equatable {
  final List<ListingEntity> listings;
  final List<CategoryEntity> categories;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  const MarketplaceState({
    this.listings = const [],
    this.categories = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.error,
  });

  MarketplaceState copyWith({
    List<ListingEntity>? listings,
    List<CategoryEntity>? categories,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) => MarketplaceState(
    listings: listings ?? this.listings,
    categories: categories ?? this.categories,
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    hasMore: hasMore ?? this.hasMore,
    error: clearError ? null : error ?? this.error,
  );

  @override
  List<Object?> get props => [
    listings,
    categories,
    isLoading,
    isLoadingMore,
    hasMore,
    error,
  ];
}
