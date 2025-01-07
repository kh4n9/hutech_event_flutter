import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hutech_event_flutter/screens/auth/login_screen.dart';
import 'package:hutech_event_flutter/screens/admin/admin_dashboard.dart';
import 'package:hutech_event_flutter/screens/student/student_home.dart';
import 'package:hutech_event_flutter/screens/colab/colab_dashboard.dart';
import 'package:local_auth/local_auth.dart';

class DecistionsTree extends StatefulWidget {
  const DecistionsTree({Key? key}) : super(key: key);

  @override
  _DecistionsTreeState createState() => _DecistionsTreeState();
}

class _DecistionsTreeState extends State<DecistionsTree> {
  final LocalAuthentication auth = LocalAuthentication();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true; // New state variable

  Future<bool> authenticate() async {
    try {
      bool authenticated = await auth.authenticate(
        localizedReason: 'Please authenticate to access the admin dashboard',
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );
      return authenticated;
    } catch (e) {
      return false;
    }
  }

  logout() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  Future<bool> checkuser() async {
    User? user = _auth.currentUser;
    if (user != null) {
      bool authenticated = await authenticate();
      if (!authenticated) {
        logout();
        return false; // Prevent further processing
      }
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    bool isAuthenticated = await checkuser();
    if (isAuthenticated) {
      await determineUserRole();
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> determineUserRole() async {
    User? user = _auth.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: user.email)
          .get();
      if (snapshot.docs.isNotEmpty) {
        String role = snapshot.docs.first['role'];
        if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminDashboard()),
          );
        } else if (role == 'student') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => StudentHome()),
          );
        } else if (role == 'colab') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ColabDashboard()),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : LoginScreen(),
    );
  }
}
