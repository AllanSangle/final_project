import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'Tweet.dart';
import 'main.dart'; // For the signOut function
import 'package:final_project/Profile.dart';
import 'package:final_project/TweetPage.dart';
import 'package:final_project/OtherUsers.dart';

class SearchTweetsPage extends StatefulWidget {
  final List<Tweet> allTweets;
  final String? profilePicUrl;

  const SearchTweetsPage({Key? key, required this.allTweets, this.profilePicUrl})
      : super(key: key);

  @override
  State<SearchTweetsPage> createState() => _SearchTweetsPageState();
}

class _SearchTweetsPageState extends State<SearchTweetsPage> {
  List<Tweet> filteredTweets = [];
  List<String> userSearchResults = []; // List to store matching usernames
  String searchQuery = '';
  int currentIndex = 1; // Set default to the "Search" tab

  @override
  void initState() {
    super.initState();
    filteredTweets = widget.allTweets;
  }

  // Update search results based on the query
  void updateSearchResults(String query) async {
    setState(() {
      searchQuery = query;
      filteredTweets = widget.allTweets.where((tweet) {
        final tweetContent = tweet.description?.toLowerCase() ?? '';
        final userName = tweet.userName.toLowerCase();
        final searchLower = query.toLowerCase();
        
        // Also search through the tweet descriptions
        return tweetContent.contains(searchLower) || userName.contains(searchLower);
      }).toList();
    });

    // Search for users
    if (query.isNotEmpty) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThan: query + 'z')
          .get();
      setState(() {
        userSearchResults = snapshot.docs.map((doc) => doc['username'] as String).toList();
      });
    } else {
      setState(() {
        userSearchResults = [];
      });
    }
  }

  Future<String> fetchProfileImagePath(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      return userDoc.exists ? (userDoc['profileImagePath'] ?? 'assets/profile.png') : 'assets/profile.png';
    } catch (e) {
      return 'assets/profile.png'; // Default fallback on error
    }
  }

  // Function to handle navigating to the user's profile page
  void navigateToUserProfile(String userName) async {
    try {
      // Query Firestore to get the user document where 'username' matches the provided userName
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: userName)
          .limit(1)  // Assuming usernames are unique, limit the result to 1
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        // Get the userId (document ID) from the first document in the snapshot
        String userId = userSnapshot.docs.first.id;

        // Now navigate to the UserProfilePage and pass the userId
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfilePage(userId: userId), // Pass userId
          ),
        );
      } else {
        // Handle case when no user is found
        print('User with username $userName not found.');
      }
    } catch (e) {
      print('Error retrieving userId: $e');
    }
  }


  void onTabTapped(int index) {
    setState(() {
      currentIndex = index;
    });

    if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => CreateNewTweet()));
    } else if (index == 4) {
      signOut(context);
    } else if (index == 3) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage()));
    } else if (index == 0) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => TweetWidget()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Tweets"),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: updateSearchResults,
            ),
          ),
          // Displaying user search results
          if (searchQuery.isNotEmpty && userSearchResults.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text('Users', style: TextStyle(fontWeight: FontWeight.bold)),
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: userSearchResults.length,
                    itemBuilder: (context, index) {
                      final userName = userSearchResults[index];
                      return ListTile(
                        title: Text(userName),
                        onTap: () => navigateToUserProfile(userName),
                      );
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: filteredTweets.isEmpty
                ? Center(
                    child: Text(
                      searchQuery.isEmpty
                          ? 'Start typing to search tweets'
                          : 'No results found',
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredTweets.length,
                    itemBuilder: (context, index) {
                      final tweet = filteredTweets[index];
                      return FutureBuilder<String>(
                        future: fetchProfileImagePath(tweet.userId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const ListTile(
                              leading: CircularProgressIndicator(),
                              title: Text('Loading...'),
                            );
                          } else if (snapshot.hasError) {
                            return ListTile(
                              leading: const CircleAvatar(
                                backgroundImage: AssetImage('assets/profile.png'),
                              ),
                              title: Text(tweet.userName),
                              subtitle: Text(tweet.description ?? 'No description'),
                            );
                          } else {
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: AssetImage(snapshot.data!),
                              ),
                              title: Text(tweet.userName),
                              subtitle: Text(tweet.description ?? 'No description'),
                            );
                          }
                        },
                      );
                    },
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
