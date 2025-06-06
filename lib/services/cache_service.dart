import 'dart:async';
import 'dart:convert'; // For jsonEncode and jsonDecode
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:video_app/models/post.dart';
import 'package:video_app/models/post_type.dart'; // Ensure this is imported
import 'package:video_app/models/subscribed_account.dart';
import 'package:video_app/models/comment.dart';

class CacheService {
  static const _databaseName = 'video_app_cache.db';
  static const int _databaseVersion = 2; // Incremented version

  static const _postsTable = 'posts';
  static const _accountsTable = 'subscribed_accounts';
  static const _commentsTable = 'comments';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getDatabasesPath();
    final path = join(documentsDirectory, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createTables,
      onUpgrade: _onUpgrade, // Added onUpgrade callback
    );
  }

  // Called if the database version increases
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // For simplicity in this example, we just drop and recreate tables.
    // In a production app, you'd use ALTER TABLE for migrations to preserve data.
    await db.execute("DROP TABLE IF EXISTS $_postsTable");
    await db.execute("DROP TABLE IF EXISTS $_accountsTable");
    await db.execute("DROP TABLE IF EXISTS $_commentsTable");
    await _createTables(db, newVersion);
     print("Database upgraded from version $oldVersion to $newVersion. Tables recreated.");
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_postsTable (
        id TEXT PRIMARY KEY,
        user_id TEXT, 
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
        publish_time INTEGER, 
        is_private INTEGER DEFAULT 0,
        view_count INTEGER DEFAULT 0,
        location TEXT,
        series_id TEXT,
        chapter INTEGER,
        tags TEXT,
        category_index INTEGER 
      )
    ''');

    await db.execute('''
      CREATE TABLE $_accountsTable (
        id TEXT PRIMARY KEY,
        name TEXT,
        avatar_url TEXT,
        description TEXT,
        followers INTEGER,
        following INTEGER,
        is_verified INTEGER
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
        timestamp INTEGER, 
        likes INTEGER
      )
    ''');
  }

  Future<void> cachePosts(List<Post> posts, int categoryIndex) async {
    final db = await database;
    final batch = db.batch();
    for (var post in posts) {
      batch.insert(
        _postsTable,
        {
          'id': post.id,
          'user_id': post.authorId,
          'title': post.title,
          'content': post.content,
          'thumbnail': post.thumbnail,
          'video_url': post.videoUrl,
          'author_name': post.authorName,
          'author_avatar': post.authorAvatar,
          'author_id': post.authorId,
          'likes': post.likes,
          'dislikes': post.dislikes,
          'comments': post.commentsCount, // Map Post.commentsCount to 'comments' column
          'shares': post.shares,
          'type': post.type.toString(), // Store PostType as string
          'publish_time': post.publishTime.millisecondsSinceEpoch, // Store as integer
          'is_private': post.isPrivate ? 1 : 0,
          'view_count': post.viewCount,
          'location': post.location,
          'series_id': post.seriesId,
          'chapter': post.chapter,
          'tags': post.tags != null ? jsonEncode(post.tags) : null, // Encode tags to JSON string
          'category_index': categoryIndex,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Post>> getCachedPosts(int categoryIndex) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _postsTable,
      where: 'category_index = ?',
      whereArgs: [categoryIndex],
      orderBy: 'publish_time DESC', // Example ordering
    );

    return List.generate(maps.length, (i) {
      final tagsString = maps[i]['tags'] as String?;
      List<String>? tags;
      if (tagsString != null && tagsString.isNotEmpty) {
        try {
          tags = List<String>.from(jsonDecode(tagsString) as List);
        } catch (e) {
          print("Error decoding tags for post ${maps[i]['''id''']}': $e");
          tags = null; // Or an empty list: [];
        }
      }
      
      PostType type;
      try {
        // Assuming PostType.toString() format is "PostType.image", "PostType.video", etc.
        String typeString = maps[i]['''type'''] as String? ?? PostType.text.toString();
        type = PostType.values.firstWhere(
          (e) => e.toString() == typeString,
          orElse: () => PostType.text, // Default if parsing fails
        );
      } catch (e) {
        print("Error parsing PostType for post ${maps[i]['''id''']}': $e. Defaulting to text.");
        type = PostType.text; // Default on any error
      }

      return Post(
        id: maps[i]['''id'''] as String,
        title: maps[i]['''title'''] as String?,
        content: maps[i]['''content'''] as String?,
        thumbnail: maps[i]['''thumbnail'''] as String?,
        videoUrl: maps[i]['''video_url'''] as String?,
        authorName: maps[i]['''author_name'''] as String? ?? 'Unknown Author',
        authorAvatar: maps[i]['''author_avatar'''] as String?,
        authorId: maps[i]['''user_id'''] as String? ?? 'unknown_author_id',
        likes: maps[i]['''likes'''] as int? ?? 0,
        dislikes: maps[i]['''dislikes'''] as int? ?? 0,
        commentsCount: maps[i]['''comments'''] as int? ?? 0, // Map 'comments' column to commentsCount
        shares: maps[i]['''shares'''] as int? ?? 0,
        type: type,
        publishTime: DateTime.fromMillisecondsSinceEpoch(maps[i]['''publish_time'''] as int? ?? 0),
        isPrivate: (maps[i]['''is_private'''] as int? ?? 0) == 1,
        viewCount: maps[i]['''view_count'''] as int?,
        location: maps[i]['''location'''] as String?,
        seriesId: maps[i]['''series_id'''] as String?,
        chapter: maps[i]['''chapter'''] as int?,
        tags: tags,
        // isLikedByCurrentUser is not directly stored here, needs to be determined at runtime
      );
    });
  }

  Future<void> cacheAccounts(List<SubscribedAccount> accounts) async {
    final db = await database;
    final batch = db.batch();
    for (var account in accounts) {
      batch.insert(
        _accountsTable,
        account.toMap(), // Assuming SubscribedAccount has a toMap() method
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<SubscribedAccount>> getCachedAccounts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_accountsTable);
    return List.generate(maps.length, (i) {
      return SubscribedAccount.fromMap(maps[i]); // Assuming SubscribedAccount has fromMap()
    });
  }

  Future<void> cacheComments(List<Comment> comments) async {
    final db = await database;
    final batch = db.batch();
    for (var comment in comments) {
      batch.insert(
        _commentsTable,
        comment.toMap(), // Assuming Comment has a toMap() method
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Comment>> getCachedComments(String postId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _commentsTable,
      where: 'post_id = ?',
      whereArgs: [postId],
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) {
      return Comment.fromMap(maps[i]); // Assuming Comment has fromMap()
    });
  }

  Future<void> clearCache() async {
    final db = await database;
    await db.delete(_postsTable);
    await db.delete(_accountsTable);
    await db.delete(_commentsTable);
    print("Cache cleared.");
  }

  Future<void> updatePostStats({
    required String postId,
    int? likes,
    int? dislikes,
    int? comments,
    int? shares,
    int? viewCount,
  }) async {
    final db = await database;
    Map<String, dynamic> dataToUpdate = {};
    if (likes != null) dataToUpdate['''likes'''] = likes;
    if (dislikes != null) dataToUpdate['''dislikes'''] = dislikes;
    if (comments != null) dataToUpdate['''comments'''] = comments;
    if (shares != null) dataToUpdate['''shares'''] = shares;
    if (viewCount != null) dataToUpdate['''view_count'''] = viewCount;

    if (dataToUpdate.isNotEmpty) {
      await db.update(
        _postsTable,
        dataToUpdate,
        where: 'id = ?',
        whereArgs: [postId],
      );
    }
  }
}
