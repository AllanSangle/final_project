
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/Comment.dart';
import 'package:final_project/Draft.dart';
import 'package:final_project/Tweet.dart';
import 'package:final_project/notification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TweetHeader extends StatelessWidget {
  final Tweet tweet;
  final Function() onHideTweet;

  const TweetHeader({
    Key? key,
    required this.tweet,
    required this.onHideTweet,
  }) : super(key: key);

  void _showHideDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hide Tweet"),
        content: const Text("Would You Like To Hide This Tweet?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              onHideTweet();
              Navigator.of(context).pop();
            },
            child: const Text("Hide"),
          ),
        ],
      ),
    );
  }

  Future<String> fetchProfileImagePath(String userId) async {
    // Fetch the user document from Firestore to get the profile image path
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      return userDoc['profileImagePath'] ?? 'assets/profile.png'; // Default if not found
    } else {
      return 'assets/profile.png'; // Default fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    String timeString = '${tweet.timestamp.hour}:${tweet.timestamp.minute}';

    return FutureBuilder<String>(
      future: fetchProfileImagePath(tweet.userId), // Fetch the profile image path
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator()); // Show loading indicator
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error loading profile image')); // Error handling
        } else if (snapshot.hasData) {
          String profileImagePath = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(
              children: [
                // Profile Image
                CircleAvatar(
                  radius: 20,  // Set a fixed size for the profile image
                  backgroundImage: AssetImage(profileImagePath),  // Use fetched profile image path
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,  // Left-align the text
                    children: [
                      Row(
                        children: [
                          // User Name
                          Text(
                            tweet.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                            ),
                          ),
                          const SizedBox(width: 5.0),
                          // User Email (Display the part before @)
                          Text(
                            '@${tweet.userEmail.split('@')[0]}',
                            style: const TextStyle(color: Colors.grey, fontSize: 14.0),
                          ),
                          const SizedBox(width: 5.0),
                          // Timestamp (hour and minute)
                          Text(
                            '· $timeString',
                            style: const TextStyle(color: Colors.grey, fontSize: 14.0),
                          ),
                          const Spacer(),
                          // More options button (Hide Tweet)
                          IconButton(
                            icon: const Icon(Icons.expand_more, size: 20, color: Colors.grey),
                            onPressed: () => _showHideDialog(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          return const Center(child: Text('No profile image found'));
        }
      },
    );
  }
}



// TweetActions component for handling likes, retweets, etc.
class TweetActions extends StatelessWidget {
  final Tweet tweet;
  final TweetInteractionManager interactions;
  final VoidCallback onBookmark;

  const TweetActions({
    Key? key,
    required this.tweet,
    required this.interactions,
    required this.onBookmark,
  }) : super(key: key);

  Widget _iconWithCount(IconData icon, int count, VoidCallback onPressed, {Color? iconColor}) {
    return Row(
      children: [
        IconButton(
          icon: Icon(icon, color: iconColor ?? Colors.grey),
          onPressed: onPressed,
        ),
        Text(count.toString(), style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 32.0), 
      child: Row(
        children: [
          _iconWithCount(
            Icons.chat_bubble_outline,
            tweet.numComments,
            () => interactions.addComment(context),
          ),
          const SizedBox(width: 20),
          _iconWithCount(
            tweet.isRetweeted ? Icons.repeat : Icons.repeat_outlined,
            tweet.numRetweets,
            interactions.addRetweet,
            iconColor: tweet.isRetweeted ? const Color.fromARGB(255, 25, 129, 28) : Colors.grey,
          ),
          const SizedBox(width: 20),
          _iconWithCount(
            tweet.isLiked ? Icons.favorite : Icons.favorite_border,
            tweet.numLikes,
            interactions.addLike,
            iconColor: tweet.isLiked ? const Color.fromARGB(255, 172, 26, 15) : Colors.grey,
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              tweet.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: tweet.isBookmarked ? const Color.fromARGB(255, 47, 27, 158) : Colors.grey,
            ),
            onPressed: onBookmark,
          ),
        ],
      ),
    );
  }
}


// CommentItem component for individual comments
class CommentItem extends StatelessWidget {
  final Comment comment;

  const CommentItem({
    Key? key,
    required this.comment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 32.0, top: 8.0),
      child: Row(
        children: [
          const CircleAvatar(radius: 15, backgroundColor: Colors.grey),
          const SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      comment.userLongName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 5.0),
                    Text(
                      '@${comment.userShortName}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(width: 5.0),
                    Text(
                      '· ${comment.timestamp.hour}:${comment.timestamp.minute}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                Text(comment.text),
                if (comment.imageURL.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Image.network(
                      comment.imageURL,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TweetDescriptionAndImage extends StatelessWidget {
  final String description;
  final String imageURL;

  const TweetDescriptionAndImage({
    Key? key,
    required this.description,
    required this.imageURL,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 40.0),  // Shift to the right by 16 pixels
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,  // Keep the text left-aligned
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text(description),
          ),
          if (imageURL.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0), // Radius of 12
                child: Image.network(
                  imageURL,
                  width: 200.0,  // Set a width for the image
                  height: 200.0, // Set a height if needed
                  fit: BoxFit.cover,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class TweetImage extends StatefulWidget {
  final Tweet tweet;
  final Function() bookmarkTweet;
  final Function() hideTweet;

  const TweetImage({
    Key? key,
    required this.tweet,
    required this.bookmarkTweet,
    required this.hideTweet,
  }) : super(key: key);

  @override
  _TweetImageState createState() => _TweetImageState();
}

class _TweetImageState extends State<TweetImage> {
  late TweetInteractionManager _interactions;

  @override
  void initState() {
    super.initState();
    _interactions = TweetInteractionManager(
      tweet: widget.tweet,
      setState: setState,
      tweetsRef: tweetsRef,
      commentsRef: commentsRef,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.black,
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TweetHeader(
                tweet: widget.tweet,
                onHideTweet: widget.hideTweet,
              ),
              TweetDescriptionAndImage(
                description: widget.tweet.description,
                imageURL: widget.tweet.imageURL,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TweetActions(
                  tweet: widget.tweet,
                  interactions: _interactions,
                  onBookmark: widget.bookmarkTweet,
                ),
              ),
              CommentsList(comments: widget.tweet.comments),
            ],
          ),
        ),
      ),
    );
  }
}




class CreateNewTweet extends StatefulWidget {
  @override
  _CreateNewTweetState createState() => _CreateNewTweetState();
}

class _CreateNewTweetState extends State<CreateNewTweet> {
  final description = TextEditingController();
  final imageUrl = TextEditingController();
  bool isImageUrlVisible = false;  // Track if the image URL field is visible

  // Function to toggle the visibility of the image URL text field
  void toggleImageUrlField() {
    setState(() {
      isImageUrlVisible = !isImageUrlVisible;
    });
  }

  Timer? _inactivityTimer;

  // Reset inactivity timer
  void resetInactivityTimer() {
    if (_inactivityTimer?.isActive ?? false) {
      _inactivityTimer?.cancel();
    }
    _inactivityTimer = Timer(const Duration(seconds: 20), _triggerPushNotification);
  }

  // Trigger push notification after inactivity
  void _triggerPushNotification() {
    NotificationService.showNotification();
  }

  // Save draft tweet
  Future<void> draftTweet() async {
    final newDraft = Draft(
      description: description.text,
      imageURL: imageUrl.text.isNotEmpty ? imageUrl.text : '',
    );
    await DraftsDatabase.instance.insertDraft(newDraft);

    resetInactivityTimer(); // Reset the timer after saving a draft

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tweet saved as draft')),
    );
  }

  // Create tweet
  Future<void> createTweet() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final newTweet = Tweet(
          userName: user.displayName ?? 'Anonymous',
          userEmail: user.email ?? 'unknown@example.com',
          userId: user.uid,
          timestamp: DateTime.now(),
          description: description.text,
          imageURL: imageUrl.text.isNotEmpty ? imageUrl.text : '',
          numComments: 0,
          numRetweets: 0,
          numLikes: 0,
          isBookmarked: false,
          isLiked: false,
          isRetweeted: false,
          comments: [],
          likedBy: [],
          retweetedBy: [],
        );
        Navigator.of(context).pop(newTweet);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating tweet: ${e.toString()}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User not authenticated')),
      );
    }
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Create New Tweet'),
      backgroundColor: const Color.fromARGB(255, 202, 195, 247),
      foregroundColor: const Color.fromARGB(255, 48, 40, 98),
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color.fromARGB(255, 48, 40, 98), width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(16),
            child: Stack(
              children: [
                Column(
                  children: [
                    // Description text box
                    TextField(
                      controller: description,
                      maxLines: 5, // Makes the text box bigger, allowing more lines
                      decoration: InputDecoration(
                        hintText: 'Today I am feeling..',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: const Color.fromARGB(255, 48, 40, 98), width: 2),
                        ),
                      ),
                    ),
                    if (isImageUrlVisible)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: TextField(
                          controller: imageUrl,
                          decoration: const InputDecoration(hintText: 'Image URL (optional)'),
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: draftTweet,
                          child: const Text('Save as Draft'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: createTweet,
                          child: const Text('Create Tweet'),
                        ),
                      ],
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: IconButton(
                    icon: const Icon(Icons.image),
                    onPressed: () {
                      setState(() {
                        isImageUrlVisible = !isImageUrlVisible; 
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DraftsScreen()),
                  );
                  resetInactivityTimer(); 
                },
                child: const Text('View Previous Drafts'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
}
