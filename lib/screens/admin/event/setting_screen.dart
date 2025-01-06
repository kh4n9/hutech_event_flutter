import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? linkedAccountEmail;

  String? username;
  String? email;
  String? email1;

  @override
  void initState() {
    super.initState();
    _checkLinkedAccount();
    _fetchUserInfo();
  }

  Future<void> _checkLinkedAccount() async {
    User? user = _auth.currentUser;
    if (user != null) {
      for (UserInfo userInfo in user.providerData) {
        if (userInfo.providerId == 'google.com') {
          setState(() {
            linkedAccountEmail = userInfo.email;
          });
          break;
        }
      }
    }
  }

  Future<void> _fetchUserInfo() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        QuerySnapshot userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: user.email)
            .get();

        if (userQuery.docs.isNotEmpty) {
          DocumentSnapshot userDoc = userQuery.docs.first;
          setState(() {
            username = userDoc['username'];
            email = userDoc['email'];
            email1 = userDoc['email'];
          });
        } else {
          _showSnackBar('User document does not exist');
        }
      } catch (e) {
        _showSnackBar('Failed to fetch user info: $e');
      }
    } else {
      _showSnackBar('No user is currently signed in');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    TextEditingController newPasswordController = TextEditingController();
    TextEditingController confirmPasswordController = TextEditingController();
    String dialogError = '';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newPasswordController,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              SizedBox(height: 10),
              TextField(
                controller: confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              if (dialogError.isNotEmpty)
                Text(dialogError, style: TextStyle(color: Colors.red)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  setState(() {
                    dialogError = 'Passwords do not match';
                  });
                  return;
                }

                try {
                  User? user = _auth.currentUser;
                  if (user != null) {
                    await user.updatePassword(newPasswordController.text);
                    _showSnackBar('Password changed successfully');
                    Navigator.of(context).pop();
                  } else {
                    setState(() {
                      dialogError = 'No user is currently signed in';
                    });
                  }
                } catch (e) {
                  setState(() {
                    dialogError = 'Failed to change password: $e';
                  });
                }
              },
              child: Text('Change Password'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Settings'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (username != null && email1 != null)
              Column(
                children: [
                  Text('Username: $username'),
                  Text('Email: $email1'),
                ],
              ),
            if (linkedAccountEmail != null)
              Text('Linked Google Account: $linkedAccountEmail'),
            ElevatedButton(
              onPressed: _showChangePasswordDialog,
              child: Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }
}
