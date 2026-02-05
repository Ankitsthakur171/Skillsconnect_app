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
  int _lastUnreadCount = 0;
  DateTime? _lastPolledAt;

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
      _lastUnreadCount = 0;
    } else {
      _lastUnreadCount = bloc.state.notifications.where(_isUnread).length;
    }

    // Poll only every 30 seconds but only if there's a potential change
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final now = DateTime.now();
      // Only poll if it's been at least 30 seconds since last poll
      if (_lastPolledAt == null || now.difference(_lastPolledAt!).inSeconds >= 30) {
        _lastPolledAt = now;
        print('🔔 [NotificationBell] Polling for new notifications...');
        context.read<NotificationBloc>().add(LoadNotifications());
      }
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
        if (current.isLoading) {
          return false;
        }
        // Only rebuild if the unread count actually changed
        final prevUnreadCount = previous.notifications.where(_isUnread).length;
        final currUnreadCount = current.notifications.where(_isUnread).length;
        
        final shouldRebuild = prevUnreadCount != currUnreadCount;
        
        if (shouldRebuild) {
          print('🔔 [NotificationBell] Unread count changed: $prevUnreadCount → $currUnreadCount (REBUILDING)');
        } else {
          print('🔔 [NotificationBell] Unread count unchanged: $currUnreadCount (SKIPPING REBUILD)');
        }
        
        return shouldRebuild;
      },
      builder: (context, state) {
        final unreadCount = state.notifications.where(_isUnread).length;
        
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

                // Refresh after returning from notifications page
                if (result != null) {
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
