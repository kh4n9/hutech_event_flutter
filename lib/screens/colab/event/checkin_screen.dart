import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:intl/intl.dart';

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

  // Improved QR scanning with better error handling
  Future<void> scanQRCode() async {
    try {
      final result = await BarcodeScanner.scan();
      if (!mounted) return;

      setState(() => _scanResult = result.rawContent);
      if (result.rawContent.isNotEmpty) {
        _studentCodeController.text = result.rawContent;
        await checkin();
      }
    } on PlatformException catch (e) {
      setState(() => _scanResult = "Error: ${e.message}");
    } catch (e) {
      setState(() => _scanResult = "Error: Unknown error occurred");
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

  // Optimized check-in logic
  Future<void> checkin() async {
    if (!_validateInput()) return;

    setState(() {
      _isLoading = true;
      _error = '';
      _successMessage = '';
    });

    try {
      if (!await _checkEventCapacity()) return;
      final student = await _getStudent();
      if (student == null) return;
      if (!await _validateEventStatus()) return;
      if (await _isAlreadyCheckedIn(student.id)) return;

      await _createCheckin(student);
      _handleSuccess(student['name']);
    } catch (e) {
      _showError('Error during check-in: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _validateInput() {
    if (_studentCodeController.text.isEmpty) {
      _showError('Please enter student code');
      return false;
    }
    return true;
  }

  Future<bool> _checkEventCapacity() async {
    final currentCheckins = await FirebaseFirestore.instance
        .collection('checkins')
        .where('event_id', isEqualTo: widget.event.id)
        .count()
        .get();

    if (currentCheckins.count! >= widget.event['capacity']) {
      _showError('Event has reached maximum capacity');
      return false;
    }
    return true;
  }

  Future<DocumentSnapshot?> _getStudent() async {
    final studentQuery = await FirebaseFirestore.instance
        .collection('students')
        .where('studentCode', isEqualTo: _studentCodeController.text)
        .where('deleted_at', isNull: true)
        .limit(1)
        .get();

    if (studentQuery.docs.isEmpty) {
      _showError('Student not found');
      return null;
    }
    return studentQuery.docs.first;
  }

  Future<bool> _validateEventStatus() async {
    final eventData = widget.event.data();
    if (eventData == null) {
      _showError('Event not found');
      return false;
    }

    final now = Timestamp.now();
    final endTime = eventData['end_time'] as Timestamp?;
    if (endTime != null && endTime.compareTo(now) < 0) {
      _showError('Event has ended');
      return false;
    }
    return true;
  }

  Future<bool> _isAlreadyCheckedIn(String studentId) async {
    final existingCheckin = await FirebaseFirestore.instance
        .collection('checkins')
        .where('event_id', isEqualTo: widget.event.id)
        .where('student_id', isEqualTo: studentId)
        .limit(1)
        .get();

    if (existingCheckin.docs.isNotEmpty) {
      _showError('Student already checked in');
      return true;
    }
    return false;
  }

  Future<void> _createCheckin(DocumentSnapshot student) async {
    await FirebaseFirestore.instance.collection('checkins').add({
      'event_id': widget.event.id,
      'student_id': student.id,
      'student_code': student['studentCode'],
      'student_name': student['name'],
      'checkin_by': FirebaseAuth.instance.currentUser!.uid,
      'checkin_at': Timestamp.now(),
    });
  }

  reloadCheckins() {
    setState(() async {
      await FirebaseFirestore.instance.collection('checkins').get();
    });
  }

  void _handleSuccess(String studentName) {
    setState(() {
      _successMessage = 'Check-in successful: $studentName';
      _studentCodeController.clear();
      _scanResult = "No data scanned yet.";
    });
    _focusNode.requestFocus();
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

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
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
          ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: scanQRCode,
                      icon: const Icon(Icons.qr_code),
                      label: const Text('Scan QR'),
                    ),
                    ElevatedButton.icon(
                      onPressed: checkin,
                      icon: const Icon(Icons.check),
                      label: const Text('Check-in'),
                    ),
                  ],
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

  // Improved date formatting
  String _formatDateTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('HH:mm').format(date);
  }
}
