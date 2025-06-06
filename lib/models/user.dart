import 'package:flutter/foundation.dart';

class User {
  final String id;
  final String name;
  final String? avatar;
  final String? bio;
  final int followers;
  final int following;
  final int posts;
  final bool isFollowing;

  const User({
    required this.id,
    required this.name,
    required this.avatar,
    this.bio,
    required this.followers,
    required this.following,
    required this.posts,
    this.isFollowing = false,
  });

  User copyWith({
    String? id,
    String? name,
    String? avatar,
    String? bio,
    int? followers,
    int? following,
    int? posts,
    bool? isFollowing,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      posts: posts ?? this.posts,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'bio': bio,
      'followers': followers,
      'following': following,
      'posts': posts,
      'is_following': isFollowing,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String,
      bio: json['bio'] as String?,
      followers: json['followers'] as int,
      following: json['following'] as int,
      posts: json['posts'] as int,
      isFollowing: json['is_following'] as bool? ?? false,
    );
  }
}
