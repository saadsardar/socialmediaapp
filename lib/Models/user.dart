import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  String username;
  String email;
  String photoUrl;
  String displayName;
  String bio;
  int coins;
  bool agreedToTerms;

  User({
    this.id,
    this.username,
    this.email,
    this.photoUrl,
    this.displayName,
    this.bio,
    this.coins,
    this.agreedToTerms,
  });

  factory User.fromDocument(DocumentSnapshot doc) {
    return User(
        id: doc['id'],
        email: doc['email'],
        username: doc['username'],
        photoUrl: doc['photoUrl'],
        displayName: doc['displayName'],
        bio: doc['bio'],
        coins: doc['coins'],
        agreedToTerms: doc['agreedToTerms']);
  }
}
