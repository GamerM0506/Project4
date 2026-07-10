import '../../domain/entities/user_entity.dart';

abstract class UserState {}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserLoaded extends UserState {
  final UserEntity user;
  UserLoaded({required this.user});
}

class UserError extends UserState {
  final String message;
  UserError({required this.message});
}
