import 'dart:convert';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:chatbot_ui/services/notification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class ChatAPI {
  static const apiUrl = "http://10.0.2.2:8000";
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final notificationService = NotificationService();

  Future<String?> getFreshAccessToken() async {
    try {
      final String? accessToken = await _secureStorage.read(key: 'access_token');
      final String? expirationTimeStr = await _secureStorage.read(key: 'expiration_time');

      if (accessToken == null || expirationTimeStr == null) {
        return null;
      }

      final DateTime expirationTime = DateTime.parse(expirationTimeStr);
      if (DateTime.now().isBefore(expirationTime)) {
        return accessToken;
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final String newAccessToken = googleAuth.accessToken!;

        await _secureStorage.write(key: 'access_token', value: newAccessToken);
        await _secureStorage.write(key: 'expiration_time', value: DateTime.now().add(const Duration(seconds: 3600)).toIso8601String());

        return newAccessToken;
      }

      return null;
    } catch (e) {
      print('Error getting fresh access token: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> sendMessageToApi(
      String message, chatHistory, stage, email) async {
    final String? accessToken = await getFreshAccessToken();

    if (accessToken == null) {
      await _signOut();
      return {'text': "Failed to retrieve access token. User signed out."};
    }
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };

    var body = jsonEncode({
      "query": message,
      "chat_history": chatHistory,
      "stage": stage,
      "email": email,
    });

    try {
      final response = await http.post(Uri.parse('$apiUrl/chat'), headers: headers, body: body);
      if (response.statusCode == 200) {
        var decodedResponse = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decodedResponse);
        // final data = json.decode(response.body);
        print(data);
        if (data['nInfo'] != null) {
          final nInfo = data['nInfo'];

          if (nInfo['delete'] != null && nInfo['delete'] is List) {
            for (var id in nInfo['delete']) {
              if (id != null && id is String) {
                await NotificationService().cancelAllTypeNotification(id);
              }
            }
          } else {
            String? taskId = nInfo['task_id'] as String?;
          String title = nInfo['title'] as String? ?? "Scheduled Task";
          String body = nInfo['body'] as String? ?? "You have a scheduled event. Ask for more details.";
          String? startDate = nInfo['startdate'] as String?;
          String? startTime = nInfo['starttime'] as String?;
          String? endTime = nInfo['endtime'] as String?;
            String title1 = nInfo['title1'] as String? ?? "Not found title ";
            String body1 = nInfo['body1'] as String? ?? "Not found body ";
// Check for null values before proceeding
          if (taskId != null && startDate != null && startTime != null && endTime != null) {
            DateTime startDateTime = DateTime.parse('$startDate $startTime:00');
            DateTime endDateTime = DateTime.parse('$startDate $endTime:00');

            // Calculate the duration between start and end times
            Duration duration = endDateTime.difference(startDateTime);

            // Find 20% of the duration (for chat notification)
            Duration twentyPercentDuration = duration * 0.20;

            // Calculate the time for the chat notification (start time + 20% of duration)
            DateTime chatNotificationTime = startDateTime.add(twentyPercentDuration);

            bool isAllowed = await AwesomeNotifications().isNotificationAllowed();

            // 🔹 If not allowed, request permission
            if (!isAllowed) {
              print("🔔 Notification permission is not granted. Requesting now...");

              // Request permission
              await AwesomeNotifications().requestPermissionToSendNotifications();

              // 🔹 Re-check after requesting
              bool isNowAllowed = await AwesomeNotifications().isNotificationAllowed();

              if (!isNowAllowed) {
                print("🚫 Notification permission denied. Cannot schedule notification.");
                return {'text': "Changes saved to database but notification not allowed. you can allow notification in the app settings."};
              }
            }

            // Check if it's a daily event or a one-time event
            if (data['payload']['daily'] != null && data['payload']['daily'] == true) {
              TimeOfDay scheduledTimeOfDay = TimeOfDay(hour: startDateTime.hour, minute: startDateTime.minute);
              await notificationService.scheduleDailyNotification(
                eventId: taskId,
                title: title,
                body: body,
                timeOfDay: scheduledTimeOfDay,
              );

              // Schedule the chat notification after 20% of the duration
              TimeOfDay chatNotificationTimeOfDay = TimeOfDay(hour: chatNotificationTime.hour, minute: chatNotificationTime.minute);

              await notificationService.scheduleDailyChatNotification(
                eventId: taskId,
                title: title1,
                body: body1,
                timeOfDay: chatNotificationTimeOfDay,
              );
            } else {
              // Schedule the exact time notification (at the start time)
              await notificationService.scheduleNotification(
                eventId: taskId,
                title: title,
                body: body,
                scheduledTime: startDateTime,
              );

              // Schedule the chat notification after 20% of the duration
              await notificationService.scheduleChatNotification(
                eventId: taskId,
                title: title1,
                body: body1,
                scheduledTime: chatNotificationTime,
              );
            }
          }
          }
        }
        return data;
      } else {
        return {'text': "Error during API request"};
      }
    } catch (e) {
      print(e);
      return {'text': "Error during API request"};
    }
  }
  Future<Map<String, dynamic>> generateMessage(String msg) async {
    var body = jsonEncode({
      "task": msg
    });

    try {
      final response = await http.post(Uri.parse('$apiUrl/message'),
          headers: {"Content-Type": "application/json"},
          body: body);
      if (response.statusCode == 200) {
        var decodedResponse = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decodedResponse);
        return data;
      } else {
        return {'text': "Error during API request"};
      }
    } catch (e) {
      print(e);
      return {'text': "Error during API request"};
    }
  }
  Future<Map<String, dynamic>> generateConversation(String msg,String history,email) async {
    var body = jsonEncode({
      "msg": msg,
      "history":history,
      "email":email
    });

    try {
      final response = await http.post(Uri.parse('$apiUrl/conv'),
          headers: {"Content-Type": "application/json"},
          body: body);
      if (response.statusCode == 200) {
        var decodedResponse = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decodedResponse);
        return data;
      } else {
        return {'text': "Error during API request"};
      }
    } catch (e) {
      print(e);
      return {'text': "Error during API request"};
    }
  }
  Future<Map<String, dynamic>> retriveMessages(String email) async {
    var body = jsonEncode({
      "email":email
    });

    try {
      final response = await http.post(Uri.parse('$apiUrl/retriveMessages'),
          headers: {"Content-Type": "application/json"},
          body: body);
      if (response.statusCode == 200) {
        var decodedResponse = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decodedResponse);
        return data;
      } else if(response.statusCode == 404){
        return {'msg': "no messages",'data':[]};
      }else{
        return {'msg':"Error while retrive messages API request"};
      }
    } catch (e) {
      print(e);
      return {'text': "Error during API request"};
    }
  }
  Future<Map<String, dynamic>> deleteMessages(String email) async {
    var body = jsonEncode({
      "email": email,
    });

    try {
      final response = await http.post(Uri.parse('$apiUrl/deleteMessages'),
          headers: {"Content-Type": "application/json"},
          body: body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        return {'msg': "Error while deleting messages"};
      }
    } catch (e) {
      print(e);
      return {'text': "Error during API request"};
    }
  }
  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      print('User signed out successfully.');
    } catch (e) {
      print('Error signing out: $e');
    }
  }
}