import 'package:equatable/equatable.dart';
import '../../../marketplace/domain/entities/listing_entity.dart';

abstract class GroupInventoryState extends Equatable {
  const GroupInventoryState();

  @override
  List<Object?> get props => [];
}

class GroupInventoryInitial extends GroupInventoryState {}

class GroupInventoryLoading extends GroupInventoryState {}

class GroupInventoryLoaded extends GroupInventoryState {
  final List<ListingEntity> items;

  const GroupInventoryLoaded(this.items);

  @override
  List<Object?> get props => [items];
}

class GroupInventoryError extends GroupInventoryState {
  final String message;

  const GroupInventoryError(this.message);

  @override
  List<Object?> get props => [message];
}
