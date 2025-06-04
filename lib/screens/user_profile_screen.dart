import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user.dart';
import '../models/post.dart';
import '../models/post_type.dart';
import '../services/cache_service.dart';
import 'detail_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String userAvatar;

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
  final CacheService _cacheService = CacheService.instance;
  late TabController _tabController;
  
  User? _user;
  bool _isLoading = true;
  bool _isFollowing = false;
  List<Post> _userPosts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      // TODO: 从服务器获取用户信息，这里使用模拟数据
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _user = User(
            id: widget.userId,
            name: widget.userName,
            avatar: widget.userAvatar,
            bio: '分享生活，记录美好',
            followers: 1234,
            following: 321,
            posts: 42,
            isFollowing: false,
          );
          _isFollowing = _user?.isFollowing ?? false;
          
          // 模拟用户发布的内容
          _userPosts = List.generate(10, (index) => Post(
            id: 'post_$index',
            title: '${widget.userName}的作品 $index',
            content: '这是第$index个作品的内容描述',
            authorName: widget.userName,
            authorAvatar: widget.userAvatar,
            thumbnail: 'https://picsum.photos/400/300?random=$index',
            likes: 100 + index,
            dislikes: 5 + index,
            comments: 20 + index,
            shares: 10 + index,
            type: index % 2 == 0 ? PostType.image : PostType.video,
            videoUrl: index % 2 == 0 ? null : 'https://example.com/video$index.mp4',
          ));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('加载用户信息失败')),
        );
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (_user == null) return;

    final newFollowState = !_isFollowing;
    setState(() => _isFollowing = newFollowState);

    try {
      // TODO: 实现关注/取关 API 调用
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _user = _user!.copyWith(
          isFollowing: newFollowState,
          followers: _user!.followers + (newFollowState ? 1 : -1),
        );
      });
    } catch (e) {
      // 恢复原状态
      setState(() => _isFollowing = !newFollowState);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(newFollowState ? '关注失败' : '取消关注失败')),
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
                    imageUrl: _user!.avatar,
                    fit: BoxFit.cover,
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
              title: Text(_user!.name),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              _user!.followers.toString(),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text('粉丝'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              _user!.following.toString(),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text('关注'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              _user!.posts.toString(),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text('作品'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_user!.bio != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(_user!.bio!),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _toggleFollow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFollowing ? Colors.grey[200] : Theme.of(context).primaryColor,
                        foregroundColor: _isFollowing ? Colors.black87 : Colors.white,
                      ),
                      child: Text(_isFollowing ? '已关注' : '关注'),
                    ),
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: '作品'),
                    Tab(text: '动态'),
                    Tab(text: '喜欢'),
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
            const Center(child: Text('暂无动态')),
            const Center(child: Text('暂无喜欢的内容')),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.8,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _userPosts.length,
      itemBuilder: (context, index) {
        final post = _userPosts[index];
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailScreen(post: post),
              ),
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: post.thumbnail ?? post.authorAvatar,
                fit: BoxFit.cover,
              ),
              if (post.type == PostType.video)
                const Positioned(
                  right: 4,
                  top: 4,
                  child: Icon(
                    Icons.play_circle_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              Positioned(
                bottom: 4,
                left: 4,
                child: Row(
                  children: [
                    const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      post.likes.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
