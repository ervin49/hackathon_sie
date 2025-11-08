import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import './task.dart';
import './app_notification.dart';
import './history.dart';
import './group.dart';

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
    final path = join(await getDatabasesPath(), 'todo_app.db');
    return await openDatabase(
      path,
      version: 2, // Version bump to trigger the corrected schema creation
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // The simplest and most robust migration strategy is to start fresh.
    await db.execute('DROP TABLE IF EXISTS group_invitations'); // Drop old mistaken table
    await db.execute('DROP TABLE IF EXISTS notifications');
    await db.execute('DROP TABLE IF EXISTS task_history');
    await db.execute('DROP TABLE IF EXISTS task_participants');
    await db.execute('DROP TABLE IF EXISTS group_members');
    await db.execute('DROP TABLE IF EXISTS groups');
    await db.execute('DROP TABLE IF EXISTS tasks');
    await db.execute('DROP TABLE IF EXISTS users');
    await _onCreate(db, newVersion);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''CREATE TABLE users(id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT NOT NULL UNIQUE, password TEXT NOT NULL)''');
    await db.execute('''CREATE TABLE tasks(id INTEGER PRIMARY KEY AUTOINCREMENT, ownerId INTEGER NOT NULL, title TEXT NOT NULL, description TEXT, status TEXT NOT NULL, deadline TEXT, FOREIGN KEY (ownerId) REFERENCES users (id) ON DELETE CASCADE)''');
    await db.execute('''CREATE TABLE task_participants(taskId INTEGER NOT NULL, userId INTEGER NOT NULL, PRIMARY KEY (taskId, userId), FOREIGN KEY (taskId) REFERENCES tasks (id) ON DELETE CASCADE, FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE)''');
    await db.execute('''CREATE TABLE task_history(id INTEGER PRIMARY KEY AUTOINCREMENT, taskId INTEGER NOT NULL, userId INTEGER NOT NULL, action TEXT NOT NULL, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP, FOREIGN KEY (taskId) REFERENCES tasks (id) ON DELETE CASCADE, FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE)''');
    await db.execute('''CREATE TABLE groups(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, ownerId INTEGER NOT NULL, FOREIGN KEY (ownerId) REFERENCES users (id) ON DELETE CASCADE)''');
    await db.execute('''CREATE TABLE group_members(groupId INTEGER NOT NULL, userId INTEGER NOT NULL, role TEXT NOT NULL, PRIMARY KEY (groupId, userId), FOREIGN KEY (groupId) REFERENCES groups (id) ON DELETE CASCADE, FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE)''');
    
    // CORRECTED UNIFIED NOTIFICATIONS TABLE
    await db.execute('''
      CREATE TABLE notifications(
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        fromUserId INTEGER NOT NULL, 
        toUserId INTEGER NOT NULL, 
        taskId INTEGER, 
        groupId INTEGER, 
        type TEXT NOT NULL, 
        status TEXT NOT NULL, 
        FOREIGN KEY (fromUserId) REFERENCES users (id) ON DELETE CASCADE, 
        FOREIGN KEY (toUserId) REFERENCES users (id) ON DELETE CASCADE, 
        FOREIGN KEY (taskId) REFERENCES tasks (id) ON DELETE CASCADE, 
        FOREIGN KEY (groupId) REFERENCES groups (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _logHistory(int taskId, int userId, String action) async {
    final db = await instance.database;
    await db.insert('task_history', {'taskId': taskId, 'userId': userId, 'action': action});
  }

  Future<List<History>> getTaskHistory(int taskId) async {
    final db = await instance.database;
    final maps = await db.rawQuery('''SELECT h.action, u.username, h.timestamp FROM task_history h JOIN users u ON h.userId = u.id WHERE h.taskId = ? ORDER BY h.timestamp DESC''', [taskId]);
    return List.generate(maps.length, (i) => History.fromMap(maps[i]));
  }

  Future<RegistrationResponse> registerUser(String username, String password) async {
    final db = await instance.database;
    final usernameCheck = await db.query('users', where: 'username = ?', whereArgs: [username]);
    if (usernameCheck.isNotEmpty) return RegistrationResponse(RegistrationResult.usernameExists);
    final passwordCheck = await db.query('users', where: 'password = ?', whereArgs: [password]);
    if (passwordCheck.isNotEmpty) return RegistrationResponse(RegistrationResult.passwordUsed, username: passwordCheck.first['username'] as String?);
    await db.insert('users', {'username': username, 'password': password});
    return RegistrationResponse(RegistrationResult.success);
  }

  Future<Map<String, dynamic>?> loginUser(String username, String password) async {
    final db = await instance.database;
    final maps = await db.query('users', where: 'username = ? AND password = ?', whereArgs: [username, password]);
    return maps.isNotEmpty ? maps.first : null;
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await instance.database;
    return await db.query('users');
  }

  Future<int> addTask(Task task, int ownerId) async {
    final db = await instance.database;
    final taskId = await db.insert('tasks', {'ownerId': ownerId, 'title': task.title, 'description': task.description, 'status': task.status.toString(), 'deadline': task.deadline?.toIso8601String()});
    await assignTaskToUser(taskId, ownerId);
    await _logHistory(taskId, ownerId, 'Created task');
    return taskId;
  }

  Future<void> assignTaskToUser(int taskId, int userId) async {
    final db = await instance.database;
    await db.insert('task_participants', {'taskId': taskId, 'userId': userId}, conflictAlgorithm: ConflictAlgorithm.ignore);
    await _logHistory(taskId, userId, 'Joined task');
  }

  Future<void> sendTaskInvitation(int fromUserId, int toUserId, int taskId) async {
    final db = await instance.database;
    await db.insert('notifications', {'fromUserId': fromUserId, 'toUserId': toUserId, 'taskId': taskId, 'type': 'task', 'status': 'pending'});
    await _logHistory(taskId, fromUserId, 'Invited user');
  }

  Future<void> sendGroupInvitation(int fromUserId, int toUserId, int groupId) async {
    final db = await instance.database;
    await db.insert('notifications', {'fromUserId': fromUserId, 'toUserId': toUserId, 'groupId': groupId, 'type': 'group', 'status': 'pending'});
  }

  Future<List<AppNotification>> getNotifications(int userId) async {
    final db = await instance.database;
    final maps = await db.rawQuery('''
      SELECT 
        n.id, 
        u.username as fromUser, 
        n.fromUserId, 
        COALESCE(t.title, g.name) as itemName, 
        COALESCE(n.taskId, n.groupId) as itemId, 
        n.type, 
        n.status
      FROM notifications n
      JOIN users u ON n.fromUserId = u.id
      LEFT JOIN tasks t ON n.taskId = t.id
      LEFT JOIN groups g ON n.groupId = g.id
      WHERE n.toUserId = ?
    ''', [userId]);
    return List.generate(maps.length, (i) => AppNotification.fromMap(maps[i]));
  }

  Future<void> acceptInvitation(AppNotification notification, int userId) async {
    final db = await instance.database;
    await db.update('notifications', {'status': 'accepted'}, where: 'id = ?', whereArgs: [notification.id]);
    if (notification.type == NotificationType.task) {
      await assignTaskToUser(notification.itemId, userId);
      await _logHistory(notification.itemId, userId, 'Accepted invitation');
    } else {
      await db.insert('group_members', {'groupId': notification.itemId, 'userId': userId, 'role': 'member'});
    }
  }

  Future<void> declineInvitation(AppNotification notification) async {
    final db = await instance.database;
    await db.update('notifications', {'status': 'declined'}, where: 'id = ?', whereArgs: [notification.id]);
    if (notification.type == NotificationType.task) {
      await _logHistory(notification.itemId, notification.fromUserId, 'Declined invitation');
    }
  }

  Future<List<Task>> getTasks(int userId) async {
    final db = await instance.database;
    final maps = await db.rawQuery('''SELECT DISTINCT t.*, (SELECT COUNT(*) FROM task_participants WHERE taskId = t.id) as participantCount FROM tasks t LEFT JOIN task_participants tp ON t.id = tp.taskId WHERE tp.userId = ?''', [userId]);
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  Future<List<String>> getTaskParticipants(int taskId) async {
    final db = await instance.database;
    final maps = await db.rawQuery('''SELECT u.username FROM users u JOIN task_participants tp ON u.id = tp.userId WHERE tp.taskId = ?''', [taskId]);
    return maps.map((user) => user['username'] as String).toList();
  }

  Future<int> updateTask(Task task, int userId) async {
    final db = await instance.database;
    final oldTask = await db.query('tasks', where: 'id = ?', whereArgs: [task.id]);
    if (oldTask.isNotEmpty) {
      if (oldTask.first['title'] != task.title) await _logHistory(task.id!, userId, 'Renamed task to \'${task.title}\'');
      if (oldTask.first['description'] != task.description) await _logHistory(task.id!, userId, 'Updated description');
      if (oldTask.first['status'] != task.status.toString()) await _logHistory(task.id!, userId, 'Changed status to ${task.status.toString().split('.').last}');
    }
    return await db.update('tasks', {'title': task.title, 'description': task.description, 'status': task.status.toString(), 'deadline': task.deadline?.toIso8601String()}, where: 'id = ?', whereArgs: [task.id]);
  }

  Future<int> deleteTask(int id, int userId) async {
    final db = await instance.database;
    await _logHistory(id, userId, 'Deleted task');
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> createGroup(String name, int ownerId) async {
    final db = await instance.database;
    final groupId = await db.insert('groups', {'name': name, 'ownerId': ownerId});
    await db.insert('group_members', {'groupId': groupId, 'userId': ownerId, 'role': 'admin'});
    return groupId;
  }

  Future<List<Group>> getGroupsForUser(int userId) async {
    final db = await instance.database;
    final maps = await db.rawQuery('''SELECT g.*, (SELECT COUNT(*) FROM group_members WHERE groupId = g.id) as memberCount FROM groups g JOIN group_members gm ON g.id = gm.groupId WHERE gm.userId = ?''', [userId]);
    return List.generate(maps.length, (i) => Group.fromMap(maps[i]));
  }

  Future<List<Map<String, dynamic>>> getGroupMembers(int groupId) async {
    final db = await instance.database;
    return await db.rawQuery('''SELECT u.id, u.username, gm.role FROM users u JOIN group_members gm ON u.id = gm.userId WHERE gm.groupId = ?''', [groupId]);
  }
}
