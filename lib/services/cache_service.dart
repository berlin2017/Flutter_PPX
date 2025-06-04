import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post.dart';
import '../models/post_type.dart';
import '../models/subscribed_account.dart';
import '../models/comment.dart';

class CacheService {
  static const String _postsTable = 'posts';
  static const String _accountsTable = 'accounts';
  static const String _userInteractionsTable = 'user_interactions';
  static const String _commentsTable = 'comments';
  static const String _commentLikesTable = 'comment_likes';
  static Database? _database;
  static SharedPreferences? _prefs;

  // 单例模式
  static final CacheService instance = CacheService._internal();
  CacheService._internal();

  Future<void> init() async {
    try {
      if (_database == null) {
        _database = await _initDatabase();
      }
      if (_prefs == null) {
        _prefs = await SharedPreferences.getInstance();
      }
    } catch (e) {
      print('Cache service initialization failed: $e');
      // 重试一次
      await Future.delayed(const Duration(seconds: 1));
      _database = await _initDatabase();
      _prefs = await SharedPreferences.getInstance();
    }
  }

  Future<Database> _getDatabase() async {
    return _database ?? await _initDatabase();
  }

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'cache.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE $_postsTable (
            id TEXT PRIMARY KEY,
            title TEXT,
            content TEXT,
            thumbnail TEXT,
            video_url TEXT,
            author_name TEXT,
            author_avatar TEXT,
            author_id TEXT,
            likes INTEGER DEFAULT 0,
            dislikes INTEGER DEFAULT 0,
            comments INTEGER DEFAULT 0,
            shares INTEGER DEFAULT 0,
            type TEXT,
            publish_time TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE $_accountsTable (
            id TEXT PRIMARY KEY,
            name TEXT,
            avatar TEXT,
            description TEXT,
            followers INTEGER DEFAULT 0,
            following INTEGER DEFAULT 0,
            posts INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE $_userInteractionsTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT,
            post_id TEXT,
            is_liked INTEGER DEFAULT 0,
            is_disliked INTEGER DEFAULT 0,
            timestamp TEXT,
            UNIQUE(user_id, post_id)
          )
        ''');

        await db.execute('''
          CREATE TABLE $_commentsTable (
            id TEXT PRIMARY KEY,
            post_id TEXT,
            user_id TEXT,
            user_name TEXT,
            user_avatar TEXT,
            content TEXT,
            timestamp TEXT,
            likes INTEGER DEFAULT 0,
            parent_id TEXT,
            reply_count INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE $_commentLikesTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            comment_id TEXT,
            user_id TEXT,
            timestamp TEXT,
            UNIQUE(comment_id, user_id)
          )
        ''');
      },
    );
  }

  // 缓存帖子
  Future<void> cachePosts(int categoryIndex, List<Post> posts) async {
    final db = await _initDatabase();
    final batch = db.batch();

    for (final post in posts) {
      batch.insert(
        _postsTable,
        {
          'id': post.id,
          'category_index': categoryIndex,
          'title': post.title,
          'content': post.content,
          'author_name': post.authorName,
          'author_avatar': post.authorAvatar,
          'likes': post.likes,
          'dislikes': post.dislikes,
          'comments': post.comments,
          'shares': post.shares,
          'type': post.type.toString(),
          'thumbnail': post.thumbnail,
          'video_url': post.videoUrl,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit();
  }

  // 获取缓存的帖子
  Future<List<Post>> getCachedPosts(int categoryIndex) async {
    final db = await _initDatabase();
    final maps = await db.query(
      _postsTable,
      where: 'category_index = ?',
      whereArgs: [categoryIndex],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) {
      return Post(
        id: map['id'] as String,
        title: map['title'] as String,
        content: map['content'] as String,
        authorName: map['author_name'] as String,
        authorAvatar: map['author_avatar'] as String,
        likes: map['likes'] as int,
        dislikes: map['dislikes'] as int,
        comments: map['comments'] as int,
        shares: map['shares'] as int,
        type: PostType.values.firstWhere(
          (e) => e.toString() == map['type'],
        ),
        thumbnail: map['thumbnail'] as String?,
        videoUrl: map['video_url'] as String?,
      );
    }).toList();
  }

  // 缓存订阅账户 (Update to include is_followed)
  Future<void> cacheAccounts(List<SubscribedAccount> accounts) async {
    final db = await _initDatabase();
    final batch = db.batch();

    for (final account in accounts) {
      batch.insert(
        _accountsTable,
        {
          'id': account.name, // 使用name作为唯一标识
          'name': account.name,
          'avatar': account.avatar,
          'has_update': account.hasUpdate ? 1 : 0,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'is_followed': account.isFollowed ? 1 : 0, // Save follow status
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit();
  }

  // 获取缓存的订阅账户 (Update to include is_followed)
  Future<List<SubscribedAccount>> getCachedAccounts() async {
    final db = await _initDatabase();
    final maps = await db.query(
      _accountsTable,
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) {
      return SubscribedAccount(
        name: map['name'] as String,
        avatar: map['avatar'] as String,
        hasUpdate: map['has_update'] == 1,
        isFollowed: map['is_followed'] == 1, // Load follow status
      );
    }).toList();
  }

  // Check if an account is followed
  Future<bool> isAccountFollowed(String accountName) async {
    final db = await _initDatabase();
    final result = await db.query(
      _accountsTable,
      where: 'name = ?',
      whereArgs: [accountName],
      limit: 1,
    );
    if (result.isEmpty) {
      return false;
    }
    return result.first['is_followed'] == 1;
  }

  // Follow an account
  Future<void> followAccount(SubscribedAccount account) async {
    final db = await _initDatabase();
    await db.insert(
      _accountsTable,
      {
        'id': account.name,
        'name': account.name,
        'avatar': account.avatar,
        'has_update': account.hasUpdate ? 1 : 0,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'is_followed': 1, // Set is_followed to true
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Unfollow an account
  Future<void> unfollowAccount(String accountName) async {
    final db = await _initDatabase();
    await db.update(
      _accountsTable,
      {'is_followed': 0}, // Set is_followed to false
      where: 'name = ?',
      whereArgs: [accountName],
    );
  }

  // 获取帖子的交互状态
  Future<Map<String, bool>> getPostInteractionState(String postId) async {
    final db = await _initDatabase();
    final prefs = await _getPrefs();
    final userId = prefs.getString('current_user_id') ?? 'anonymous';

    final List<Map<String, dynamic>> interactions = await db.query(
      _userInteractionsTable,
      where: 'post_id = ? AND user_id = ?',
      whereArgs: [postId, userId],
    );

    if (interactions.isEmpty) {
      return {'isLiked': false, 'isDisliked': false};
    }

    final interaction = interactions.first;
    return {
      'isLiked': interaction['is_liked'] == 1,
      'isDisliked': interaction['is_disliked'] == 1,
    };
  }

  // 更新帖子的交互状态
  Future<void> updatePostInteraction(String postId, bool isLiked, bool isDisliked) async {
    final db = await _initDatabase();
    final prefs = await _getPrefs();
    final userId = prefs.getString('current_user_id') ?? 'anonymous';

    await db.insert(
      _userInteractionsTable,
      {
        'post_id': postId,
        'user_id': userId,
        'is_liked': isLiked ? 1 : 0,
        'is_disliked': isDisliked ? 1 : 0,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 获取帖子的评论列表
  Future<List<Comment>> getCommentsForPost(String postId, {String? parentId}) async {
    final db = await _initDatabase();
    final List<Map<String, dynamic>> maps = await db.query(
      _commentsTable,
      where: 'post_id = ? AND parent_id ${parentId == null ? "IS NULL" : "= ?"}',
      whereArgs: parentId == null ? [postId] : [postId, parentId],
      orderBy: 'timestamp DESC',
    );

    final currentUserId = 'current_user_id'; // TODO: 从认证服务获取
    final List<Comment> comments = [];

    for (var map in maps) {
      final commentId = map['id'] as String;
      
      // 获取回复数
      final repliesCount = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM $_commentsTable WHERE parent_id = ?',
        [commentId],
      )) ?? 0;

      // 检查是否已点赞
      final liked = await isCommentLiked(commentId, currentUserId);

      comments.add(Comment(
        id: commentId,
        postId: map['post_id'] as String,
        userId: map['user_id'] as String,
        userName: map['user_name'] as String,
        userAvatar: map['user_avatar'] as String,
        content: map['content'] as String,
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
        likes: map['likes'] as int,
        parentId: map['parent_id'] as String?,
        replyCount: repliesCount,
        isLiked: liked,
      ));
    }

    return comments;
  }

  // 获取评论
  Future<List<Comment>> getComments(String postId) async {
    final db = await _getDatabase();
    final List<Map<String, dynamic>> maps = await db.query(
      _commentsTable,
      where: 'post_id = ? AND parent_id IS NULL',
      whereArgs: [postId],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => Comment.fromJson(map)).toList();
  }

  // 获取评论回复
  Future<List<Comment>> getCommentReplies(String commentId) async {
    final db = await _getDatabase();
    final List<Map<String, dynamic>> maps = await db.query(
      _commentsTable,
      where: 'parent_id = ?',
      whereArgs: [commentId],
      orderBy: 'timestamp ASC',
    );

    return maps.map((map) => Comment.fromJson(map)).toList();
  }

  // 更新评论点赞状态
  Future<void> updateCommentLike(String commentId, bool isLiked) async {
    final db = await _getDatabase();
    final prefs = await _getPrefs();
    final userId = prefs.getString('current_user_id') ?? 'anonymous';

    if (isLiked) {
      await db.insert(
        _commentLikesTable,
        {
          'comment_id': commentId,
          'user_id': userId,
          'timestamp': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      await db.delete(
        _commentLikesTable,
        where: 'comment_id = ? AND user_id = ?',
        whereArgs: [commentId, userId],
      );
    }

    // 更新评论的点赞数
    await db.rawUpdate('''
      UPDATE $_commentsTable 
      SET likes = (
        SELECT COUNT(*) 
        FROM $_commentLikesTable 
        WHERE comment_id = ?
      )
      WHERE id = ?
    ''', [commentId, commentId]);
  }

  // 更新评论点赞状态（toggleCommentLike 的别名，用于向后兼容）
  Future<void> toggleCommentLike(String commentId, bool isLiked) async {
    return updateCommentLike(commentId, isLiked);
  }

  // 保存评论
  Future<void> saveComment(Comment comment) async {
    final db = await _getDatabase();
    await db.insert(
      _commentsTable,
      comment.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (comment.parentId != null) {
      // 更新父评论的回复数
      await db.rawUpdate('''
        UPDATE $_commentsTable 
        SET reply_count = (
          SELECT COUNT(*) 
          FROM $_commentsTable 
          WHERE parent_id = ?
        )
        WHERE id = ?
      ''', [comment.parentId, comment.parentId]);
    }
  }

  // 更新帖子的交互状态

  Future<void> _updatePostStats(String postId) async {
    final db = await _getDatabase();
    
    // 更新点赞数
    await db.rawUpdate('''
      UPDATE $_postsTable 
      SET likes = (
        SELECT COUNT(*) 
        FROM $_userInteractionsTable 
        WHERE post_id = ? AND is_liked = 1
      )
      WHERE id = ?
    ''', [postId, postId]);

    // 更新踩数
    await db.rawUpdate('''
      UPDATE $_postsTable 
      SET dislikes = (
        SELECT COUNT(*) 
        FROM $_userInteractionsTable 
        WHERE post_id = ? AND is_disliked = 1
      )
      WHERE id = ?
    ''', [postId, postId]);
  }

  // 检查用户是否已点赞评论
  Future<bool> isCommentLiked(String commentId, String userId) async {
    final db = await _initDatabase();
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM $_commentLikesTable WHERE comment_id = ? AND user_id = ?',
      [commentId, userId],
    ));
    return count! > 0;
  }

  // 删除评论
  Future<void> deleteComment(String commentId) async {
    final db = await _initDatabase();
    await db.transaction((txn) async {
      // 获取评论信息
      final comment = await txn.query(
        _commentsTable,
        where: 'id = ?',
        whereArgs: [commentId],
        limit: 1,
      );

      if (comment.isNotEmpty) {
        final postId = comment.first['post_id'] as String;
        final parentId = comment.first['parent_id'] as String?;

        // 删除评论
        await txn.delete(
          _commentsTable,
          where: 'id = ?',
          whereArgs: [commentId],
        );

        // 更新帖子评论数
        await txn.rawUpdate(
          'UPDATE $_postsTable SET comments = comments - 1 WHERE id = ?',
          [postId],
        );

        // 如果是回复评论，更新父评论的回复数
        if (parentId != null) {
          await txn.rawUpdate(
            'UPDATE $_commentsTable SET reply_count = reply_count - 1 WHERE id = ?',
            [parentId],
          );
        }
      }
    });
  }

  // 清除过期缓存
  Future<void> clearOldCache() async {
    final db = await _initDatabase();
    final oldTimestamp = DateTime.now()
        .subtract(const Duration(days: 7))
        .millisecondsSinceEpoch;

    await db.delete(
      _postsTable,
      where: 'timestamp < ?',
      whereArgs: [oldTimestamp],
    );

    await db.delete(
      _accountsTable,
      where: 'timestamp < ?',
      whereArgs: [oldTimestamp],
    );
  }
}
