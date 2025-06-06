class Comment {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final DateTime timestamp;
  int likes; // Made non-final to be updatable
  bool isLiked; // Made non-final to be updatable

  final String? parentId;
  final int replyCount;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    required this.timestamp,
    this.likes = 0,
    this.parentId,
    this.replyCount = 0,
    this.isLiked = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'commentId': id, // Changed from 'id'
      'postId': postId, // Changed from 'post_id'
      'userId': userId, // Changed from 'user_id'
      'userName': userName, // Changed from 'user_name'
      'userAvatar': userAvatar, // Changed from 'user_avatar'
      'commentText': content, // Changed from 'content' to match DB
      'commentTime': timestamp.millisecondsSinceEpoch, // Changed from 'timestamp'
      'likes': likes, // Added
      // 'parentId': parentId, // Not in current DB comments table
      // 'replyCount': replyCount, // Not in current DB comments table
      // 'isLiked' is not directly stored in the comments table, it's derived.
      // However, if fetching, it might be populated, but for inserts/updates, it's based on the likes table.
    };
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    // Robust parsing for timestamp (commentTime)
    dynamic commentTimeValue = map['commentTime'];
    int commentTimeMillis;
    if (commentTimeValue is int) {
      commentTimeMillis = commentTimeValue;
    } else if (commentTimeValue is String) {
      commentTimeMillis = int.tryParse(commentTimeValue) ?? 0;
    } else {
      commentTimeMillis = 0; // Default or error case
    }

    // Robust parsing for likes
    dynamic likesValue = map['likes'];
    int likesCount;
    if (likesValue is int) {
      likesCount = likesValue;
    } else if (likesValue is String) {
      likesCount = int.tryParse(likesValue) ?? 0;
    } else {
      likesCount = 0;
    }

    // Robust parsing for replyCount
    dynamic replyCountValue = map['replyCount'];
    int replies;
    if (replyCountValue is int) {
      replies = replyCountValue;
    } else if (replyCountValue is String) {
      replies = int.tryParse(replyCountValue) ?? 0;
    } else {
      replies = 0;
    }

    // Robust parsing for isLiked (expecting 0 or 1 from DB)
    dynamic isLikedValue = map['isLiked'];
    bool likedStatus;
    if (isLikedValue is int) {
      likedStatus = isLikedValue == 1;
    } else if (isLikedValue is String) {
      likedStatus = (int.tryParse(isLikedValue) ?? 0) == 1;
    } else if (isLikedValue is bool) { // Should not happen with current DB query but good to be safe
      likedStatus = isLikedValue;
    }
    else {
      likedStatus = false;
    }

    return Comment(
      id: map['commentId'] as String,
      postId: map['postId'] as String,
      userId: map['userId'] as String,
      userName: map['userName'] as String,
      userAvatar: map['userAvatar'] as String?,
      content: map['commentText'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(commentTimeMillis),
      likes: likesCount,
      parentId: map['parentId'] as String?,
      replyCount: replies,
      isLiked: likedStatus,
    );
  }

  Comment copyWith({
    String? id,
    String? postId,
    String? userId,
    String? userName,
    String? userAvatar,
    String? content,
    DateTime? timestamp,
    int? likes,
    String? parentId,
    int? replyCount,
    bool? isLiked,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      likes: likes ?? this.likes,
      parentId: parentId ?? this.parentId,
      replyCount: replyCount ?? this.replyCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}
