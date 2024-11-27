import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:final_project/main.dart';
import 'package:final_project/TweetPage.dart';
import 'package:final_project/SearchTweetsPage.dart'; 

final FirebaseAuth _auth = FirebaseAuth.instance;
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
  bool _isSaved = false; // Flag to track if profile has been saved

  @override
  void initState() {
    super.initState();
    _getUserData(); // Ensure data is loaded when the page is refreshed
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
        _descriptionController.text = userDoc['description'] ?? ''; // Load description from Firestore
        _usernameController.text = _username ?? ''; // Set the username controller
        _isSaved = true; // Mark that the profile has been loaded and saved previously
      });
    }
  }

  // Save profile data to Firestore
  Future<void> _saveProfileData() async {
    final User? user = _auth.currentUser;

    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'description': _descriptionController.text,
        'username': _usernameController.text, // Save edited username
      }, SetOptions(merge: true));

      setState(() {
        _isEditing = false;
        _isSaved = true; // Mark profile as saved
        _username = _usernameController.text; // Update the username state
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
    body: Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Profile Picture
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _profilePictureUrl != null
                          ? NetworkImage(_profilePictureUrl!)
                          : AssetImage('assets/placeholder_profile.png') as ImageProvider,
                      child: _profilePictureUrl == null
                          ? Icon(Icons.add_a_photo, size: 50)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    // User Details (Name and Email stacked vertically)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _username ?? 'Loading...',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _userEmail ?? 'Loading...',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Add space between the profile details and description
                const SizedBox(height: 6), // Adjust this space as needed
                !_isEditing && _isSaved
                    ? Container(
                        padding: const EdgeInsets.all(1.0),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 150),
                        child: Text(
                          _descriptionController.text,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 4,
                          softWrap: true,
                        ),
                      )
                    : Container(),
                const SizedBox(height: 16),
                // Only show the description text field if editing
                _isEditing
                    ? TextField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: "Edit your description",
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 4,
                      )
                    : Container(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        Positioned(
          top: 220.0,
          right: 20.0,
          child: ElevatedButton(
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
        ),
      ],
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
            MaterialPageRoute(builder: (context) => ProfilePage()),
          );
        } else if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SearchTweetsPage(
                allTweets: [],  // Pass your list of tweets here
                profilePicUrl: _profilePictureUrl,  // Pass the profile picture URL
              ),
            ),
          );
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