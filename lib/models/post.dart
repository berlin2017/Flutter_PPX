import 'package:video_app/models/post_type.dart';

class Post {
  final String id;
  // final String? userId; // Removed as it seems redundant with authorId for DB purposes
  final String? title;
  final String? content;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final PostType type;
  final String? videoUrl;
  final String? thumbnail;
  final DateTime publishTime;
  final int likes;
  final int dislikes;
  final int commentsCount;
  final int shares;
  final bool isPrivate;
  final bool isLikedByCurrentUser;
  final int? viewCount;
  final String? location;
  final String? seriesId;
  final int? chapter;
  final List<String>? tags;

  Post({
    required this.id,
    // this.userId,
    this.title,
    this.content,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.type,
    this.videoUrl,
    this.thumbnail,
    required this.publishTime,
    this.likes = 0,
    this.dislikes = 0,
    this.commentsCount = 0,
    this.shares = 0,
    this.isPrivate = false,
    this.isLikedByCurrentUser = false,
    this.viewCount,
    this.location,
    this.seriesId,
    this.chapter,
    this.tags,
  });

  Post copyWith({
    String? id,
    // String? userId,
    String? title,
    String? content,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    PostType? type,
    String? videoUrl,
    String? thumbnail,
    DateTime? publishTime,
    int? likes,
    int? dislikes,
    int? commentsCount,
    int? shares,
    bool? isPrivate,
    bool? isLikedByCurrentUser,
    int? viewCount,
    String? location,
    String? seriesId,
    int? chapter,
    List<String>? tags,
  }) {
    return Post(
      id: id ?? this.id,
      // userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      type: type ?? this.type,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnail: thumbnail ?? this.thumbnail,
      publishTime: publishTime ?? this.publishTime,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
      commentsCount: commentsCount ?? this.commentsCount,
      shares: shares ?? this.shares,
      isPrivate: isPrivate ?? this.isPrivate,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      viewCount: viewCount ?? this.viewCount,
      location: location ?? this.location,
      seriesId: seriesId ?? this.seriesId,
      chapter: chapter ?? this.chapter,
      tags: tags ?? this.tags,
    );
  }

  factory Post.fromMap(Map<String, dynamic> map, {bool isLiked = false}) {
    PostType _parsePostType(dynamic typeValue) {
      if (typeValue is String) {
        return PostType.values.firstWhere(
          (e) => e.name.toLowerCase() == typeValue.toLowerCase(),
          orElse: () => PostType.text,
        );
      } else if (typeValue is int) {
        if (typeValue >= 0 && typeValue < PostType.values.length) {
          return PostType.values[typeValue];
        }
      }
      return PostType.text;
    }

    dynamic publishTimeValue = map['publishTime'];
    int publishTimeMillis;
    if (publishTimeValue is int) {
      publishTimeMillis = publishTimeValue;
    } else if (publishTimeValue is String) {
      publishTimeMillis = int.tryParse(publishTimeValue) ?? 0;
    } else {
      publishTimeMillis = 0; // Default or error case
    }

    return Post(
      id: map['id'] as String,
      // userId: map['authorId'] as String?, // Assuming authorId should be used here if userId was meant for author
      title: map['title'] as String?,
      content: map['content'] as String?,
      authorId: map['authorId'] as String, // This is the correct field from DB
      authorName: map['authorName'] as String,
      authorAvatar: map['authorAvatar'] as String?,
      type: _parsePostType(map['type']),
      videoUrl: map['videoUrl'] as String?,
      thumbnail: map['thumbnail'] as String?,
      publishTime: DateTime.fromMillisecondsSinceEpoch(publishTimeMillis),
      likes: map['likes'] as int? ?? 0,
      dislikes: map['dislikes'] as int? ?? 0,
      commentsCount: map['comments'] as int? ?? 0, // In DB it's 'comments'
      shares: map['shares'] as int? ?? 0,
      isPrivate: map['isPrivate'] as bool? ?? false, // Read if present, but not in tablePosts schema
      isLikedByCurrentUser: isLiked, // This is passed as a separate parameter for runtime state
      viewCount: map['viewCount'] as int?, // Read if present, but not in tablePosts schema
      location: map['location'] as String?, // Read if present, but not in tablePosts schema
      seriesId: map['seriesId'] as String?, // Read if present, but not in tablePosts schema
      chapter: map['chapter'] as int?, // Read if present, but not in tablePosts schema
      tags: map['tags'] == null ? null : List<String>.from(map['tags'] as List<dynamic>), // Read if present, but not in tablePosts schema
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      // 'userId': userId, // Removed: posts table does not have userId, uses authorId
      'title': title,
      'content': content,
      'authorId': authorId, // Correct: posts table has authorId
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'type': type.name,
      'videoUrl': videoUrl,
      'thumbnail': thumbnail,
      'publishTime': publishTime.millisecondsSinceEpoch,
      'likes': likes,
      'dislikes': dislikes,
      'comments': commentsCount, // Changed 'commentsCount' to 'comments' to match DB table_posts
      'shares': shares,
      // 'isPrivate': isPrivate, // tablePosts does not have isPrivate
      'isLikedByCurrentUser': isLikedByCurrentUser ? 1 : 0, // Stored as INTEGER (0 or 1) in DB
      // 'viewCount': viewCount, // tablePosts does not have viewCount
      // 'location': location, // tablePosts does not have location
      // 'seriesId': seriesId, // tablePosts does not have seriesId
      // 'chapter': chapter, // tablePosts does not have chapter
      // 'tags': tags, // tablePosts does not have tags
    };
  }
}
