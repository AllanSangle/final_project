import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/TweetPage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      'timestamp': Timestamp.fromDate(timestamp),  
      'text': text,
      'imageURL': imageURL,
      'tweetId': tweetId,
    };
  }

  static Comment fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      userLongName: data['userLongName'] ?? '',  
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





class CreateComment extends StatefulWidget {
  const CreateComment({super.key});

  @override
  _CreateCommentState createState() => _CreateCommentState();
}

class _CreateCommentState extends State<CreateComment> {
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _imageURLController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    _imageURLController.dispose();
    super.dispose();
  }

  void submitComment() {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      // Handle case where no user is logged in
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to comment')),
      );
      return;
    }

    if (_commentController.text.trim().isEmpty) {
      // Prevent empty comments
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment cannot be empty')),
      );
      return;
    }

    final newComment = Comment(
      userLongName: user.displayName ?? 'Anonymous User', // Use Firebase user's display name
      userShortName: '@${user.email?.split('@').first ?? 'user'}', // Create a short username from email
      timestamp: DateTime.now(),
      text: _commentController.text.trim(),
      imageURL: _imageURLController.text.trim().isNotEmpty 
        ? _imageURLController.text.trim() 
        : '', // Optional image URL
    );

    Navigator.pop(context, newComment);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add a Comment"),
        backgroundColor: const Color.fromARGB(255, 202, 195, 247),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: "Write your comment...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              maxLines: 4,
              maxLength: 280, // Optional: Limit comment length
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _imageURLController,
              decoration: InputDecoration(
                hintText: "Optional Image URL",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: submitComment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 202, 195, 247),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Post Comment",
                style: TextStyle(
                  color: Color.fromARGB(255, 45, 39, 86),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}