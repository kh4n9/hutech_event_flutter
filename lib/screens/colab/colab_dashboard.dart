import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hutech_event_flutter/screens/colab/event/events_screen.dart';
import 'package:hutech_event_flutter/screens/colab/event/setting_screen.dart';

class ColabDashboard extends StatefulWidget {
  const ColabDashboard({Key? key}) : super(key: key);

  @override
  _ColabDashboardState createState() => _ColabDashboardState();
}

class _ColabDashboardState extends State<ColabDashboard> {
  int currentPageIndex = 0;
  logout() async {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Colab Dashboard'),
        actions: [
          IconButton(
            onPressed: () {
              logout();
              Navigator.pushReplacementNamed(context, '/');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: IndexedStack(
        index: currentPageIndex,
        children: const <Widget>[
          EventsScreen(),
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
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
