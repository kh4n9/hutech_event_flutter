import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    final snapshot = await FirebaseFirestore.instance
        .collection('events')
        .where('deleted_at', isNull: true)
        .get();
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
    if (events == null) return;

    final now = DateTime.now();
    setState(() {
      filteredEvents = events!.docs.where((doc) {
        final endDate = (doc.data()['end_date'] as Timestamp?)?.toDate();
        if (endDate == null) return false;

        if (value.isEmpty) {
          return endDate.isAfter(now);
        }

        final name = doc.data()['name']?.toString().toLowerCase() ?? '';
        return name.contains(value.toLowerCase()) && endDate.isAfter(now);
      }).toList();
    });
  }

  void filterEventsByStatus(int index) {
    if (events == null) return;

    final now = DateTime.now();
    setState(() {
      _selectedIndex = index;
      filteredEvents = events!.docs.where((doc) {
        final startDate = (doc.data()['start_date'] as Timestamp?)?.toDate();
        final endDate = (doc.data()['end_date'] as Timestamp?)?.toDate();
        if (startDate == null || endDate == null) return false;

        switch (index) {
          case 0: // Upcoming
            return startDate.isAfter(now);
          case 1: // Ongoing
            return startDate.isBefore(now) && endDate.isAfter(now);
          case 2: // Completed
            return endDate.isBefore(now);
          default:
            return false;
        }
      }).toList();
    });
  }

  void showEventDetailsDialog(Map<String, dynamic> eventData) {
    // Safely get dates
    final startDate = (eventData['start_date'] as Timestamp?)?.toDate();
    final endDate = (eventData['end_date'] as Timestamp?)?.toDate();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(eventData['name'] ?? 'No name'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (eventData['image_url'] != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      eventData['image_url'],
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text('Organization: ${eventData['organization'] ?? 'N/A'}'),
                Text('Description: ${eventData['description'] ?? 'N/A'}'),
                Text('Location: ${eventData['location'] ?? 'N/A'}'),
                Text('Start: ${startDate?.toString() ?? 'N/A'}'),
                Text('End: ${endDate?.toString() ?? 'N/A'}'),
                Text('Capacity: ${eventData['capacity']?.toString() ?? 'N/A'}'),
                if (startDate != null) // Only show weather if start date exists
                  FutureBuilder<Map<String, dynamic>?>(
                    future: fetchWeather(
                      date: startDate.toString().substring(0, 10),
                      hour: startDate.hour,
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
                        final forecast =
                            weatherData['forecast']['forecastday'][0];
                        final condition =
                            forecast['hour'][0]['condition']['text'];
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget buildEventCard(QueryDocumentSnapshot<Map<String, dynamic>> event) {
    final data = event.data();
    final now = DateTime.now();
    final startDate = (data['start_date'] as Timestamp?)?.toDate();
    final endDate = (data['end_date'] as Timestamp?)?.toDate();

    if (startDate == null || endDate == null) {
      return const SizedBox.shrink(); // Skip invalid events
    }

    // Determine card color based on event status
    Color? cardColor;
    if (endDate.isBefore(now)) {
      cardColor = Colors.grey[200];
    } else if (startDate.isBefore(now) && endDate.isAfter(now)) {
      cardColor = Colors.green[100];
    } else {
      cardColor = Colors.amber[100];
    }

    return Card(
      color: cardColor,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => showEventDetailsDialog(data),
        child: Row(
          children: [
            if (data['image_url'] != null)
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(data['image_url']),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
              ),
            Expanded(
              child: ListTile(
                title: Text(data['name'] ?? 'No name'),
                subtitle: Text(
                  '${startDate.toString().substring(0, 16)} - ${endDate.toString().substring(0, 16)}\n'
                  '${data['location'] ?? 'No location'} | ${data['organization'] ?? 'No organization'}\n'
                  '${checkInCounts[event.id] ?? 0}/${data['capacity'] ?? 0} people',
                ),
                isThreeLine: true,
              ),
            ),
          ],
        ),
      ),
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
                      itemBuilder: (context, index) =>
                          buildEventCard(filteredEvents[index]),
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
        onTap: filterEventsByStatus,
      ),
    );
  }
}
