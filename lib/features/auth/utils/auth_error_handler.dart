import 'package:firebase_auth/firebase_auth.dart';

class AuthErrorHandler {
  static String parse(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Firebase refuse la création du profil. Vérifiez les règles Firestore.';
        case 'unavailable':
        case 'network-request-failed':
          return 'Firebase est temporairement inaccessible. Vérifiez votre connexion.';
        case 'deadline-exceeded':
          return 'Firebase met trop de temps à répondre. Réessayez.';
      }
    }
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
        case 'invalid-credential':
          return 'Adresse email ou mot de passe incorrect.';
        case 'user-mismatch':
          return 'Adresse email ou mot de passe incorrect.';
        case 'email-already-in-use':
          return 'Cette adresse email est déjà utilisée.';
        case 'weak-password':
          return 'Le mot de passe est trop faible (8 caractères minimum).';
        case 'network-request-failed':
          return 'Firebase Auth est inaccessible depuis ce navigateur. '
              'Vérifiez la connexion, les extensions bloqueuses et le domaine autorisé.';
        case 'operation-not-allowed':
          return 'La connexion par email n’est pas activée dans Firebase.';
        case 'too-many-requests':
          return 'Trop de tentatives, réessayez plus tard.';
        default:
          return 'Erreur Firebase (${error.code}) : ${error.message}';
      }
    }

    return 'Une erreur est survenue. Veuillez réessayer plus tard.';
  }
}
