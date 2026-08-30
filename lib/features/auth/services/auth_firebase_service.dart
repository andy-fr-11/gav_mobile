import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/firebase_constants.dart';
import '../models/auth_user_model.dart';

class AuthFirebaseService {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthFirebaseService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential> signInWithEmail(String email, String password) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<UserCredential> registerWithEmail(String email, String password) {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<void> createUserDocument(AuthUserModel userModel) async {
    final docRef = _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(userModel.uid);
    await docRef.set(userModel.toMap());
  }

  Future<AuthUserModel> fetchUserProfile(String uid) async {
    final snapshot = await _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(uid)
        .get();

    if (!snapshot.exists || snapshot.data() == null) {
      throw Exception('Utilisateur introuvable');
    }

    return AuthUserModel.fromMap(snapshot.data()!, uid);
  }
}
