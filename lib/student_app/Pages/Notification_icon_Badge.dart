import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../Model/Notification_Model.dart';
import '../Utilities/Get_All_Notifications.dart';
import '../blocpage/NotificationBloc/notification_bloc.dart';
import '../blocpage/NotificationBloc/notification_state.dart';
import 'Notifications_page.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  int unreadCount = 0;

  bool _isUnread(AppNotification n) {
    final v = (n.readStatus).toString().trim().toLowerCase();
    return v == 'no' || v == 'unread' || v == '0';
  }

  Future<void> _loadUnreadCount() async {
    try {
      print('🔔 [NotificationBell] _loadUnreadCount() starting...');
      final all = await NotificationsApi.getNotifications(unreadOnly: false);
      final unread = all.where(_isUnread).length;
      print('🔔 [NotificationBell] Total notifications: ${all.length}, Unread: $unread');
      if (!mounted) {
        print('⚠️ [NotificationBell] Widget not mounted, skipping setState');
        return;
      }
      setState(() => unreadCount = unread);
      print('✅ [NotificationBell] unreadCount updated to: $unreadCount');
    } catch (e) {
      print('❌ [NotificationBell] Error loading unread count: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    print('🔔 [NotificationBell] initState() called');
    _loadUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    print('🔔 [NotificationBell] build() called, current unreadCount: $unreadCount');
    return BlocListener<NotificationBloc, NotificationState>(
      listener: (context, state) {
        print('📢 [NotificationBell] BLocListener - NotificationState changed: ${state.notifications.length} notifications, isLoading: ${state.isLoading}');
        _loadUnreadCount();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
        IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: () async {
            final result = await Navigator.of(context).push<int>(
              MaterialPageRoute(builder: (_) => const NotificationsScreensd()),
            );
            if (!mounted) return;
            if (result != null) {
              setState(() => unreadCount = result);
            } else {
              await _loadUnreadCount();
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
      ),
    );
  }
}
