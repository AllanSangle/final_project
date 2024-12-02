

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/Comment.dart';
import 'package:final_project/Tweet.dart';
import 'package:final_project/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:final_project/TweetPage.dart';

final tweetsRef = FirebaseFirestore.instance.collection('tweets');
final commentsRef = FirebaseFirestore.instance.collection('comments');

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
    setState(() {
      tweet.isLiked = !tweet.isLiked;
      tweet.numLikes += tweet.isLiked ? 1 : -1;
    });
    await tweetsRef.doc(tweet.id).update({
      'isLiked': tweet.isLiked,
      'numLikes': tweet.numLikes,
    });
  }

  Future<void> addRetweet() async {
    setState(() {
      tweet.isRetweeted = !tweet.isRetweeted;
      tweet.numRetweets += tweet.isRetweeted ? 1 : -1;
    });
    await tweetsRef.doc(tweet.id).update({
      'isRetweeted': tweet.isRetweeted,
      'numRetweets': tweet.numRetweets,
    });
  }

  Future<void> addComment(BuildContext context) async {
    final reply = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateComment(),
      ),
    );
    
    if (reply != null) {
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
   bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTweets();
  }
Future<void> loadTweets() async {
  setState(() {
    _isLoading = true; // Start the loading indicator
  });

  try {
    // Simulate a 3-second delay
    await Future.delayed(const Duration(seconds: 3));

    final querySnapshot = await tweetsRef.orderBy('timestamp', descending: true).get();

    // Load comments for each tweet
    final loadedTweets = await Future.wait(
      querySnapshot.docs.map((doc) async {
        final tweet = Tweet.fromDocument(doc);
        await loadComments(tweet);
        return tweet;
      }),
    );

    if (mounted) {
      setState(() {
        tweets = loadedTweets;
        _isLoading = false; // Stop the loading indicator
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _isLoading = false; // Stop the loading indicator
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error loading tweets: ${e.toString()}')),
    );
  }
}

  // Load tweets from Firebase


  // Load comments for a specific tweet
Future<void> loadComments(Tweet tweet) async {
  final querySnapshot = await commentsRef
      .where('tweetId', isEqualTo: tweet.id)
      .orderBy('timestamp', descending: false)
      .get();

  if (mounted) {
    setState(() {
      tweet.comments = querySnapshot.docs.map((doc) => Comment.fromDocument(doc)).toList();
    });
  }
}
  // Add new tweet to Firebase
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


  // Update tweet in Firebase
  Future<void> updateTweet(Tweet tweet) async {
    if (tweet.id != null) {
      await tweetsRef.doc(tweet.id).update(tweet.toMap());
    }
  }

  // Remove tweet from Firebase
  Future<void> removeTweet(int index) async {
    final tweet = tweets[index];
    if (tweet.id != null) {
      await tweetsRef.doc(tweet.id).delete();
      // Delete associated comments
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
        title: const Text('Twitter Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => signOut(context),
          ),
        ],
      ),
      body: _isLoading 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading Tweets...', style: TextStyle(fontSize: 16)),
              ],
            ),
          )
        : tweets.isEmpty
          ? Center(child: Text('No tweets found'))
          : ListView.builder(
              itemCount: tweets.length,
              itemBuilder: (context, index) {
                final tweet = tweets[index];
                return TweetImage(
                  tweet: tweet,
                  bookmarkTweet: () => favouriteTweet(tweet),
                  hideTweet: () => removeTweet(index),
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