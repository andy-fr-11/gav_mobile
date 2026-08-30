import 'package:flutter/foundation.dart';

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

      if (uid == null) {
        throw Exception('Impossible de récupérer l\'identifiant utilisateur');
      }

      _userProfile = await _repository.fetchUserProfile(uid);
      _status = AuthStatus.authenticated;
    } catch (error) {
      _status = AuthStatus.error;
      _message = AuthErrorHandler.parse(error);
    } finally {
      notifyListeners();
    }
  }

  Future<void> register(AuthUserModel userModel, String password) async {
    _status = AuthStatus.authenticating;
    _message = '';
    notifyListeners();

    try {
      final credentials = await _repository.register(userModel.email, password);
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
      _status = AuthStatus.success;
      _message = 'Compte créé avec succès. Veuillez vous connecter.';
    } catch (error) {
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

    try {
      _userProfile = await _repository.fetchUserProfile(uid);
      _status = AuthStatus.authenticated;
    } catch (_) {
      _status = AuthStatus.error;
      _message = 'Impossible de charger le profil utilisateur.';
    }

    notifyListeners();
  }
}
