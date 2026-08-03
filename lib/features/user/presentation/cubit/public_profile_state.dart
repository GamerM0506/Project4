import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

enum PublicProfileStatus { initial, loading, loaded, error }

class PublicProfileState extends Equatable {
  final PublicProfileStatus status;
  final UserEntity? user;
  final String? errorMessage;

  const PublicProfileState({
    this.status = PublicProfileStatus.initial,
    this.user,
    this.errorMessage,
  });

  PublicProfileState copyWith({
    PublicProfileStatus? status,
    UserEntity? user,
    String? errorMessage,
  }) {
    return PublicProfileState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage];
}
