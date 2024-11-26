import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/Comment.dart';
import 'package:final_project/main.dart';
import 'package:final_project/TweetPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
  List<Comment> comments; // Change this line

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
    List<Comment>? comments, 
    this.likedBy = const [],
    this.retweetedBy = const [],
  }) : comments = comments ?? []; 

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
        // Create a new list with existing comments and the new comment
        tweet.comments = List<Comment>.from(tweet.comments)..add(reply);
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
    try {
      // Query the comments collection to fetch comments related to the tweet
      final querySnapshot = await commentsRef
          .where('tweetId', isEqualTo: tweet.id) // Match comments with the tweet ID
          .orderBy('timestamp', descending: false) // Sort comments by timestamp in ascending order
          .get();

      // Map the query snapshot to a list of Comment objects
      final comments = querySnapshot.docs.map((doc) {
        try {
          return Comment.fromDocument(doc); // Parse each comment document
        } catch (e) {
          print("Error parsing comment: $e");
          return null; // Skip malformed comments
        }
      }).where((comment) => comment != null).toList().cast<Comment>();

      // Update the tweet object with the loaded comments
      setState(() {
        tweet.comments = comments;
      });
    } catch (e) {
      print("Error loading comments for tweet with ID ${tweet.id}: $e");
    }
  }

  Future<void> newTweet(Tweet tweet) async {
    final docRef = await tweetsRef.add(tweet.toMap());
    tweet.id = docRef.id;
    setState(() {
      tweets.insert(0, tweet);
    });
  }

  void favouriteTweet(Tweet tweet) {
    setState(() {
      tweet.isBookmarked = !tweet.isBookmarked;
      tweets.sort((a, b) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Blog Demo alpha-V.1',
          style: TextStyle(
            fontSize: 24, // Set the font size
            fontWeight: FontWeight.bold, // Make the font bold
            color: Color.fromARGB(255, 45, 39, 86), // Set the text color
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 202, 195, 247), // Set the background color
        elevation: 5.0, // Add some elevation for shadow effect
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color.fromARGB(255, 45, 39, 86)), // Set icon color
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
        backgroundColor: const Color.fromARGB(255, 202, 195, 247), // Set FAB background color
      ),
    );
  }
}