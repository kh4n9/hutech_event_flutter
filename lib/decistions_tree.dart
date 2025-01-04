import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hutech_event_flutter/screens/auth/login_screen.dart';
import 'package:hutech_event_flutter/screens/admin/admin_dashboard.dart';
import 'package:hutech_event_flutter/screens/student/student_home.dart';
import 'package:hutech_event_flutter/screens/colab/colab_dashboard.dart';

class DecistionsTree extends StatefulWidget {
  const DecistionsTree({Key? key}) : super(key: key);

  @override
  _DecistionsTreeState createState() => _DecistionsTreeState();
}

class _DecistionsTreeState extends State<DecistionsTree> {
  createFirstUser() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('users').get();
      if (snapshot.docs.isEmpty) {
        print('Creating first user');
        await FirebaseFirestore.instance.collection('users').add({
          'email': null,
          'username': 'admin',
          'role': 'admin',
        });
      } else {
        print('First user already exists');
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    createFirstUser();
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: user.email)
          .get()
          .then((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          if (snapshot.docs.first['role'] == 'admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => AdminDashboard(),
              ),
            );
          } else if (snapshot.docs.first['role'] == 'student') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => StudentHome(),
              ),
            );
          } else if (snapshot.docs.first['role'] == 'colab') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ColabDashboard(),
              ),
            );
          }
        }
      });
    } else {
      return LoginScreen();
    }
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
