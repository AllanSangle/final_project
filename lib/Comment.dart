import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/TweetPage.dart';
import 'package:flutter/material.dart';

final commentsRef = FirebaseFirestore.instance.collection('comments');
class Comment {
  String? id;
  final String userLongName;
  final String userShortName;
  final DateTime timestamp;
  final String text;
  final String imageURL;
  String? tweetId;

  Comment({
    this.id,
    required this.userLongName,
    required this.userShortName,
    required this.timestamp,
    required this.text,
    required this.imageURL,
    this.tweetId,
  });

  Map<String, dynamic> toMap() {
    return {
      'userLongName': userLongName,
      'userShortName': userShortName,
      'timestamp': Timestamp.fromDate(timestamp),  // Fix: Convert DateTime to Timestamp
      'text': text,
      'imageURL': imageURL,
      'tweetId': tweetId,
    };
  }

  static Comment fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      userLongName: data['userLongName'] ?? '',  // Add null safety
      userShortName: data['userShortName'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      text: data['text'] ?? '',
      imageURL: data['imageURL'] ?? '',
      tweetId: data['tweetId'],
    );
  }
}

class CommentsList extends StatelessWidget {
  final List<Comment> comments;

  const CommentsList({
    Key? key,
    required this.comments,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: comments.map((comment) => CommentItem(comment: comment)).toList(),
    );
  }
}

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