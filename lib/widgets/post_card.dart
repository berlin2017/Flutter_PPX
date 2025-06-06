import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post.dart';
import '../models/post_type.dart';
import '../services/cache_service.dart';
import 'package:share_plus/share_plus.dart';
import '../screens/detail_screen.dart';
import '../screens/user_profile_screen.dart';
import 'package:video_player/video_player.dart';

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({
    super.key,
    required this.post,
    // Removed onTap parameter
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isLiked = false;
  bool _isDisliked = false;
  int _likes = 0;
  int _dislikes = 0;
  final CacheService _cacheService = CacheService.instance;
  bool _showCommentInput = false;
  final TextEditingController _commentController = TextEditingController();
  VideoPlayerController? _videoController;
  bool _isPlaying = false;
  bool _isVideoInitialized = false;
  @override
  void initState() {
    super.initState();
    _likes = widget.post.likes;
    _dislikes = widget.post.dislikes;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _loadInteractionState();

    if (widget.post.type == PostType.video && widget.post.videoUrl != null) {
      _initializeVideoController();
    }
  }

  Future<void> _initializeVideoController() async {
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.post.videoUrl!)
    );
    
    try {
      await _videoController!.initialize();
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  void _togglePlay() {
    if (_videoController != null && _isVideoInitialized) {
      setState(() {
        _isPlaying = !_isPlaying;
        _isPlaying ? _videoController!.play() : _videoController!.pause();
      });
    }
  }

  void _handleLongPressStart() {
    if (_videoController != null && _isVideoInitialized) {
      setState(() {
        _videoController!.setPlaybackSpeed(2.0);
      });
    }
  }

  void _handleLongPressEnd() {
    if (_videoController != null && _isVideoInitialized) {
      setState(() {
        _videoController!.setPlaybackSpeed(1.0);
      });
    }
  }

  Future<void> _loadInteractionState() async {
    final state = await _cacheService.getPostInteractionState(widget.post.id);
    if (mounted) {
      setState(() {
        _isLiked = state['isLiked']!;
        _isDisliked = state['isDisliked']!;
        // 更新计数,考虑已有的交互状态
        if (_isLiked) _likes++;
        if (_isDisliked) _dislikes++;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _commentController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _handleLike() async {
    if (_isDisliked) {
      setState(() {
        _isDisliked = false;
        _dislikes = widget.post.dislikes;
      });
    }

    setState(() {
      _isLiked = !_isLiked;
      _likes = widget.post.likes + (_isLiked ? 1 : 0);
    });

    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    // 保存交互状态
    await _cacheService.updatePostInteraction(widget.post.id, _isLiked, false);
  }

  Future<void> _handleDislike() async {
    if (_isLiked) {
      setState(() {
        _isLiked = false;
        _likes = widget.post.likes;
      });
    }

    setState(() {
      _isDisliked = !_isDisliked;
      _dislikes = widget.post.dislikes + (_isDisliked ? 1 : 0);
    });

    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    // 保存交互状态
    await _cacheService.updatePostInteraction(widget.post.id, false, _isDisliked);
  }

  void _handleComment() {
    setState(() {
      _showCommentInput = !_showCommentInput;
    });
    if (_showCommentInput) {
      // 显示底部输入框
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: '写下你的评论...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          // TODO: 处理评论提交
                          if (_commentController.text.isNotEmpty) {
                            // 这里可以添加评论提交的逻辑
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('评论已发布')),
                            );
                            _commentController.clear();
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('发布'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ).whenComplete(() {
        setState(() {
          _showCommentInput = false;
        });
      });
    }
  }

  void _handleShare() {
    Share.share(
      '${widget.post.title}\n${widget.post.content}',
      subject: widget.post.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(  // Added InkWell for overall card tap
      onTap: () {
        // Stop video if playing before navigating
        if (_isPlaying && _videoController != null) {
          _videoController!.pause();
          setState(() {
            _isPlaying = false;
          });
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailScreen(post: widget.post),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author info - InkWell removed
            ListTile(
              leading: GestureDetector(
                onTap: () { // Kept GestureDetector for profile navigation
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
              title: GestureDetector( // Kept GestureDetector for profile navigation
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
              subtitle: Text(widget.post.title),
            ),
            // Content area
            if (widget.post.type == PostType.text)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(widget.post.content),
              )
            else if (widget.post.type == PostType.image)
              // InkWell removed from CachedNetworkImage
              CachedNetworkImage(
                imageUrl: widget.post.thumbnail!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(Icons.error),
                ),
              )
            else if (widget.post.type == PostType.video)
              GestureDetector( // This GestureDetector handles video play/pause and prevents outer InkWell tap
                onTap: () {
                  if (_videoController == null || !_isVideoInitialized) {
                    _initializeVideoController().then((_) {
                      if (mounted) {
                        setState(() {
                          _isPlaying = true;
                          _videoController?.play();
                        });
                      }
                    });
                  } else {
                    _togglePlay();
                  }
                },
                onDoubleTap: () { // Optional: Keep double tap for details as a shortcut
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailScreen(post: widget.post),
                    ),
                  );
                },
                onLongPressStart: (_) => _handleLongPressStart(),
                onLongPressEnd: (_) => _handleLongPressEnd(),
                behavior: HitTestBehavior.opaque, // Crucial: Prevents tap from reaching the outer InkWell
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_isVideoInitialized)
                      AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      ),
                    if (!_isVideoInitialized || !_isPlaying)
                      CachedNetworkImage(
                        imageUrl: widget.post.thumbnail!,
                        width: double.infinity,
                        height: 300,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 300,
                          color: Colors.grey[200],
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 300,
                          color: Colors.grey[200],
                          child: const Center(child: Icon(Icons.error)),
                        ),
                      ),
                    // Play/Pause button
                    AnimatedOpacity(
                      opacity: !_isPlaying || !_isVideoInitialized ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                    // Progress bar
                    if (_isVideoInitialized)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          color: Colors.black.withOpacity(0.5),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const SizedBox(width: 8),
                              ValueListenableBuilder(
                                valueListenable: _videoController!,
                                builder: (context, VideoPlayerValue value, child) {
                                  return Text(
                                    '${value.position.inMinutes}:${(value.position.inSeconds % 60).toString().padLeft(2, '0')} / ${value.duration.inMinutes}:${(value.duration.inSeconds % 60).toString().padLeft(2, '0')}',
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  );
                                },
                              ),
                              Expanded(
                                child: VideoProgressIndicator(
                                  _videoController!,
                                  allowScrubbing: true,
                                  colors: const VideoProgressColors(
                                    playedColor: Colors.red,
                                    bufferedColor: Colors.white24,
                                    backgroundColor: Colors.white12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            // Interaction buttons bar - InkWell removed
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: _InteractionButton(
                      icon: _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                      label: '$_likes',
                      color: _isLiked ? Colors.red : null,
                      onTap: _handleLike,
                    ),
                  ),
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: _InteractionButton(
                      icon: _isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                      label: '$_dislikes',
                      color: _isDisliked ? Colors.red : null,
                      onTap: _handleDislike,
                    ),
                  ),
                  _InteractionButton(
                    icon: Icons.comment_outlined,
                    label: '${widget.post.comments}',
                    color: _showCommentInput ? Colors.red : null,
                    onTap: _handleComment,
                  ),
                  _InteractionButton(
                    icon: Icons.share_outlined,
                    label: '${widget.post.shares}',
                    onTap: _handleShare,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InteractionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _InteractionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }
}
