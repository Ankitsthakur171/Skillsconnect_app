import '../../model/notification_model.dart';

class NotificationState {
  final List<NotificationModel> notifications;
  final bool isLoading;

  NotificationState({
    this.notifications = const [],
    this.isLoading = false,
  });
}


class NotificationError extends NotificationState {
  final int? code;       // e.g. 404, 500
  final String message;  // error detail
  NotificationError({this.code, required this.message});
}