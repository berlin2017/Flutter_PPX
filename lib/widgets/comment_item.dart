import 'package:flutter/material.dart';
import '../models/comment.dart';
import '../services/cache_service.dart'; // TODO: Review if CacheService is still needed here for comment likes
import '../utils/date_formatter.dart';

class CommentItem extends StatefulWidget {
  final Comment comment;
  final VoidCallback? onReplyTap;
  final bool isReply;
  final Function(bool) onLikeChanged; // Callback when like state changes

  const CommentItem({
    super.key,
    required this.comment,
    this.onReplyTap,
    this.isReply = false,
    required this.onLikeChanged,
  });

  @override
  State<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  // Local state for optimistic UI updates for likes
  // These will be initialized from widget.comment.isLiked and widget.comment.likes
  bool _isLikedLocal = false;
  int _likeCountLocal = 0;

  // TODO: If CacheService is only for comment likes, and if comment likes are
  // now handled by PostRepository/DetailScreen, CacheService might not be needed here.
  // For now, _cacheService.toggleCommentLike is assumed to exist and work.
  // final CacheService _cacheService = CacheService.instance;

  @override
  void initState() {
    super.initState();
    // Initialize local like state from the passed comment object
    _isLikedLocal = widget.comment.isLiked;
    _likeCountLocal = widget.comment.likes;
  }

  // This method is called when the widget's properties change.
  // We need this to ensure that if the parent rebuilds CommentItem with new data
  // (e.g., after a global state update for likes), our local state reflects that.
  @override
  void didUpdateWidget(covariant CommentItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.comment.isLiked != oldWidget.comment.isLiked ||
        widget.comment.likes != oldWidget.comment.likes) {
      setState(() {
        _isLikedLocal = widget.comment.isLiked;
        _likeCountLocal = widget.comment.likes;
      });
    }
  }

  Future<void> _handleLike() async {
    final originalIsLiked = _isLikedLocal;
    final originalLikeCount = _likeCountLocal;
    final newLikeState = !_isLikedLocal;

    // Optimistic UI update
    setState(() {
      _isLikedLocal = newLikeState;
      _likeCountLocal += newLikeState ? 1 : -1;
    });

    // Call the callback provided by the parent (e.g., DetailScreen)
    // This callback should handle the actual logic of persisting the like state
    // and potentially updating the global state or repository.
    widget.onLikeChanged(newLikeState);

    // The following try-catch block using _cacheService might be redundant
    // if DetailScreen._likeComment (triggered by onLikeChanged) handles everything.
    // Review if direct cache interaction is needed here anymore.
    // For now, keeping it as per original structure but with a note.
    /*
    try {
      // Assuming toggleCommentLike in CacheService updates some local cache.
      // This might conflict or be duplicative if DetailScreen also manages this.
      await _cacheService.toggleCommentLike(widget.comment.id, newLikeState);
      // The onLikeChanged callback above should be the primary mechanism
      // for notifying the parent to handle the like logic.
    } catch (e) {
      // If operation fails, revert optimistic UI update
      setState(() {
        _isLikedLocal = originalIsLiked;
        _likeCountLocal = originalLikeCount;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('操作失败，请重试')),
        );
      }
    }
    */
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('编辑评论'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement edit functionality (e.g., call a callback passed from parent)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('编辑功能即将上线')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('删除评论'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement delete functionality (e.g., call a callback passed from parent)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('删除功能即将上线')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('举报评论'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement report functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('举报功能即将上线')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Use local state for displaying likes, which reflects optimistic updates
    // and updates from the parent widget.
    final displayIsLiked = _isLikedLocal;
    final displayLikeCount = _likeCountLocal;

    return Padding(
      padding: EdgeInsets.only(
        left: widget.isReply ? 40.0 : 16.0, // Adjusted reply indent slightly
        right: 16.0,
        top: 8.0,
        bottom: 8.0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: widget.isReply ? 14 : 16, // Smaller avatar for replies
            backgroundImage: (widget.comment.userAvatar != null && widget.comment.userAvatar!.isNotEmpty)
                ? NetworkImage(widget.comment.userAvatar!)
                : null,
            backgroundColor: Colors.grey[300], // Background for the avatar circle
            child: (widget.comment.userAvatar == null || widget.comment.userAvatar!.isEmpty)
                ? Icon(
                    Icons.person,
                    size: widget.isReply ? 12 : 16,
                    color: Colors.white, // Icon color that contrasts with backgroundColor
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Wrap( // Using Wrap to prevent overflow if name and date are too long
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8.0, // Space between name and date
                        children: [
                          Text(
                            widget.comment.userName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            DateFormatter.formatRelativeTime(widget.comment.timestamp),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Only show more options if it's not a reply (or based on your logic)
                    // and if current user is the author of the comment (TODO: add this check)
                    if (!widget.isReply) 
                      IconButton(
                        icon: const Icon(Icons.more_horiz),
                        onPressed: _showMoreOptions,
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(widget.comment.content, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _handleLike,
                      child: Row(
                        children: [
                          Icon(
                            displayIsLiked ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: displayIsLiked ? Colors.red : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            displayLikeCount.toString(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Only show reply button if it's not already a reply and onReplyTap is provided
                    if (!widget.isReply && widget.onReplyTap != null) ...[
                      const SizedBox(width: 24), // Increased spacing
                      GestureDetector(
                        onTap: widget.onReplyTap,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.reply_outlined, // Using outlined version
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            // Show "Reply" text or reply count if available
                            if (widget.comment.replyCount > 0)
                              Text(
                                '${widget.comment.replyCount} 条回复',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                ),
                              )
                            else
                               Text(
                                '回复', // Show "Reply" if no replies yet
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                // TODO: Implement display of replies if this comment has replies
                // if (widget.comment.replies != null && widget.comment.replies.isNotEmpty)
                //   _buildRepliesSection(widget.comment.replies) 
              ],
            ),
          ),
        ],
      ),
    );
  }
}
