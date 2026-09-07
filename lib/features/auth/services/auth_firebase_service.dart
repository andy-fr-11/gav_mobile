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
      password: password,
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
    final batch = _firestore.batch();
    final data = userModel.toMap();
    final userRef = _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(userModel.uid);
    batch.set(userRef, data);

    final role = userModel.role.trim().toLowerCase();
    final collection = role == 'patient'
        ? FirebaseConstants.patientsCollection
        : FirebaseConstants.personnelCollection;
    final profileRef = _firestore.collection(collection).doc(userModel.uid);
    batch.set(profileRef, data);
    await batch.commit();
  }

  Future<void> updateUserDocument(AuthUserModel userModel) async {
    final batch = _firestore.batch();
    final data = userModel.toMap();
    final userRef = _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(userModel.uid);
    batch.set(userRef, data, SetOptions(merge: true));

    final role = userModel.role.trim().toLowerCase();
    final targetCollection = role == 'patient'
        ? FirebaseConstants.patientsCollection
        : FirebaseConstants.personnelCollection;
    final targetRef = _firestore
        .collection(targetCollection)
        .doc(userModel.uid);
    batch.set(targetRef, data, SetOptions(merge: true));

    final oldCollection = role == 'patient'
        ? FirebaseConstants.personnelCollection
        : FirebaseConstants.patientsCollection;
    batch.delete(_firestore.collection(oldCollection).doc(userModel.uid));
    await batch.commit();
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
