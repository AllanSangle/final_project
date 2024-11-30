import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'Tweet.dart';
import 'main.dart'; // For the signOut function
import 'package:final_project/Profile.dart';
import 'package:final_project/TweetPage.dart';

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
  String searchQuery = '';
  int currentIndex = 1; // Set default to the "Search" tab

  @override
  void initState() {
    super.initState();
    filteredTweets = widget.allTweets;
  }

  void updateSearchResults(String query) {
    setState(() {
      searchQuery = query;

      filteredTweets = widget.allTweets.where((tweet) {
        final tweetContent = tweet.description?.toLowerCase() ?? '';
        final userName = tweet.userName.toLowerCase();
        final searchLower = query.toLowerCase();

        return tweetContent.contains(searchLower) || userName.contains(searchLower);
      }).toList();
    });
  }

  Future<String> fetchProfileImagePath(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      return userDoc.exists ? (userDoc['profileImagePath'] ?? 'assets/profile.png') : 'assets/profile.png';
    } catch (e) {
      return 'assets/profile.png'; // Default fallback on error
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
