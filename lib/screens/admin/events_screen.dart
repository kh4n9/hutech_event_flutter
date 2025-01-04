import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({Key? key}) : super(key: key);

  @override
  _EventsScreenState createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  QuerySnapshot<Map<String, dynamic>>? events;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> filteredEvents = [];

  @override
  void initState() {
    super.initState();
    getEvents();
  }

  Future<void> getEvents() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('events').get();
    setState(() {
      events = snapshot;
      filteredEvents = snapshot.docs;
    });
  }

  void searchEvents(String value) {
    if (value.isEmpty) {
      setState(() {
        filteredEvents = events?.docs ?? [];
      });
      return;
    }

    setState(() {
      filteredEvents = events?.docs
              .where((doc) => doc['name']
                  .toString()
                  .toLowerCase()
                  .contains(value.toLowerCase()))
              .toList() ??
          [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                offset: Offset(0, 2),
                blurRadius: 2,
              ),
            ],
          ),
          child: TextField(
            onSubmitted: (value) => searchEvents(value),
            decoration: const InputDecoration(
              hintText: 'Search events',
              prefixIcon: Icon(Icons.search),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
      body: Center(
        child: events == null
            ? const CircularProgressIndicator()
            : filteredEvents.isEmpty
                ? const Text('No events found.')
                : ListView.builder(
                    itemCount: filteredEvents.length,
                    itemBuilder: (context, index) {
                      final event = filteredEvents[index];
                      return Card(
                        child: ListTile(
                          title: Text(event['name']),
                          subtitle: Text((event['start_date'] as Timestamp)
                              .toDate()
                              .toString()),
                          tileColor: event['status'] == 'Published'
                              ? Colors.green[100]
                              : event['status'] == 'Draft'
                                  ? Colors.blue[100]
                                  : Colors.red[100],
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('events')
                                  .doc(event.id)
                                  .delete();
                              getEvents();
                            },
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
