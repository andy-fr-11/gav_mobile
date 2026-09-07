import 'package:firebase_auth/firebase_auth.dart';

import '../models/auth_user_model.dart';
import '../services/auth_firebase_service.dart';

class AuthRepository {
  final AuthFirebaseService _firebaseService;

  AuthRepository({AuthFirebaseService? firebaseService})
    : _firebaseService = firebaseService ?? AuthFirebaseService();

  Stream<User?> get authStateChanges => _firebaseService.authStateChanges();
  User? get currentUser => _firebaseService.currentUser;

  Future<UserCredential> login(String email, String password) {
    return _firebaseService.signInWithEmail(email, password);
  }

  Future<UserCredential> register(String email, String password) {
    return _firebaseService.registerWithEmail(email, password);
  }

  Future<void> sendPasswordReset(String email) {
    return _firebaseService.sendPasswordResetEmail(email);
  }

  Future<void> logout() {
    return _firebaseService.signOut();
  }

  Future<void> saveUserProfile(AuthUserModel userModel) {
    return _firebaseService.createUserDocument(userModel);
  }

  Future<void> updateUserProfile(AuthUserModel userModel) {
    return _firebaseService.updateUserDocument(userModel);
  }

  Future<AuthUserModel> fetchUserProfile(String uid) {
    return _firebaseService.fetchUserProfile(uid);
  }
}
