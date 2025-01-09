import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:jose/jose.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NotificationScreen extends StatefulWidget {
  // Renamed class
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  _NotificationScreenState createState() =>
      _NotificationScreenState(); // Renamed class
}

class _NotificationScreenState extends State<NotificationScreen> {
  // Renamed class
  late FirebaseMessaging messaging;

  @override
  void initState() {
    super.initState();
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

  Future<void> sendNotificationToAllDevices(String body, String title) async {
    const String endpoint =
        'https://fcm.googleapis.com/v1/projects/hutechevent/messages:send';

    final String accessToken = await getAccessToken(); // Tạo access token

    final Map<String, dynamic> message = {
      "message": {
        "topic": "all", // Topic đăng ký
        "notification": {
          "title": title,
          "body": body,
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

  TextEditingController titleController = TextEditingController();
  TextEditingController bodyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: bodyController,
                decoration: const InputDecoration(
                  labelText: 'Body',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                sendNotificationToAllDevices(
                    bodyController.text, titleController.text);
              },
              child: const Text('Send Notification to All Devices'),
            ),
          ],
        ),
      ),
    );
  }
}
