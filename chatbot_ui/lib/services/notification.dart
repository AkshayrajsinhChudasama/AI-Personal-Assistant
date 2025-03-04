import 'dart:convert';
import 'dart:io';
import 'package:chatbot_ui/services/api.dart';
import 'package:crypto/crypto.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';
import '../main.dart';
import 'notificationController.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  static final user= FirebaseAuth.instance.currentUser;
  NotificationService._internal();

  Future<void> initNotifications() async {
    print("Initializing Awesome Notifications...");
    AwesomeNotifications().initialize(
      null,
      [_defaultNotificationChannel()],
      debug: true,
    );

    AwesomeNotifications().setListeners(
      onActionReceivedMethod: NotificationController.onActionReceivedMethod,
      onNotificationCreatedMethod:
          NotificationController.onNotificationCreatedMethod,
      onNotificationDisplayedMethod:
          NotificationController.onNotificationDisplayedMethod,
      onDismissActionReceivedMethod:
          NotificationController.onDismissActionReceivedMethod,
    );

    tz.initializeTimeZones();
    if (Platform.isAndroid) await requestNotificationPermission();
  }
  Future<void> requestNotificationPermission() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();

    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }
  NotificationChannel _defaultNotificationChannel() {
    return NotificationChannel(
      channelKey: 'scheduled_channel_id',
      channelName: 'Notifications',
      channelDescription: 'General notifications',
      defaultColor: Colors.teal,
      ledColor: Colors.white,
      importance: NotificationImportance.Max,
      channelShowBadge: true,
      playSound: true,
    );
  }

  Future<void> onActionReceived(ReceivedAction receivedAction) async {
    print("Notification action received: ${receivedAction.buttonKeyPressed}");
    final data = receivedAction.payload?['data'];
    if (data == null) return;

    final parsedData = jsonDecode(data);
    final eventId = parsedData['eventId'];

    switch (receivedAction.buttonKeyPressed) {
      case 'action_ok':
        print("User clicked OK, cancelling notification.");
        await cancelNotification(eventId, 0);
        break;
      case 'action_remind_later':
        print("User clicked Remind Me Later, rescheduling.");
        final fetchData = await ChatAPI().generateMessage(parsedData['body']);
        parsedData['body'] = fetchData['body'];
        parsedData['title'] = fetchData['title'];
        await _scheduleNotification(parsedData,
            DateTime.now().add(const Duration(minutes: 10)), true, false);
        break;
      case 'action_reply':
        final userReply = receivedAction.buttonKeyInput;
        print("User Reply: $userReply");

        String currentBody = parsedData['body'];
        String history = parsedData['history'];
        history += "\nUser:$userReply";
        final fetchData =
            await ChatAPI().generateConversation(userReply,history,user?.email);
        history += "\nBot:${fetchData['res']}";
        String updatedBody = "";

        String boldYou = "<b>You</b>";
        String boldBot = "<b>Bot</b>";

        updatedBody += "$boldYou<br>";
        updatedBody += "$userReply<br>";
        updatedBody += "$boldBot<br>";
        updatedBody += "${fetchData['res']}";
        int notificationId = _generateNotificationId(eventId, 1);
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
              id: notificationId,
              channelKey: 'scheduled_channel_id',
              title: parsedData['title'] ?? "Chatbot Response",
              body: updatedBody,
              payload: {
                'data': jsonEncode({
                  'eventId': parsedData['eventId'],
                  'title': parsedData['title'],
                  'body': updatedBody,
                  'history':history
                }),
              },
              notificationLayout: NotificationLayout.BigText),
          actionButtons:
              _chatNotificationActions(), // Make sure the reply button is added here
        );
        homeScreenKey.currentState?.loadMessages();
        print("Notification body updated with reply.");
        break;
      default:
        print("Notification tapped without a registered button.");
    }
  }


  int _generateNotificationId(String input, int type) {
    int baseId = sha256
            .convert(utf8.encode(input))
            .bytes
            .sublist(0, 4)
            .fold(0, (a, b) => (a << 8) | b) &
        0xFFFFFFFF;

    baseId = baseId % 100000000;
    return baseId * 10 + (type % 10);
  }

  Future<void> showInstantNotification() async {
    print("Showing instant notification");
    final data = {
      'eventId': 'instant',
      'title': 'Instant Notification',
      'body': 'This is an instant notification with options!'
    };
    await _scheduleNotification(data, DateTime.now(), false, false);
  }

  Future<void> scheduleNotification({
    required String eventId,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final data = {'eventId': eventId, 'title': title, 'body': body};
    await _scheduleNotification(data, scheduledTime, false, false);
  }

  Future<void> scheduleDailyNotification({
    required String eventId,
    required String title,
    required String body,
    required TimeOfDay timeOfDay,
  }) async {
    final now = DateTime.now();
    var scheduledTime = DateTime(
        now.year, now.month, now.day, timeOfDay.hour, timeOfDay.minute);
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    final data = {'eventId': eventId, 'title': title, 'body': body};
    await _scheduleNotification(data, scheduledTime, true, false);
  }

  Future<void> scheduleChatNotification({
    required String eventId,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final data = {'eventId': eventId, 'title': title, 'body': body,'history':'Context : $title & $body'};

    // scheduledTime = DateTime.now().add(const Duration(seconds: 5));

    await _scheduleNotification(data, scheduledTime, false, true);
  }

  Future<void> scheduleDailyChatNotification({
    required String eventId,
    required String title,
    required String body,
    required TimeOfDay timeOfDay,
  }) async {
    final now = DateTime.now();
    var scheduledTime = DateTime(
        now.year, now.month, now.day, timeOfDay.hour, timeOfDay.minute);
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    final data = {'eventId': eventId, 'title': title, 'body': body,'history':'Context : $title & $body'};
    await _scheduleNotification(data, scheduledTime, true, true);
  }

  Future<void> _scheduleNotification(Map<String, dynamic> data,
      DateTime scheduledTime, bool repeats, bool isChat) async {
    final id = _generateNotificationId(data['eventId'], isChat ? 1 : 0);
    final payload = jsonEncode(data);

    print(
        "Scheduling notification for eventId: ${data['eventId']} at $scheduledTime");

    final actionButtons =
        isChat ? _chatNotificationActions() : _notificationActions();

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: id,
          channelKey: 'scheduled_channel_id',
          title: data['title'],
          body: data['body'],
          payload: {'data': payload},
          notificationLayout: NotificationLayout.BigText),
      schedule: NotificationCalendar(
        hour: scheduledTime.hour,
        minute: scheduledTime.minute,
        day: scheduledTime.day,
        repeats: repeats,
        preciseAlarm: true,
      ),
      actionButtons: actionButtons,
    );
  }

  List<NotificationActionButton> _notificationActions() {
    return [
      NotificationActionButton(
        key: 'action_ok',
        label: 'OK',
        autoDismissible: true,
        actionType: ActionType.SilentAction,
      ),
      NotificationActionButton(
        key: 'action_remind_later',
        label: 'Remind Me Later',
        autoDismissible: true,
        actionType: ActionType.SilentAction,
      ),
    ];
  }

  List<NotificationActionButton> _chatNotificationActions() {
    return [
      NotificationActionButton(
        key: 'action_reply',
        label: 'Reply',
        requireInputText: true,
        autoDismissible: false,
        actionType: ActionType.SilentAction,
      ),
    ];
  }

  Future<void> cancelNotification(String eventId, int type) async {
    final id = _generateNotificationId(eventId, type);
    print("Cancelling notification with ID: $id");
    await AwesomeNotifications().cancel(id);
  }

  Future<void> cancelAllTypeNotification(String eventId) async {
    final reminderId = _generateNotificationId(eventId, 0); // Reminder type
    final chatId = _generateNotificationId(eventId, 1); // Chat type

    print("Cancelling notifications with IDs: $reminderId and $chatId");
    await AwesomeNotifications().cancel(reminderId);
    await AwesomeNotifications().cancel(chatId);
  }

  Future<void> cancelAllNotifications() async {
    print("Cancelling all notifications");
    await AwesomeNotifications().cancelAll();
  }
}
