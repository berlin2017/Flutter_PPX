class SubscribedAccount {
  final String id;
  final String? name;
  final String? avatarUrl; // Renamed from 'avatar' to match 'avatar_url' in DB
  final String? description;
  final int? followers;
  final int? following;
  final bool? isVerified; // Mapped to INTEGER (0 or 1) in DB

  // 'hasUpdate' and 'isFollowed' from the original class are not in the DB schema.
  // We can decide to add them to the DB or manage them as transient state.
  // For now, I'll keep them in the model if they are used by the UI,
  // but they won't be part of toMap/fromMap unless added to DB.
  final bool hasUpdate;
  final bool isFollowed;

  const SubscribedAccount({
    required this.id,
    this.name,
    this.avatarUrl,
    this.description,
    this.followers,
    this.following,
    this.isVerified,
    this.hasUpdate = false, // Default value from original class
    this.isFollowed = false, // Default value from original class
  });

  factory SubscribedAccount.fromMap(Map<String, dynamic> map) {
    return SubscribedAccount(
      id: map['id'] as String,
      name: map['name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      description: map['description'] as String?,
      followers: map['followers'] as int?,
      following: map['following'] as int?,
      isVerified: map['is_verified'] != null ? (map['is_verified'] as int == 1) : null,
      // hasUpdate and isFollowed are not read from the map here as they are not in _accountsTable
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatar_url': avatarUrl,
      'description': description,
      'followers': followers,
      'following': following,
      'is_verified': isVerified == null ? null : (isVerified! ? 1 : 0),
      // hasUpdate and isFollowed are not written to the map as they are not in _accountsTable
    };
  }

  SubscribedAccount copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    String? description,
    int? followers,
    int? following,
    bool? isVerified,
    bool? hasUpdate,
    bool? isFollowed,
  }) {
    return SubscribedAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      description: description ?? this.description,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      isVerified: isVerified ?? this.isVerified,
      hasUpdate: hasUpdate ?? this.hasUpdate,
      isFollowed: isFollowed ?? this.isFollowed,
    );
  }
}
