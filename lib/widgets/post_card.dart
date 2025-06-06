import 'package:flutter/material.dart';
import 'package:video_app/models/post.dart';
import 'package:video_app/models/post_type.dart';
import 'package:video_app/screens/detail_screen.dart';
import 'package:video_app/utils/date_formatter.dart';
import 'package:video_app/utils/number_formatter.dart';
import 'package:video_app/widgets/expandable_text.dart';
import 'package:video_player/video_player.dart'; // Assuming you use this for video playback

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback? onTap; // Optional: if the whole card is tappable for navigation

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  VideoPlayerController? _videoPlayerController;
  bool _isPlayerInitialized = false;
  bool _isLiked = false; // Local like state for immediate UI feedback
  int _likesCount = 0;    // Local likes count for immediate UI feedback

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLikedByCurrentUser;
    _likesCount = widget.post.likes;

    final String? videoUrl = widget.post.videoUrl; // Use local variable
    if (widget.post.type == PostType.video && videoUrl != null && videoUrl.isNotEmpty) {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(videoUrl)) // Use local variable
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isPlayerInitialized = true;
            });
          }
        }).catchError((error) {
           debugPrint("Error initializing video player: $error for url: $videoUrl");
            if (mounted) {
              setState(() {
                _isPlayerInitialized = false; // Explicitly set to false on error
              });
            }
        });
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }

  void _toggleLike() {
    // TODO: Integrate with actual like functionality (e.g., call PostRepository)
    setState(() {
      if (_isLiked) {
        _likesCount--;
      } else {
        _likesCount++;
      }
      _isLiked = !_isLiked;
    });
    // Placeholder for API call
    debugPrint("Post ${widget.post.id} like toggled. New status: $_isLiked, New count: $_likesCount");
  }

  void _navigateToDetail() {
    if (widget.onTap != null) {
      widget.onTap!(); // This onTap is from the constructor, assuming it's correctly handled by the parent
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DetailScreen(postId: widget.post.id)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      elevation: 2.0,
      clipBehavior: Clip.antiAlias, // Ensures content respects card's rounded corners
      child: InkWell(
        onTap: _navigateToDetail,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PostCardHeader(post: widget.post),
            _PostCardContent(
              post: widget.post,
              videoPlayerController: _videoPlayerController,
              isPlayerInitialized: _isPlayerInitialized,
            ),
            _PostCardFooter(
              post: widget.post,
              isLiked: _isLiked, // Pass local state
              likesCount: _likesCount, // Pass local state
              onLikeTap: _toggleLike,
              onCommentTap: () {
                _navigateToDetail(); // Comments section is usually on detail screen
                debugPrint('Comment button tapped for post ${widget.post.id}');
              },
              onShareTap: () {
                // TODO: Implement share functionality
                debugPrint('Share button tapped for post ${widget.post.id}');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCardHeader extends StatelessWidget {
  final Post post;

  const _PostCardHeader({required this.post});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final String? authorAvatar = post.authorAvatar; 

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: (authorAvatar != null && authorAvatar.isNotEmpty)
                ? NetworkImage(authorAvatar) 
                : null,
            child: (authorAvatar == null || authorAvatar.isEmpty)
                ? Text(post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : 'U')
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.authorName, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text(
                  DateFormatter.formatRelativeTime(post.publishTime),
                  style: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Implement more options (e.g., report, hide)
              debugPrint('More options tapped for post ${post.id}');
            },
          ),
        ],
      ),
    );
  }
}

class _PostCardContent extends StatelessWidget {
  final Post post;
  final VideoPlayerController? videoPlayerController;
  final bool isPlayerInitialized;

  const _PostCardContent({
    required this.post,
    this.videoPlayerController,
    required this.isPlayerInitialized,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final String? title = post.title;
    final String? content = post.content;
    final String? thumbnail = post.thumbnail;
    final List<String>? tags = post.tags;
    final String? videoUrl = post.videoUrl;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null && title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(title, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
            ),
          if (content != null && content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: ExpandableText(
                content,
                trimLines: 3,
                style: textTheme.bodyMedium?.copyWith(fontSize: 15.0, color: Colors.grey[800]),
              ),
            ),
          if (post.type == PostType.image && thumbnail != null && thumbnail.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 9, // Common aspect ratio for images
              child: Image.network(
                thumbnail,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 40));
                },
              ),
            ),
          if (post.type == PostType.video && videoUrl != null && videoUrl.isNotEmpty)
            if (isPlayerInitialized && videoPlayerController != null && videoPlayerController!.value.isInitialized)
              AspectRatio(
                aspectRatio: videoPlayerController!.value.aspectRatio, // This ! is safe due to videoPlayerController.value.isInitialized
                child: VideoPlayer(videoPlayerController!), // This ! is safe due to videoPlayerController.value.isInitialized
              )
            else if (thumbnail != null && thumbnail.isNotEmpty) // Show thumbnail while video loads or if it fails
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.network(
                      thumbnail,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(child: Icon(Icons.ondemand_video, color: Colors.grey, size: 40));
                      },
                    ),
                    // Optionally, show a play icon or loading indicator
                    if(!isPlayerInitialized) const CircularProgressIndicator() else const Icon(Icons.play_circle_fill, color: Colors.white70, size: 60),
                  ],
                ),
              )
            else // Fallback if video is not initialized and no thumbnail
              Container(
                height: 200,
                color: Colors.grey[300],
                child: const Center(child: Icon(Icons.videocam_off_outlined, color: Colors.grey, size: 50)),
              ),
          if (tags != null && tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Wrap(
                spacing: 6.0,
                runSpacing: 4.0,
                children: tags.map((tag) => Chip(
                  label: Text('#$tag', style: textTheme.bodySmall?.copyWith(color: Theme.of(context).primaryColor)),
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 0.0),
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  side: BorderSide.none,
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _PostCardFooter extends StatelessWidget {
  final Post post;
  final bool isLiked;
  final int likesCount;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentTap;
  final VoidCallback onShareTap;

  const _PostCardFooter({
    required this.post,
    required this.isLiked,
    required this.likesCount,
    required this.onLikeTap,
    required this.onCommentTap,
    required this.onShareTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0), // Reduced horizontal padding for button touch area
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _FooterButton(
            icon: isLiked ? Icons.favorite : Icons.favorite_border,
            label: NumberFormatter.formatCount(likesCount), // Use local likesCount
            iconColor: isLiked ? Colors.red : Colors.grey[700],
            onPressed: onLikeTap,
          ),
          _FooterButton(
            icon: Icons.chat_bubble_outline,
            label: NumberFormatter.formatCount(post.commentsCount),
            onPressed: onCommentTap,
          ),
          _FooterButton(
            icon: Icons.share_outlined,
            label: NumberFormatter.formatCount(post.shares),
            onPressed: onShareTap,
          ),
        ],
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? iconColor;

  const _FooterButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: Icon(icon, size: 20, color: iconColor ?? Colors.grey[700]),
      label: Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
