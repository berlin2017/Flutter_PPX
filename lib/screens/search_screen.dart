import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/search_history_service.dart';
import '../models/post.dart';
import '../models/post_type.dart';
import '../screens/detail_screen.dart';
import '../screens/user_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SearchHistoryService _searchService = SearchHistoryService();
  List<String> _searchHistory = [];
  List<Post> _searchResults = [];
  bool _isSearching = false;
  final String _defaultAvatarUrl = 'https://picsum.photos/seed/default_avatar/50/50'; // Default avatar

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  Future<void> _loadSearchHistory() async {
    final history = await _searchService.getSearchHistory();
    if (mounted) {
      setState(() {
        _searchHistory = history;
      });
    }
  }

  Future<void> _handleSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    await _searchService.insertSearch(query);
    
    // Simulate search results
    await Future.delayed(const Duration(seconds: 1));
    final results = List.generate(
      20,
      (index) => Post(
        id: 'search_$index',
        title: '搜索结果 $index',
        content: '这是关于"$query"的搜索结果 $index',
        authorId: 'author_id_search_$index', // Added authorId
        authorName: '作者 $index',
        authorAvatar: index % 5 == 0 ? null : 'https://picsum.photos/50/50?random=search_$index', // Make some avatars null
        likes: 100 + index,
        dislikes: 10 + index,
        commentsCount: 20 + index,
        shares: 30 + index,
        type: PostType.values[index % 3],
        thumbnail: index % 3 != 0 ? 'https://picsum.photos/400/200?random=search_thumb_$index' : null,
        videoUrl: index % 3 == 2 ? 'https://example.com/video$index.mp4' : null,
        publishTime: DateTime.now().subtract(Duration(minutes: index * 10)), // Added publishTime
      ),
    );

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }

    _loadSearchHistory();
  }

  Future<void> _deleteHistoryItem(String query) async {
    await _searchService.deleteSearchHistory(query);
    _loadSearchHistory();
  }

  Future<void> _clearHistory() async {
    await _searchService.clearSearchHistory();
    _loadSearchHistory();
  }

  Widget _buildSearchItem(Post post) {
    final String avatarUrl = post.authorAvatar?.isNotEmpty == true ? post.authorAvatar! : _defaultAvatarUrl;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DetailScreen(postId: post.id)),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.thumbnail != null && post.thumbnail!.isNotEmpty)
              Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: post.thumbnail!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                        width: double.infinity, height: 200, color: Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator())),
                    errorWidget: (context, url, error) => Container(
                        width: double.infinity, height: 200, color: Colors.grey[300],
                        child: const Center(child: Icon(Icons.error))),
                  ),
                  if (post.type == PostType.video)
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailScreen(postId: post.id),
                              ),
                            );
                          },
                          child: const Center(
                            child: CircleAvatar(
                              backgroundColor: Colors.black45,
                              child: Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title ?? '[无标题]', // Handle null title
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.content ?? '', // Handle null content
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserProfileScreen(
                                userId: post.authorId, // Ensure authorId is passed
                                userName: post.authorName,
                                userAvatar: avatarUrl, // Pass the resolved avatarUrl
                              ),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: CachedNetworkImageProvider(avatarUrl), // Use resolved avatarUrl
                              radius: 12,
                              // Fallback for CircleAvatar if CachedNetworkImageProvider fails (though CNI handles errors)
                              onBackgroundImageError: (_ , __) {
                                // Optionally log error or handle differently
                              },
                              child: avatarUrl == _defaultAvatarUrl && post.authorAvatar?.isNotEmpty != true 
                                  ? const Icon(Icons.person, size: 12) // Show person icon on default
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              post.authorName,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${post.likes}点赞 · ${post.commentsCount}评论', // Use commentsCount from Post model
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) { // Show message if search was done but no results
      return const Center(
        child: Text('暂无搜索结果'),
      );
    }
    // If search results are empty and search text is empty, it means we should show history (or initial state)
    // This case is handled by the main body logic.

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) => _buildSearchItem(_searchResults[index]),
    );
  }

  Widget _buildSearchHistory() {
    if (_searchHistory.isEmpty) {
      return const Center(
        child: Text('暂无搜索历史'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(
                '搜索历史',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _clearHistory,
                child: const Text('清空'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _searchHistory.length,
            itemBuilder: (context, index) {
              final query = _searchHistory[index];
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(query),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => _deleteHistoryItem(query),
                ),
                onTap: () {
                  _searchController.text = query;
                  _handleSearch(query);
                },
              );            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: '搜索内容',
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty 
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      // Optionally reset search results when clearing the text field
                      setState(() {
                        _searchResults = [];
                      });
                    },
                  )
                : const Icon(Icons.search), // Show search icon if text is empty
          ),
          onChanged: (text) {
            // Update UI to show clear button when text is entered
            setState(() {});
          },
          onSubmitted: _handleSearch,
        ),
      ),
      // Show search history if search results are empty AND search controller is empty
      // Otherwise, show search results (which might be "no results" message or actual items)
      body: _searchController.text.isEmpty && _searchResults.isEmpty
          ? _buildSearchHistory()
          : _buildSearchResults(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
