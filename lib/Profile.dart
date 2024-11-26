import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:final_project/main.dart';
import 'package:final_project/TweetPage.dart';


final FirebaseAuth _auth = FirebaseAuth.instance;
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  TextEditingController _descriptionController = TextEditingController();
  String? _profilePictureUrl;
  String? _username;
  String? _userEmail;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    final User? user = _auth.currentUser;

    if (user != null) {
      // Fetch user profile data from Firestore
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      setState(() {
        _username = user.displayName;
        _userEmail = user.email;
        _profilePictureUrl = user.photoURL;
        _descriptionController.text = userDoc['description'] ?? '';
      });
    }
  }

  // Save profile data to Firestore
  Future<void> _saveProfileData() async {
    final User? user = _auth.currentUser;

    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'description': _descriptionController.text,
        'username': _username,
      }, SetOptions(merge: true));

      setState(() {
        _isEditing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        backgroundColor: const Color.fromARGB(255, 202, 195, 247),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              child: CircleAvatar(
                radius: 60,
                backgroundImage: _profilePictureUrl != null
                    ? NetworkImage(_profilePictureUrl!)
                    : AssetImage('assets/placeholder_profile.png') as ImageProvider,
                child: _profilePictureUrl == null
                    ? Icon(Icons.add_a_photo, size: 50)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _username ?? 'Loading...',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _userEmail ?? 'Loading...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: "Edit your description",
                border: OutlineInputBorder(),
                enabled: _isEditing,
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'New Tweet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Logout',
          ),
        ],
        onTap: (index) {
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CreateNewTweet()),
            );
          } else if (index == 4) {
            signOut(context);
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage()));
          }
        },
        backgroundColor: const Color.fromARGB(255, 202, 195, 247),
        selectedItemColor: const Color.fromARGB(255, 45, 39, 86),
        unselectedItemColor: const Color.fromARGB(255, 155, 140, 180),
        elevation: 10.0,
      ),
    );
  }
}
