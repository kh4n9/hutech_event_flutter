import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      // Lấy document của người dùng từ Firestore
      var snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: _auth.currentUser!.email)
          .get();

      var userDoc = snapshot.docs.isEmpty ? null : snapshot.docs.first;

      if (userDoc == null) return false;

      bool biometricEnabled = userDoc['biometric'] ?? false;
      if (biometricEnabled) {
        // Kiểm tra nếu thiết bị hỗ trợ biometrics
        bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
        print('Thiết bị hỗ trợ biometrics: $canAuthenticateWithBiometrics');
        // lấy ra danh sách các loại biometrics mà thiết bị hỗ trợ
        List<BiometricType> availableBiometrics =
            await auth.getAvailableBiometrics();

        if (canAuthenticateWithBiometrics && availableBiometrics.isNotEmpty) {
          bool authenticated = await authenticate();
          if (!authenticated) return false;
        } else {
          print('Thiết bị không hỗ trợ biometrics.');
          return true;
        }
      }
      return true;
    } catch (e) {
      print('Lỗi kiểm tra người dùng: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : LoginScreen(),
    );
  }
}
