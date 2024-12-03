import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;

  const UserProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _username;
  String? _userEmail;
  String? _profileImagePath;
  String? _description;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(widget.userId).get();

      if (userDoc.exists) {
        setState(() {
          _username = userDoc['username'] ?? 'No username';
          _userEmail = userDoc['email'] ?? 'No email';
          _description = userDoc['description'] ?? 'No description';
          _profileImagePath = userDoc['profileImagePath'] ?? 'assets/profile.png';
        });
      } else {
        setState(() {
          _username = 'User not found';
          _userEmail = 'No email';
          _description = 'No description';
          _profileImagePath = 'assets/profile.png';
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        _username = 'Error loading profile';
        _userEmail = 'Error loading email';
        _description = 'Error loading description';
        _profileImagePath = 'assets/profile.png';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Profile"),
        backgroundColor: const Color.fromARGB(255, 202, 195, 247),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Profile Picture
                CircleAvatar(
                  radius: 60,
                  backgroundImage: _profileImagePath != null
                      ? AssetImage(_profileImagePath!)
                      : const AssetImage('assets/placeholder_profile.png'),
                ),
                const SizedBox(height: 16),
                // Username
                Text(
                  _username ?? 'Loading...',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // User Email
                Text(
                  _userEmail ?? 'Loading...', 
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                // Description Text
                Text(
                  _description ?? 'No description available', 
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
