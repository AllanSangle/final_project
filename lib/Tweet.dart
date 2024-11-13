import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/Comment.dart';
import 'package:flutter/material.dart';


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
      'timestamp': Timestamp.fromDate(timestamp),
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