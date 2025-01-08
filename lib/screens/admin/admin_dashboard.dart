import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hutech_event_flutter/screens/admin/notification/notifucation_screen.dart';
import 'package:hutech_event_flutter/screens/admin/report_screen.dart';
import 'package:hutech_event_flutter/screens/admin/student/students_screen.dart';
import 'package:hutech_event_flutter/screens/admin/user/users_screen.dart';

import 'event/events_screen.dart';
import 'package:hutech_event_flutter/screens/admin/event/setting_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int currentPageIndex = 0;
  String error = '';

  logout() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    setState(() {
      error = '';
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.deepPurple[50],
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            onPressed: () {
              logout();
              Navigator.pushNamed(context, '/');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: IndexedStack(
        index: currentPageIndex,
        children: const <Widget>[
          EventsScreen(),
          UsersScreen(),
          StudentsScreen(),
          ReportScreen(),
          NotificationScreen(),
          SettingScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: Colors.amber,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.school),
            label: 'Students',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: 'Report',
          ),
          NavigationDestination(
              icon: Icon(Icons.notifications), label: 'Notifi'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
