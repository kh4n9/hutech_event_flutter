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
            Image.asset('images/background-hutech-removebg.png', width: 200),
            SizedBox(height: 20),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  TextField(
                    style: TextStyle(fontSize: 20),
                    controller: usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username/MSSV',
                      border: InputBorder.none,
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.teal, width: 2),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    obscureText: true,
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: InputBorder.none,
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.teal, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (error.isNotEmpty)
              Text(error, style: TextStyle(color: Colors.red)),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[500],
                shadowColor: Colors.teal[700],
                elevation: 10,
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                login();
              },
              child: Text('Login',
                  style: TextStyle(fontSize: 20, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
