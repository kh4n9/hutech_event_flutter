import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CheckinScreen extends StatefulWidget {
  final DocumentSnapshot<Map<String, dynamic>> event;
  const CheckinScreen({Key? key, required this.event}) : super(key: key);

  @override
  _CheckinScreenState createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  TextEditingController student_codeController = TextEditingController();
  String error = '';

  checkin() async {
    try {
      // tạo một checkin mới với student_id và event_id checkin_by(id của user đang đăng nhập) checkin_at
      await FirebaseFirestore.instance.collection('checkins').add({
        'event_id': widget.event.id,
        'student_id': await FirebaseFirestore.instance
            .collection('students')
            .where('student_code', isEqualTo: student_codeController.text)
            .get()
            .then((snapshot) => snapshot.docs.first.id),
        'checkin_by': FirebaseAuth.instance.currentUser!.uid,
        'checkin_at': Timestamp.now(),
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Checkin Event ${widget.event['name']}'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Event: ${widget.event['name']}'),
            TextField(
              controller: student_codeController,
              decoration: InputDecoration(labelText: 'Student Code'),
            ),
            if (error.isNotEmpty)
              Text(error, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: () {
                checkin();
              },
              child: const Text('Checkin'),
            ),
          ],
        ),
      ),
    );
  }
}
