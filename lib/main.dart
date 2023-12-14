import 'package:flutter/material.dart';
import 'login.dart';
import 'dailyexpenses.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp ({super.key});

  @override
  Widget build(BuildContext context){
    const title = 'Daily Expenses';
    home: LoginScreen();

        return MaterialApp(
          title: title,
          home: Scaffold(
            appBar: AppBar(
              title: const Text(title),
            ),
            body: ListView(
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.attach_money),
                  title: Text('Groceries - \RM150.00'),
                ),
                ListTile(
                leading: Icon(Icons.attach_money),
                title: Text('Groceries - \RM150.00'),
                ),
                ListTile(
                leading: Icon(Icons.attach_money),
                title: Text('Groceries - \RM150.00'),
                ),
              ],
            ),
          ),
        );
  }
}