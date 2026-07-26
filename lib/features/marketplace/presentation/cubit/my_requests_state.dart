import 'package:equatable/equatable.dart';

import '../../domain/entities/request_entity.dart';

class MyRequestsState extends Equatable {
  final List<RequestEntity> requests;
  final Map<String, String> listingTitles;
  final bool isLoading;
  final String? processingId;
  final String? error;

  const MyRequestsState({
    this.requests = const [],
    this.listingTitles = const {},
    this.isLoading = false,
    this.processingId,
    this.error,
  });

  @override
  List<Object?> get props => [
    requests,
    listingTitles,
    isLoading,
    processingId,
    error,
  ];
}
