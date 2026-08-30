import 'package:firebase_auth/firebase_auth.dart';

class AuthErrorHandler {
  static String parse(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'L\'adresse email n\'est pas valide.';
        case 'user-disabled':
          return 'Ce compte a été désactivé.';
        case 'user-not-found':
          return 'Aucun utilisateur trouvé avec cette adresse email.';
        case 'wrong-password':
          return 'Mot de passe incorrect.';
        case 'email-already-in-use':
          return 'Cette adresse email est déjà utilisée.';
        case 'weak-password':
          return 'Le mot de passe est trop faible (8 caractères minimum).';
        case 'network-request-failed':
          return 'Connexion internet introuvable. Vérifiez votre connexion.';
        case 'too-many-requests':
          return 'Trop de tentatives, réessayez plus tard.';
        default:
          return 'Erreur lors de l\'authentification : ${error.message}';
      }
    }

    return 'Une erreur est survenue. Veuillez réessayer plus tard.';
  }
}
