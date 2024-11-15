
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:final_project/TweetPage.dart';

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
