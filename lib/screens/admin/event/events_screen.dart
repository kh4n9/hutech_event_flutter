import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_event_screen.dart';
import 'checkin_screen.dart';

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
      searchEvents(''); // Apply the current filter after loading events
    });
  }

  void searchEvents(String value) {
    if (value.isEmpty) {
      setState(() {
        filteredEvents = events?.docs
                .where((doc) => !doc.data().containsKey('deleted_at'))
                .toList() ??
            [];
      });
      return;
    }

    setState(() {
      filteredEvents = events?.docs
              .where((doc) =>
                  doc['name']
                      .toString()
                      .toLowerCase()
                      .contains(value.toLowerCase()) &&
                  !doc.data().containsKey('deleted_at'))
              .toList() ??
          [];
    });
  }

  softDeleteEvent(String id, String name) async {
    await FirebaseFirestore.instance.collection('events').doc(id).update({
      'deleted_at': Timestamp.now(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Event $name has been deleted.'),
      ),
    );
    getEvents(); // Reload events after deletion
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
                        color: event['start_date']
                                .toDate()
                                .isBefore(DateTime.now())
                            ? Colors.grey[500]
                            : null,
                        child: Row(
                          children: [
                            Expanded(
                              child: ListTile(
                                title: Text(event['name']),
                                subtitle: Text(
                                    '${event['start_date'].toDate().toString().substring(0, 16)} - ${event['end_date'].toDate().toString().substring(0, 16)} | ${event['location']} | ${event['organization']} | ${event['capacity']} people'),
                              ),
                            ),
                            //button check in
                            IconButton(
                              icon: const Icon(Icons.check),
                              onPressed: () {
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) {
                                  return CheckinScreen(event: event);
                                }));
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) {
                                  return AddEventScreen(event: event);
                                })).then((value) {
                                  if (value == true) {
                                    getEvents();
                                  }
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                await showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('Delete Event'),
                                      content: Text(
                                          'Are you sure you want to delete ${event['name']}?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            softDeleteEvent(event.id,
                                                event['name'].toString());
                                            Navigator.pop(context, true);
                                          },
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return AddEventScreen();
          })).then((value) {
            if (value == true) {
              getEvents();
            }
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
