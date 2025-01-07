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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    try {
      bool isAuthenticated = await checkUser();
      if (isAuthenticated) {
        await determineUserRole();
      }
    } catch (e) {
      print('Initialization error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> checkUser() async {
    if (_auth.currentUser == null) return false;

    try {
      var userDoc = await _firestore
          .collection('users')
          .where('email', isEqualTo: _auth.currentUser!.email)
          .get()
          .then((snapshot) => snapshot.docs.firstOrNull);

      if (userDoc == null) return false;

      bool biometricEnabled = userDoc['biometric'] ?? false;
      return !biometricEnabled || await authenticate();
    } catch (e) {
      print('Check user error: $e');
      return false;
    }
  }

  Future<void> determineUserRole() async {
    if (_auth.currentUser == null) return;

    try {
      var userDoc = await _firestore
          .collection('users')
          .where('email', isEqualTo: _auth.currentUser!.email)
          .get()
          .then((snapshot) => snapshot.docs.firstOrNull);

      if (userDoc == null) return;

      final Map<String, Widget Function(BuildContext)> roleScreens = {
        'admin': (context) => AdminDashboard(),
        'student': (context) => StudentHome(),
        'colab': (context) => ColabDashboard(),
      };

      var screen = roleScreens[userDoc['role']];
      if (screen != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: screen),
        );
      }
    } catch (e) {
      print('Role determination error: $e');
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : LoginScreen(),
    );
  }
}
