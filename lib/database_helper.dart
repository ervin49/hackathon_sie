import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import './task.dart';

enum RegistrationResult {
  success,
  usernameExists,
  passwordUsed,
}

class RegistrationResponse {
  final RegistrationResult result;
  final String? username;

  RegistrationResponse(this.result, {this.username});
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'tasks_database.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        status TEXT NOT NULL,
        deadline TEXT,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.execute('DROP TABLE IF EXISTS tasks');
    await db.execute('DROP TABLE IF EXISTS users');
    await _onCreate(db, newVersion);
  }

  Future<RegistrationResponse> registerUser(String username, String password) async {
    final db = await instance.database;

    final usernameCheck = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (usernameCheck.isNotEmpty) {
      return RegistrationResponse(RegistrationResult.usernameExists);
    }

    final passwordCheck = await db.query(
      'users',
      where: 'password = ?',
      whereArgs: [password],
    );
    if (passwordCheck.isNotEmpty) {
      return RegistrationResponse(
        RegistrationResult.passwordUsed,
        username: passwordCheck.first['username'] as String?,
      );
    }

    await db.insert('users', {'username': username, 'password': password});
    return RegistrationResponse(RegistrationResult.success);
  }

  Future<Map<String, dynamic>?> loginUser(String username, String password) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<int> addTask(Task task, int userId) async {
    final db = await instance.database;
    return await db.insert('tasks', {
      'userId': userId,
      'title': task.title,
      'description': task.description,
      'status': task.status.toString(),
      'deadline': task.deadline?.toIso8601String(),
    });
  }

  Future<List<Task>> getTasks(int userId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return List.generate(maps.length, (i) {
      return Task(
        id: maps[i]['id'] as int?,
        title: maps[i]['title'],
        description: maps[i]['description'],
        status: TaskStatus.values
            .firstWhere((e) => e.toString() == maps[i]['status']),
        deadline: maps[i]['deadline'] != null
            ? DateTime.parse(maps[i]['deadline'])
            : null,
      );
    });
  }

  Future<int> updateTask(Task task) async {
    final db = await instance.database;
    return await db.update(
      'tasks',
      {
        'title': task.title,
        'description': task.description,
        'status': task.status.toString(),
        'deadline': task.deadline?.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await instance.database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
