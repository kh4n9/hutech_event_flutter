import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart'; // Import for rootBundle
import 'package:jose/jose.dart';

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

    // Lấy token của thiết bị hiện tại
    String? token = await messaging.getToken();
    print('Device Token: $token');
    //show snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Device Token: $token'),
      ),
    );

    // Yêu cầu quyền thông báo (chỉ cho iOS)
    await messaging.requestPermission();

    // Đăng ký topic "all"
    FirebaseMessaging.instance.subscribeToTopic('all');
  }

  Future<String> getAccessToken() async {
    final String serviceAccount = await rootBundle.loadString(
        'assets/hutechevent-firebase-adminsdk-q5itl-0205e65f9d.json');
    final Map<String, dynamic> credentials = json.decode(serviceAccount);

    final String clientEmail = credentials['client_email'];
    final String privateKeyString = credentials['private_key'];
    final String tokenUri = credentials['token_uri'];

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

  Future<void> sendNotificationToAllDevices() async {
    const String endpoint =
        'https://fcm.googleapis.com/v1/projects/hutechevent/messages:send';

    final String accessToken = await getAccessToken(); // Tạo access token

    final Map<String, dynamic> message = {
      "message": {
        "topic": "all", // Topic đăng ký
        "notification": {
          "title": "Thông báo mới!",
          "body": "Đây là thông báo gửi đến tất cả thiết bị.",
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: sendNotificationToAllDevices,
          child: const Text('Send Notification to All Devices'),
        ),
      ),
    );
  }
}
