import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:uuid/uuid.dart';
import '../models/post.dart';
import '../models/post_type.dart';
import '../models/comment.dart';
import '../services/cache_service.dart';
import '../widgets/comment_item.dart';
import '../screens/user_profile_screen.dart';

class DetailScreen extends StatefulWidget {
  final Post post;

  const DetailScreen({super.key, required this.post});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {  late VideoPlayerController _videoController;
  final TextEditingController _commentController = TextEditingController();
  final CacheService _cacheService = CacheService.instance;
  final _uuid = Uuid();
  
  bool _isPlaying = false;
  bool _isControllerInitialized = false;
  bool _isLoadingComments = false;
  bool _isPostingComment = false;
  String? _commentError;
  String? _replyToComment;
  
  int _likes = 0;
  int _dislikes = 0;
  int _shares = 0;
  bool _isLiked = false;
  bool _isDisliked = false;
  
  List<Comment> _comments = [];
  Map<String, List<Comment>> _commentReplies = {};
  Map<String, bool> _expandedComments = {};

  @override
  void initState() {
    super.initState();
    _likes = widget.post.likes;
    _dislikes = widget.post.dislikes;
    _shares = widget.post.shares;
    
    if (widget.post.type == PostType.video && widget.post.videoUrl != null) {
      _initializeVideoPlayer();
    }
    
    _loadComments();
    _loadInteractionState();
  }

  Future<void> _initializeVideoPlayer() async {
    _videoController = VideoPlayerController.network(widget.post.videoUrl!);
    try {
      await _videoController.initialize();
      setState(() {
        _isControllerInitialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing video player: $e');
    }
  }

  Future<void> _loadInteractionState() async {
    try {
      final interactions = await _cacheService.getPostInteractionState(widget.post.id);
      if (mounted) {
        setState(() {
          _isLiked = interactions['isLiked'] ?? false;
          _isDisliked = interactions['isDisliked'] ?? false;
          if (_isLiked) _likes++;
          if (_isDisliked) _dislikes++;
        });
      }
    } catch (e) {
      debugPrint('Error loading interaction state: $e');
    }
  }

  Future<void> _loadComments() async {
    if (_isLoadingComments) return;
    
    setState(() {
      _isLoadingComments = true;
      _commentError = null;
    });

    try {
      final comments = await _cacheService.getComments(widget.post.id);
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _commentError = '加载评论失败';
          _isLoadingComments = false;
        });
      }
    }
  }

  void _toggleCommentReplies(String commentId) async {
    setState(() {
      _expandedComments[commentId] = !(_expandedComments[commentId] ?? false);
    });

    if (_expandedComments[commentId] == true && 
        (!_commentReplies.containsKey(commentId) || _commentReplies[commentId]!.isEmpty)) {
      try {
        final replies = await _cacheService.getCommentReplies(commentId);
        if (mounted) {
          setState(() {
            _commentReplies[commentId] = replies;
          });
        }
      } catch (e) {
        debugPrint('Error loading replies: $e');
      }
    }
  }

  void _handleReply(Comment comment) {
    _replyToComment = comment.id;
    _commentController.text = '@${comment.userName} ';
    _commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commentController.text.length),
    );
    FocusScope.of(context).requestFocus();
  }

  void _handleCommentLike(String commentId, bool isLiked) async {
    try {
      await _cacheService.updateCommentLike(commentId, isLiked);
      _loadComments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isLiked ? '点赞失败' : '取消点赞失败')),
        );
      }
    }
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
      _isPlaying ? _videoController.play() : _videoController.pause();
    });
  }

  void _handleLongPressStart() {
    if (_isControllerInitialized && !_isPlaying) {
      _togglePlay();
    }
  }

  void _handleLongPressEnd() {
    if (_isControllerInitialized && _isPlaying) {
      _togglePlay();
    }
  }

  Future<void> _handleLike() async {
    if (_isDisliked) {
      setState(() {
        _isDisliked = false;
        _dislikes = widget.post.dislikes;
      });
    }
    
    try {
      setState(() {
        _isLiked = !_isLiked;
        _likes = widget.post.likes + (_isLiked ? 1 : 0);
      });

      await _cacheService.updatePostInteraction(widget.post.id, _isLiked, false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isLiked ? '点赞成功' : '已取消点赞')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
          _likes = widget.post.likes + (_isLiked ? 1 : 0);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('操作失败')),
        );
      }
    }
  }

  Future<void> _handleDislike() async {
    if (_isLiked) {
      setState(() {
        _isLiked = false;
        _likes = widget.post.likes;
      });
    }
    
    try {
      setState(() {
        _isDisliked = !_isDisliked;
        _dislikes = widget.post.dislikes + (_isDisliked ? 1 : 0);
      });

      await _cacheService.updatePostInteraction(widget.post.id, false, _isDisliked);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isDisliked ? '已踩' : '已取消踩')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDisliked = !_isDisliked;
          _dislikes = widget.post.dislikes + (_isDisliked ? 1 : 0);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('操作失败')),
        );
      }
    }
  }

  Future<void> _handleShare() async {
    setState(() => _shares++);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('分享成功')),
    );
  }

  Future<void> _handlePostComment() async {
    if (_commentController.text.isEmpty) return;

    setState(() {
      _isPostingComment = true;
    });

    try {
      final newComment = Comment(
        id: _uuid.v4(),
        postId: widget.post.id,
        userId: 'current_user', // 这里应该使用真实的用户ID
        userName: '当前用户', // 这里应该使用真实的用户名
        userAvatar: 'https://example.com/avatar.png', // 这里应该使用真实的用户头像
        content: _commentController.text,
        timestamp: DateTime.now(),
        parentId: _replyToComment,
      );
      
      await _cacheService.saveComment(newComment);
      _commentController.clear();
      _replyToComment = null;
      await _loadComments();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('评论发布成功')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('评论发布失败')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPostingComment = false;
        });
      }
    }
  }  @override
  void dispose() {
    if (widget.post.type == PostType.video) {
      _videoController.dispose();
    }
    _commentController.dispose();
    super.dispose();
  }

  Widget _buildMediaContent() {
    if (widget.post.type == PostType.video && _isControllerInitialized) {
      return AspectRatio(
        aspectRatio: _videoController.value.aspectRatio,
        child: Stack(
          children: [
            GestureDetector(
              onTap: _togglePlay,
              onLongPressStart: (_) => _handleLongPressStart(),
              onLongPressEnd: (_) => _handleLongPressEnd(),
              child: VideoPlayer(_videoController),
            ),
            AnimatedOpacity(
              opacity: !_isPlaying || _videoController.value.position == Duration.zero ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Center(
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 64,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ),
            if (_isControllerInitialized)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ValueListenableBuilder(
                  valueListenable: _videoController,
                  builder: (context, value, child) {
                    return VideoProgressIndicator(
                      _videoController,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: Colors.red,
                        bufferedColor: Colors.grey,
                        backgroundColor: Colors.black45,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      );
    } else if (widget.post.type == PostType.image && widget.post.thumbnail != null) {
      return CachedNetworkImage(
        imageUrl: widget.post.thumbnail!,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildCommentSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '评论',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _isLoadingComments
              ? const Center(child: CircularProgressIndicator())
              : _commentError != null
                  ? Center(child: Text(_commentError!))
                  : Column(
                      children: _comments.map((comment) {
                        return Column(
                          children: [
                            CommentItem(
                              comment: comment,
                              onReplyTap: () => _handleReply(comment),
                              onLikeChanged: (isLiked) =>
                                  _handleCommentLike(comment.id, isLiked),
                            ),
                            if (comment.replyCount > 0)
                              Padding(
                                padding: const EdgeInsets.only(left: 56),
                                child: TextButton(
                                  onPressed: () => _toggleCommentReplies(comment.id),
                                  child: Text(
                                    _expandedComments[comment.id] ?? false
                                        ? '收起回复'
                                        : '查看${comment.replyCount}条回复',
                                  ),
                                ),
                              ),
                            if (_expandedComments[comment.id] ?? false)
                              Padding(
                                padding: const EdgeInsets.only(left: 56),
                                child: Column(
                                  children: _commentReplies[comment.id]?.map((reply) =>
                                    CommentItem(
                                      comment: reply,
                                      onReplyTap: () => _handleReply(reply),
                                      onLikeChanged: (isLiked) =>
                                          _handleCommentLike(reply.id, isLiked),
                                    ),
                                  ).toList() ?? [],
                                ),
                              ),
                          ],
                        );
                      }).toList(),
                    ),
        ],
      ),
    );
  }
  // 移除 _formatTimestamp 方法，使用 DateFormatter 工具类
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.post.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.share),
                        title: const Text('分享'),
                        onTap: () {
                          Navigator.pop(context);
                          // TODO: 实现分享功能
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.flag_outlined),
                        title: const Text('举报'),
                        onTap: () {
                          Navigator.pop(context);
                          // TODO: 实现举报功能
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [          // 媒体内容区
          _buildMediaContent(),
          // 内容区
          if (widget.post.type == PostType.text)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(widget.post.content),
            ),
          // 用户信息和互动区域
          ListTile(
            leading: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserProfileScreen(
                      userId: widget.post.authorId ?? widget.post.authorName,
                      userName: widget.post.authorName,
                      userAvatar: widget.post.authorAvatar,
                    ),
                  ),
                );
              },
              child: CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(widget.post.authorAvatar),
              ),
            ),
            title: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserProfileScreen(
                      userId: widget.post.authorId ?? widget.post.authorName,
                      userName: widget.post.authorName,
                      userAvatar: widget.post.authorAvatar,
                    ),
                  ),
                );
              },
              child: Text(widget.post.authorName),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.person_add_outlined),
              onPressed: () {
                // TODO: 实现关注功能
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('关注成功')),
                );
              },
            ),
          ),          // 互动按钮区域
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  icon: _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                  label: _likes.toString(),
                  onPressed: _handleLike,
                  isActive: _isLiked,
                ),
                _buildActionButton(
                  icon: _isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                  label: _dislikes.toString(),
                  onPressed: _handleDislike,
                  isActive: _isDisliked,
                ),
                _buildActionButton(
                  icon: Icons.share_outlined,
                  label: _shares.toString(),
                  onPressed: _handleShare,
                ),
              ],
            ),
          ),
          const Divider(),
        // 评论区标题
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '评论 ${_comments.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton.icon(
                  onPressed: () => _loadComments(),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('刷新'),
                ),
              ],
            ),
          ),
          // 评论列表
          Expanded(
            child: _isLoadingComments
                ? const Center(child: CircularProgressIndicator())
                : _commentError != null
                    ? Center(child: Text(_commentError!))
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          return Column(
                            children: [
                              CommentItem(
                                comment: comment,
                                onReplyTap: () => _handleReply(comment),
                                onLikeChanged: (isLiked) => _handleCommentLike(comment.id, isLiked),
                              ),
                              if (comment.replyCount > 0)
                                Padding(
                                  padding: const EdgeInsets.only(left: 56.0),                                  child: TextButton.icon(
                                    onPressed: () => _toggleCommentReplies(comment.id),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      minimumSize: const Size.fromHeight(36),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    icon: Icon(
                                      _expandedComments[comment.id] ?? false
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      size: 18,
                                    ),
                                    label: Text(
                                      _expandedComments[comment.id] ?? false
                                          ? '收起回复'
                                          : '查看 ${comment.replyCount} 条回复',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ),                              if (_expandedComments[comment.id] ?? false)
                                Container(
                                  margin: const EdgeInsets.only(left: 56.0),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      left: BorderSide(
                                        color: Colors.grey[300]!,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    children: _commentReplies[comment.id]?.map((reply) => CommentItem(
                                      comment: reply,
                                      isReply: true,
                                      onLikeChanged: (isLiked) => _handleCommentLike(reply.id, isLiked),
                                    )).toList() ?? [],
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
          ),
        // 底部评论框和交互按钮
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // 输入框
                  Expanded(
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: '写下你的评论...',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 点赞按钮
                  _buildActionIconButton(
                    icon: _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                    label: _likes.toString(),
                    onPressed: _handleLike,
                    isActive: _isLiked,
                  ),
                  // 踩按钮
                  _buildActionIconButton(
                    icon: _isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                    label: _dislikes.toString(),
                    onPressed: _handleDislike,
                    isActive: _isDisliked,
                  ),
                  // 分享按钮
                  _buildActionIconButton(
                    icon: Icons.share_outlined,
                    label: _shares.toString(),
                    onPressed: _handleShare,
                  ),
                  if (_commentController.text.isNotEmpty)
                    _isPostingComment
                        ? const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.send),
                            color: Theme.of(context).primaryColor,
                            onPressed: _handlePostComment,
                          ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildPostHeader() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileScreen(
              userId: widget.post.authorId ?? widget.post.authorName,
              userName: widget.post.authorName,
              userAvatar: widget.post.authorAvatar,
            ),
          ),
        ),
        child: CircleAvatar(
          backgroundImage: CachedNetworkImageProvider(widget.post.authorAvatar),
        ),
      ),
      title: Text(widget.post.authorName),
      subtitle: Text(
        '发布时间：${widget.post.publishTime?.toString().split('.').first ?? '未知'}',
      ),
    );
  }

  Widget _buildPostContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        widget.post.content,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    final color = isActive ? Theme.of(context).primaryColor : Colors.grey;
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: color),
      label: Text(label, style: TextStyle(color: color)),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _buildActionButton(
                  icon: _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                  label: _likes.toString(),
                  onPressed: _handleLike,
                  isActive: _isLiked,
                ),
                _buildActionButton(
                  icon: _isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                  label: _dislikes.toString(),
                  onPressed: _handleDislike,
                  isActive: _isDisliked,
                ),
                _buildActionButton(
                  icon: Icons.share_outlined,
                  label: _shares.toString(),
                  onPressed: _handleShare,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _loadComments(),
                  icon: const Icon(Icons.comment_outlined),
                  label: Text('${_comments.length}'),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: '添加评论...',
                        border: InputBorder.none,
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                  ),
                  if (_commentController.text.isNotEmpty)
                    IconButton(
                      icon: _isPostingComment
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      onPressed: _handlePostComment,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    final color = isActive ? Theme.of(context).primaryColor : Colors.grey[600];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
