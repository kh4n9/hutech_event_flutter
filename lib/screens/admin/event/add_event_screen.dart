import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class AddEventScreen extends StatefulWidget {
  final event;
  const AddEventScreen({Key? key, this.event}) : super(key: key);

  @override
  _AddEventScreenState createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  TextEditingController organizationController = TextEditingController();
  TextEditingController capacityController = TextEditingController();
  DateTime? start_date;
  DateTime? end_date;
  num? capacity;
  bool firstTime = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      nameController.text = widget.event['name'];
      descriptionController.text = widget.event['description'];
      locationController.text = widget.event['location'];
      organizationController.text = widget.event['organization'];
      start_date = widget.event['start_date'].toDate();
      end_date = widget.event['end_date'].toDate();
      capacity = widget.event['capacity'];
    }
  }

  setStartDate(DateTime date) {
    setState(() {
      start_date = date;
    });
  }

  setEndDate(DateTime date) {
    setState(() {
      end_date = date;
    });
  }

  Future<DateTime> pickDateTime() async {
    // Chọn ngày
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    // Chọn giờ
    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (selectedDate == null || selectedTime == null) return DateTime.now();
    // Kết hợp ngày và giờ
    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
  }

  addEvent() async {
    try {
      await FirebaseFirestore.instance.collection('events').add({
        'name': nameController.text,
        'description': descriptionController.text,
        'location': locationController.text,
        'created_by': FirebaseAuth.instance.currentUser!.uid,
        'organization': organizationController.text,
        'start_date': start_date,
        'end_date': end_date,
        'capacity': capacity,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    }
  }

  updateEvent() async {
    try {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.event.id)
          .update({
        'name': nameController.text,
        'description': descriptionController.text,
        'location': locationController.text,
        'organization': organizationController.text,
        'start_date': start_date,
        'end_date': end_date,
        'capacity': capacity,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.event != null
            ? const Text('Edit Event')
            : const Text('Add Event'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              TextField(
                controller: organizationController,
                decoration: const InputDecoration(labelText: 'Organization'),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final DateTime date = await pickDateTime();
                      setStartDate(date);
                    },
                    child: const Text('Start Date'),
                  ),
                  if (start_date != null)
                    Text(
                      start_date.toString(),
                    )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final DateTime date = await pickDateTime();
                      setEndDate(date);
                    },
                    child: const Text('End Date'),
                  ),
                  if (end_date != null)
                    Text(
                      end_date.toString(),
                    )
                ],
              ),
              TextFormField(
                  initialValue: capacity?.toString(),
                  onChanged: (value) => capacity = num.tryParse(value),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(labelText: "Capacity")),
              if (error.isNotEmpty)
                Text(
                  error,
                  style: const TextStyle(color: Colors.red),
                ),
              ElevatedButton(
                onPressed: () {
                  if (widget.event != null) {
                    updateEvent();
                  } else {
                    addEvent();
                  }
                  Navigator.pop(context, true);
                },
                child: widget.event != null
                    ? const Text('Update Event')
                    : const Text('Add Event'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
