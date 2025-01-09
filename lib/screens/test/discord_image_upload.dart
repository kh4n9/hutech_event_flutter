import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DiscordImageUpload extends StatefulWidget {
  @override
  _DiscordImageUploadState createState() => _DiscordImageUploadState();
}

class _DiscordImageUploadState extends State<DiscordImageUpload> {
  _uploadImageToDiscord() async {
    final String botToken = dotenv.env['DISCORD_BOT_TOKEN']!;
    final String channelId = dotenv.env['DISCORD_CHANNEL_ID']!;
    // Chọn tệp ảnh từ thiết bị
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result == null || result.files.isEmpty) {
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
            'Đây là ảnh của tôi!' // Nội dung tin nhắn (tuỳ chọn)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Upload Image to Discord"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _uploadImageToDiscord,
          child: Text("Upload Image"),
        ),
      ),
    );
  }
}
