import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Tweet.dart';
import 'main.dart'; // For the signOut function
import 'package:final_project/Profile.dart';
import 'package:final_project/TweetPage.dart';
import 'package:final_project/SearchTweetsPage.dart';


class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _usernameController = TextEditingController();
  String? _profilePictureUrl;
  String? _username;
  String? _userEmail;
  bool _isEditing = false;
  int currentIndex = 3;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      setState(() {
        _username = user.displayName;
        _userEmail = user.email;
        _profilePictureUrl = user.photoURL;
        _descriptionController.text = userDoc['description'] ?? '';
        _usernameController.text = _username ?? '';
      });
    }
  }

  Future<void> _saveProfileData() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'description': _descriptionController.text,
        'username': _usernameController.text,
      }, SetOptions(merge: true));

      setState(() {
        _isEditing = false;
        _username = _usernameController.text;
      });
    }
  }

  void onTabTapped(int index) {
    setState(() {
      currentIndex = index;
    });

    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CreateNewTweet()),
      );
    } else if (index == 4) {
      signOut(context);
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchTweetsPage(
            allTweets: [],
            profilePicUrl: _profilePictureUrl,
          ),
        ),
      );
    } else if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TweetWidget()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: const Color.fromARGB(255, 202, 195, 247),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: _profilePictureUrl != null
                    ? NetworkImage(_profilePictureUrl!)
                    : const AssetImage('assets/placeholder_profile.png')
                        as ImageProvider,
                child: _profilePictureUrl == null
                    ? const Icon(Icons.add_a_photo, size: 50)
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                _username ?? 'Loading...',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _userEmail ?? 'Loading...',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              _isEditing
                  ? TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: "Edit your description",
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                    )
                  : Text(
                      _descriptionController.text,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (_isEditing) {
                      _saveProfileData();
                    }
                    _isEditing = !_isEditing;
                  });
                },
                child: Text(_isEditing ? "Save" : "Edit Profile"),
              ),
            ],
          ),
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
        currentIndex: currentIndex,
        onTap: onTabTapped,
        backgroundColor: const Color.fromARGB(255, 202, 195, 247),
        selectedItemColor: const Color.fromARGB(255, 45, 39, 86),
        unselectedItemColor: const Color.fromARGB(255, 155, 140, 180),
        elevation: 10.0,
      ),
    );
  }
}
