import '../../Model/Notification_Model.dart';

abstract class NotificationEvent {}

class LoadNotifications extends NotificationEvent {}

class AddNotification extends NotificationEvent {
  final AppNotification notification;
  AddNotification({required this.notification});
}

class MarkNotificationRead extends NotificationEvent {
  final int notificationId;
  MarkNotificationRead({required this.notificationId});
}

class ResetNotifications extends NotificationEvent {}