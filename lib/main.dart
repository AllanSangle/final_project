import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:final_project/firebase_options.dart';


void main() async
{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);
  runApp(const MaterialApp(home: TweetWidget()));
}

final tweetsRef = FirebaseFirestore.instance.collection('tweets');
final commentsRef = FirebaseFirestore.instance.collection('comments');


class Tweet {
  String? id; // Add ID field for Firebase
  final String userLongName;
  final String userShortName;
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

  Tweet({
    this.id,
    required this.userLongName,
    required this.userShortName,
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
  });

  // Convert Tweet to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'userLongName': userLongName,
      'userShortName': userShortName,
      'timestamp': timestamp,
      'description': description,
      'imageURL': imageURL,
      'numComments': numComments,
      'numRetweets': numRetweets,
      'numLikes': numLikes,
      'isBookmarked': isBookmarked,
      'isLiked': isLiked,
      'isRetweeted': isRetweeted,
    };
  }

  // Create Tweet from Firebase document
  static Tweet fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Tweet(
      id: doc.id,
      userLongName: data['userLongName'],
      userShortName: data['userShortName'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      description: data['description'],
      imageURL: data['imageURL'],
      numComments: data['numComments'],
      numRetweets: data['numRetweets'],
      numLikes: data['numLikes'],
      isBookmarked: data['isBookmarked'],
      isLiked: data['isLiked'],
      isRetweeted: data['isRetweeted'],
    );
  }
}


class TweetImage extends StatefulWidget 
{
  final Tweet tweet;
  final Function() bookmarkTweet;
  final Function() hideTweet;

  const TweetImage
  ({
    Key key = const Key(""), 
    required this.tweet,
    required this.bookmarkTweet,
    required this.hideTweet,
  }) : super(key: key);

  @override
  _TweetImageState createState() => _TweetImageState();
}

class _TweetImageState extends State<TweetImage> {
  Future<void> addLike() async {
    setState(() {
      widget.tweet.isLiked = !widget.tweet.isLiked;
      widget.tweet.numLikes += widget.tweet.isLiked ? 1 : -1;
    });
    await tweetsRef.doc(widget.tweet.id).update({
      'isLiked': widget.tweet.isLiked,
      'numLikes': widget.tweet.numLikes,
    });
  }

  Future<void> addRetweet() async {
    setState(() {
      widget.tweet.isRetweeted = !widget.tweet.isRetweeted;
      widget.tweet.numRetweets += widget.tweet.isRetweeted ? 1 : -1;
    });
    await tweetsRef.doc(widget.tweet.id).update({
      'isRetweeted': widget.tweet.isRetweeted,
      'numRetweets': widget.tweet.numRetweets,
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
      reply.tweetId = widget.tweet.id;
      final docRef = await commentsRef.add(reply.toMap());
      reply.id = docRef.id;
      
      setState(() {
        widget.tweet.comments.add(reply);
        widget.tweet.numComments++;
      });
      
      await tweetsRef.doc(widget.tweet.id).update({
        'numComments': widget.tweet.numComments,
      });
    }
  }

  void hideTweetDialog(BuildContext context) 
  {
    showDialog(
      context: context,
      builder: (context) 
      {
        return AlertDialog(
          title: const Text("Hide Tweet"),
          content: const Text("Would You Like To Hide This Tweet?"),
          actions: [
            TextButton(
              onPressed: () 
              {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () 
              {
                widget.hideTweet();
                Navigator.of(context).pop();
              },
              child: const Text("Hide"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) 
  {
    String timeString = '${widget.tweet.timestamp.hour}:${widget.tweet.timestamp.minute}';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 15, backgroundColor: Colors.grey),
              const SizedBox(width: 8.0),
              Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Row(
                        children: [
                          Text(
                            widget.tweet.userLongName, 
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 5.0),
                          Text(
                            '@${widget.tweet.userShortName}', 
                            style: const TextStyle(color: Colors.grey)),
                          const SizedBox(width: 5.0),
                          Text(
                            '· $timeString', 
                            style: const TextStyle(color: Colors.grey)),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.expand_more, size: 15, color: Colors.grey),
                            onPressed: () => hideTweetDialog(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(widget.tweet.description),
          ),
          Image.network(widget.tweet.imageURL, width: double.infinity, fit: BoxFit.fitWidth),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                iconWithCount(Icons.chat_bubble_outline, widget.tweet.numComments, () => addComment(context)),
                const SizedBox(width: 20),
                iconWithCount(
                  widget.tweet.isRetweeted ? Icons.repeat : Icons.repeat_outlined,
                  widget.tweet.numRetweets,
                  addRetweet,
                  iconColor: widget.tweet.isRetweeted ? const Color.fromARGB(255, 25, 129, 28) : Colors.grey,
                ),
                const SizedBox(width: 20),
                iconWithCount(
                  widget.tweet.isLiked ? Icons.favorite : Icons.favorite_border,
                  widget.tweet.numLikes,
                  addLike,
                  iconColor: widget.tweet.isLiked ? const Color.fromARGB(255, 172, 26, 15) : Colors.grey,
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    widget.tweet.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: widget.tweet.isBookmarked ? const Color.fromARGB(255, 47, 27, 158) : Colors.grey,
                  ),
                  onPressed: widget.bookmarkTweet,
                ),
              ],
            ),
          ),

        for (var comment in widget.tweet.comments) 
          Padding(
            padding: const EdgeInsets.only(left: 32.0, top: 8.0),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.grey,
                ),
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
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 5.0),
                          Text(
                            '@${comment.userShortName}', 
                            style: const TextStyle(color: Colors.grey)),
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
          ),
        ],
      ),
    );
  }

  Widget iconWithCount(IconData icon, int count, VoidCallback onPressed, {Color? iconColor}) 
  {
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

  // Load tweets from Firebase
  Future<void> loadTweets() async {
    final querySnapshot = await tweetsRef.orderBy('timestamp', descending: true).get();
    setState(() {
      tweets = querySnapshot.docs.map((doc) => Tweet.fromDocument(doc)).toList();
      
      // Load comments for each tweet
      for (var tweet in tweets) {
        loadComments(tweet);
      }
    });
  }

  // Load comments for a specific tweet
  Future<void> loadComments(Tweet tweet) async {
    final querySnapshot = await commentsRef
        .where('tweetId', isEqualTo: tweet.id)
        .orderBy('timestamp', descending: false)
        .get();
    
    setState(() {
      tweet.comments = querySnapshot.docs.map((doc) => Comment.fromDocument(doc)).toList();
    });
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
  Widget build(BuildContext context) 
  {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Twitter Demo'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async 
              {
                final newTweet = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreateNewTweet()),
                );
                if (newTweet != null) 
                {
                  this.newTweet(newTweet);
                }
              },
            ),
          ],
        ),
        body: ListView.builder(
          itemCount: tweets.length,
          itemBuilder: (context, index) 
          {
            final tweet = tweets[index];
            return TweetImage(
              tweet: tweet,
              bookmarkTweet: () => favouriteTweet(tweet),
              hideTweet: () => removeTweet(index),
            );
          },
        ),
      ),
    );
  }
}
class Comment {
  String? id; // Add ID field for Firebase
  String userLongName;
  String userShortName;
  DateTime timestamp;
  String text;
  String imageURL;
  String? tweetId; // Reference to parent tweet

  Comment({
    this.id,
    required this.userLongName,
    required this.userShortName,
    required this.timestamp,
    required this.text,
    required this.imageURL,
    this.tweetId,
  });

  // Convert Comment to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'userLongName': userLongName,
      'userShortName': userShortName,
      'timestamp': timestamp,
      'text': text,
      'imageURL': imageURL,
      'tweetId': tweetId,
    };
  }

  // Create Comment from Firebase document
  static Comment fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      userLongName: data['userLongName'],
      userShortName: data['userShortName'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      text: data['text'],
      imageURL: data['imageURL'],
      tweetId: data['tweetId'],
    );
  }
}

class CreateNewTweet extends StatefulWidget 
{
  @override
  _CreateNewTweetState createState() => _CreateNewTweetState();
}

class _CreateNewTweetState extends State<CreateNewTweet> 
{
  final longName = TextEditingController();
  final shortName = TextEditingController();
  final description = TextEditingController();
  final imageUrl = TextEditingController();

  void createTweet() 
  {
    final newTweet = Tweet(
      userLongName: longName.text,
      userShortName: shortName.text,
      timestamp: DateTime.now(),
      description: description.text,
      imageURL: imageUrl.text,
      numComments: 0,
      numRetweets: 0,
      numLikes: 0,
      isBookmarked: false,
      isLiked: false,
      isRetweeted: false,
      comments: [],
    );

    Navigator.of(context).pop(newTweet);
  }

  @override
  Widget build(BuildContext context) 
  {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Tweet'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: longName,
              decoration: const InputDecoration(hintText: 'Name'),
            ),
            TextField(
              controller: shortName,
              decoration: const InputDecoration(hintText: 'Username'),
            ),
            TextField(
              controller: description,
              decoration: const InputDecoration(hintText: 'Description'),
            ),
            TextField(
              controller: imageUrl,
              decoration: const InputDecoration(hintText: 'Image URL (optional)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: createTweet,
              child: const Text('Create Tweet'),
            ),
          ],
        ),
      ),
    );
  }
}



  // Convert Comment to Map for Firebase
  

// Modify _TweetWidgetState to use Firebase

class CreateComment extends StatefulWidget 
{
  const CreateComment({super.key});

  
  @override
  _CreateCommentState createState() => _CreateCommentState();
}

class _CreateCommentState extends State<CreateComment> 
{
  final userLongName = TextEditingController();
  final userShortName = TextEditingController();
  final text = TextEditingController();
  final imageURL = TextEditingController();

  void submitComment() 
  {
    final newComment = Comment(
      userLongName: userLongName.text,
      userShortName: userShortName.text,
      timestamp: DateTime.now(),
      text: text.text,
      imageURL: imageURL.text,
    );

    Navigator.pop(context, newComment);
  }

  @override
  Widget build(BuildContext context) 
  {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create A Comment"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: userLongName,
              decoration: const InputDecoration(hintText: 'Name'),
            ),
            TextField(
              controller: userShortName,
              decoration: const InputDecoration(hintText: 'Username'),
            ),
            TextField(
              controller: text,
              decoration: const InputDecoration(hintText: "Add Reply..."),
            ),
            TextField(
              controller: imageURL, 
              decoration: const InputDecoration(hintText: "Image URL (optional)"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: submitComment,
              child: const Text("Comment"),
            ),
          ],
        ),
      ),
    );
  }
}