import 'package:skillsconnect/TPO/Model/notify_model.dart';



abstract class NotificationEvent {}

class LoadNotifications extends NotificationEvent {}

class AddNotification extends NotificationEvent {
  final TPONotificationModel notification;
  AddNotification({required this.notification});
}

class MarkNotificationRead extends NotificationEvent {
  final int notificationId;
  MarkNotificationRead({required this.notificationId});
}
