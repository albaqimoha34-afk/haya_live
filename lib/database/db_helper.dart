import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/competition_model.dart';
import '../models/match_model.dart';
import '../models/favorite_model.dart';

// هذا الكلاس مسؤول عن كل شيء متعلق بقاعدة البيانات:
// إنشاء الجداول، وعمليات الإضافة/الجلب/التعديل/الحذف (CRUD) لكل جدول.
// استخدمنا Singleton (نسخة واحدة فقط من قاعدة البيانات) لتجنب فتح اتصالات متعددة.
class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // ═══════════════════════════════════════════════════════
    // حل مدمج يعمل على كل المنصات (Web + Android + iOS)
    // ═══════════════════════════════════════════════════════

    String path;

    try {
      // 1) نجرب الطريقة الرسمية أولاً (تعمل على الموبايل)
      final dbPath = await getDatabasesPath();

      if (dbPath != null && dbPath.isNotEmpty) {
        path = join(dbPath, 'hayya_live.db');
      } else {
        // 2) إذا رجعت null (وهذا ما يحدث على الويب غالباً)
        //    نستخدم مساراً بسيطاً يعمل مع databaseFactoryFfiWeb
        path = 'hayya_live.db';
      }
    } catch (e) {
      // 3) في حال أي خطأ، نستخدم المسار البسيط
      path = 'hayya_live.db';
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // جدول المستخدمين
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');

    // جدول البطولات
    await db.execute('''
      CREATE TABLE competitions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        logo_url TEXT NOT NULL
      )
    ''');

    // جدول المباريات
    await db.execute('''
      CREATE TABLE matches(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        competition_id INTEGER NOT NULL,
        home_team TEXT NOT NULL,
        away_team TEXT NOT NULL,
        home_logo_url TEXT NOT NULL,
        away_logo_url TEXT NOT NULL,
        home_score INTEGER NOT NULL,
        away_score INTEGER NOT NULL,
        match_date TEXT NOT NULL,
        match_time TEXT NOT NULL,
        stadium TEXT NOT NULL,
        referee TEXT NOT NULL,
        status TEXT NOT NULL,
        FOREIGN KEY (competition_id) REFERENCES competitions (id)
      )
    ''');

    // جدول المفضلة
    await db.execute('''
      CREATE TABLE favorites(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        match_id INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (match_id) REFERENCES matches (id)
      )
    ''');

    // بيانات أولية (Seed) حتى لا يفتح التطبيق فارغًا تمامًا
    await _insertSeedData(db);
  }

  Future<void> _insertSeedData(Database db) async {
    await db.insert('competitions', {
      'name': 'الدوري السعودي للمحترفين',
      'logo_url': 'https://cdn-icons-png.flaticon.com/512/197/197578.png',
    });
    await db.insert('competitions', {
      'name': 'دوري أبطال أوروبا',
      'logo_url': 'https://cdn-icons-png.flaticon.com/512/197/197374.png',
    });
  }

  // ============ عمليات المستخدمين (Users) ============

  Future<int> registerUser(UserModel user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  // تُستخدم لتسجيل الدخول والتحقق من نسيان كلمة المرور
  Future<UserModel?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query('users', where: 'email = ?', whereArgs: [email]);
    if (result.isEmpty) return null;
    return UserModel.fromMap(result.first);
  }

  Future<UserModel?> login(String email, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (result.isEmpty) return null;
    return UserModel.fromMap(result.first);
  }

  // تُستخدم بعد نجاح التحقق من رمز OTP لتحديث كلمة المرور
  Future<int> updatePassword(String email, String newPassword) async {
    final db = await database;
    return await db.update(
      'users',
      {'password': newPassword},
      where: 'email = ?',
      whereArgs: [email],
    );
  }

  // ============ عمليات البطولات (Competitions) ============

  Future<List<CompetitionModel>> getCompetitions() async {
    final db = await database;
    final result = await db.query('competitions');
    return result.map((e) => CompetitionModel.fromMap(e)).toList();
  }

  // ============ عمليات المباريات (Matches) - CRUD كامل ============

  Future<int> addMatch(MatchModel match) async {
    final db = await database;
    return await db.insert('matches', match.toMap());
  }

  Future<List<MatchModel>> getAllMatches() async {
    final db = await database;
    final result = await db.query('matches', orderBy: 'match_date DESC, match_time DESC');
    return result.map((e) => MatchModel.fromMap(e)).toList();
  }

  Future<List<MatchModel>> getMatchesByDate(String date) async {
    final db = await database;
    final result = await db.query('matches', where: 'match_date = ?', whereArgs: [date]);
    return result.map((e) => MatchModel.fromMap(e)).toList();
  }

  Future<List<MatchModel>> getMatchesByCompetition(int competitionId) async {
    final db = await database;
    final result = await db.query(
      'matches',
      where: 'competition_id = ?',
      whereArgs: [competitionId],
    );
    return result.map((e) => MatchModel.fromMap(e)).toList();
  }

  Future<int> updateMatch(MatchModel match) async {
    final db = await database;
    return await db.update(
      'matches',
      match.toMap(),
      where: 'id = ?',
      whereArgs: [match.id],
    );
  }

  Future<int> deleteMatch(int id) async {
    final db = await database;
    return await db.delete('matches', where: 'id = ?', whereArgs: [id]);
  }

  // ============ عمليات المفضلة (Favorites) ============

  Future<int> addFavorite(int userId, int matchId) async {
    final db = await database;
    return await db.insert('favorites', {'user_id': userId, 'match_id': matchId});
  }

  Future<int> removeFavorite(int userId, int matchId) async {
    final db = await database;
    return await db.delete(
      'favorites',
      where: 'user_id = ? AND match_id = ?',
      whereArgs: [userId, matchId],
    );
  }

  Future<bool> isFavorite(int userId, int matchId) async {
    final db = await database;
    final result = await db.query(
      'favorites',
      where: 'user_id = ? AND match_id = ?',
      whereArgs: [userId, matchId],
    );
    return result.isNotEmpty;
  }

  // تجلب المباريات المفضلة الخاصة بمستخدم معيّن (JOIN بسيط بين جدولين)
  Future<List<MatchModel>> getFavoriteMatches(int userId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT matches.* FROM matches
      INNER JOIN favorites ON matches.id = favorites.match_id
      WHERE favorites.user_id = ?
    ''', [userId]);
    return result.map((e) => MatchModel.fromMap(e)).toList();
  }
}
