class Comment {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String userAvatar;
  final String content;
  final DateTime timestamp;
  final int likes;
  final String? parentId; // 父评论ID，如果是二级评论的话
  final int replyCount; // 回复数量
  final bool isLiked; // 当前用户是否点赞

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.content,
    required this.timestamp,
    this.likes = 0,
    this.parentId,
    this.replyCount = 0,
    this.isLiked = false,
  });  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'likes': likes,
      'parent_id': parentId,
      'reply_count': replyCount,
      'is_liked': isLiked,
    };
  }

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      userAvatar: json['user_avatar'] as String,
      content: json['content'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      likes: json['likes'] as int? ?? 0,
      parentId: json['parent_id'] as String?,
      replyCount: json['reply_count'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
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
