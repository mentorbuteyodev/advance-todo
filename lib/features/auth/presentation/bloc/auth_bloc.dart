// Auth BLoC — manages authentication state.

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription? _authSubscription;

  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<SignInRequested>(_onSignIn);
    on<SignUpRequested>(_onSignUp);
    on<SignOutRequested>(_onSignOut);
    on<UpdateProfileRequested>(_onUpdateProfile);
    on<ChangePasswordRequested>(_onChangePassword);
    on<PasswordResetRequested>(_onPasswordReset);
    on<_InternalAuthChanged>((event, emit) => emit(Authenticated(event.user)));
    on<_InternalAuthCleared>((event, emit) => emit(Unauthenticated()));
  }

  void _onCheckAuthStatus(CheckAuthStatus event, Emitter<AuthState> emit) {
    // Check current user immediately
    final user = _authRepository.currentUser;
    if (user != null) {
      emit(Authenticated(user));
    } else {
      emit(Unauthenticated());
    }

    // Listen to auth state changes for future updates
    _authSubscription?.cancel();
    _authSubscription = _authRepository.authStateChanges.listen((user) {
      if (user != null) {
        if (state is! Authenticated ||
            (state as Authenticated).user.uid != user.uid) {
          add(_InternalAuthChanged(user));
        }
      } else {
        if (state is! Unauthenticated) {
          add(_InternalAuthCleared());
        }
      }
    });
  }

  Future<void> _onSignIn(SignInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signInWithEmail(
        email: event.email,
        password: event.password,
      );
      emit(Authenticated(user));
    } catch (e) {
      print('Sign In Error: $e'); // Log the actual error
      emit(AuthError(_mapError(e)));
    }
  }

  Future<void> _onSignUp(SignUpRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signUpWithEmail(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
      );
      emit(Authenticated(user));
    } catch (e) {
      print('Sign Up Error: $e'); // Log the actual error
      emit(AuthError(_mapError(e)));
    }
  }

  Future<void> _onSignOut(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await _authRepository.signOut();
    emit(Unauthenticated());
  }

  Future<void> _onUpdateProfile(
    UpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.updateDisplayName(event.displayName);
      final user = _authRepository.currentUser;
      if (user != null) {
        emit(Authenticated(user));
      }
    } catch (e) {
      emit(AuthError(_mapError(e)));
    }
  }

  Future<void> _onChangePassword(
    ChangePasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.changePassword(
        event.currentPassword,
        event.newPassword,
      );
      // Optional: Emit a success message or state if UI needs it
      // For now, keeping it simple or maybe re-emit Authenticated to trigger listeners?
    } catch (e) {
      emit(AuthError(_mapError(e)));
    }
  }

  Future<void> _onPasswordReset(
    PasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.sendPasswordResetEmail(event.email);
    } catch (e) {
      emit(AuthError(_mapError(e)));
    }
  }

  String _mapError(dynamic e) {
    if (e is Exception) {
      final msg = e.toString();
      if (msg.contains('user-not-found')) {
        return 'No account found with this email.';
      }
      if (msg.contains('wrong-password')) {
        return 'Incorrect password.';
      }
      if (msg.contains('email-already-in-use')) {
        return 'An account already exists with this email.';
      }
      if (msg.contains('weak-password')) {
        return 'Password is too weak. Use at least 6 characters.';
      }
      if (msg.contains('invalid-email')) {
        return 'Please enter a valid email address.';
      }
      if (msg.contains('invalid-credential')) {
        return 'Invalid email or password.';
      }
      if (msg.contains('network-request-failed')) {
        return 'Network error. Check your connection.';
      }
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}

// ── Internal events (not exposed outside BLoC) ──

class _InternalAuthChanged extends AuthEvent {
  final UserEntity user;
  const _InternalAuthChanged(this.user);

  @override
  List<Object?> get props => [user];
}

class _InternalAuthCleared extends AuthEvent {}
