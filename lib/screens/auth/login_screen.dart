import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hutech_event_flutter/decistions_tree.dart';
import 'package:hutech_event_flutter/screens/auth/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String error = '';
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  login() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: usernameController.text)
          .get();
      if (snapshot.docs.isNotEmpty) {
        if (snapshot.docs.first['email'] == null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RegisterScreen(
                username: usernameController.text,
              ),
            ),
          );
        } else {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: snapshot.docs.first['email'],
            password: passwordController.text,
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DecistionsTree(),
            ),
          );
        }
      } else {
        setState(() {
          error = 'Username not found';
        });
      }
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Login', style: TextStyle(fontSize: 24)),
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                labelText: 'Username/MSSV',
              ),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
              ),
            ),
            if (error.isNotEmpty)
              Text(error, style: TextStyle(color: Colors.red)),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                login();
              },
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
