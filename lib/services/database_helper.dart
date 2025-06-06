import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p; // For p.join

// Import your models here, ensure paths are correct
import 'package:video_app/models/post.dart'; // Assuming Post model is here
import 'package:video_app/models/comment.dart'; // Assuming Comment model is here
import 'package:video_app/models/user.dart';   // Assuming User model is here
import 'package:video_app/models/post_type.dart'; // Assuming PostType enum is here


class DatabaseHelper {
  static const _databaseName = "VideoApp.db";
  static const _databaseVersion = 2; // Incremented version for schema changes

  // Table names
  static const tablePosts = 'posts';
  static const tableComments = 'comments';
  static const tableUsers = 'users'; // Example, if you cache user details
  static const tablePostLikes = 'post_likes';
  static const tableCommentLikes = 'comment_likes'; // New table for comment likes
  static const tableLastRefreshed = 'last_refreshed'; // For caching strategy


  // --- Singleton Pattern ---
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = p.join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, 
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tablePosts (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT,
        authorId TEXT,
        authorName TEXT,
        authorAvatar TEXT,
        thumbnail TEXT,
        videoUrl TEXT,
        type TEXT, 
        likes INTEGER DEFAULT 0,
        dislikes INTEGER DEFAULT 0, 
        comments INTEGER DEFAULT 0,
        shares INTEGER DEFAULT 0,
        publishTime TEXT,
        isSynced INTEGER DEFAULT 0,
        isLikedByCurrentUser INTEGER DEFAULT 0,
        isPrivate INTEGER DEFAULT 0,
        viewCount INTEGER DEFAULT 0,
        location TEXT,
        seriesId TEXT,
        chapter INTEGER,
        tags TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableComments (
        commentId TEXT PRIMARY KEY,
        postId TEXT NOT NULL,
        userId TEXT NOT NULL,
        userName TEXT,
        userAvatar TEXT,
        commentText TEXT NOT NULL,
        commentTime TEXT NOT NULL,
        likes INTEGER DEFAULT 0,       -- Added likes count
        isSynced INTEGER DEFAULT 0,
        FOREIGN KEY (postId) REFERENCES $tablePosts (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableUsers (
        id TEXT PRIMARY KEY,
        name TEXT,
        avatarUrl TEXT,
        bio TEXT,
        followers INTEGER DEFAULT 0,
        following INTEGER DEFAULT 0,
        postsCount INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE $tablePostLikes (
        userId TEXT NOT NULL,
        postId TEXT NOT NULL,
        PRIMARY KEY (userId, postId),
        FOREIGN KEY (postId) REFERENCES $tablePosts (id) ON DELETE CASCADE
      )
    ''');

    // New table for comment likes
    await db.execute('''
      CREATE TABLE $tableCommentLikes (
        userId TEXT NOT NULL,
        commentId TEXT NOT NULL,
        PRIMARY KEY (userId, commentId),
        FOREIGN KEY (commentId) REFERENCES $tableComments (commentId) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableLastRefreshed (
        itemId TEXT PRIMARY KEY,
        lastRefreshedTime TEXT NOT NULL
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print("Database upgrading from $oldVersion to $newVersion");
    if (oldVersion < 2) {
      // Add likes column to comments table
      try {
        await db.execute("ALTER TABLE $tableComments ADD COLUMN likes INTEGER DEFAULT 0;");
         print("Upgraded $tableComments: Added likes column.");
      } catch (e) {
        print("Error adding likes column to $tableComments (it might already exist): $e");
      }
      // Create comment_likes table
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $tableCommentLikes (
            userId TEXT NOT NULL,
            commentId TEXT NOT NULL,
            PRIMARY KEY (userId, commentId),
            FOREIGN KEY (commentId) REFERENCES $tableComments (commentId) ON DELETE CASCADE
          )
        ''');
        print("Upgraded: Created $tableCommentLikes table.");
      } catch (e) {
        print("Error creating $tableCommentLikes table (it might already exist): $e");
      }
    }
  }

  // --- Helper Methods for Posts (omitted for brevity, assume they are correct) ---
   Future<int> insertOrUpdatePost(Post post, {bool? isLiked}) async {
    final db = await database;
    Map<String, dynamic> row = post.toMap();
    row['type'] = post.type.name; 
    if (isLiked != null) {
      row['isLikedByCurrentUser'] = isLiked ? 1 : 0;
    } else {
      row['isLikedByCurrentUser'] = post.isLikedByCurrentUser ? 1 : 0;
    }
    int id = await db.insert(
      tablePosts,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await setLastRefreshedTime(post.id);
    return id;
  }

  Future<void> insertOrUpdatePosts(List<Post> posts, {String? currentUserId}) async {
    final db = await database;
    Batch batch = db.batch();
    for (var post in posts) {
      Map<String, dynamic> row = post.toMap();
      row['type'] = post.type.name; 
      if (currentUserId != null) {
        final liked = await isPostLikedByUser(currentUserId, post.id); 
        row['isLikedByCurrentUser'] = liked ? 1 : 0;
      } else {
        row['isLikedByCurrentUser'] = post.isLikedByCurrentUser ? 1 : 0;
      }
      batch.insert(tablePosts, row, conflictAlgorithm: ConflictAlgorithm.replace);
      // await setLastRefreshedTime(post.id); // Consider batching this too or a general refresh time
    }
    await batch.commit(noResult: true);
    if (posts.isNotEmpty) { // Set refresh time only if posts were processed
        await setLastRefreshedTime('all_posts_page_0'); 
    }
  }


  Future<Post?> getPostById(String postId, {String? currentUserId}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tablePosts,
      where: 'id = ?',
      whereArgs: [postId],
    );

    if (maps.isNotEmpty) {
      Post post = Post.fromMap(maps.first);
      if (currentUserId != null) {
        final liked = await isPostLikedByUser(currentUserId, postId);
        return post.copyWith(isLikedByCurrentUser: liked);
      }
      return post;
    }
    return null;
  }

  Future<List<Post>> getPosts({int limit = 20, int offset = 0, String? currentUserId}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tablePosts,
      orderBy: 'publishTime DESC',
      limit: limit,
      offset: offset,
    );

    List<Post> posts = [];
    for (var map in maps) {
      Post post = Post.fromMap(map);
      if (currentUserId != null) {
        final liked = await isPostLikedByUser(currentUserId, post.id);
        posts.add(post.copyWith(isLikedByCurrentUser: liked));
      } else {
        posts.add(post);
      }
    }
    return posts;
  }

  Future<List<Post>> searchPosts(String query, {String? currentUserId}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tablePosts,
      where: 'title LIKE ? OR content LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'publishTime DESC',
    );
    List<Post> posts = [];
    for (var map in maps) {
      Post post = Post.fromMap(map);
      if (currentUserId != null) {
        final liked = await isPostLikedByUser(currentUserId, post.id);
        posts.add(post.copyWith(isLikedByCurrentUser: liked));
      } else {
        posts.add(post);
      }
    }
    return posts;
  }

  Future<int> deletePost(String id) async {
    final db = await database;
    return await db.delete(
      tablePosts,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Helper Methods for Comments ---
  Future<Comment?> addCommentAndReturn(Comment comment) async {
    final db = await database;
    Map<String, dynamic> row = comment.toMap();
    // Ensure isSynced is handled if model doesn't provide it
    row['isSynced'] = row['isSynced'] ?? 0; 
    // Ensure likes is initialized if model doesn't provide it or if it's null
    row['likes'] = row['likes'] ?? 0;

    try {
      await db.insert(tableComments, row, conflictAlgorithm: ConflictAlgorithm.replace);
      return comment; // Return the original comment, assuming ID was already set
    } catch (e) {
      print("Error inserting comment into DB: $e");
      return null;
    }
  }


  Future<List<Comment>> getCommentsForPost(String postId, {String? currentUserId}) async {
    final db = await database;
    // Query to get comments and check if the current user has liked them
    // The 'isLiked' field will be 1 if liked, 0 otherwise.
    String query = '''
      SELECT c.*, CASE WHEN cl.userId IS NOT NULL THEN 1 ELSE 0 END AS isLiked
      FROM $tableComments c
      LEFT JOIN $tableCommentLikes cl ON c.commentId = cl.commentId AND cl.userId = ?
      WHERE c.postId = ?
      ORDER BY c.commentTime ASC
    ''';
    final List<Map<String, dynamic>> maps = await db.rawQuery(query, [currentUserId, postId]);
    
    return List.generate(maps.length, (i) {
      // The map from rawQuery already contains 'isLiked' derived from the JOIN.
      // And 'likes' is directly from the comments table.
      return Comment.fromMap(maps[i]);
    });
  }

  Future<int> clearCommentsForPost(String postId) async {
    final db = await database;
    return await db.delete(
      tableComments,
      where: 'postId = ?',
      whereArgs: [postId],
    );
  }

  // --- Helper Methods for Post Likes (omitted for brevity) ---
  Future<void> addLike(String userId, String postId) async {
    final db = await database;
    await db.insert(
      tablePostLikes,
      {'userId': userId, 'postId': postId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    await db.update(
        tablePosts,
        {'isLikedByCurrentUser': 1},
        where: 'id = ?',
        whereArgs: [postId]
    );
  }

  Future<void> removeLike(String userId, String postId) async {
    final db = await database;
    await db.delete(
      tablePostLikes,
      where: 'userId = ? AND postId = ?',
      whereArgs: [userId, postId],
    );
    await db.update(
        tablePosts,
        {'isLikedByCurrentUser': 0},
        where: 'id = ?',
        whereArgs: [postId]
    );
  }

  Future<bool> isPostLikedByUser(String userId, String postId) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      tablePostLikes,
      where: 'userId = ? AND postId = ?',
      whereArgs: [userId, postId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<int> getLikesForPost(String postId) async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $tablePostLikes WHERE postId = ?', [postId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // --- Helper Methods for Comment Likes (NEW) ---
  Future<void> addCommentLike(String userId, String commentId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        tableCommentLikes,
        {'userId': userId, 'commentId': commentId},
        conflictAlgorithm: ConflictAlgorithm.ignore, 
      );
      await txn.rawUpdate(
        'UPDATE $tableComments SET likes = likes + 1 WHERE commentId = ?', 
        [commentId]
      );
    });
    print("User $userId liked comment $commentId. Likes incremented.");
  }

  Future<void> removeCommentLike(String userId, String commentId) async {
    final db = await database;
    await db.transaction((txn) async {
      int count = await txn.delete(
        tableCommentLikes,
        where: 'userId = ? AND commentId = ?',
        whereArgs: [userId, commentId],
      );
      // Only decrement if a like was actually removed for this user
      if (count > 0) {
        await txn.rawUpdate(
          'UPDATE $tableComments SET likes = MAX(0, likes - 1) WHERE commentId = ?', 
          [commentId]
        );
      }
    });
    print("User $userId unliked comment $commentId. Likes decremented if like existed.");
  }

  // isCommentLikedByUser is effectively handled by the JOIN in getCommentsForPost
  // but can be a standalone method if needed elsewhere.
  Future<bool> isCommentLikedByUser(String userId, String commentId) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      tableCommentLikes,
      where: 'userId = ? AND commentId = ?',
      whereArgs: [userId, commentId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // --- Caching Refresh Time (omitted for brevity) ---
  Future<void> setLastRefreshedTime(String itemId) async {
    final db = await database;
    await db.insert(
      tableLastRefreshed,
      {'itemId': itemId, 'lastRefreshedTime': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<DateTime?> getLastRefreshedTime(String itemId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableLastRefreshed,
      where: 'itemId = ?',
      whereArgs: [itemId],
      limit: 1,
    );
    if (maps.isNotEmpty && maps.first['lastRefreshedTime'] != null) {
      return DateTime.tryParse(maps.first['lastRefreshedTime'] as String);
    }
    return null;
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(tableComments);
    await db.delete(tablePostLikes);
    await db.delete(tableCommentLikes); // Clear new table
    await db.delete(tablePosts);
    await db.delete(tableUsers); 
    await db.delete(tableLastRefreshed);
    print("All data cleared from the database.");
  }
}
