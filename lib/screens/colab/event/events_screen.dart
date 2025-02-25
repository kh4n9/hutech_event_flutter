import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'checkin_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({Key? key}) : super(key: key);

  @override
  _EventsScreenState createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  QuerySnapshot<Map<String, dynamic>>? events;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> filteredEvents = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    getEvents();
  }

  Future<void> getEvents() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('events')
        .where('deleted_at', isNull: true)
        .get();
    setState(() {
      events = snapshot;
      searchEvents(''); // Apply the current filter after loading events
    });
  }

  void searchEvents(String value) {
    if (value.isEmpty) {
      setState(() {
        filteredEvents = events?.docs.toList() ?? [];
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
                : RefreshIndicator(
                    onRefresh: getEvents,
                    child: ListView.builder(
                      itemCount: filteredEvents.length,
                      itemBuilder: (context, index) {
                        final event = filteredEvents[index];
                        final now = DateTime.now();
                        final startDate = event['start_date'].toDate();
                        final endDate = event['end_date'].toDate();

                        // Determine card color based on event status
                        Color? cardColor;
                        if (endDate.isBefore(now)) {
                          cardColor = Colors.grey[200]; // Completed event
                        } else if (startDate.isBefore(now) &&
                            endDate.isAfter(now)) {
                          cardColor = Colors.green[100]; // Ongoing event
                        } else if (startDate.isAfter(now)) {
                          cardColor = Colors.amber[100]; // Upcoming event
                        }

                        return Card(
                          color: cardColor,
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
                                onPressed: () async {
                                  // Check capacity before allowing navigation to check-in screen
                                  final currentCheckins =
                                      await FirebaseFirestore
                                          .instance
                                          .collection('checkins')
                                          .where('event_id',
                                              isEqualTo: event.id)
                                          .count()
                                          .get();

                                  final eventCapacity =
                                      event['capacity'] as num;
                                  if (currentCheckins.count! >= eventCapacity) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Event has reached maximum capacity'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (context) {
                                    return CheckinScreen(event: event);
                                  }));
                                },
                                // Grey out button if event ended or capacity reached
                                color: event['end_date']
                                        .toDate()
                                        .isBefore(DateTime.now())
                                    ? Colors.grey
                                    : Colors.green,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
      ),
      // phân loại các sự kiện theo trạng thái chưa diễn ra, đang diễn ra, đã diễn ra
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Upcoming',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_arrow),
            label: 'Ongoing',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.done),
            label: 'Completed',
          ),
        ],
        onTap: (index) {
          final now = DateTime.now();
          setState(() {
            _selectedIndex = index;
            filteredEvents = events?.docs
                    .where((doc) => (index == 0
                        ? doc['start_date'].toDate().isAfter(now)
                        : index == 1
                            ? doc['start_date'].toDate().isBefore(now) &&
                                doc['end_date'].toDate().isAfter(now)
                            : doc['end_date'].toDate().isBefore(now)))
                    .toList() ??
                [];
          });
        },
      ),
    );
  }
}
