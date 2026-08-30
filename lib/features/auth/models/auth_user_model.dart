import 'package:cloud_firestore/cloud_firestore.dart';

class AuthUserModel {
  final String uid;
  final String nom;
  final String prenom;
  final String sexe;
  final DateTime dateNaissance;
  final String telephone;
  final String email;
  final String photo;
  final String role;
  final String statut;
  final String adresse;
  final DateTime createdAt;

  const AuthUserModel({
    required this.uid,
    required this.nom,
    required this.prenom,
    required this.sexe,
    required this.dateNaissance,
    required this.telephone,
    required this.email,
    required this.photo,
    required this.role,
    required this.statut,
    required this.adresse,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'prenom': prenom,
      'sexe': sexe,
      'dateNaissance': Timestamp.fromDate(dateNaissance),
      'telephone': telephone,
      'email': email,
      'photo': photo,
      'role': role,
      'statut': statut,
      'adresse': adresse,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AuthUserModel.fromMap(Map<String, dynamic> map, String uid) {
    final Timestamp createdAtTimestamp = map['createdAt'] as Timestamp;
    final Timestamp dateNaissanceTimestamp = map['dateNaissance'] as Timestamp;

    return AuthUserModel(
      uid: uid,
      nom: map['nom'] as String? ?? '',
      prenom: map['prenom'] as String? ?? '',
      sexe: map['sexe'] as String? ?? '',
      dateNaissance: dateNaissanceTimestamp.toDate(),
      telephone: map['telephone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      photo: map['photo'] as String? ?? '',
      role: map['role'] as String? ?? 'patient',
      statut: map['statut'] as String? ?? 'actif',
      adresse: map['adresse'] as String? ?? '',
      createdAt: createdAtTimestamp.toDate(),
    );
  }
}
