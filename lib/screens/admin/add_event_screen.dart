import 'package:flutter/material.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({Key? key}) : super(key: key);

  @override
  _AddEventScreenState createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: <Widget>[
          // back button
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Back'),
          ),
          Text('Add Event'),
        ],
      ),
    );
  }
}
