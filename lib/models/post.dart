import 'post_type.dart';

class Post {  final String id;
  final String title;
  final String content;
  final String? thumbnail;
  final String? videoUrl;
  final String authorName;
  final String authorAvatar;
  final String? authorId;
  final int likes;
  final int dislikes;
  final int comments;
  final int shares;
  final PostType type;
  final DateTime? publishTime;

  const Post({
    required this.id,
    required this.title,
    required this.content,
    this.thumbnail,
    this.videoUrl,
    required this.authorName,
    required this.authorAvatar,
    this.authorId,
    required this.likes,
    required this.dislikes,
    required this.comments,
    required this.shares,
    required this.type,
    this.publishTime,
  });

  Post copyWith({
    String? id,
    String? title,
    String? content,
    String? thumbnail,
    String? videoUrl,
    String? authorName,
    String? authorAvatar,
    String? authorId,
    int? likes,
    int? dislikes,
    int? comments,
    int? shares,
    PostType? type,
    DateTime? publishTime,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      thumbnail: thumbnail ?? this.thumbnail,
      videoUrl: videoUrl ?? this.videoUrl,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      authorId: authorId ?? this.authorId,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      type: type ?? this.type,
      publishTime: publishTime ?? this.publishTime,
    );
  }
}
