import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user.dart';
import '../models/post.dart';
import '../models/post_type.dart';
// import '../services/cache_service.dart'; // CacheService seems to be no longer used here directly
import 'detail_screen.dart'; // Ensure DetailScreen import is correct

const String _defaultAvatarUrl = 'https://picsum.photos/seed/default_avatar/200/200'; // Default avatar

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String? userAvatar; // Assuming this can be empty or a non-valid URL

  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userAvatar,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with SingleTickerProviderStateMixin {
  // final CacheService _cacheService = CacheService.instance; // No longer seems to be used
  late TabController _tabController;

  User? _user; // This User object is from your local simulation
  bool _isLoading = true;
  bool _isFollowing = false; // Simulated follow state
  List<Post> _userPosts = []; // Simulated list of posts for this user

  // TODO: Replace simulated data with actual data fetching from a repository/service
  // For example, you would have something like:
  // late final UserRepository _userRepository;
  // late final PostRepository _postRepository;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // TODO: Initialize your repositories here if needed
    // _userRepository = UserRepository(DatabaseHelper.instance); // Example
    // _postRepository = PostRepository(DatabaseHelper.instance); // Example
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      // TODO: 从服务器或仓库获取用户信息和用户帖子
      // await _fetchUserDetails();
      // await _fetchUserPosts();

      // --- SIMULATED DATA ---
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          // Simulate fetching user details
          _user = User(
            id: widget.userId,
            name: widget.userName,
            avatar: widget.userAvatar, // This might be empty
            bio: '分享生活，记录美好 (模拟数据)',
            followers: 1234, // Simulated
            following: 321,  // Simulated
            posts: 42,   // Simulated (renamed from 'posts' to avoid confusion with List<Post>)
            // isFollowing: false, // This will be handled by _isFollowing state variable
          );
          _isFollowing = false; // Simulate initial follow status, e.g., from _user.isFollowing

          // 模拟用户发布的内容
          _userPosts = List.generate(10, (index) => Post(
            id: 'profile_post_${widget.userId}_$index', // Make ID more unique
            title: '${widget.userName}的作品 $index (模拟)',
            content: '这是第$index个作品的内容描述 (模拟)',
            authorId: widget.userId,
            authorName: widget.userName,
            authorAvatar: widget.userAvatar, // This might be empty
            thumbnail: 'https://picsum.photos/400/300?random=user${widget.userId}$index', // More varied pics
            likes: 100 + index,
            dislikes: 5 + index, // Assuming Post model has dislikes
            commentsCount: 20 + index, // Assuming Post model has commentsCount
            shares: 10 + index, // Assuming Post model has shares
            type: index % 2 == 0 ? PostType.image : PostType.video,
            videoUrl: index % 2 == 0 ? null : 'https://example.com/video_user_${widget.userId}_$index.mp4',
            publishTime: DateTime.now().subtract(Duration(days: index)), // Simulated publish time
            // isLikedByCurrentUser: false, // Should be determined by current user context
          ));
          _isLoading = false;
        });
      }
      // --- END SIMULATED DATA ---

    } catch (e) {
      if (mounted) {
        debugPrint("Error loading user profile: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('加载用户信息失败')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (_user == null) return;

    final originalFollowState = _isFollowing;
    final originalFollowers = _user!.followers;

    setState(() {
      _isFollowing = !originalFollowState;
      _user = _user!.copyWith(
        followers: _user!.followers + (_isFollowing ? 1 : -1),
        // isFollowing: _isFollowing // If your User model has isFollowing
      );
    });

    try {
      // TODO: 实现关注/取关 API 调用
      // For example:
      // if (_isFollowing) {
      //   await _userRepository.followUser(currentUserId, widget.userId);
      // } else {
      //   await _userRepository.unfollowUser(currentUserId, widget.userId);
      // }
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call
      // If API call fails, revert state:
      // throw Exception("Simulated API error");
    } catch (e) {
      debugPrint("Error toggling follow: $e");
      // 恢复原状态
      setState(() {
        _isFollowing = originalFollowState;
        _user = _user!.copyWith(followers: originalFollowers);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isFollowing ? '取消关注失败' : '关注失败')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.userName)), // Show username even when loading
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final currentUserProfile = _user!; // Safe to use ! due to check above

    // Use default avatar if current user's avatar is null or empty
    final String profileAvatarUrl = (currentUserProfile.avatar != null && currentUserProfile.avatar!.isNotEmpty)
        ? currentUserProfile.avatar!
        : _defaultAvatarUrl;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: profileAvatarUrl, // Use resolved URL
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey[300]),
                    errorWidget: (context, url, error) => Container(color: Colors.grey[300], child: const Icon(Icons.person, color: Colors.white70, size: 50)),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(currentUserProfile.name, style: const TextStyle(color: Colors.white)),
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn('粉丝', currentUserProfile.followers.toString()),
                      _buildStatColumn('关注', currentUserProfile.following.toString()),
                      _buildStatColumn('作品', currentUserProfile.posts.toString()), // Assuming postsCount from User model
                    ],
                  ),
                ),
                if (currentUserProfile.bio != null && currentUserProfile.bio!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(currentUserProfile.bio!, textAlign: TextAlign.center),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    // TODO: Disable button if this profile is the current user's profile
                    child: ElevatedButton(
                      onPressed: _toggleFollow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFollowing ? Colors.grey[300] : Theme.of(context).primaryColor,
                        foregroundColor: _isFollowing ? Colors.black87 : Colors.white,
                      ),
                      child: Text(_isFollowing ? '已关注' : '关注'),
                    ),
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Theme.of(context).primaryColor,
                  tabs: const [
                    Tab(text: '作品'),
                    Tab(text: '动态'), // Placeholder
                    Tab(text: '喜欢'), // Placeholder
                  ],
                ),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPostsGrid(),
            const Center(child: Text('动态功能暂未开放')), // Placeholder
            const Center(child: Text('喜欢列表暂未开放')), // Placeholder
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildPostsGrid() {
    if (_userPosts.isEmpty) {
      return const Center(child: Text('该用户还没有发布任何作品'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.8, // Adjust as needed for your content
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _userPosts.length,
      itemBuilder: (context, index) {
        final post = _userPosts[index];
        // Determine the image URL for the post grid item
        String imageUrl = _defaultAvatarUrl; // Start with default
        if (post.thumbnail != null && post.thumbnail!.isNotEmpty) {
          imageUrl = post.thumbnail!;
        } else if (post.authorAvatar != null && post.authorAvatar!.isNotEmpty) {
          imageUrl = post.authorAvatar!;
        }

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailScreen(postId: post.id), // MODIFIED HERE
              ),
            );
          },
          child: Card( // Using Card for better visual separation and potential elevation
            elevation: 1.0,
            clipBehavior: Clip.antiAlias, // Ensures content respects card boundaries
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: imageUrl, // Use the resolved image URL
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported, color: Colors.grey)),
                ),
                if (post.type == PostType.video)
                  const Positioned(
                    right: 4,
                    top: 4,
                    child: Icon(
                      Icons.play_circle_outline,
                      color: Colors.white,
                      size: 24,
                      shadows: [Shadow(blurRadius: 2.0, color: Colors.black54)],
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          post.likes.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Ensure your User and Post models are correctly defined.
// Example for User model (ensure fields match what's used above):
// class User {
//   final String id;
//   final String name;
//   final String? avatar; // Assuming avatar can be nullable or empty
//   final String? bio;
//   final int followers;
//   final int following;
//   final int postsCount; // Renamed from 'posts'
//   // final bool isFollowing; // Optional: can be managed by a separate state or derived

//   User({
//     required this.id,
//     required this.name,
//     this.avatar,
//     this.bio,
//     required this.followers,
//     required this.following,
//     required this.postsCount,
//     // this.isFollowing = false,
//   });

//  User copyWith({ ... }) { ... } // For updating user fields
// }

// Example for Post model (ensure fields match what's used above):
// class Post {
//   final String id;
//   final String title;
//   final String content;
//   final String authorId;
//   final String authorName;
//   final String? authorAvatar; // Assuming authorAvatar can be nullable or empty
//   final String? thumbnail;
//   final int likes;
//   final int? dislikes;
//   final int? commentsCount;
//   final int? shares;
//   final PostType type;
//   final String? videoUrl;
//   final DateTime? publishTime;
//   // final bool isLikedByCurrentUser; // This should ideally be determined by the app's current user context

//   Post({
//     required this.id,
//     required this.title,
//     required this.content,
//     required this.authorId,
//     required this.authorName,
//     this.authorAvatar,
//     this.thumbnail,
//     required this.likes,
//     this.dislikes,
//     this.commentsCount,
//     this.shares,
//     required this.type,
//     this.videoUrl,
//     this.publishTime,
//     // this.isLikedByCurrentUser = false,
//   });
// }
