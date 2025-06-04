import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post.dart';
import '../models/post_type.dart';
import '../models/subscribed_account.dart';
import '../widgets/post_card.dart';
import '../screens/search_screen.dart';
import '../services/cache_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final CacheService _cacheService = CacheService.instance;
  final Map<int, ScrollController> _scrollControllers = {};
  SubscribedAccount? selectedAccount;
  final PageController _pageController = PageController(initialPage: 1);
  late AnimationController _slideController;
  int _selectedCategoryIndex = 1;
  bool _isLoadingMore = false;
  bool _isRefreshing = false;
  bool _isInitializing = true;
  final int _postsPerPage = 10;
  Map<int, List<Post>> _categoryPosts = {};
  bool _isOffline = false;

  ScrollController _getScrollController(int index) {
    if (!_scrollControllers.containsKey(index)) {
      _scrollControllers[index] = ScrollController();
    }
    return _scrollControllers[index]!;
  }

  void scrollToTop() {
    final controller = _getScrollController(_selectedCategoryIndex);
    if (controller.hasClients) {
      controller.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _initCacheService();
    _pageController.addListener(_handlePageChange);
  }

  Future<void> _initCacheService() async {
    try {
      await _cacheService.init();
      await _loadCachedData();
      _refreshContent(); // 加载完缓存后尝试获取新数据
    } catch (e) {
      print('Failed to initialize cache service: $e');
      setState(() => _isOffline = true);
    }
  }

  Future<void> _loadCachedData() async {
    try {
      // 加载缓存的订阅账户
      final cachedAccounts = await _cacheService.getCachedAccounts();
      if (cachedAccounts.isNotEmpty && mounted) {
        setState(() {
          subscribedAccounts = cachedAccounts;
        });
      }

      // 加载当前分类的缓存帖子
      final cachedPosts = await _cacheService.getCachedPosts(_selectedCategoryIndex);
      if (cachedPosts.isNotEmpty && mounted) {
        setState(() {
          _categoryPosts[_selectedCategoryIndex] = cachedPosts;
        });
      }
    } catch (e) {
      print('Failed to load cached data: $e');
      if (mounted) {
        setState(() => _isOffline = true);
      }
    }
  }

  void _handlePageChange() {
    final page = _pageController.page?.round() ?? 0;
    if (page != _selectedCategoryIndex) {
      setState(() {
        _selectedCategoryIndex = page;
        selectedAccount = null;
        if (_categoryPosts[page]?.isEmpty ?? true) {
          _loadCachedData();
        }
      });
    }
  }

  Post _createPost(int index, PostType defaultType, [SubscribedAccount? account]) {
    String? thumbnail;
    String? videoUrl;
    
    final type = defaultType == PostType.mixed
        ? index % 3 == 0 ? PostType.text 
            : index % 3 == 1 ? PostType.image 
            : PostType.video
        : defaultType;
    
    if (type == PostType.image || type == PostType.video) {
      thumbnail = 'https://picsum.photos/400/200?random=${account != null ? index + 100 : index}';
      if (type == PostType.video) {
        videoUrl = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
      }
    }

    return Post(
      id: account != null ? 'user_post_$index' : 'post_$index',
      title: account != null ? '${account.name}的${index + 1}号作品' : '分类${_selectedCategoryIndex + 1}的内容 $index',
      content: account != null ? '这是${account.name}发布的第${index + 1}个作品' : '这是分类${_selectedCategoryIndex + 1}的第$index个内容',
      authorName: account?.name ?? 'Author $index',
      authorAvatar: account?.avatar ?? 'https://picsum.photos/50/50?random=$index',
      likes: (account != null ? 200 : 100) + index,
      dislikes: (account != null ? 5 : 10) + index,
      comments: (account != null ? 30 : 20) + index,
      shares: (account != null ? 40 : 30) + index,
      type: type,
      thumbnail: thumbnail,
      videoUrl: videoUrl,
    );
  }
  Future<void> _loadMoreContent() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      // 模拟加载更多内容
      await Future.delayed(const Duration(seconds: 1));

      // 为当前分类添加更多内容
    final currentPosts = _categoryPosts[_selectedCategoryIndex] ?? [];
    final newPosts = List.generate(
      _postsPerPage, 
      (i) => _createPost(
        currentPosts.length + i,
        _selectedCategoryIndex == 2 ? PostType.video 
          : _selectedCategoryIndex == 3 ? (i % 2 == 0 ? PostType.text : PostType.image)
          : PostType.mixed,
        _selectedCategoryIndex == 0 ? selectedAccount : null
      )
    );    // 保存新的帖子到缓存
    await _cacheService.cachePosts(_selectedCategoryIndex, [...currentPosts, ...newPosts]);

    setState(() {
      _categoryPosts[_selectedCategoryIndex] = [...currentPosts, ...newPosts];
      _isLoadingMore = false;
    });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
        _isOffline = true;
      });
    }
  }
  Future<void> _refreshContent() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
      _isOffline = false;
    });

    try {
      // 模拟延迟以展示刷新动画
      await Future.delayed(const Duration(milliseconds: 800));

      // 生成新的帖子数据
      final newPosts = List.generate(
        _postsPerPage,
        (i) => _createPost(
          i,
          _selectedCategoryIndex == 2 ? PostType.video 
            : _selectedCategoryIndex == 3 ? (i % 2 == 0 ? PostType.text : PostType.image)
            : PostType.mixed,
          _selectedCategoryIndex == 0 ? selectedAccount : null
        ),
      );

      // 保存到缓存
      await _cacheService.cachePosts(_selectedCategoryIndex, newPosts);
      
      if (_selectedCategoryIndex == 1) {
        await _cacheService.cacheAccounts(subscribedAccounts);
      }

      if (mounted) {
        setState(() {
          _categoryPosts[_selectedCategoryIndex] = newPosts;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      print('Failed to refresh content: $e');
      // 发生错误时尝试加载缓存
      if (mounted) {
        final cachedPosts = await _cacheService.getCachedPosts(_selectedCategoryIndex);
        setState(() {
          if (cachedPosts.isNotEmpty) {
            _categoryPosts[_selectedCategoryIndex] = cachedPosts;
          } else {
            _isOffline = true;
          }
          _isRefreshing = false;
        });
      }
    }
  }
  @override
  void dispose() {
    _scrollControllers.values.forEach((controller) => controller.dispose());
    _pageController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // 示例数据
  final List<String> categories = [
    '关注',
    '推荐',
    '视频',
    '图文',
    '南京',
    '职业圈',
    '颜值',
  ];
  // 示例用户数据
  List<SubscribedAccount> subscribedAccounts = [
    SubscribedAccount(
      name: '渔你同乐',
      avatar: 'https://picsum.photos/200?random=1',
      hasUpdate: true,
    ),
    SubscribedAccount(
      name: '男科郝朋友',
      avatar: 'https://picsum.photos/200?random=2',
      hasUpdate: true,
    ),
    SubscribedAccount(
      name: '篮球之家',
      avatar: 'https://picsum.photos/200?random=3',
      hasUpdate: true,
    ),
    SubscribedAccount(
      name: 'C座802',
      avatar: 'https://picsum.photos/200?random=4',
      hasUpdate: false,
    ),
    SubscribedAccount(
      name: '环球异事',
      avatar: 'https://picsum.photos/200?random=5',
      hasUpdate: false,
    ),
    SubscribedAccount(
      name: 'LOL马后炮',
      avatar: 'https://picsum.photos/200?random=6',
      hasUpdate: true,
    ),
  ];

  // 示例帖子数据
  final List<Post> posts = [
    Post(
      id: '1',
      title: '分享一个有趣的故事',
      content: '今天遇到一件特别有趣的事情...',
      authorName: '故事分享者',
      authorAvatar: 'https://picsum.photos/200?random=7',
      likes: 1234,
      dislikes: 56,
      comments: 89,
      shares: 45,
      type: PostType.text,
    ),
    Post(
      id: '2',
      title: '看看我拍的照片',
      content: '这张照片拍得不错',
      thumbnail: 'https://picsum.photos/400/300?random=8',
      authorName: '摄影爱好者',
      authorAvatar: 'https://picsum.photos/200?random=9',
      likes: 2345,
      dislikes: 78,
      comments: 120,
      shares: 67,
      type: PostType.image,
    ),
    Post(
      id: '3',
      title: '精彩视频分享',
      content: '记录生活中的美好时刻',
      thumbnail: 'https://picsum.photos/400/300?random=10',
      videoUrl: 'https://example.com/video.mp4',
      authorName: '视频博主',
      authorAvatar: 'https://picsum.photos/200?random=11',
      likes: 3456,
      dislikes: 90,
      comments: 234,
      shares: 89,
      type: PostType.video,
    ),
  ];  void _handleAccountTap(SubscribedAccount account) {
    setState(() {
      selectedAccount = selectedAccount?.name == account.name ? null : account;
    });
    _refreshContent();
  }

  Widget _buildAccountsList() {
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: subscribedAccounts.length,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemBuilder: (context, index) {
          final account = subscribedAccounts[index];
          final isSelected = selectedAccount == account;
          return GestureDetector(
            onTap: () => _handleAccountTap(account),
            child: Container(
              width: 70,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.red,
                            width: isSelected ? 3 : 2,
                          ),
                        ),                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: account.avatar,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          ),
                        ),
                      ),
                      if (account.hasUpdate && !isSelected)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              '有更新',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    account.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : null,
                      color: isSelected ? Colors.blue : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (_isOffline)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                width: double.infinity,
                color: Colors.orange.withOpacity(0.1),
                child: const Center(
                  child: Text(
                    '当前处于离线模式',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            _buildCategories(),
            Expanded(
              child: _buildPageView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              padding: const EdgeInsets.only(left: 16),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = index == _selectedCategoryIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: InkWell(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: isSelected ? Colors.red : Theme.of(context).textTheme.bodyLarge?.color,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: isSelected ? 17.0 : 15.0,
                          ),
                          child: Text(category),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 2,
                          width: isSelected ? 24 : 20,
                          color: isSelected ? Colors.red : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),          ),
          Container(
            width: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Theme.of(context).scaffoldBackgroundColor.withOpacity(0),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildPageView() {
    return PageView.builder(
      controller: _pageController,
      itemCount: categories.length,
      onPageChanged: (index) {
        setState(() {
          _selectedCategoryIndex = index;
          selectedAccount = null;
        });
        // 如果当前分类没有数据，尝试加载
        if (_categoryPosts[index]?.isEmpty ?? true) {
          _loadCachedData().then((_) {
            if (_categoryPosts[index]?.isEmpty ?? true) {
              _refreshContent();
            }
          });
        }
      },
      itemBuilder: (context, pageIndex) {
        return RefreshIndicator(
          onRefresh: _refreshContent,          child: _isRefreshing && (_categoryPosts[pageIndex]?.isEmpty ?? true)
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : (_categoryPosts[pageIndex]?.isEmpty ?? true) && _isOffline
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('暂无内容', style: TextStyle(color: Colors.grey)),
                        TextButton(
                          onPressed: _refreshContent,
                          child: const Text('点击重试'),
                        ),
                      ],
                    ),
                  )
              : NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollEndNotification) {
                      if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 200) {
                        _loadMoreContent();
                      }
                    }
                    return false;
                  },
                  child              : ListView.builder(
                    controller: _getScrollController(pageIndex),
                    key: PageStorageKey('category_$pageIndex'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: (_categoryPosts[pageIndex]?.length ?? 0) + 
                              (pageIndex == 1 ? 1 : 0) +  // 订阅账户列表
                              (_isLoadingMore || _isRefreshing ? 1 : 0),   // 加载指示器
                    // 添加空状态显示
                    itemBuilder: (context, index) {                      // 在推荐栏目的第一个位置显示订阅账户列表
                      if (pageIndex == 1 && index == 0) {
                        return _buildAccountsList();
                      }
                      
                      final posts = _categoryPosts[pageIndex] ?? [];
                      final postIndex = pageIndex == 1 ? index - 1 : index;
                      
                      // 显示加载指示器
                      if (postIndex == posts.length && (_isLoadingMore || _isRefreshing)) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (postIndex < posts.length) {
                        return PostCard(
                          key: Key('post_${posts[postIndex].id}'),
                          post: posts[postIndex],
                          onTap: () {
                            // TODO: Handle post tap
                          },
                        );
                      }
                      return null;
                    },
                  ),
                ),
        );
      },
    );
  }
}

class _AccountDetailsSheet extends StatefulWidget {
  final SubscribedAccount account;

  const _AccountDetailsSheet({required this.account});

  @override
  State<_AccountDetailsSheet> createState() => _AccountDetailsSheetState();
}

class _AccountDetailsSheetState extends State<_AccountDetailsSheet> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _closeSheet() {
    _animController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, MediaQuery.of(context).size.height * _slideAnimation.value),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 下滑指示器
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // 标题栏
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 4, 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: CachedNetworkImageProvider(widget.account.avatar),
                          radius: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.account.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${10000 + widget.account.hashCode % 90000} 粉丝',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _closeSheet,
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  // 作品列表
                  Flexible(
                    child: CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                            child: Text(
                              '最新作品',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.8,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final type = index % 3;  // 0: 文字, 1: 图片, 2: 视频
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[100],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    if (type > 0)
                                      CachedNetworkImage(
                                        imageUrl: 'https://picsum.photos/400/500?random=${widget.account.name.hashCode + index}',
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                    if (type == 2)
                                      Positioned(
                                        right: 8,
                                        top: 8,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.6),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Icon(
                                            Icons.play_arrow,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                            colors: [
                                              Colors.black.withOpacity(0.8),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.favorite,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${1000 + index * 100}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            childCount: 20,
                          ),
                        ),
                        const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
