import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int completedEvents = 0;
  int ongoingEvents = 0;
  int upcomingEvents = 0;

  @override
  void initState() {
    super.initState();
    getEvents();
  }

  Future<void> getEvents() async {
    final snapshot = await FirebaseFirestore.instance.collection('events').get();
    final now = DateTime.now();

    int completed = 0;
    int ongoing = 0;
    int upcoming = 0;

    for (var doc in snapshot.docs) {
      final startDate = doc['start_date'].toDate();
      final endDate = doc['end_date'].toDate();

      if (endDate.isBefore(now)) {
        completed++;
      } else if (startDate.isBefore(now) && endDate.isAfter(now)) {
        ongoing++;
      } else if (startDate.isAfter(now)) {
        upcoming++;
      }
    }

    setState(() {
      completedEvents = completed;
      ongoingEvents = ongoing;
      upcomingEvents = upcoming;
    });
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Event Report'),
    ),
    body: Center(
      child: completedEvents + ongoingEvents + upcomingEvents == 0
          ? const CircularProgressIndicator()
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Completed Events: $completedEvents'),
                Text('Ongoing Events: $ongoingEvents'),
                Text('Upcoming Events: $upcomingEvents'),
                const SizedBox(height: 20),
                SizedBox(
                  width: 200, // Set the desired width
                  height: 200, // Set the desired height
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: completedEvents.toDouble(),
                          title: 'Completed',
                          color: Colors.grey,
                        ),
                        PieChartSectionData(
                          value: ongoingEvents.toDouble(),
                          title: 'Ongoing',
                          color: Colors.green,
                        ),
                        PieChartSectionData(
                          value: upcomingEvents.toDouble(),
                          title: 'Upcoming',
                          color: Colors.amber,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    ),
  );
}
}