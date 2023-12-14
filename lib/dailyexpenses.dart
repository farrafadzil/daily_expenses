import '../Controller/request_controller.dart';
import 'package:flutter/material.dart';
import '../Model/expense.dart';

void main() {
  runApp(DailyExpensesApp(username: "Farra"));
}

class DailyExpensesApp extends StatelessWidget {
  final String username;
  DailyExpensesApp({required String this.username});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ExpenseList(username: username),
    );
  }
}

class ExpenseList extends StatefulWidget {
  final String username;
  ExpenseList({required this.username});
  @override
  _ExpenseListState createState() => _ExpenseListState();
}

class _ExpenseListState extends State<ExpenseList> {
  final List<Expense> expenses = [];
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController totalAmountController = TextEditingController();
  final TextEditingController txtDateController = TextEditingController();
  double totalAmount = 0.0;

  void _addExpense() async{
    String description = descriptionController.text.trim();
    String amount = amountController.text.trim();

    if(amount.isNotEmpty && description.isNotEmpty){
      Expense exp =
      Expense(double.parse(amount), description, txtDateController.text);

      if (await exp.save()){
        setState((){
          expenses.add(exp);
          descriptionController.clear();
          amountController.clear();
          calculateTotal();

        });
      }else{
        _showMessage("Failed to save Expenses date");
      }
    }

  }

  void calculateTotal(){
    totalAmount = 0;
    for (Expense ex in expenses){
      totalAmount += ex.amount;
    }
    totalAmountController.text = totalAmount.toString();
  }

  void _removeExpense(int index) {
    totalAmount += expenses[index].amount;
    setState(() {
      expenses.removeAt(index);
      totalAmountController.text = totalAmount.toString();
    });
  }

  void _showMessage(String msg){
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content : Text(msg),
        ),
      );
    }
  }

  void _editExpense(int index) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditExpenseScreen(
          expense: expenses[index],
          onSave: (editedExpense) async {
            bool isUpdated = await editedExpense.update();
            if (isUpdated) {
              setState(() {
                totalAmount += editedExpense.amount - expenses[index].amount;
                expenses[index] = editedExpense;
                totalAmountController.text = totalAmount.toString();
              });
            }
          },
        ),
      ),
    );
  }



  _selectDate() async{
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedDate != null && pickedTime != null){
      setState((){
        txtDateController.text =
        "${pickedDate.year}-${pickedDate.month}- ${pickedDate.day}"
            "${pickedTime.hour} : ${pickedTime.minute}:00";
      });
    }
  }

  @override
  void initState(){
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async{
      _showMessage("Welcome ${widget.username}");

      RequestController req = RequestController(
          path: "/api/timezone/Asia/Kuala_Lumpur",
          server: "http://worldtimeapi.org");
      req.get().then((value) {
        dynamic res = req.result();
        txtDateController.text =
            res["datetime"].toString().substring(0,19).replaceAll('T', ' ');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Expenses'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            //mew
            padding: const EdgeInsets.all(3.0),
            child: TextField(
              keyboardType: TextInputType.datetime,
              controller: txtDateController,
              readOnly: true,
              onTap: _selectDate,
              decoration: const InputDecoration(labelText: 'Date'),
            ),

          ),
          Padding(
            padding: const EdgeInsets.all(3.0),
            child: TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(3.0),
            child: TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: 'Amount (RM)',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(3.0),
            child: TextFormField(
              controller: totalAmountController,
              readOnly: true,
              decoration: InputDecoration(
                  labelText: 'Total spend (RM): '),
            ),
          ),
          Padding(
            padding:
            const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            child: ElevatedButton(
              onPressed: _addExpense,
              child: Text('Add Expense'),
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.all(3.0),
                  child: ListTile(
                    title: Text(expenses[index].description),
                    subtitle: Row(children: [
                      Text('Amount: ${expenses[index].amount}'),
                      const Spacer(),
                      Text('Date: ${expenses[index].dateTime}')
                    ]),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _removeExpense(index),
                    ),
                    onLongPress: () {
                      _editExpense(index);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class EditExpenseScreen extends StatelessWidget {
  final Expense expense;
  final Function(Expense) onSave;

  EditExpenseScreen({required this.expense, required this.onSave})
      : descController = TextEditingController(text: expense.description),
        amountController = TextEditingController(text: expense.amount.toString()),
        dateTimeController = TextEditingController(text: expense.dateTime);

  final TextEditingController descController;
  final TextEditingController amountController;
  final TextEditingController dateTimeController;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(expense.dateTime),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(DateTime.parse(expense.dateTime)),
      );

      if (pickedTime != null) {
        DateTime selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        dateTimeController.text = selectedDateTime.toString();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Expense'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(3.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: 'Description',
              ),
            ),
            SizedBox(height: 3.0),
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: 'Amount (RM)',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            SizedBox(height: 3.0),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: TextField(
                  controller: dateTimeController,
                  decoration: InputDecoration(
                    labelText: 'Date Time',
                  ),
                ),
              ),
            ),
            SizedBox(height: 3.0),
            ElevatedButton(
              onPressed: () async {
                String newDesc = descController.text.trim();
                double newAmount = double.parse(amountController.text);
                String newDateTime = dateTimeController.text;


                Expense updatedExpense = Expense(newAmount, newDesc, newDateTime);
                bool isUpdated = await updatedExpense.update();
                if (isUpdated){
                  // Handle success
                  onSave(updatedExpense);
                  Navigator.pop(context);
                } else {
                  // Handle failure
                }
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
