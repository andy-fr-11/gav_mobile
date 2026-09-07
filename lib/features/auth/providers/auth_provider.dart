import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/roles.dart';
import '../models/auth_user_model.dart';
import '../repositories/auth_repository.dart';
import '../utils/auth_error_handler.dart';

enum AuthStatus {
  unauthenticated,
  authenticating,
  authenticated,
  success,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  AuthStatus _status = AuthStatus.unauthenticated;
  AuthStatus get status => _status;

  String _message = '';
  String get message => _message;

  AuthUserModel? _userProfile;
  AuthUserModel? get userProfile => _userProfile;

  UserRole get currentRole => UserRoleHelper.normalize(_userProfile?.role);

  AuthProvider({AuthRepository? repository})
    : _repository = repository ?? AuthRepository();

  Future<void> initialize() async {
    if (_repository.currentUser != null) {
      await loadUserProfile();
    }
  }

  bool get isAuthenticated => _repository.currentUser != null;

  Future<void> login(String email, String password) async {
    _status = AuthStatus.authenticating;
    _message = '';
    notifyListeners();

    try {
      final credentials = await _repository.login(email, password);
      final uid = credentials.user?.uid;

      if (kDebugMode) {
        debugPrint('AuthProvider.login: signed in uid=$uid');
      }

      if (uid == null) {
        throw Exception('Impossible de récupérer l\'identifiant utilisateur');
      }

      try {
        _userProfile = await _repository.fetchUserProfile(uid);
      } catch (_) {
        // Do not create a fallback dummy profile. Leave profile null so UI
        // can prompt the user to complete their profile instead of showing test data.
        _userProfile = null;
        _message = 'Profil utilisateur absent. Complétez votre profil.';
      }

      _status = AuthStatus.authenticated;
      _message = '';
    } catch (error) {
      _status = AuthStatus.error;
      _message = AuthErrorHandler.parse(error);
      if (kDebugMode) {
        debugPrint('AuthProvider.login error: $error');
      }
    } finally {
      if (kDebugMode) {
        debugPrint(
          'AuthProvider.login: status=$_status, userProfile=${_userProfile?.toMap()}',
        );
      }
      notifyListeners();
    }
  }

  Future<void> register(AuthUserModel userModel, String password) async {
    _status = AuthStatus.authenticating;
    _message = '';
    notifyListeners();

    UserCredential? credentials;
    try {
      credentials = await _repository.register(userModel.email, password);
      final uid = credentials.user?.uid;

      if (uid == null) {
        throw Exception('Impossible de récupérer l\'identifiant utilisateur');
      }

      final profile = AuthUserModel(
        uid: uid,
        nom: userModel.nom,
        prenom: userModel.prenom,
        sexe: userModel.sexe,
        dateNaissance: userModel.dateNaissance,
        telephone: userModel.telephone,
        email: userModel.email,
        photo: userModel.photo,
        role: userModel.role,
        statut: userModel.statut,
        adresse: userModel.adresse,
        createdAt: DateTime.now(),
      );

      await _repository.saveUserProfile(profile);
      // Firebase signs the new account in automatically. End that session so
      // the registration flow can return to login and load the profile there.
      await _repository.logout();
      _status = AuthStatus.success;
      _message = 'Compte créé avec succès. Veuillez vous connecter.';
    } catch (error) {
      if (credentials?.user != null) {
        try {
          await credentials!.user!.delete();
        } catch (_) {
          await _repository.logout();
        }
      }
      _status = AuthStatus.error;
      _message = AuthErrorHandler.parse(error);
    } finally {
      notifyListeners();
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    _status = AuthStatus.authenticating;
    _message = '';
    notifyListeners();

    try {
      await _repository.sendPasswordReset(email);
      _status = AuthStatus.success;
      _message = 'Lien de réinitialisation envoyé. Vérifiez votre boîte mail.';
    } catch (error) {
      _status = AuthStatus.error;
      _message = AuthErrorHandler.parse(error);
    } finally {
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    _userProfile = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> loadUserProfile() async {
    final uid = _repository.currentUser?.uid;
    if (uid == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    if (kDebugMode) {
      debugPrint('AuthProvider.loadUserProfile: loading uid=$uid');
    }

    try {
      _userProfile = await _repository.fetchUserProfile(uid);
      _status = AuthStatus.authenticated;
      _message = '';
    } catch (_) {
      // If no Firestore profile exists, leave it null so the UI shows
      // a clear CTA to complete the profile instead of seeded test data.
      _userProfile = null;
      _status = AuthStatus.authenticated;
      _message = 'Complétez votre profil pour activer votre tableau de bord.';
    }

    notifyListeners();
    if (kDebugMode) {
      debugPrint(
        'AuthProvider.loadUserProfile: loaded userProfile=${_userProfile?.toMap()}',
      );
    }
  }

  Future<void> updateUserProfile(AuthUserModel userModel) async {
    try {
      await _repository.updateUserProfile(userModel);
      _userProfile = userModel;
      if (kDebugMode) {
        debugPrint(
          'AuthProvider.updateUserProfile: updated ${userModel.toMap()}',
        );
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('AuthProvider.updateUserProfile: error $e');
      rethrow;
    }
  }
}
