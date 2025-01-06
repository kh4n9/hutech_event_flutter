import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ColabDashboard extends StatefulWidget {
  const ColabDashboard({Key? key}) : super(key: key);

  @override
  _ColabDashboardState createState() => _ColabDashboardState();
}

class _ColabDashboardState extends State<ColabDashboard> {
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
      body: Center(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              Container(
                alignment: Alignment.topLeft,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/colab/event');
                  },
                  child: const Text('Event'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
