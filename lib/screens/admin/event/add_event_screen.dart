import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:jose/jose.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  late FirebaseMessaging messaging;
  String? image_url;

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
      image_url = widget.event['image_url'];
    }
    setupFirebaseMessaging();
  }

  void setupFirebaseMessaging() async {
    messaging = FirebaseMessaging.instance;

    // Yêu cầu quyền thông báo (chỉ cho iOS)
    await messaging.requestPermission();

    // Đăng ký topic "all"
    FirebaseMessaging.instance.subscribeToTopic('all');
  }

  Future<String> getAccessToken() async {
    final String clientEmail = dotenv.env['CLIENT_EMAIL']!;
    final String privateKeyString = dotenv.env['PRIVATE_KEY']!.replaceAll(
      r'\n',
      '\n',
    );
    final String tokenUri = dotenv.env['TOKEN_URI']!;

    // Create claims for FCM scope
    final claims = JsonWebTokenClaims.fromJson({
      "iss": clientEmail,
      "scope": "https://www.googleapis.com/auth/firebase.messaging",
      "aud": tokenUri,
      "exp":
          DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
      "iat": DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });

    // Create JWT
    final builder = JsonWebSignatureBuilder()
      ..jsonContent = claims.toJson()
      ..addRecipient(
        JsonWebKey.fromPem(privateKeyString),
        algorithm: 'RS256',
      );

    final token = builder.build();

    final response = await http.post(
      Uri.parse(tokenUri),
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {
        "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
        "assertion": token.toCompactSerialization(),
      },
    );

    if (response.statusCode == 200) {
      // show snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Access token generated successfully!'),
        ),
      );
      return json.decode(response.body)['access_token'];
    } else {
      print('Failed to generate access token: ${response.body}');
      // show snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate access token! ${response.body}'),
        ),
      );
      throw Exception('Failed to generate access token: ${response.body}');
    }
  }

  Future<void> sendNotificationToAllDevices(
      String body, String title, String image_url) async {
    const String endpoint =
        'https://fcm.googleapis.com/v1/projects/hutechevent/messages:send';

    final String accessToken = await getAccessToken(); // Tạo access token

    final Map<String, dynamic> message = {
      "message": {
        "topic": "all", // Topic đăng ký
        "notification": {
          "title": title,
          "body": body,
          "image": image_url,
        },
        "android": {
          "priority": "high",
        },
        "apns": {
          "headers": {
            "apns-priority": "10",
          },
        },
      }
    };

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.authorizationHeader: 'Bearer $accessToken',
        },
        body: json.encode(message),
      );

      if (response.statusCode == 200) {
        print('Notification sent successfully!');
        // Show a snackbar to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification sent successfully!'),
          ),
        );
      } else {
        print('Failed to send notification: ${response.body}');
        // Show a snackbar to indicate failure
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send notification!'),
          ),
        );
      }
    } catch (e) {
      print('Error sending notification: $e');
      // Show a snackbar to indicate failure
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error sending notification!'),
        ),
      );
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

  Future<void> pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null) {
      String? uploadedUrl = await _uploadImageToDiscord(result);
      if (uploadedUrl != null) {
        setState(() {
          image_url = uploadedUrl;
        });
      }
    }
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
        'image_url': image_url,
        'created_at': FieldValue.serverTimestamp(),
        'deleted_at': null,
      });

      // Send notification about the new event
      await sendNotificationToAllDevices(
          '${nameController.text} at ${locationController.text}',
          'New Event Added!',
          image_url ?? '');
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    }
  }

  _uploadImageToDiscord(FilePickerResult result) async {
    final String botToken = dotenv.env['DISCORD_BOT_TOKEN']!;
    final String channelId = dotenv.env['DISCORD_CHANNEL_ID']!;

    if (result.files.isEmpty) {
      print('Không chọn tệp nào');
      return;
    }

    File file = File(result.files.single.path!);

    try {
      // Tạo multipart request
      var uri =
          Uri.parse("https://discord.com/api/v10/channels/$channelId/messages");
      var request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bot $botToken'
        ..fields['content'] =
            nameController.text // Nội dung tin nhắn (tuỳ chọn)
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      // Gửi request
      var response = await request.send();

      if (response.statusCode == 200) {
        print('Ảnh đã được tải lên thành công!');
        // get response body
        var responseString = await response.stream.bytesToString();
        final body = json.decode(responseString);
        return body['attachments'][0]['url'];
      } else {
        print('Lỗi khi tải ảnh lên: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Lỗi: $e');
      return null;
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
        'image_url': image_url,
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
          child: SingleChildScrollView(
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
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: pickImage,
                        child: const Text('Choose Image'),
                      ),
                      if (image_url != null) ...[
                        const SizedBox(height: 10),
                        Image.network(
                          image_url!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ],
                    ],
                  ),
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
                  onPressed: () async {
                    // Changed to async
                    if (widget.event != null) {
                      await updateEvent();
                    } else {
                      await addEvent(); // Wait for addEvent to complete
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
      ),
    );
  }
}
