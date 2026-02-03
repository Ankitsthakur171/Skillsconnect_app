import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../Model/Notification_Model.dart';
import '../Utilities/Get_All_Notifications.dart';
import '../blocpage/NotificationBloc/notification_bloc.dart';
import '../blocpage/NotificationBloc/notification_event.dart';
import '../blocpage/bloc_logic.dart';
import '../blocpage/bloc_event.dart';

class NotificationsScreensd extends StatefulWidget {
  const NotificationsScreensd({super.key});

  @override
  State<NotificationsScreensd> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreensd> {
  List<AppNotification> notifications = [];
  bool _loading = true;
  String? _error;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    print('📄 [NotificationsPage] initState() called');
    _loadNotifications();
    // Sync with BLoC for real-time updates
    print('📄 [NotificationsPage] Adding LoadNotifications event to BLoC');
    context.read<NotificationBloc>().add(LoadNotifications());
  }

  int _unreadCount() => notifications.where((n) => n.readStatus == "No").length;

  Future<void> _loadNotifications() async {
    print('📄 [NotificationsPage] _loadNotifications() starting...');
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await NotificationsApi.getNotifications();
      print('✅ [NotificationsPage] Loaded ${list.length} notifications');
      setState(() => notifications = list);
    } catch (e) {
      print('❌ [NotificationsPage] Error loading notifications: $e');
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        print('📄 [NotificationsPage] Loading finished');
      }
    }
  }

  Future<void> _markAsRead(AppNotification item) async {
    print('📄 [NotificationsPage] _markAsRead() called for notification: ${item.id} (${item.title})');
    if (item.readStatus == "No") {
      try {
        await NotificationsApi.markAsRead(item.id);
        print('✅ [NotificationsPage] Marked notification ${item.id} as read in API');
        setState(() {
          final idx = notifications.indexWhere((n) => n.id == item.id);
          if (idx != -1) {
            notifications[idx] = notifications[idx].copyWith(readStatus: "Yes");
            print('✅ [NotificationsPage] Updated local state for notification ${item.id}');
          }
        });
        // Update BLoC - get context before async gap
        final bloc = context.read<NotificationBloc>();
        print('📄 [NotificationsPage] Adding MarkNotificationRead event to BLoC for ${item.id}');
        bloc.add(MarkNotificationRead(notificationId: item.id));
      } catch (e) {
        print('❌ [NotificationsPage] Error marking notification as read: $e');
      }
    }
  }

  Future<void> _markAllAsRead() async {
    print('📄 [NotificationsPage] _markAllAsRead() called');
    final unread = notifications.where((n) => n.readStatus == "No").toList();
    print('📄 [NotificationsPage] Found ${unread.length} unread notifications to mark as read');
    // Get BLoC reference before async gap
    final bloc = context.read<NotificationBloc>();
    for (final item in unread) {
      try {
        await NotificationsApi.markAsRead(item.id);
        print('✅ [NotificationsPage] Marked ${item.id} as read');
        // Update BLoC for each notification
        bloc.add(MarkNotificationRead(notificationId: item.id));
      } catch (e) {
        print('❌ [NotificationsPage] Error marking ${item.id} as read: $e');
      }
    }
    setState(() {
      notifications =
          notifications.map((n) => n.copyWith(readStatus: "Yes")).toList();
    });
    print('✅ [NotificationsPage] All notifications marked as read');
  }

  String stripHtml(String html) {
    return html
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&nbsp', ' ')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .trim();
  }

  String extractLink(String html) {
    final match = RegExp(r'href="([^"]+)"').firstMatch(html);
    return match != null ? match.group(1)! : "";
  }

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'now';
    if (d.inHours < 1) return '${d.inMinutes}m ago';
    if (d.inDays < 1) return '${d.inHours}h ago';
    return DateFormat('d MMM').format(t);
  }

  void _handleLinkNavigation(String link) {
    print('🔗 [NotificationsPage] Handling navigation for link: $link');
    
    // Close the notifications page
    Navigator.of(context).pop<int>(_unreadCount());
    
    // Navigate to appropriate tab based on link content
    if (link.contains('interviewControlRoom')) {
      print('➡️ Navigating to Interview tab');
      context.read<NavigationBloc>().add(GoToInterviewScreen2());
    } else if (link.contains('jobs')) {
      print('➡️ Navigating to Jobs tab');
      context.read<NavigationBloc>().add(GotoJobScreen2());
    }
  }

  Future<bool> _onWillPop() async {
    Navigator.of(context).pop<int>(_unreadCount());
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _tab == 0
        ? notifications
        : notifications.where((n) => n.readStatus == "No").toList();

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: BackButton(
            color: Colors.black,
            onPressed: () {
              Navigator.of(context).pop<int>(_unreadCount());
            },
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'Notifications',
            style: TextStyle(
                fontSize: 22.sp,
                color: Colors.black,
                fontWeight: FontWeight.w500),
          ),
          actions: [
            if (_unreadCount() > 0)
              TextButton(
                onPressed: _markAllAsRead,
                child: Text(
                  "Mark all as read",
                  style: TextStyle(fontSize: 12.sp, color: Colors.black),
                ),
              ),
          ],
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator()
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Text(
                        _error!,
                        style: TextStyle(fontSize: 13.sp, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      SizedBox(height: 8.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _filterChip("All", 0),
                          SizedBox(width: 8.w),
                          _filterChip("Unread (${_unreadCount()})", 1),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Expanded(
                        child: notifications.isEmpty
                            ? Center(
                                child: Text(
                                  'No notifications',
                                  style: TextStyle(fontSize: 13.sp),
                                ),
                              )
                            : _tab == 1 && filtered.isEmpty
                                ? Center(
                                    child: Text(
                                      'No notification available',
                                      style: TextStyle(fontSize: 13.sp),
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: _loadNotifications,
                                    child: ListView.builder(
                                      padding: EdgeInsets.only(
                                        left: 12.w,
                                        right: 12.w,
                                        top: 12.w,
                                        bottom: 40.h,
                                      ),
                                      itemCount: filtered.length,
                                      itemBuilder: (_, i) {
                                        final item = filtered[i];
                                        final cleanText = stripHtml(item.body);
                                        final link = extractLink(item.body);
                                        return GestureDetector(
                                          onTap: () => _markAsRead(item),
                                          child: _notificationCard(
                                              item, cleanText, link),
                                        );
                                      },
                                    ),
                                  ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _filterChip(String label, int index) {
    final bool selected = _tab == index;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          color: selected ? Colors.white : const Color(0xFF003840),
          fontWeight: FontWeight.w600,
        ),
      ),
      selected: selected,
      selectedColor: const Color(0xFF005E6A),
      checkmarkColor: Colors.white,
      backgroundColor: Colors.teal.shade50,
      onSelected: (_) => setState(() => _tab = index),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
    );
  }

  Widget _notificationCard(
      AppNotification item, String cleanText, String link) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: const Color(0xFFEBF6F7),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_none,
                size: 22.sp, color: const Color(0xFF005E6A)),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.sp,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    if (item.readStatus == "No")
                      Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle, 
                          color: Colors.red.shade400,
                        ),
                      )
                  ],
                ),
                SizedBox(height: 6.h),
                GestureDetector(
                  onTap: link.isEmpty
                      ? null
                      : () {
                          print("Tapped link: $link");
                          _handleLinkNavigation(link);
                        },
                  child: Text(
                    cleanText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.sp,
                      height: 1.3,
                      color: Colors.black87,
                      decoration: link.isEmpty
                          ? TextDecoration.none
                          : TextDecoration.underline,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  _ago(item.createdAt),
                  style:
                      TextStyle(color: Colors.grey.shade600, fontSize: 11.sp),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
