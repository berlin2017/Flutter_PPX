import 'package:flutter/material.dart';
import 'package:video_app/models/post.dart';
import 'package:video_app/repositories/post_repository.dart';
import 'package:video_app/services/database_helper.dart'; // For PostRepository instantiation
import 'package:video_app/widgets/post_card.dart'; // Assuming you have a PostCard widget
import 'package:video_app/screens/detail_screen.dart'; // For navigation
// import 'package:video_app/services/auth_service.dart'; // Example: if you need current user

class HomeScreen extends StatefulWidget {
  // If HomeScreen needs to accept a Key from MainScreen, it should be declared here.
  // Example: const HomeScreen({Key? key}) : super(key: key);
  // For now, assuming the key is passed directly to super constructor if needed,
  // or handled by MainScreen's GlobalKey usage.
  const HomeScreen({super.key});

  @override
  //Ensure this line correctly uses the public state class name
  State<HomeScreen> createState() => HomeScreenState();
}

// Renamed to public class HomeScreenState
class HomeScreenState extends State<HomeScreen> {
  late final PostRepository _postRepository;
  // late final AuthService _authService; // Example for getting current user

  final ScrollController _scrollController = ScrollController();
  List<Post> _posts = [];
  bool _isLoading = false; // For initial load and pull-to-refresh
  bool _isFetchingMore = false; // For loading more items at the bottom
  bool _canLoadMore = true; // To prevent fetching if no more items are expected
  bool _hasError = false;
  final int _limit = 10; // Number of posts to fetch per page

  @override
  void initState() {
    super.initState();
    final dbHelper = DatabaseHelper.instance;
    _postRepository = PostRepository(dbHelper);
    // _authService = AuthService(); // Example initialization

    _loadPosts(); // Initial load

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9 &&
          !_isFetchingMore &&
          _canLoadMore &&
          !_isLoading) {
        _loadPosts(isLoadMore: true);
      }
    });
  }

  // Public method to scroll to top and refresh
  Future<void> scrollToTopAndRefresh() async {
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
    // After scrolling (or if already at top), trigger a refresh.
    // Ensure _refreshPosts sets loading state correctly.
    await _refreshPosts();
  }

  Future<void> _loadPosts({bool isLoadMore = false, bool forceRefresh = false}) async {
    if (!isLoadMore && _isLoading && !forceRefresh) return; 
    
    if (!isLoadMore) {
      if (mounted) {
        setState(() {
          _isLoading = true; 
          _hasError = false; 
        });
      }
    } else {
      if (_isFetchingMore || !_canLoadMore) return;
      if (mounted) {
        setState(() {
          _isFetchingMore = true;
          _hasError = false;
        });
      }
    }

    try {
      final currentOffset = isLoadMore ? _posts.length : 0;
      String? currentUserId = "user_placeholder_123"; 

      final List<Post> newPosts = await _postRepository.getPosts(
        offset: currentOffset,
        limit: _limit,
        forceRefresh: forceRefresh,
        userId: currentUserId,
      );

      if (mounted) {
        setState(() {
          if (isLoadMore) {
            _posts.addAll(newPosts);
            _canLoadMore = newPosts.length == _limit; 
          } else {
            _posts = newPosts;
            _canLoadMore = newPosts.length == _limit;
          }
        });
      }
    } catch (e, stackTrace) {
      if (mounted) {
        debugPrint("Error loading posts in HomeScreen: $e");
        debugPrint("StackTrace: $stackTrace");
        setState(() {
          _hasError = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          if (isLoadMore) {
            _isFetchingMore = false;
          } else {
            _isLoading = false;
          }
        });
      }
    }
  }

  Future<void> _refreshPosts() async {
    if (mounted) {
      setState(() {
        _canLoadMore = true; 
        _hasError = false;   
        // _isLoading will be set by _loadPosts
      });
    }
    await _loadPosts(forceRefresh: true, isLoadMore: false);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('动态'), 
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              print("Search button pressed");
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _posts.isEmpty && !_hasError) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_hasError && _posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('加载帖子失败，请稍后重试。'),
            ),
            ElevatedButton(
              onPressed: () => _loadPosts(forceRefresh: true, isLoadMore: false),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
    
    if (_posts.isEmpty && !_isLoading && !_hasError) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.list_alt_outlined, color: Colors.grey, size: 60),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('暂无内容，下拉刷新试试？'),
              ),
              ElevatedButton(
                onPressed: _refreshPosts,
                child: const Text('刷新'),
              ),
            ],
          ),
        );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _posts.length + (_isFetchingMore && _canLoadMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _posts.length) {
          return _isFetchingMore && _canLoadMore 
                 ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
                 : const SizedBox.shrink();
        }
        final post = _posts[index];
        // Ensure PostCard gets the onTap callback to navigate to DetailScreen
        return PostCard(
          post: post,
        );
      },
    );
  }
}
