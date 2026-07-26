import 'package:equatable/equatable.dart';
import '../../../donation/data/models/donation_model.dart';

abstract class GroupInventoryState extends Equatable {
  const GroupInventoryState();

  @override
  List<Object?> get props => [];
}

class GroupInventoryInitial extends GroupInventoryState {}

class GroupInventoryLoading extends GroupInventoryState {}

class GroupInventoryLoaded extends GroupInventoryState {
  final List<DonationModel> donations;
  final List<InventoryItemModel> items;
  final bool isProcessing;
  final String? publishingItemId;
  final String? actionError;

  const GroupInventoryLoaded({
    required this.donations,
    required this.items,
    this.isProcessing = false,
    this.publishingItemId,
    this.actionError,
  });

  @override
  List<Object?> get props => [
    donations,
    items,
    isProcessing,
    publishingItemId,
    actionError,
  ];
}

class GroupInventoryError extends GroupInventoryState {
  final String message;

  const GroupInventoryError(this.message);

  @override
  List<Object?> get props => [message];
}
