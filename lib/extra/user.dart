import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:watch_hub_ep/extra/user_edit.dart';


class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('users');

  List<Map<String, dynamic>> _userList = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  void _fetchUsers() {
    _dbRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      List<Map<String, dynamic>> tempList = [];

      if (data != null) {
        data.forEach((key, value) {
          tempList.add({
            'key': key,
            'name': value['name'],
            'email': value['email'],
            'age': value['age'].toString(),
            'number': value['number'],
            'address': value['address'],
          });
        });
      }

      setState(() {
        _userList = tempList;
      });
    });
  }

  void _editUser(Map<String, dynamic> userData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditUserPage(userData: userData),
      ),
    );
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text("User Dashboard"),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    ),
    body: ListView.builder(
      itemCount: _userList.length,
      itemBuilder: (context, index) {
        final user = _userList[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: ListTile(
            title: Text(user['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: ${user['email']}'),
                Text('Age: ${user['age']}'),
                Text('Number: ${user['number']}'),
                Text('Address: ${user['address']}'),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editUser(user),
            ),
            isThreeLine: true,
          ),
        );
      },
    ),
  );
}


}
