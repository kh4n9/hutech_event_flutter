import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:barcode_scan2/barcode_scan2.dart';

class CheckinScreen extends StatefulWidget {
  final DocumentSnapshot<Map<String, dynamic>> event;
  const CheckinScreen({Key? key, required this.event}) : super(key: key);

  @override
  _CheckinScreenState createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  final TextEditingController _studentCodeController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  String _error = '';
  String _successMessage = '';

  String _scanResult = "No data scanned yet.";

  // Hàm quét QR code
  Future<void> scanQRCode() async {
    try {
      var result = await BarcodeScanner.scan();
      setState(() {
        _scanResult = result.rawContent; // Lấy nội dung của QR Code
      });
      _studentCodeController.text =
          _scanResult; // Điền nội dung vào ô nhập liệu
      checkin(); // Thực hiện check-in
    } catch (e) {
      setState(() {
        _scanResult = "Error: $e";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Auto focus on input field when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _studentCodeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> checkin() async {
    if (_studentCodeController.text.isEmpty) {
      _showError('Please enter student code');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
      _successMessage = '';
    });

    try {
      // Get student data
      final studentQuery = await FirebaseFirestore.instance
          .collection('students')
          .where('studentCode', isEqualTo: _studentCodeController.text)
          .where('deleted_at', isNull: true)
          .limit(1)
          .get();

      if (studentQuery.docs.isEmpty) {
        _showError('Student not found');
        return;
      }

      final student = studentQuery.docs.first;

      // Check if event is still active
      final eventData = widget.event.data();
      if (eventData == null) {
        _showError('Event not found');
        return;
      }

      final now = Timestamp.now();
      final endTime = eventData['end_time'] as Timestamp?;
      if (endTime != null && endTime.compareTo(now) < 0) {
        _showError('Event has ended');
        return;
      }

      // Check for existing check-in
      final existingCheckin = await FirebaseFirestore.instance
          .collection('checkins')
          .where('event_id', isEqualTo: widget.event.id)
          .where('student_id', isEqualTo: student.id)
          .limit(1)
          .get();

      if (existingCheckin.docs.isNotEmpty) {
        _showError('Student already checked in');
        return;
      }

      // Create new check-in
      await FirebaseFirestore.instance.collection('checkins').add({
        'event_id': widget.event.id,
        'student_id': student.id,
        'student_code': student['studentCode'],
        'student_name': student['name'],
        'checkin_by': FirebaseAuth.instance.currentUser!.uid,
        'checkin_at': now,
      });

      // Show success and clear input
      setState(() {
        _successMessage = 'Check-in successful: ${student['name']}';
        _studentCodeController.clear();
      });

      // Refocus input for next check-in
      _focusNode.requestFocus();
    } catch (e) {
      _showError('Error during check-in: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    setState(() {
      _error = message;
      _successMessage = '';
      _isLoading = false;
    });
  }

  Stream<QuerySnapshot> getCheckinStream() {
    try {
      return FirebaseFirestore.instance
          .collection('checkins')
          .where('event_id', isEqualTo: widget.event.id)
          .orderBy('checkin_at', descending: true)
          .snapshots()
          .handleError((error) {
        if (error.toString().contains('requires an index')) {
          // _showError('Please create an index for this query. Check Firebase Console.');
        } else {
          _showError('Error loading checkins: $error');
        }
      });
    } catch (e) {
      _showError('Error setting up checkin stream: $e');
      rethrow;
    }
  }

  Widget _buildCheckinList() {
    return StreamBuilder<QuerySnapshot>(
      stream: getCheckinStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading checkins\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Retry loading
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final checkins = snapshot.data!.docs;

        if (checkins.isEmpty) {
          return const Center(
            child: Text('No students checked in yet'),
          );
        }

        return ListView.builder(
          itemCount: checkins.length,
          itemBuilder: (context, index) {
            final checkin = checkins[index].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4.0,
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    '${checkins.length - index}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(checkin['student_name'] ?? 'Unknown'),
                subtitle: Text(checkin['student_code'] ?? 'No code'),
                trailing: Text(
                  _formatDateTime(checkin['checkin_at'] as Timestamp),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Check-in: ${widget.event['name']}'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          widget.event['name'],
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Scan QR code or enter student code to check-in',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(_scanResult, style: TextStyle(color: Colors.blue)),
                        ElevatedButton(
                          onPressed: scanQRCode,
                          child: const Text('Scan QR Code'),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _studentCodeController,
                          focusNode: _focusNode,
                          decoration: const InputDecoration(
                            labelText: 'Student Code',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          keyboardType: TextInputType.number,
                          onSubmitted: (_) => checkin(),
                          enabled: !_isLoading,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      _error,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (_successMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      _successMessage,
                      style: const TextStyle(color: Colors.green),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ElevatedButton(
                  onPressed: _isLoading ? null : checkin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Check-in'),
                ),
              ],
            ),
          ),
          const Divider(thickness: 1),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Text(
                  'Checked-in Students',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                StreamBuilder<QuerySnapshot>(
                  stream: getCheckinStream(),
                  builder: (context, snapshot) {
                    final count =
                        snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return Text(
                      'Total: $count',
                      style: Theme.of(context).textTheme.titleMedium,
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(child: _buildCheckinList()),
        ],
      ),
    );
  }

  String _formatDateTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
