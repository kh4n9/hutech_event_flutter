import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'events_screen.dart';
import 'add_event_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int currentPageIndex = 0;

  logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
          Text('Users Screen'),
          Text('Students Screen'),
          Text('Reports Screen'),
          Text('Notifications Screen'),
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
          NavigationDestination(icon: Icon(Icons.report), label: 'Reports'),
          NavigationDestination(
              icon: Icon(Icons.notifications), label: 'Notifications'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber,
        onPressed: () {
          if (currentPageIndex == 0) {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return const AddEventScreen();
            }));
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
