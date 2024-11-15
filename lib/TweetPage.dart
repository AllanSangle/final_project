
import 'package:final_project/Comment.dart';
import 'package:final_project/Tweet.dart';
import 'package:flutter/material.dart';

class TweetHeader extends StatelessWidget {
  final Tweet tweet;
  final VoidCallback onHideTweet;

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

  @override
  Widget build(BuildContext context) {
    String timeString = '${tweet.timestamp.hour}:${tweet.timestamp.minute}';

    return Row(
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
                      tweet.userLongName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 5.0),
                    Text(
                      '@${tweet.userShortName}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(width: 5.0),
                    Text(
                      '· $timeString',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.expand_more, size: 15, color: Colors.grey),
                      onPressed: () => _showHideDialog(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
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
    return Row(
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

// Updated TweetImage State class
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TweetHeader(
            tweet: widget.tweet,
            onHideTweet: widget.hideTweet,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(widget.tweet.description),
          ),
          Image.network(
            widget.tweet.imageURL,
            width: double.infinity,
            fit: BoxFit.fitWidth,
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

