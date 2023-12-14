import '../Controller/request_controller.dart';
import '../Controller/sqlite_db.dart';

class Expense {
  static const String SQLiteTable = "expense";
  int? id; // Field to hold the expense ID
  String description;
  double amount;
  String dateTime;

  Expense(this.amount, this.description, this.dateTime);

  Expense.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        description = json['desc'] as String,
        amount = double.parse(json['amount'] as dynamic),
        dateTime = json['dateTime'] as String;

  Map<String, dynamic> toJson() =>
      {'desc': description, 'amount': amount, 'dateTime': dateTime};

  Future<bool> save() async {
    // Save to local SQlite
    await SQLiteDB().insert(SQLiteTable, toJson());
    // API operation
    RequestController req = RequestController(path: "/api/expenses.php");
    req.setBody(toJson());
    await req.post();
    if (req.status() == 200) {
      id = req.result()["id"]; // Assuming the server returns the ID after saving
      return true;
    }
    else {
      if (await SQLiteDB().insert(SQLiteTable, toJson()) != 0) {
        return true;
      } else
      return false;
    }
  }

  Future<bool> update() async {
    RequestController req = RequestController(path: "/api/expenses.php");
    req.setBody(toJson());

    await req.put();
    if (req.status() == 200) {
      return true;
    }
    return false;
  }

  static Future<List<Expense>> loadAll() async {
    List<Expense> result = [];
    RequestController req = RequestController(path: "/api/expenses.php");
    await req.get();
    if (req.status() == 200 && req.result() != null) {
      for (var item in req.result()) {
        result.add(Expense.fromJson(item));
      }
    }
    else {
      List<Map<String, dynamic>> result = await SQLiteDB().queryAll(SQLiteTable);
      List<Expense> expenses = [];
      for (var item in result) {
        result.add(Expense.fromJson(item) as Map<String, dynamic>);
      }
    }
    return result;
  }
}
