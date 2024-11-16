import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/Comment.dart';
import 'package:final_project/main.dart';
import 'package:final_project/TweetPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';


final tweetsRef = FirebaseFirestore.instance.collection('tweets');

class Tweet {
  String? id;
  final String userName;
  final String userEmail;
  final String userId;
  final DateTime timestamp;
  final String description;
  final String imageURL;
  int numComments;
  int numRetweets;
  int numLikes;
  bool isBookmarked;
  bool isLiked;
  bool isRetweeted;
  List<Comment> comments;
  List<String> likedBy;
  List<String> retweetedBy;

  Tweet({
    this.id,
    required this.userName,
    required this.userEmail,
    required this.userId,
    required this.timestamp,
    required this.description,
    required this.imageURL,
    this.numComments = 0,
    this.numRetweets = 0,
    this.numLikes = 0,
    this.isBookmarked = false,
    this.isLiked = false,
    this.isRetweeted = false,
    this.comments = const [],
    this.likedBy = const [],
    this.retweetedBy = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'userName': userName,
      'userEmail': userEmail,
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      'description': description,
      'imageURL': imageURL,
      'numComments': numComments,
      'numRetweets': numRetweets,
      'numLikes': numLikes,
      'isBookmarked': isBookmarked,
      'isLiked': isLiked,
      'isRetweeted': isRetweeted,
      'likedBy': likedBy,
      'retweetedBy': retweetedBy,
    };
    
  }
    factory Tweet.fromJson(Map<String, dynamic> json) {
    return Tweet(
      id: json['id'],
      userName: json['userName'],
      userEmail: json['userEmail'],
      userId: json['userId'],
      timestamp: DateTime.parse(json['timestamp']), // Assuming timestamp is a string
      description: json['description'],
      imageURL: json['imageURL'],
      numComments: json['numComments'] ?? 0,
      numRetweets: json['numRetweets'] ?? 0,
      numLikes: json['numLikes'] ?? 0,
      isBookmarked: json['isBookmarked'] ?? false,
      isLiked: json['isLiked'] ?? false,
      isRetweeted: json['isRetweeted'] ?? false,
    
      likedBy: List<String>.from(json['likedBy'] ?? []),
      retweetedBy: List<String>.from(json['retweetedBy'] ?? []),
    );
  }
    Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': userName,
      'userEmail': userEmail,
      'userId': userId,
      'timestamp': timestamp.toIso8601String(),
      'description': description,
      'imageURL': imageURL,
      'numComments': numComments,
      'numRetweets': numRetweets,
      'numLikes': numLikes,
      'isBookmarked': isBookmarked,
      'isLiked': isLiked,
      'isRetweeted': isRetweeted,
      'comments': comments,
      'likedBy': likedBy,
      'retweetedBy': retweetedBy,
    };
  }

  static Tweet fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Tweet(
      id: doc.id,
      userName: data['userName'] ?? 'Anonymous',
      userEmail: data['userEmail'] ?? 'unknown@example.com',
      userId: data['userId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: data['description'] ?? '',
      imageURL: data['imageURL'] ?? '',
      numComments: data['numComments'] ?? 0,
      numRetweets: data['numRetweets'] ?? 0,
      numLikes: data['numLikes'] ?? 0,
      isBookmarked: data['isBookmarked'] ?? false,
      isLiked: data['isLiked'] ?? false,
      isRetweeted: data['isRetweeted'] ?? false,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      retweetedBy: List<String>.from(data['retweetedBy'] ?? []),
    );
  }
}

class TweetInteractionManager {
  final Tweet tweet;
  final Function setState;
  final CollectionReference tweetsRef;
  final CollectionReference commentsRef;

  TweetInteractionManager({
    required this.tweet,
    required this.setState,
    required this.tweetsRef,
    required this.commentsRef,
  });


  Future<void> addLike() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && tweet.id != null) {
      setState(() {
        tweet.isLiked = !tweet.isLiked;
        if (tweet.isLiked) {
          tweet.likedBy.add(user.uid);
          tweet.numLikes++;
        } else {
          tweet.likedBy.remove(user.uid);
          tweet.numLikes--;
        }
      });
      await tweetsRef.doc(tweet.id).update({
        'isLiked': tweet.isLiked,
        'numLikes': tweet.numLikes,
        'likedBy': tweet.likedBy,
      });
      
    }
  }

  Future<void> addRetweet() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && tweet.id != null) {
      setState(() {
        tweet.isRetweeted = !tweet.isRetweeted;
        if (tweet.isRetweeted) {
          tweet.retweetedBy.add(user.uid);
          tweet.numRetweets++;
        } else {
          tweet.retweetedBy.remove(user.uid);
          tweet.numRetweets--;
        }
      });
      await tweetsRef.doc(tweet.id).update({
        'isRetweeted': tweet.isRetweeted,
        'numRetweets': tweet.numRetweets,
        'retweetedBy': tweet.retweetedBy,
      });
      
    }
  }

  Future<void> addComment(BuildContext context) async {
    final reply = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateComment(),
      ),
    );
    
    if (reply != null && tweet.id != null) {
      reply.tweetId = tweet.id;
      final docRef = await commentsRef.add(reply.toMap());
      reply.id = docRef.id;
      
      setState(() {
        tweet.comments.add(reply);
        tweet.numComments++;
      });
      
      await tweetsRef.doc(tweet.id).update({
        'numComments': tweet.numComments,
      });
      
      
    }
  }
}

class TweetWidget extends StatefulWidget 
{
  const TweetWidget({super.key});

  @override
  _TweetWidgetState createState() => _TweetWidgetState();
}

class _TweetWidgetState extends State<TweetWidget> {
  List<Tweet> tweets = [];
  List<Tweet> filteredTweets = [];
  TextEditingController searchController = TextEditingController();

  
  @override
  void initState() {
    super.initState();
    loadTweets();
  }

 Future<void> loadTweets() async {
  try {
    final querySnapshot = await tweetsRef.orderBy('timestamp', descending: true).get();

    // Parse tweets and handle possible null/malformed documents
    List<Tweet> loadedTweets = querySnapshot.docs
        .map((doc) {
          try {
            return Tweet.fromDocument(doc);
          } catch (e) {
            print("Error parsing tweet: $e");
            return null; // Skip malformed tweet
          }
        })
        .where((tweet) => tweet != null) // Filter out null tweets
        .toList()
        .cast<Tweet>();

    // Load comments for each valid tweet
    for (var tweet in loadedTweets) {
      await loadComments(tweet); // Wait for each comment load to complete
    }

    // Update state with the loaded tweets
    setState(() {
      tweets = loadedTweets;
    });
  } catch (e) {
    print("Error loading tweets: $e");
  }
}

  Future<void> loadComments(Tweet tweet) async {
    final querySnapshot = await commentsRef
        .where('tweetId', isEqualTo: tweet.id)
        .orderBy('timestamp', descending: false)
        .get();
    
    setState(() {
      tweet.comments = querySnapshot.docs.map((doc) => Comment.fromDocument(doc)).toList();
    });
  }

  Future<void> newTweet(Tweet tweet) async {
    final docRef = await tweetsRef.add(tweet.toMap());
    tweet.id = docRef.id;
    setState(() {
      tweets.insert(0, tweet);
    });
  }
    void favouriteTweet(Tweet tweet) 
  {
    setState(() 
    {
      tweet.isBookmarked = !tweet.isBookmarked;
      tweets.sort((a, b) 
      {
        if (a.isBookmarked && !b.isBookmarked) return -1;
        if (!a.isBookmarked && b.isBookmarked) return 1;
        return 0;
      });
    });
  }

  Future<void> updateTweet(Tweet tweet) async {
    if (tweet.id != null) {
      await tweetsRef.doc(tweet.id).update(tweet.toMap());
    }
  }

  Future<void> removeTweet(int index) async {
    final tweet = tweets[index];
    if (tweet.id != null) {
      await tweetsRef.doc(tweet.id).delete();
      final commentSnapshot = await commentsRef.where('tweetId', isEqualTo: tweet.id).get();
      for (var doc in commentSnapshot.docs) {
        await doc.reference.delete();
      }
    }
    setState(() {
      tweets.removeAt(index);
    });
  }
   void _filterTweets() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredTweets = tweets
          .where((tweet) => tweet.description.toLowerCase().contains(query)) // Filter based on tweet content
          .toList();
    });
  }


 @override
Widget build(BuildContext context) {
   return Scaffold(
      appBar: AppBar(
        title: const Text('Blog Demo alpha-V.1'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Navigate to the search page when the search button is tapped
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchPage(tweets: tweets),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => signOut(context),
          ),
        ],
      ),
    body: StreamBuilder<QuerySnapshot>(
      stream: tweetsRef.orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final tweets = snapshot.data?.docs.map((doc) => Tweet.fromDocument(doc)).toList() ?? [];

        return ListView.builder(
          itemCount: tweets.length,
          itemBuilder: (context, index) {
            final tweet = tweets[index];
            return TweetImage(
              tweet: tweet,
              bookmarkTweet: () => favouriteTweet(tweet),
              hideTweet: () => removeTweet(index),
            );
          },
        );
      },
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () async {
        final tweet = await Navigator.push<Tweet>(
          context,
          MaterialPageRoute(builder: (context) => CreateNewTweet()),
        );
        if (tweet != null) {
          await newTweet(tweet);
        }
      },
      child: const Icon(Icons.add),
    ),
  );
}
}

class SearchPage extends StatefulWidget {
  final List<Tweet> tweets;

  const SearchPage({Key? key, required this.tweets}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController searchController = TextEditingController();
  List<Tweet> filteredTweets = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    filteredTweets = widget.tweets;
    searchController.addListener(_filterTweets);
  }

  @override
  void dispose() {
    searchController.removeListener(_filterTweets);
    searchController.dispose();
    super.dispose();
  }

  void _filterTweets() {
    String query = searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      _fetchUserTweets(query);
    } else {
      setState(() {
        filteredTweets = widget.tweets;
      });
    }
  }

  Future<void> _fetchUserTweets(String username) async {
    setState(() {
      isLoading = true;
    });

    final url = 'https://api.example.com/tweets?username=$username'; // Replace with your API endpoint

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> tweetList = json.decode(response.body);
        setState(() {
          filteredTweets = tweetList
              .map((tweetData) => Tweet.fromJson(tweetData))
              .toList();
        });
      } else {
        // Handle error
        print('Failed to load tweets');
      }
    } catch (e) {
      print('Error fetching tweets: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Tweets'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search by username...',
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          if (isLoading)
            const Center(child: CircularProgressIndicator()),
          Expanded(
            child: ListView.builder(
              itemCount: filteredTweets.length,
              itemBuilder: (context, index) {
                final tweet = filteredTweets[index];
                return TweetImage(
                  tweet: tweet,
                  bookmarkTweet: () => print("Bookmark tweet"),
                  hideTweet: () => print("Hide tweet"),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}