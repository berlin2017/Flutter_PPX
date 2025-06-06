import 'dart:async';
import 'package:video_app/models/post.dart';
import 'package:video_app/models/comment.dart';
import 'package:video_app/models/post_type.dart'; // Import PostType
import 'package:video_app/services/database_helper.dart';
// import 'package:video_app/services/api_service.dart'; // Placeholder for your API service

class PostRepository {
  final DatabaseHelper _dbHelper;
  // final ApiService _apiService; // TODO: Uncomment when ApiService is created

  // TODO: Uncomment the ApiService parameter when it's created
  PostRepository(this._dbHelper /*, this._apiService */);

  Future<List<Post>> getPosts({
    String? userId,
    int limit = 20,
    int offset = 0,
    bool forceRefresh = false,
  }) async {
    print("PostRepository: getPosts called. Offset: $offset, Limit: $limit, ForceRefresh: $forceRefresh, UserID: $userId");
    bool shouldFetchFromApi = forceRefresh; // Always fetch if forced

    if (!forceRefresh && offset == 0) {
      final cachedPostsCheck = await _dbHelper.getPosts(limit: 1, offset: 0, currentUserId: userId);
      if (cachedPostsCheck.isEmpty) {
        print("PostRepository: Cache is empty for the first page. Will fetch from API.");
        shouldFetchFromApi = true;
      } else {
        final lastRefreshedTime = await _dbHelper.getLastRefreshedTime('all_posts_page_0');
        if (lastRefreshedTime == null || DateTime.now().difference(lastRefreshedTime).inMinutes > 60) { // e.g., refresh if older than 1 hour
          print("PostRepository: Cache for first page is older than 1 hour or no refresh time found. Will fetch from API.");
          shouldFetchFromApi = true;
        } else {
          print("PostRepository: Valid cache found for the first page. Not fetching from API unless forced.");
        }
      }
    } else if (offset > 0 && !forceRefresh) {
      // For subsequent pages, if not forcing refresh, rely on DB (which might be empty if API previously returned no more data)
      print("PostRepository: Not forcing refresh for a scrolled page (offset > 0). Will fetch from DB.");
      shouldFetchFromApi = false;
    } else if (forceRefresh) {
        print("PostRepository: forceRefresh is true. Will fetch from API.");
        shouldFetchFromApi = true;
    }

    if (shouldFetchFromApi) {
      print('PostRepository: Fetching posts from API (generating FAKE data)... Offset: $offset');
      List<Post> postsFromApi = [];
      try {
        await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

        int numberOfFakePostsToGenerate = 0;
        // Simulate API: only return data for first page (offset 0) or if explicitly asked for more in a real scenario
        // For this fake API, let's limit to one page of fresh data for simplicity unless forced
        if (offset == 0 ) { // Only generate for the first page for initial load/refresh
             numberOfFakePostsToGenerate = limit;
        } else {
            // Simulate end of API data for subsequent pages unless a real API call would fetch more
            print("PostRepository: FAKE API - offset is $offset, returning no more fake posts to simulate end of data for subsequent pages.");
            numberOfFakePostsToGenerate = 0; 
        }

        for (int i = 0; i < numberOfFakePostsToGenerate; i++) {
          String postId = 'fake_post_${offset + i}_${DateTime.now().millisecondsSinceEpoch}';
          postsFromApi.add(Post(
            id: postId,
            title: 'Fake Post Title ${offset + i + 1}',
            content: 'This is the amazing content for fake post number ${offset + i + 1}. '
                'It has some random text to make it look like a real post. '
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
            authorId: 'fake_author_${(i % 3) + 1}',
            authorName: 'Fake Author ${(i % 3) + 1}',
            authorAvatar: 'https://picsum.photos/seed/${postId}_author/100/100',
            thumbnail: (i % 4 == 0) ? null : 'https://picsum.photos/seed/$postId/400/${200 + (i%5)*20}',
            videoUrl: (i % 3 == 1) ? 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4' : null,
            type: (i % 3 == 0) ? PostType.text : ((i % 3 == 1) ? PostType.video : PostType.image),
            likes: (i + 1) * 17 % 200,
            commentsCount: (i + 1) * 5 % 50,
            shares: (i+1) * 3 % 30,
            publishTime: DateTime.now().subtract(Duration(hours: offset + i, minutes: i*10)),
            isLikedByCurrentUser: (userId != null && i % 2 == 0) ? true : false, dislikes: i,
          ));
        }

        print('PostRepository: Generated ${postsFromApi.length} fake posts for offset $offset.');

        if (postsFromApi.isNotEmpty) {
          await _dbHelper.insertOrUpdatePosts(postsFromApi, currentUserId: userId);
          print('PostRepository: Fake posts "cached" into DB.');
        }
        if (offset == 0 && postsFromApi.isNotEmpty) { // Only update refresh time if API returned data for the first page
          await _dbHelper.setLastRefreshedTime('all_posts_page_0');
          print('PostRepository: Updated lastRefreshedTime for all_posts_page_0.');
        }
        // If API returned data, return it. Otherwise, fall through to fetch from DB (which might also be empty).
        // This handles cases where an offset page is requested and API provides new data (real API scenario).
        // For this fake API, if offset > 0 and no data generated, it relies on DB.
        if (postsFromApi.isNotEmpty || (offset > 0 && !forceRefresh) ) {
            return postsFromApi; 
        }

      } catch (e, stackTrace) {
        print('PostRepository: Failed to generate or cache fake posts: $e');
        print('PostRepository: StackTrace: $stackTrace');
        // Don't rethrow, attempt to load from DB as a fallback
      }
    } 

    print('PostRepository: Fetching posts from DB. Offset: $offset, Limit: $limit');
    return _dbHelper.getPosts(limit: limit, offset: offset, currentUserId: userId);
  }

  Future<Post?> getPostById(String postId, {String? userId}) async {
    print('PostRepository: Fetching post $postId from DB for user $userId.');
    Post? post = await _dbHelper.getPostById(postId, currentUserId: userId);

    if (post == null) {
      print('PostRepository: Post $postId not found in DB, trying FAKE API single fetch...');
      try {
        await Future.delayed(const Duration(milliseconds: 300));
        if (postId.startsWith("fake_post_detail_")) {
          post = Post(
            id: postId,
            title: 'Detailed Fake Post: ${postId.substring(17)}',
            content: 'This is a detailed fake post fetched individually. It might have specific content related to its ID.',
            authorId: 'fake_author_detail',
            authorName: 'Detail Author',
            authorAvatar: 'https://picsum.photos/seed/${postId}_author/100/100',
            thumbnail: 'https://picsum.photos/seed/$postId/600/300',
            type: PostType.image, 
            likes: 123,
            commentsCount: 45,
            shares: 67,
            publishTime: DateTime.now().subtract(const Duration(days: 1)),
            isLikedByCurrentUser: userId != null, dislikes: 10,
          );
          await _dbHelper.insertOrUpdatePost(post, isLiked: userId != null); 
          print('PostRepository: Generated and cached a fake detailed post for $postId.');
        } else {
          print('PostRepository: FAKE API - No specific fake detail generation for $postId.');
        }
      } catch (e) {
        print('PostRepository: Failed to fetch/generate fake post $postId from API: $e');
      }
    }
    return post;
  }

  Future<List<Comment>> getCommentsForPost(String postId, {String? currentUserId, bool forceRefresh = false}) async {
    if (forceRefresh) {
      print("PostRepository: forceRefresh for comments on $postId - FAKE API: generating new comments.");
      // Consider clearing only if API call is expected to be successful
      // For fake data, we clear then add new.
      await _dbHelper.clearCommentsForPost(postId); 
      List<Comment> fakeComments = [];
      int numberOfFakeComments = 5; 
      for (int i=0; i < numberOfFakeComments; i++) {
        String commentId = "fake_comment_${postId}_${i}_${DateTime.now().millisecondsSinceEpoch}";
        fakeComments.add(Comment(
          id: commentId,
          postId: postId,
          userId: "fake_commenter_id_$i",
          userName: "Commenter ${i+1}",
          userAvatar: "https://picsum.photos/seed/$commentId/50/50",
          content: "This is fake comment number ${i+1} for post $postId. It's quite insightful!",
          timestamp: DateTime.now().subtract(Duration(minutes: (numberOfFakeComments - i) * 5)),
          likes: i * 2, // Initial fake likes
          isLiked: (currentUserId != null && i % 2 == 0), // Fake liked status
          replyCount: 0, 
        ));
      }
      for (var comment in fakeComments) {
        // The addCommentAndReturn method in DB helper now expects a Comment object
        // and will handle its `likes` and `isSynced` properties based on its toMap().
        await _dbHelper.addCommentAndReturn(comment); 
      }
      print("PostRepository: Generated and cached ${fakeComments.length} fake comments for post $postId.");
      // After generating, fetch them with correct like status for the current user
      return _dbHelper.getCommentsForPost(postId, currentUserId: currentUserId);
    }

    print('PostRepository: Fetching comments for post $postId from DB for user $currentUserId.');
    return _dbHelper.getCommentsForPost(postId, currentUserId: currentUserId);
  }

  Future<Comment?> addComment({
    required String postId,
    required String userId,
    required String userName,
    String? userAvatar,
    required String commentText,
  }) async {
    print('PostRepository: Attempting to add comment to post $postId by user $userId...');
    final String commentId = "local_comment_${DateTime.now().millisecondsSinceEpoch}";

    final commentObject = Comment(
      id: commentId,
      postId: postId,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      content: commentText,
      timestamp: DateTime.now(),
      likes: 0,
      isLiked: false, 
      replyCount: 0,
    );

    try {
      // TODO: API call here first. If successful, then update DB.
      // For now, directly to DB:
      final newComment = await _dbHelper.addCommentAndReturn(commentObject);
      if (newComment != null) {
        print('PostRepository: Comment added to DB successfully.');
        // Optionally, update commentsCount on the Post object in DB here or via a trigger.
      } else {
        print('PostRepository: Failed to add comment to DB.');
      }
      return newComment;
    } catch (e) {
      print('PostRepository: Error adding comment: $e');
      return null;
    }
  }

  Future<bool> toggleLikeStatus({
    required String userId,
    required String postId,
    required bool currentLikeStatus,
  }) async {
    print('PostRepository: Toggling post like for post $postId by user $userId. Current like status was: $currentLikeStatus');
    // TODO: Implement API call to sync like status if a real API exists.

    try {
      if (currentLikeStatus) { 
        await _dbHelper.removeLike(userId, postId);
        print('PostRepository: Post $postId unliked in DB by user $userId.');
      } else { 
        await _dbHelper.addLike(userId, postId);
        print('PostRepository: Post $postId liked in DB by user $userId.');
      }
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate API call delay
      return true; 
    } catch (e) {
      print('PostRepository: Error toggling post like status in DB: $e');
      return false;
    }
  }

  // New method to toggle like status for a comment
  Future<bool> toggleCommentLikeStatus({
    required String userId,
    required String commentId,
    required bool currentLikeStatus, // True if currently liked, false otherwise
  }) async {
    print('PostRepository: Toggling comment like for comment $commentId by user $userId. Current status: $currentLikeStatus');
    // TODO: Implement API call to sync comment like status with a backend.
    // If API call is successful, then update local DB.

    try {
      if (currentLikeStatus) {
        // User wants to unlike the comment
        await _dbHelper.removeCommentLike(userId, commentId);
        print('PostRepository: Comment $commentId unliked in DB by user $userId.');
      } else {
        // User wants to like the comment
        await _dbHelper.addCommentLike(userId, commentId);
        print('PostRepository: Comment $commentId liked in DB by user $userId.');
      }
      // Simulate API call delay if you have an API
      // await Future.delayed(const Duration(milliseconds: 300)); 
      return true; // Assume success if DB operations complete
    } catch (e) {
      print('PostRepository: Error toggling comment like status in DB for $commentId: $e');
      // In a real app, you might want to differentiate errors or allow the UI to handle them.
      return false; // Signal failure
    }
  }

}
