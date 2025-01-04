import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  final String username;
  const RegisterScreen({Key? key, required this.username}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  register() async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: widget.username)
          .get()
          .then((snapshot) {
        snapshot.docs.first.reference.update({
          'email': emailController.text,
        });
        FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );
        Navigator.pop(context);
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Register', style: TextStyle(fontSize: 24)),
            Text('Username: ${widget.username}',
                style: TextStyle(fontSize: 24)),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // button back to login
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(Colors.amber[200]),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Back to login'),
                ),
                // button register
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(Colors.teal[200]),
                  ),
                  onPressed: () {
                    register();
                  },
                  child: Text('Register'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
