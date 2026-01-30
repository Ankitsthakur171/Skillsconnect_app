import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../Model/Notification_Model.dart';
import '../blocpage/NotificationBloc/notification_bloc.dart';
import '../blocpage/NotificationBloc/notification_event.dart';
import '../blocpage/NotificationBloc/notification_state.dart';
import 'Notifications_page.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  Timer? _pollTimer;
  int _lastUnreadCount = 0; // Track last unread count to avoid unnecessary rebuilds

  bool _isUnread(AppNotification n) {
    final v = (n.readStatus).toString().trim().toLowerCase();
    return v == 'no' || v == 'unread' || v == '0';
  }

  @override
  void initState() {
    super.initState();
    final bloc = context.read<NotificationBloc>();
    if (!bloc.state.isLoading && bloc.state.notifications.isEmpty) {
      print('🔔 [NotificationBell] initState() -> triggering initial LoadNotifications');
      bloc.add(LoadNotifications());
    } else {
      // Set initial unread count
      _lastUnreadCount = bloc.state.notifications.where(_isUnread).length;
    }

    // Lightweight polling to reflect new notifications without navigation.
    // Only reloads if there's a potential new notification
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      print('🔔 [NotificationBell] Polling for new notifications...');
      context.read<NotificationBloc>().add(LoadNotifications());
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      buildWhen: (previous, current) {
        // Only rebuild if unread count has changed from the last known count
        final currUnreadCount = current.notifications.where(_isUnread).length;
        
        if (_lastUnreadCount != currUnreadCount) {
          print('🔔 [NotificationBell] Unread count changed: $_lastUnreadCount → $currUnreadCount');
          return true;
        }
        
        return false;
      },
      builder: (context, state) {
        final unreadCount = state.notifications.where(_isUnread).length;
        _lastUnreadCount = unreadCount;
        
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () async {
                final result = await Navigator.of(context).push<int>(
                  MaterialPageRoute(builder: (_) => const NotificationsScreensd()),
                );
                if (!mounted) return;

                // If the page returned a fresh count, keep it in sync; otherwise refresh.
                if (result != null) {
                  // Push updated count into BLoC by reloading.
                  context.read<NotificationBloc>().add(LoadNotifications());
                }
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(minWidth: 18),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
