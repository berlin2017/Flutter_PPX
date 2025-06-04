class SubscribedAccount {
  final String name;
  final String avatar;
  final bool hasUpdate;
  final bool isFollowed; // Add isFollowed property

  const SubscribedAccount({
    required this.name,
    required this.avatar,
    required this.hasUpdate,
    this.isFollowed = false, // Default to false
  });

  // Add copyWith method to easily create modified instances
  SubscribedAccount copyWith({
    String? name,
    String? avatar,
    bool? hasUpdate,
    bool? isFollowed,
  }) {
    return SubscribedAccount(
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      hasUpdate: hasUpdate ?? this.hasUpdate,
      isFollowed: isFollowed ?? this.isFollowed,
    );
  }
}
