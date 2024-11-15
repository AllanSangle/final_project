import 'package:cloud_firestore/cloud_firestore.dart';

class Users {
  final String? id;  // Changed to String to match Firestore ID
  final String email;
  final String password;
  final String userLongName;
  final String userShortName;
  final DateTime timestamp;

  Users({
    this.id,
    required this.email,
    required this.password,
    required this.userLongName,
    required this.userShortName,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'userLongName': userLongName,
      'userShortName': userShortName,
      'timestamp': Timestamp.fromDate(timestamp),
      // Don't store password in Firestore, use Firebase Auth instead
    };
  }

  static Users fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Users(
      id: doc.id,
      email: data['email'] ?? '',
      password: '',  // Don't store/retrieve password
      userLongName: data['userLongName'] ?? '',
      userShortName: data['userShortName'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}

