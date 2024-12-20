import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/Comment.dart';
import 'package:final_project/main.dart';
import 'package:final_project/TweetPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:final_project/Profile.dart';
import 'package:final_project/SearchTweetsPage.dart';


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
    List<Comment>? comments, // Nullable for explicit assignment
    List<String>? likedBy,   // Nullable for explicit assignment
    List<String>? retweetedBy, // Nullable for explicit assignment
  })  : comments = comments ?? [], // Assign a new list if null
        likedBy = likedBy ?? [],
        retweetedBy = retweetedBy ?? [];

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
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateComment()),
    );

    if (result is Comment) {
      // Set the tweetId for the comment
      final commentToAdd = Comment(
        userLongName: result.userLongName,
        userShortName: result.userShortName,
        timestamp: result.timestamp,
        text: result.text,
        imageURL: result.imageURL,
        userId: result.userId,
        tweetId: tweet.id,
      );

      // Add the comment to Firestore
      await commentsRef.add(commentToAdd.toMap());

      // Update the local tweet object
      tweet.comments.add(commentToAdd);
      tweet.numComments++;

      // Trigger state update
      setState(() {});
    }
  }


Future<void> loadComments() async {
  if (tweet.id == null) return;

  final querySnapshot = await commentsRef
      .where('tweetId', isEqualTo: tweet.id)
      .orderBy('timestamp', descending: false)
      .get();

  setState(() {
    tweet.comments = querySnapshot.docs.map((doc) => Comment.fromDocument(doc)).toList();
  });
}
}

class TweetWidget extends StatefulWidget {
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
    print('Fetched ${querySnapshot.docs.length} tweets from Firestore');

      List<Tweet> loadedTweets = querySnapshot.docs
          .map((doc) {
            try {
              return Tweet.fromDocument(doc);
            } catch (e) {
              print("Error parsing tweet: $e");
              return null;
            }
          })
          .where((tweet) => tweet != null)
          .toList()
          .cast<Tweet>();

      print('Loaded tweets: ${loadedTweets.length}');
      for (var tweet in loadedTweets) {
        await loadComments(tweet);
      }

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
        title: const Text('Recent Tweets', 
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 45, 39, 86),
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 202, 195, 247),
        elevation: 5.0,
        automaticallyImplyLeading: false,
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
        } else if (index == 1) {  
          String _profilePictureUrl = ''; 

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SearchTweetsPage(
                allTweets: tweets, 
                profilePicUrl: _profilePictureUrl,
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
