import 'package:flutter/material.dart';
import '../models/comment.dart';
import '../services/cache_service.dart';
import '../utils/date_formatter.dart';

class CommentItem extends StatefulWidget {
  final Comment comment;
  final VoidCallback? onReplyTap;
  final bool isReply;
  final Function(bool) onLikeChanged;

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
  final CacheService _cacheService = CacheService.instance;
  bool _isLiked = false;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.comment.isLiked;
    _likeCount = widget.comment.likes;
  }

  Future<void> _handleLike() async {
    final newLikeState = !_isLiked;
    
    setState(() {
      _isLiked = newLikeState;
      _likeCount += newLikeState ? 1 : -1;
    });

    try {
      await _cacheService.toggleCommentLike(widget.comment.id, newLikeState);
      widget.onLikeChanged(newLikeState);
    } catch (e) {
      // 如果操作失败，恢复状态
      setState(() {
        _isLiked = !newLikeState;
        _likeCount -= newLikeState ? 1 : -1;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('操作失败，请重试')),
        );
      }
    }
  }
  // 移除 _formatTimestamp 方法，使用 DateFormatter 工具类
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
                // TODO: Implement edit functionality
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
                // TODO: Implement delete functionality
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
    
    return Padding(
      padding: EdgeInsets.only(
        left: widget.isReply ? 56.0 : 16.0,
        right: 16.0,
        top: 8.0,
        bottom: 8.0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage(widget.comment.userAvatar),
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
                      child: Row(
                        children: [
                          Text(
                            widget.comment.userName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormatter.formatTimestamp(widget.comment.timestamp),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                Text(widget.comment.content),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _handleLike,
                      child: Row(
                        children: [
                          Icon(
                            _isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: _isLiked ? Colors.red : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _likeCount.toString(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!widget.isReply) ...[
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: widget.onReplyTap,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.reply,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            if (widget.comment.replyCount > 0)
                              Text(
                                '${widget.comment.replyCount} 条回复',
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
