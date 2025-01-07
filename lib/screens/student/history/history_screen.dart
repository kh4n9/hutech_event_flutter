import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<DocumentSnapshot> _checkins = [];

  @override
  void initState() {
    super.initState();
    getCheckins();
  }

  // hàm sẽ lấy ra user trong bang users có email trùng với email của user đang đăng nhập và từ username của user đó lấy student trong bảng students có studentCode == username của user đó và từ đó lấy ra các checkin của student đó trong bảng checkins
  Future<void> getCheckins() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final User? user = _auth.currentUser;
    if (user != null) {
      final QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: user.email)
          .get(); // đây là cách lấy ra user trong bảng users có email trùng với email của user đang đăng nhập
      // in ra userQuery để xem cấu trúc của nó
      print(userQuery);

      if (userQuery.docs.isNotEmpty) {
        final DocumentSnapshot userDoc = userQuery.docs.first;
        final String username = userDoc['username'];
        final QuerySnapshot studentQuery = await FirebaseFirestore.instance
            .collection('students')
            .where('studentCode', isEqualTo: username)
            .get(); // đây là cách lấy ra student trong bảng students có studentCode trùng với username của user đó

        if (studentQuery.docs.isNotEmpty) {
          final DocumentSnapshot studentDoc = studentQuery.docs.first;
          final QuerySnapshot checkinQuery = await FirebaseFirestore.instance
              .collection('checkins')
              .where('student_code', isEqualTo: studentDoc['studentCode'])
              .get(); // đây là cách lấy ra các checkin của student đó trong bảng checkins

          if (checkinQuery.docs.isNotEmpty) {
            setState(() {
              _checkins = checkinQuery.docs;
            });
          }
        }
      }
    }
  }

  getEventById(String eventId) async {
    final DocumentSnapshot event = await FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .get();
    return event;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Check-in History'),
        centerTitle: true,
      ),
      body: _checkins.isEmpty
          ? TextButton(
              onPressed: getCheckins,
              child: Text('Get Checkins'),
            )
          : ListView.builder(
              itemCount: _checkins.length,
              itemBuilder: (context, index) {
                final DateTime checkinTime =
                    _checkins[index]['checkin_at'].toDate();
                final String formattedTime =
                    DateFormat('dd/MM/yyyy HH:mm').format(checkinTime);
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 3,
                  child: ListTile(
                    leading: Icon(Icons.event),
                    title: Text(formattedTime),
                    subtitle: FutureBuilder(
                      future: getEventById(_checkins[index]['event_id']),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Text('Loading...');
                        }
                        final DocumentSnapshot event =
                            snapshot.data as DocumentSnapshot;
                        return Text(event['name']);
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
