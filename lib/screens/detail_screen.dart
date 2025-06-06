import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart'; // Keep if you use VideoPlayer

import '../models/comment.dart'; // Make sure this path is correct
// import 'package:uuid/uuid.dart'; // Keep if you generate IDs client-side for comments before sending to API

import '../models/post.dart';
import '../models/post_type.dart';
import '../models/user.dart'; // Placeholder for your User model
import '../repositories/post_repository.dart'; // Correct path
import '../screens/user_profile_screen.dart'; // Keep if you use this
import '../services/database_helper.dart'; // Correct path
import '../widgets/comment_item.dart'; // Keep if you use this

class DetailScreen extends StatefulWidget {
  final String postId; // Changed from Post object to postId

  const DetailScreen({super.key, required this.postId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late PostRepository _postRepository;
  final DatabaseHelper _dbHelper = DatabaseHelper
      .instance; // Keep if repository needs it directly or for other local ops

  Post? _post;
  List<Comment> _comments = [];
  User? _currentUser; // To store the current user details

  bool _isLoadingPost = true;
  bool _isLoadingComments = false;
  bool _isPostingComment = false;
  final TextEditingController _commentController = TextEditingController();

  // VideoPlayer specific fields (keep if your Post model and UI support video)
  VideoPlayerController? _videoPlayerController;
  bool _isVideoPlayerInitialized = false;

  // At the top of _DetailScreenState class
  Comment? _replyingToComment; // Stores the comment being replied to
  final FocusNode _commentFocusNode = FocusNode(); // To manage focus on the comment text field

  @override
  void initState() {
    super.initState();
    _postRepository = PostRepository(_dbHelper); // Initialize repository
    _fetchCurrentUserThenLoadData();
  }

  Future<void> _fetchCurrentUserThenLoadData() async {
    // TODO: Implement your actual logic to get the current user
    // This might involve checking SharedPreferences, an auth service, etc.
    // For now, using a placeholder or allowing null.
    _currentUser = await _getCurrentUser(); // Implement this function

    // After attempting to get the user, load post and comments
    await _loadPostDetails();
    if (_post != null) {
      // Initialize video player if the post is a video
      if (_post!.type == PostType.video &&
          _post!.videoUrl != null &&
          _post!.videoUrl!.isNotEmpty) {
        _initializeVideoPlayer(_post!.videoUrl!);
      }
      await _loadInitialComments(); // Load comments only after post is loaded
    } else {
      if (mounted) {
        setState(() {
          _isLoadingPost = false; // Stop loading if post is null
        });
      }
    }
  }

  Future<User?> _getCurrentUser() async {
    // Replace with your actual auth logic to get user details
    // For example, fetch from a global state, SharedPreferences, or an auth service.
    // Placeholder:
    // return User(id: "user_123", name: "Current User", avatarUrl: "https://example.com/avatar.png");
    print("TODO: Implement _getCurrentUser in DetailScreen");
    // For now, let's simulate a logged-in user for testing purposes
    // In a real app, this would come from your auth system.
    return User(
        id: "simulated_user_id_123",
        name: "Simulated User",
        avatar: "https://picsum.photos/seed/simulated_user/100/100", // Example avatar
        // Add other fields your User model might have, e.g., bio, followers, etc.
        // For example:
        // bio: "A simulated user for testing.",
        followers: 100,
        following: 50,
        posts: 10,
    );
    // return null; // Return null if no user is logged in
  }

  Future<void> _initializeVideoPlayer(String videoUrl) async {
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(videoUrl),
    );
    try {
      await _videoPlayerController!.initialize();
      if (mounted) {
        setState(() {
          _isVideoPlayerInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video player in DetailScreen: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error loading video.')));
      }
    }
  }

  Future<void> _loadPostDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoadingPost = true;
    });
    try {
      final postData = await _postRepository.getPostById(
        widget.postId,
        userId: _currentUser?.id,
      );
      if (mounted) {
        setState(() {
          _post = postData;
          _isLoadingPost = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load post details: $e');
      if (mounted) {
        setState(() {
          _isLoadingPost = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load post: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadInitialComments() async {
    await _refreshComments(showLoadingIndicator: true);
  }

  Future<void> _refreshComments({
    bool forceRemote = false,
    bool showLoadingIndicator = false,
  }) async {
    if (!mounted || _post == null) return;
    if (showLoadingIndicator) {
      setState(() {
        _isLoadingComments = true;
      });
    }
    try {
      final commentsData = await _postRepository.getCommentsForPost(
        widget.postId,
        forceRefresh: forceRemote,
      );
      if (mounted) {
        setState(() {
          _comments = commentsData;
        });
      }
    } catch (e) {
      debugPrint('Failed to load comments: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load comments: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted && showLoadingIndicator) {
        setState(() {
          _isLoadingComments = false;
        });
      }
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _post == null) return;

    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to comment.')),
      );
      return;
    }

    setState(() {
      _isPostingComment = true;
    });

    try {
      // Assuming _currentUser is not null due to the check above
      final newComment = await _postRepository.addComment(
        postId: _post!.id,
        userId: _currentUser!.id,
        userName: _currentUser!.name,
        userAvatar: _currentUser!.avatar, // User model's avatar field might be nullable
        commentText: text,
      );
      if (newComment != null) {
        _commentController.clear();
        setState(() {
          _replyingToComment = null; // Clear reply state after successful comment
        });
        await _refreshComments(
          forceRemote: true,
        ); // Refresh to see the new comment
      } else {
        throw Exception("Failed to post comment, repository returned null.");
      }
    } catch (e) {
      debugPrint('Failed to post comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPostingComment = false;
        });
      }
    }
  }

  // --- Like/Dislike Handlers ---
  Future<void> _handleLike() async {
    if (_post == null || _currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot like post. Data missing or not logged in.'),
        ),
      );
      return;
    }
    final originalPost = _post!;
    final originalIsLiked = originalPost.isLikedByCurrentUser;
    final originalLikes = originalPost.likes;

    // Optimistic UI update
    setState(() {
      _post = _post!.copyWith(
        isLikedByCurrentUser: !originalIsLiked,
        likes: !originalIsLiked
            ? originalLikes + 1
            : (originalLikes > 0 ? originalLikes - 1 : 0),
      );
    });

    try {
      final success = await _postRepository.toggleLikeStatus(
        userId: _currentUser!.id,
        postId: _post!.id,
        currentLikeStatus: originalIsLiked,
      );
      if (!success && mounted) { // If toggle failed, revert
         setState(() {
          _post = originalPost;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update like status. Please try again.')),
        );
      }
      // Optionally, refresh post from repository to get server-confirmed state
      // await _loadPostDetails();
    } catch (e) {
      debugPrint('Error toggling like: $e');
      // Revert optimistic update on error
      if (mounted) {
        setState(() {
          _post = originalPost;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update like status.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _videoPlayerController?.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  // --- UI Building Methods ---
  @override
  Widget build(BuildContext context) {
    if (_isLoadingPost || _post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Post is loaded, build the detail UI
    return Scaffold(
      appBar: AppBar(
        title: Text(_post!.title ?? 'Details'), // FIX: Handle null title
        // Add other actions if needed
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMediaContent(),
                  _buildPostHeader(),
                  _buildPostContentDetails(),
                  _buildInteractionButtons(),
                  const Divider(),
                  _buildCommentsList(),
                ],
              ),
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildMediaContent() {
    if (_post!.type == PostType.video) {
      if (_isVideoPlayerInitialized && _videoPlayerController != null) {
        return AspectRatio(
          aspectRatio: _videoPlayerController!.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_videoPlayerController!),
              IconButton(
                icon: Icon(
                  _videoPlayerController!.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.white,
                  size: 50,
                ),
                onPressed: () {
                  setState(() {
                    _videoPlayerController!.value.isPlaying
                        ? _videoPlayerController!.pause()
                        : _videoPlayerController!.play();
                  });
                },
              ),
            ],
          ),
        );
      } else {
        // Show placeholder or loading for video
        return Container(
          height: 200,
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        );
      }
    } else if (_post!.type == PostType.image && _post!.thumbnail != null) {
      // Safe: thumbnail is checked for null before use
      return CachedNetworkImage(
        imageUrl: _post!.thumbnail!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: 200,
          color: Colors.grey[300],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          height: 200,
          color: Colors.grey[300],
          child: const Icon(Icons.error),
        ),
      );
    }
    return const SizedBox.shrink(); // For text posts or if no media
  }

  Widget _buildPostHeader() {
    // Assuming _post is not null here, as it's checked in the main build method.
    final authorAvatar = _post!.authorAvatar; // authorAvatar is nullable

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              // authorId is non-nullable in Post model.
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfileScreen(
                    userId: _post!.authorId, // authorId is non-nullable
                    userName: _post!.authorName, // authorName is non-nullable
                    userAvatar: authorAvatar, // Pass the nullable authorAvatar
                  ),
                ),
              );
            },
            child: CircleAvatar(
              backgroundImage: (authorAvatar != null && authorAvatar.isNotEmpty)
                  ? CachedNetworkImageProvider(authorAvatar)
                  : null,
              child: (authorAvatar == null || authorAvatar.isEmpty)
                  ? const Icon(Icons.person)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _post!.authorName, // authorName is non-nullable
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                // publishTime is non-nullable in Post model.
                Text(
                  _formatDateTime(_post!.publishTime),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          // Add follow button or other actions if needed
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    // Simple date formatting, replace with `intl` package for more complex needs
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  Widget _buildPostContentDetails() {
    // content is nullable in Post model. Use ?? to provide a default.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        _post!.content ?? '', // Provide default empty string if content is null
        style: const TextStyle(fontSize: 15, height: 1.5),
      ),
    );
  }

  Widget _buildInteractionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            icon: Icon(
              _post!.isLikedByCurrentUser // Non-nullable in Post
                  ? Icons.thumb_up
                  : Icons.thumb_up_outlined,
              color: _post!.isLikedByCurrentUser
                  ? Theme.of(context).primaryColor
                  : Colors.grey,
            ),
            label: Text(
              '${_post!.likes} Likes', // likes is non-nullable
              style: TextStyle(
                color: _post!.isLikedByCurrentUser
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
              ),
            ),
            onPressed: _handleLike,
          ),
          TextButton.icon(
            icon: const Icon(Icons.comment_outlined, color: Colors.grey),
            label: Text(
              // Displaying loaded comments count, not from _post.commentsCount
              // to reflect the currently visible list.
              '${_comments.length} Comments',
              style: const TextStyle(color: Colors.grey),
            ),
            onPressed: () {
              FocusScope.of(context).requestFocus(_commentFocusNode);
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.share_outlined, color: Colors.grey),
            label: Text(
              '${_post!.shares} Shares', // shares is non-nullable
              style: const TextStyle(color: Colors.grey),
            ),
            onPressed: () {
              // TODO: Implement share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share tapped (not implemented)')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    if (_isLoadingComments) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_comments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text('No comments yet. Be the first to comment!')),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _comments.length,
      itemBuilder: (context, index) {
        final comment = _comments[index];
        return CommentItem(
          comment: comment,
          onReplyTap: () => _replyToComment(comment),
          onLikeChanged: (isLiked) => _likeComment(comment, isLiked),
        );
      },
    );
  }

  void _replyToComment(Comment comment) {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to reply.')),
      );
      return;
    }
    setState(() {
      _replyingToComment = comment;
      // userName is non-nullable in Comment model.
      _commentController.text = '@${comment.userName} ';
      _commentController.selection = TextSelection.fromPosition(
        TextPosition(offset: _commentController.text.length),
      );
    });
    FocusScope.of(context).requestFocus(_commentFocusNode);
    print("Replying to comment ID: ${comment.id} by ${comment.userName}");
  }

  Future<void> _likeComment(Comment comment, bool newLikeStatus) async {
    if (_post == null || _currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please log in or ensure post data is loaded.')),
      );
      return;
    }

    final commentIndex = _comments.indexWhere((c) => c.id == comment.id);
    if (commentIndex == -1) return;

    // For optimistic UI update, you need to ensure your Comment model
    // has fields like 'isLiked' and 'likes'.
    final originalComment = _comments[commentIndex];
    final updatedComment = originalComment.copyWith(
      isLiked: newLikeStatus,
      // Example: Assumes 'isLiked' exists on Comment model
      likes: newLikeStatus
          ? (originalComment.likes + 1) // Assumes 'likes' exists
          : (originalComment.likes > 0 ? originalComment.likes - 1 : 0),
    );

    setState(() {
      _comments[commentIndex] = updatedComment;
    });

    // TODO: Implement actual repository call to toggle comment like status
    try {
      await _postRepository.toggleCommentLikeStatus(
        userId: _currentUser!.id,
        commentId: comment.id,
        currentLikeStatus: newLikeStatus,
      );
      // Optionally, refresh comments to get confirmed server state,
      // or rely on the optimistic update if toggleCommentLikeStatus returns the updated comment.
    } catch (e) {
      debugPrint('Error toggling comment like: $e');
      // Revert optimistic update
      setState(() {
        _comments[commentIndex] = originalComment;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update comment like.')),
        );
        //   }
        // }

        // Placeholder until Comment model and repository are fully updated
        print("Placeholder: User ${_currentUser!.id} ${newLikeStatus
            ? 'liked'
            : 'unliked'} comment ${comment.id}.");
        print(
            "INFO: Comment like/unlike UI shown optimistically if CommentItem handles it.");
        print(
            "INFO: Actual persistence of comment like needs Comment model updates (isLiked, likes) and PostRepository.toggleCommentLikeStatus implementation.");
      }
    }
  }


  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Colors.grey[300]!, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              focusNode: _commentFocusNode,
              controller: _commentController,
              decoration: InputDecoration(
                hintText: _replyingToComment != null
                    ? 'Reply to @${_replyingToComment!.userName}...'
                    : 'Add a comment...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10, // Adjusted padding for better look
                ),
                suffixIcon: _replyingToComment != null
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        setState(() {
                          _replyingToComment = null;
                          _commentController.clear();
                        });
                        FocusScope.of(context).unfocus(); // Unfocus to hide keyboard
                      },
                    )
                  : null,
              ),
              minLines: 1,
              maxLines: 5, // Allow more lines for longer comments
              textInputAction: TextInputAction.send, // Show send button on keyboard
              onSubmitted: (text) => _submitComment(), // Submit on keyboard send
            ),
          ),
          const SizedBox(width: 8),
          _isPostingComment
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
                  onPressed: _submitComment,
                ),
        ],
      ),
    );
  }
}

// Ensure you have a User model defined, e.g., in models/user.dart
// (This is just a reference, your actual User model might be different)
// class User {
//   final String id;
//   final String name;
//   final String? avatar; // Ensure this matches your User model's avatar field name
//
//   User({required this.id, required this.name, this.avatar});
//
//   // If your User model has a factory fromMap or other constructors, ensure they are correct.
//   // Example:
//   // factory User.fromMap(Map<String, dynamic> map) {
//   //   return User(
//   //     id: map['id'] as String,
//   //     name: map['name'] as String,
//   //     avatar: map['avatar'] as String?,
//   //   );
//   // }
// }
