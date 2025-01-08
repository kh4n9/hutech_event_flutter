import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import http
import 'package:http/http.dart' as http;

class EventsScreen extends StatefulWidget {
  const EventsScreen({Key? key}) : super(key: key);

  @override
  _EventsScreenState createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  QuerySnapshot<Map<String, dynamic>>? events;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> filteredEvents = [];
  Map<String, int> checkInCounts = {};
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    getEvents();
  }

  Future<Map<String, dynamic>?> fetchWeather({
    required String date, // Ngày (yyyy-MM-dd)
    required int hour, // Giờ (0-23)
  }) async {
    final String apiKey = '2dfd188927b5403c9ee101238242912';
    final String baseUrl = 'https://api.weatherapi.com/v1/forecast.json';
    final String location = '10.836716548527725,106.74422528655306'; // Tọa độ

    final String apiUrl =
        '$baseUrl?q=$location&days=1&dt=$date&hour=$hour&lang=vi&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        // Parse JSON data
        final data = json.decode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
        return data; // Trả về dữ liệu JSON
      } else {
        print('Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception: $e');
      return null;
    }
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
              // Weather forecast
              FutureBuilder<Map<String, dynamic>?>(
                future: fetchWeather(
                  date: eventData['start_date']
                      .toDate()
                      .toString()
                      .substring(0, 10),
                  hour: eventData['start_date']
                      .toDate()
                      .hour, // Lấy giờ bắt đầu của sự kiện
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  if (snapshot.hasError) {
                    return Text(
                        'Failed to fetch weather data: ${snapshot.error}');
                  }

                  if (snapshot.hasData) {
                    final weatherData = snapshot.data!;
                    final forecast = weatherData['forecast']['forecastday'][0];
                    final condition = forecast['hour'][0]['condition']['text'];
                    final tempC = forecast['hour'][0]['temp_c'];
                    final icon = forecast['hour'][0]['condition']['icon'];

                    return Column(
                      children: [
                        Image.network(
                          'https:$icon',
                          width: 50,
                          height: 50,
                        ),
                        Text('Weather forecast: $condition, $tempC°C'),
                      ],
                    );
                  }

                  return const Text('No weather data available');
                },
              ),
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
                    .where((doc) =>
                        !doc.data().containsKey('deleted_at') &&
                        (index == 0
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
