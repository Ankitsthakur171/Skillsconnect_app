
import '../Model/notify_model.dart';

class NotificationState {
  final List<TPONotificationModel> notifications;
  final bool isLoading;

  NotificationState({
    this.notifications = const [],
    this.isLoading = false,
  });
}
