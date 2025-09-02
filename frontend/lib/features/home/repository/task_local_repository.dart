import 'package:frontend/models/tasks_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class TaskLocalRepository {
  String tableName = 'tasks';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'tasks.db');
    return openDatabase(
      path,
      version: 2,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < newVersion) {
          await db.execute(
            'ALTER TABLE $tableName ADD COLUMN isSynced INTERGER NOT NULL',
          );
        }
      },
      onCreate: (db, version) {
        return db.execute(
          '''CREATE TABLE $tableName(
          id TEXT PRIMARY KEY, 
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          hexColor TEXT NOT NULL,
          uid TEXT NOT NULL,
          dueAt TEXT NOT NULL, 
          createdAt TEXT NOT NULL, 
          updatedAt TEXT NOT NULL,
          isSynced INTERGER NOT NULL 
         )''',
        );
      },
    );
  }

  Future<void> insertTask(TasksModel tasks) async {
    final db = await database;
    await db.delete(tableName, where: 'id = ?', whereArgs: [tasks.id]);
    await db.insert(
      tableName,
      tasks.toMap(),
    );
  }

  Future<void> insertTasks(List<TasksModel> tasks) async {
    final db = await database;
    final batch = db.batch();
    for (final task in tasks) {
      batch.insert(
        tableName,
        task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<TasksModel>> getTasks() async {
    final db = await database;
    final result = await db.query(tableName);
    if (result.isNotEmpty) {
      List<TasksModel> tasks = [];
      for (final elem in result) {
        tasks.add(TasksModel.fromMap(elem));
      }
      return tasks;
    }
    return [];
  }

  Future<List<TasksModel>> getUnsyncedTasks() async {
    final db = await database;
    final result = await db.query(
      tableName,
      where: 'isSynced = ?',
      whereArgs: [0],
    );
    if (result.isNotEmpty) {
      List<TasksModel> tasks = [];
      for (final elem in result) {
        tasks.add(TasksModel.fromMap(elem));
      }
      return tasks;
    }
    return [];
  }

  Future<void> updateRowValue(String id, int newValue) async {
    final db = await database;
    await db.update(
      tableName,
      {'isSynced': newValue},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
