import 'package:flutter/material.dart';
import 'Tweet.dart';

class SearchTweetsPage extends StatefulWidget {
  final List<Tweet> allTweets;
  final String? profilePicUrl;  

  const SearchTweetsPage({Key? key, required this.allTweets, this.profilePicUrl}) : super(key: key);

  @override
  State<SearchTweetsPage> createState() => _SearchTweetsPageState();
}

class _SearchTweetsPageState extends State<SearchTweetsPage> {
  List<Tweet> filteredTweets = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    print('All Tweets: ${widget.allTweets}');
    
    filteredTweets = widget.allTweets;
  }

  void updateSearchResults(String query) {
    setState(() {
      searchQuery = query;

      filteredTweets = widget.allTweets.where((tweet) {
        final tweetContent = tweet.description?.toLowerCase() ?? '';
        final userName = tweet.userName.toLowerCase();
        final searchLower = query.toLowerCase();

        print('Tweet Content: $tweetContent');
        print('User Name: $userName');
        print('Search Query: $searchLower');
        
        bool matches = tweetContent.contains(searchLower) || userName.contains(searchLower);
        
        // Debugging the result of the match
        print('Matches: $matches');

        return matches;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Tweets"),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: updateSearchResults, 
            ),
          ),
          Expanded(
            child: filteredTweets.isEmpty
                ? Center(
                    child: Text(
                      searchQuery.isEmpty
                          ? 'Start typing to search tweets'
                          : 'No results found',
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredTweets.length,
                    itemBuilder: (context, index) {
                      final tweet = filteredTweets[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: widget.profilePicUrl != null
                              ? NetworkImage(widget.profilePicUrl!)
                              : const AssetImage('assets/placeholder_profile.png') as ImageProvider,
                        ),
                        title: Text(tweet.userName),
                        subtitle: Text(tweet.description ?? 'No description'),
                        trailing: Text('@${tweet.userName}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
