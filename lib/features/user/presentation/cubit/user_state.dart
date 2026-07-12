import '../../domain/entities/user_entity.dart';

abstract class UserState {
  UserEntity? get userOrNull;
}

class UserInitial extends UserState {
  @override
  UserEntity? get userOrNull => null;
}

class UserLoading extends UserState {
  final UserEntity? previousUser;

  UserLoading({this.previousUser});

  @override
  UserEntity? get userOrNull => previousUser;
}

class UserLoaded extends UserState {
  final UserEntity user;

  UserLoaded({required this.user});

  @override
  UserEntity? get userOrNull => user;
}

class UserError extends UserState {
  final String message;
  final UserEntity? previousUser;

  UserError({required this.message, this.previousUser});

  @override
  UserEntity? get userOrNull => previousUser;
}

class UserUpdating extends UserState {
  final UserEntity currentUser;

  UserUpdating({required this.currentUser});

  @override
  UserEntity? get userOrNull => currentUser;
}

class UserUpdateSuccess extends UserState {
  final UserEntity user;

  UserUpdateSuccess({required this.user});

  @override
  UserEntity? get userOrNull => user;
}

class UserUpdateError extends UserState {
  final String message;
  final UserEntity? previousUser;

  UserUpdateError({required this.message, this.previousUser});

  @override
  UserEntity? get userOrNull => previousUser;
}
