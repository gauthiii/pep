import 'package:cloud_firestore/cloud_firestore.dart';

class Pep {
  final String email;
  final Timestamp timestamp;

  Pep({this.email, this.timestamp});

  factory Pep.fromDocument(DocumentSnapshot doc) {
    return Pep(email: doc['email'], timestamp: doc['timestamp']);
  }
}
