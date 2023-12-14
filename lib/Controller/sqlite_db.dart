import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SQLiteDB {
  static const String _dbName = "lab_db";

  Database? _db;

  SQLiteDB._();
  static final SQLiteDB _instance = SQLiteDB._();

  factory SQLiteDB() => _instance;

  Future<Database> get database async {
    if (_db != null) {
      return _db!;
    }

    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _dbName);

    return openDatabase(path, version: 1, onCreate: (db, version) async {
      for (String tableSql in tableSQLStrings) {
        await db.execute(tableSql);
      }
    });
  }

  static List<String> tableSQLStrings = [
    '''
  CREATE TABLE IF NOT EXISTS expense (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    amount REAL,
    desc TEXT,
    dateTime TEXT
  )
  ''',
  ];

  Future<int> insert(String tableName, Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert(tableName, row);
  }

  Future<List<Map<String, dynamic>>> queryAll(String tableName) async {
    Database db = await database;
    return await db.query(tableName);
  }

  Future<int> update(String tableName, String idColumn, Map<String, dynamic> row) async {
    Database db = await database;
    dynamic id = row[idColumn];
    return await db.update(tableName, row, where: '$idColumn = ?', whereArgs: [id]);
  }

  Future<int> delete(String tableName, String idColumn, dynamic idValue) async {
    Database db = await database;
    return await db.delete(tableName, where: '$idColumn = ?', whereArgs: [idValue]);
  }

  // Function to update expense to both local SQLite and remote database via REST API
  Future<void> updateExpense(Map<String, dynamic> expense) async {
    await _updateLocalDatabase('expense', expense);
    await _updateRemoteDatabase('https://your-api-url.com/updateExpense', expense);
  }

  // Function to update the local SQLite database
  Future<int> _updateLocalDatabase(String tableName, Map<String, dynamic> row) async {
    Database db = await database;
    return await db.update(tableName, row,
        where: 'id = ?', whereArgs: [row['id']]);
  }

  // Function to update the remote database via REST API
  Future<void> _updateRemoteDatabase(String apiUrl, Map<String, dynamic> expense) async {
    try {
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          // Add any required headers
        },
        body: jsonEncode(expense),
      );

      if (response.statusCode == 200) {
        // Successfully updated the remote database
        print('Expense updated remotely');
      } else {
        // Handle error scenario if the update fails
        print('Failed to update expense remotely: ${response.statusCode}');
      }
    } catch (e) {
      // Handle any exceptions during the API call
      print('Exception while updating expense remotely: $e');
    }
  }

  // Function to delete an expense from both local SQLite and remote database via REST API
  Future<void> deleteExpense(int id) async {
    await _deleteLocalDatabase('expense', id);
    await _deleteRemoteDatabase('https://your-api-url.com/deleteExpense/$id');
  }

  // Function to delete the expense from the local SQLite database
  Future<int> _deleteLocalDatabase(String tableName, int id) async {
    Database db = await database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  // Function to delete the expense from the remote database via REST API
  Future<void> _deleteRemoteDatabase(String apiUrl) async {
    try {
      final response = await http.delete(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          // Add any required headers
        },
      );

      if (response.statusCode == 200) {
        // Successfully deleted from the remote database
        print('Expense deleted remotely');
      } else {
        // Handle error scenario if deletion fails
        print('Failed to delete expense remotely: ${response.statusCode}');
      }
    } catch (e) {
      // Handle any exceptions during the API call
      print('Exception while deleting expense remotely: $e');
    }
  }
}
