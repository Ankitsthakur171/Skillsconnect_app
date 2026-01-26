

import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../Constant/constants.dart';
import '../../model/notification_model.dart';
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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        emit(NotificationState(notifications: [], isLoading: false));
        return;
      }

      final response = await http.get(
        Uri.parse('${BASE_URL}common/get-all-notifications'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List data = body['data'] ?? [];

        final notifications = data.map((json) => NotificationModel.fromJson(json)).toList();

        emit(NotificationState(
          notifications: List<NotificationModel>.from(notifications),
          isLoading: false,
        ));
      } else {
        emit(NotificationState(notifications: [], isLoading: false));
      }
    } catch (e) {
      emit(NotificationState(notifications: [], isLoading: false));
    }
  }

  void _onAddNotification(AddNotification event, Emitter<NotificationState> emit) {
    final updatedList = [event.notification, ...state.notifications];
    emit(NotificationState(notifications: updatedList, isLoading: false));
  }

  Future<void> _onMarkNotificationRead(MarkNotificationRead event, Emitter<NotificationState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse('${BASE_URL}common/update-notification-read-status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'notification_id': event.notificationId,
          'read_status': 'Yes',
        }),
      );

      if (response.statusCode == 200) {
        final updatedList = state.notifications.map((n) {
          return n.id == event.notificationId ? n.copyWith(readStatus: 'Yes') : n;
        }).toList();

        emit(NotificationState(notifications: updatedList, isLoading: false));
      }
    } catch (e) {
      // Handle error if needed
    }
  }
}
