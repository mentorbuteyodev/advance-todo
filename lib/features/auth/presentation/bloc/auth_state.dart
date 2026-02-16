// Auth BLoC states.

import 'package:equatable/equatable.dart';

import '../../domain/entities/user_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state before auth check.
class AuthInitial extends AuthState {}

/// Loading auth operation.
class AuthLoading extends AuthState {}

/// User is authenticated.
class Authenticated extends AuthState {
  final UserEntity user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// User is not authenticated.
class Unauthenticated extends AuthState {}

/// Auth error occurred.
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
