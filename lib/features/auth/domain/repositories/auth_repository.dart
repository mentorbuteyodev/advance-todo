// Abstract auth repository interface.

import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// Stream of auth state changes. Emits null when signed out.
  Stream<UserEntity?> get authStateChanges;

  /// Current user, null if not signed in.
  UserEntity? get currentUser;

  /// Sign in with email and password.
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  });

  /// Register with email and password.
  Future<UserEntity> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  });

  /// Update display name.
  Future<void> updateDisplayName(String name);

  /// Change password.
  Future<void> changePassword(String currentPassword, String newPassword);

  /// Send password reset email.
  Future<void> sendPasswordResetEmail(String email);

  /// Sign out the current user.
  Future<void> signOut();
}
