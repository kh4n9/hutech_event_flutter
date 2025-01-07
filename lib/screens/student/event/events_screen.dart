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
  Map<String, int> checkInCounts = {};

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
    // Get check-in counts for all events
    for (var event in snapshot.docs) {
      getCheckInCount(event.id);
    }
  }

  Future<void> getCheckInCount(String eventId) async {
    final checkIns = await FirebaseFirestore.instance
        .collection('checkins')
        .where('event_id', isEqualTo: eventId)
        .get();

    setState(() {
      checkInCounts[eventId] = checkIns.docs.length;
    });
  }

  void searchEvents(String value) {
    final now = DateTime.now();
    if (value.isEmpty) {
      setState(() {
        filteredEvents = events?.docs
                .where((doc) =>
                    !doc.data().containsKey('deleted_at') &&
                    doc['end_date']
                        .toDate()
                        .isAfter(now)) // Only show future and ongoing events
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
                  !doc.data().containsKey('deleted_at') &&
                  doc['end_date']
                      .toDate()
                      .isAfter(now)) // Only show future and ongoing events
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

  void showEventDetailsDialog(Map<String, dynamic> eventData) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(eventData['name']),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Organization: ${eventData['organization']}'),
              Text('Description: ${eventData['description']}'),
              Text('Location: ${eventData['location']}'),
              Text('Start: ${eventData['start_date'].toDate()}'),
              Text('End: ${eventData['end_date'].toDate()}'),
              Text('Capacity: ${eventData['capacity']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
                      final now = DateTime.now();
                      final startDate = event['start_date'].toDate();
                      final endDate = event['end_date'].toDate();

                      // Determine card color based on event status
                      Color? cardColor;
                      if (startDate.isBefore(now) && endDate.isAfter(now)) {
                        cardColor = Colors.green[100]; // Ongoing event
                      } else {
                        cardColor = Colors.amber[100]; // Upcoming event
                      }

                      return Card(
                        color: cardColor,
                        margin:
                            EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: InkWell(
                          onTap: () => showEventDetailsDialog(event.data()),
                          child: Row(
                            children: [
                              Expanded(
                                child: ListTile(
                                  title: Text(event['name']),
                                  subtitle: Text(
                                      '${event['start_date'].toDate().toString().substring(0, 16)} - ${event['end_date'].toDate().toString().substring(0, 16)} | ${event['location']} | ${event['organization']} | ${checkInCounts[event.id] ?? 0}/${event['capacity']} people'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
