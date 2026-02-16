import 'package:flutter/material.dart';
import 'package:date_time_picker/date_time_picker.dart'; 

void main(){
  runApp(MainApp());
}

class MainApp extends StatelessWidget{

  @override
  Widget build(BuildContext context){
     return MaterialApp(
      debugShowCheckedModeBanner:false,
      home: HomeScreen(),
  );
  }
}

//HomeScreenStructure

class HomeScreen extends StatefulWidget{
  @override
  State<HomeScreen> createState() => _HomeScreenState();
} 


class _HomeScreenState extends State<HomeScreen>{
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: Text("ESIH")),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.push (context,
          MaterialPageRoute(
            builder: (BuildContext context) {
              return AddList();
            }
          ),
          );
        } 
      ),

      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.playlist_add_circle_outlined),
            label: "My list",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_pin),
            label: "Profile",
          ),
        ],
      )
    );
  }
}

//AddTaskScreenStructure

class AddList extends StatefulWidget{
  @override
  State createState(){
    return _AddListState();
  }
} 


class _AddListState extends State{
  GlobalKey _formKey = GlobalKey();
  TextEditingController taskField = TextEditingController();
  TextEditingController _date = TextEditingController();
  TextEditingController _date2 = TextEditingController();

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: Text("ESIH")),
      body: Container(
        padding: EdgeInsets.all(10.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              Text("Task name"),
              SizedBox(height: 20.0),
              TextField(
                controller: taskField,
                decoration: InputDecoration(
                  hintText: "The name of your task"
                )
              ),

//Start Date
              DateTimePicker(
                type: DateTimePickerType.dateTime,
                controller: _date,
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
                decoration: InputDecoration(
                  icon: Icon(Icons.calendar_today_rounded),
                  labelText: "Select the start date",
              ),
            ),
          
          //End DateTime  
            DateTimePicker(
              type: DateTimePickerType.dateTime,
              controller: _date2,
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
              decoration: InputDecoration(
                icon: Icon(Icons.calendar_today_rounded),
                labelText: "Select the end date & time",
            ),
          ),
              ElevatedButton(
                onPressed: (){
                  DateTime start = DateTime.parse(_date.text);
                  DateTime end = DateTime.parse(_date2.text);
                  print("Start: $start, End: $end");
                },
                child: Text("Register the Task"),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.playlist_add_circle_outlined),
            label: "My list",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_pin),
            label: "Profile",
          ),
        ],
      )
    );
  }
}
