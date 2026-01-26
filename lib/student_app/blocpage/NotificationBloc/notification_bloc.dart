import 'package:flutter_bloc/flutter_bloc.dart';
import '../../Model/Notification_Model.dart';
import '../../Utilities/Get_All_Notifications.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc() : super(NotificationState(isLoading: true)) {
    on<LoadNotifications>(_onLoadNotifications);
    on<AddNotification>(_onAddNotification);
    on<MarkNotificationRead>(_onMarkNotificationRead);
  }

  Future<void> _onLoadNotifications(LoadNotifications event, Emitter<NotificationState> emit) async {
    emit(NotificationState(isLoading: true));

    try {
      final notifications = await NotificationsApi.getNotifications(unreadOnly: false);

      emit(NotificationState(
        notifications: List<AppNotification>.from(notifications),
        isLoading: false,
      ));
    } catch (e) {
      emit(NotificationState(notifications: [], isLoading: false));
    }
  }

  void _onAddNotification(AddNotification event, Emitter<NotificationState> emit) {
    final updatedList = [event.notification, ...state.notifications];
    emit(NotificationState(notifications: updatedList, isLoading: false));
  }

  Future<void> _onMarkNotificationRead(MarkNotificationRead event, Emitter<NotificationState> emit) async {
    try {
      await NotificationsApi.markAsRead(event.notificationId);

      final updatedList = state.notifications.map((n) {
        return n.id == event.notificationId ? n.copyWith(readStatus: 'Yes') : n;
      }).toList();

      emit(NotificationState(notifications: updatedList, isLoading: false));
    } catch (e) {
      // Handle error if needed
    }
  }
}