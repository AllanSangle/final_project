import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _username;
  String? _userEmail;
  String? _profileImagePath; // Path of the selected profile image from assets
  bool _isEditing = false;

  final List<String> _presetImages = [
    'assets/profile1.png',
    'assets/profile2.png',
    'assets/profile3.png',
    'assets/profile4.png',
    'assets/profile5.png',
  ];

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      setState(() {
        _username = user.displayName;
        _userEmail = user.email;
        _descriptionController.text = userDoc['description'] ?? '';
        _usernameController.text = _username ?? '';
        _profileImagePath = userDoc['profileImagePath'] ?? _presetImages.first;
      });
    }
  }

  Future<void> _saveProfileData({String? newProfileImagePath}) async {
    final User? user = _auth.currentUser;

    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'description': _descriptionController.text,
        'username': _usernameController.text,
        if (newProfileImagePath != null) 'profileImagePath': newProfileImagePath,
      }, SetOptions(merge: true));

      if (newProfileImagePath != null) {
        setState(() {
          _profileImagePath = newProfileImagePath;
        });
      }
    }
  }

  void _selectPresetImage() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Choose a Profile Picture",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                itemCount: _presetImages.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () async {
                      final selectedImage = _presetImages[index];
                      await _saveProfileData(newProfileImagePath: selectedImage);
                      Navigator.pop(context); // Close the bottom sheet
                    },
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: AssetImage(_presetImages[index]),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: const Color.fromARGB(255, 202, 195, 247),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Profile Picture with GestureDetector for selecting preset images
                GestureDetector(
                  onTap: _selectPresetImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: _profileImagePath != null
                        ? AssetImage(_profileImagePath!)
                        : const AssetImage('assets/placeholder_profile.png'),
                  ),
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
                // Description Text Field
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: "Your description",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  enabled: _isEditing,
                ),
                const SizedBox(height: 16),
                // Save/Edit Profile Button
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = !_isEditing;
                    });
                    if (!_isEditing) {
                      _saveProfileData();
                    }
                  },
                  child: Text(_isEditing ? "Save" : "Edit Profile"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

