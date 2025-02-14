import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:chatbot_ui/services/notification.dart';

class NotificationController {

  /// Detect when a new notification or schedule is created
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {
    // Your code here
  }

  /// Detect every time a new notification is displayed
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
    // Your code here
  }

  /// Detect when the user dismisses a notification
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(ReceivedAction receivedAction) async {
    // Your code here

  }

  /// Detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    // Your code here
    print("Action received: ${receivedAction.buttonKeyPressed}");
    await NotificationService().onActionReceived(receivedAction);
  }
}