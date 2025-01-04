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
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text("Decistions Tree"),
    );
  }
}
