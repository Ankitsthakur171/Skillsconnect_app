// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:skillsconnect/TPO/TPO_Notifications/notify_bloc.dart';
// import 'package:skillsconnect/TPO/TPO_Notifications/notify_event.dart';
// import 'package:skillsconnect/TPO/TPO_Notifications/notify_state.dart';
//
//
// class TpoNotification extends StatefulWidget {
//   const TpoNotification({super.key});
//
//   @override
//   State<TpoNotification> createState() => _NotificationsScreenState();
// }
//
// class _NotificationsScreenState extends State<TpoNotification> {
//   String? _token;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadToken();
//   }
//
//   Future<void> _loadToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('auth_token');
//
//     if (token != null) {
//       setState(() {
//         _token = token;
//       });
//     } else {
//       // Token not found, handle it
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Auth token not found')),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_token == null) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     return BlocProvider(
//       create: (_) => NotificationBloc()..add(LoadNotifications()),
//       child: Scaffold(
//         backgroundColor: const Color(0xFFF7F8F9),
//         appBar: PreferredSize(
//           preferredSize: const Size.fromHeight(60),
//           child: SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16.0),
//               child: Stack(
//                 alignment: Alignment.center,
//                 children: [
//                   Align(
//                     alignment: Alignment.centerLeft,
//                     child: Container(
//                       width: 36,
//                       height: 36,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         border: Border.all(color: Colors.grey.shade300),
//                       ),
//                       child: IconButton(
//                         icon: const Icon(Icons.arrow_back_ios_new, size: 16),
//                         onPressed: () {
//                           Navigator.pop(context);
//                         },
//                       ),
//                     ),
//                   ),
//                   const Center(
//                     child: Text(
//                       "Notifications",
//                       style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                           color: Color(0xff003840)
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//         body: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const SizedBox(height: 12),
//               Center(
//                 child: Container(
//                   height: 36,
//                   decoration: BoxDecoration(
//                     color: const Color(0xFFEFF1F3),
//                     borderRadius: BorderRadius.circular(24),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFF006766),
//                           borderRadius: BorderRadius.circular(24),
//                         ),
//                         child: const Text(
//                           "All",
//                           style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
//                         ),
//                       ),
//                       const SizedBox(width: 4),
//                       const Padding(
//                         padding: EdgeInsets.symmetric(horizontal: 16),
//                         child: Text(
//                           "Unread (7)",
//                           style: TextStyle(color: Colors.black87),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               const Text("Today", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Color(0xff003840))),
//               const SizedBox(height: 10),
//               Expanded(
//                 child: BlocBuilder<NotificationBloc, NotificationState>(
//                   builder: (context, state) {
//                     if (state.isLoading) {
//                       return const Center(child: CircularProgressIndicator());
//                     }
//                     if (state.notifications.isEmpty) {
//                       return const Center(child: Text("No notifications found."));
//                     }
//                     return ListView.builder(
//                       itemCount: state.notifications.length,
//                       itemBuilder: (context, index) {
//                         final notif = state.notifications[index];
//                         final isRead = notif.readStatus == 'Yes';
//
//                         return GestureDetector(
//                           onTap: () {
//                             if (!isRead) {
//                               context.read<NotificationBloc>().add(MarkNotificationRead(notificationId: notif.id));
//                             }
//                           },
//                           child: Column(
//                             children: [
//                               Container(
//                                 padding: const EdgeInsets.all(12),
//                                 decoration: BoxDecoration(
//                                   color: isRead ? Colors.white : const Color(0xFFEFFBFF),
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Row(
//                                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                       children: [
//                                         Expanded(
//                                           child: Text(
//                                             notif.title,
//                                             style: const TextStyle(
//                                               fontWeight: FontWeight.bold,
//                                               fontSize: 14,
//                                               fontFamily: 'Inter',
//                                             ),
//                                           ),
//                                         ),
//                                         Text(
//                                           notif.timeAgo,
//                                           style: const TextStyle(
//                                             color: Colors.grey,
//                                             fontSize: 12,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                     const SizedBox(height: 4),
//                                     Text(
//                                       notif.description,
//                                       style: TextStyle(
//                                         fontSize: 13,
//                                         color: Color(0xFF005E6A),
//                                         fontWeight: FontWeight.w500,
//                                       ),
//                                     ),
//
//                                   ],
//                                 ),
//                               ),
//                               const Divider(
//                                 color: Color(0xFFCED4DA),
//                                 thickness: 1,
//                                 height: 20,
//                               ),
//                             ],
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
// }













import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:skeletonizer/skeletonizer.dart';

import '../../Constant/constants.dart';
import '../TPO_Notifications/notify_bloc.dart';
import '../TPO_Notifications/notify_event.dart' show LoadNotifications, MarkNotificationRead;
import '../TPO_Notifications/notify_state.dart';


class TpoNotification extends StatefulWidget {
  const TpoNotification({super.key});

  @override
  State<TpoNotification> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<TpoNotification> {
  String? _token;

  // ---- Unread filter state ----
  bool _showingUnread = false;
  bool _loadingUnread = false;
  int _unreadCount = 0;
  List<_LocalNotif> _unread = [];

  // animation duration (smooth)
  static const Duration _anim = Duration(milliseconds: 220);

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null) {
      setState(() {
        _token = token;
      });
      await _syncUnreadCount(); // initialize unread count
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Auth token not found')),
          );
        }
      });
    }
  }

  Future<void> _syncUnreadCount() async {
    if (_token == null) return;
    try {
      final uri = Uri.parse(
          '${BASE_URL}common/get-all-notifications?read=No');
      final res = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
        },
      );
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['success'] == true && json['data'] is List) {
          final list = (json['data'] as List);
          setState(() {
            _unreadCount = list.length; // sirf unread ka count
          });
        }
      }
    } catch (_) {/* ignore */}
  }

  Future<void> _fetchUnreadList() async {
    if (_token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Auth token not found')),
      );
      return;
    }

    try {
      final uri = Uri.parse(
          '${BASE_URL}common/get-all-notifications?read=No');
      final res = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['success'] == true && json['data'] is List) {
          final list = (json['data'] as List).cast<Map<String, dynamic>>();
          final parsed = list.map((m) {
            return _LocalNotif(
              id: _asInt(m['id']),
              title: (m['title'] ?? '').toString(),
              description: (m['short_description'] ?? '').toString(),
              readStatus: (m['read_status'] ?? '').toString(), // "No"/"Yes"
              timeAgo: _timeAgo((m['created_on'] ?? '').toString()),
            );
          }).toList();

          setState(() {
            _unread = parsed;              // sirf unread items
            _unreadCount = parsed.length;  // sirf unread ka count
          });
        } else {
          setState(() {
            _unread = [];
            _unreadCount = 0;
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unread fetch failed (${res.statusCode})')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load unread notifications')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingUnread = false;
        });
      }
    }
  }

  void _showAll() {
    setState(() {
      _showingUnread = false; // All tab (instant highlight)
    });
    _syncUnreadCount(); // count fresh rakhna
  }

  void _showUnread() {
    // 👉 instant toggle + loader, then fetch (smooth UX)
    setState(() {
      _showingUnread = true;
      _loadingUnread = true;
    });
    _fetchUnreadList();
  }

  void _removeFromUnread(int id) {
    _unread.removeWhere((e) => e.id == id);
    setState(() {
      _unread = List<_LocalNotif>.from(_unread);
      if (_unreadCount > 0) _unreadCount -= 1;
      if (_unreadCount < 0) _unreadCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_token == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F8F9),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: _NotificationSkeletonList(),
        ),
      );
    }

    return BlocProvider(
      create: (_) => NotificationBloc()..add(LoadNotifications()),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8F9),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  const Center(
                    child: Text(
                      "Notifications",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff003840)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // ---- Filter pill row (same design, now smooth toggle) ----
              Center(
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF1F3),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ALL tab
                      GestureDetector(
                        onTap: _showAll,
                        child: AnimatedSwitcher(
                          duration: _anim,
                          child: _showingUnread
                              ? _inactivePill("All")
                              : _activePill("All"),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // UNREAD tab
                      GestureDetector(
                        onTap: _showUnread,
                        child: AnimatedSwitcher(
                          duration: _anim,
                          child: _showingUnread
                              ? _activePill("Unread (${_unreadCount})")
                              : _inactivePill("Unread (${_unreadCount})"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Text("Today",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff003840))),
              const SizedBox(height: 10),

              // ---- List area ----
              Expanded(
                child: AnimatedSwitcher(
                  duration: _anim,
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: _showingUnread
                      ? KeyedSubtree(
                    key: const ValueKey('unread'),
                    child: _buildUnreadList(context),
                  )
                      : KeyedSubtree(
                    key: const ValueKey('all'),
                    child: BlocBuilder<NotificationBloc, NotificationState>(
                      builder: (context, state) {
                        if (state.isLoading) {
                          return  _NotificationSkeletonList();
                        }
                        if (state.notifications.isEmpty) {
                          return const Center(child: Text("No notifications found."));
                        }
                        return ListView.builder(
                          itemCount: state.notifications.length,
                          itemBuilder: (context, index) {
                            final notif = state.notifications[index];
                            final isRead = notif.readStatus == 'Yes';

                            return GestureDetector(
                              onTap: () {
                                if (!isRead) {
                                  context.read<NotificationBloc>().add(
                                      MarkNotificationRead(notificationId: notif.id));
                                }
                              },
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isRead
                                          ? Colors.white
                                          : const Color(0xFFEFFBFF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                notif.title,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  fontFamily: 'Inter',
                                                ),
                                              ),
                                            ),
                                            Text(
                                              notif.timeAgo,
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _plainText(notif.description),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF005E6A),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(
                                    color: Color(0xFFCED4DA),
                                    thickness: 1,
                                    height: 20,
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Unread List builder (same card design) ----
  Widget _buildUnreadList(BuildContext context) {
    if (_loadingUnread) {
      return  _NotificationSkeletonList();
    }
    if (_unread.isEmpty) {
      return const Center(child: Text("No notifications found."));
    }
    return ListView.builder(
      itemCount: _unread.length,
      itemBuilder: (context, index) {
        final notif = _unread[index];
        final isRead = notif.readStatus == 'Yes';

        return GestureDetector(
          onTap: () {
            if (!isRead) {
              context.read<NotificationBloc>().add(
                  MarkNotificationRead(notificationId: notif.id));
              _removeFromUnread(notif.id); // turant UI se remove
            }
          },
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isRead ? Colors.white : const Color(0xFFEFFBFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                        Text(
                          notif.timeAgo,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _plainText(notif.description),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF005E6A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(
                color: Color(0xFFCED4DA),
                thickness: 1,
                height: 20,
              ),
            ],
          ),
        );
      },
    );
  }

  // ---- Pill helpers (design preserved, now animated) ----
  Widget _activePill(String text) {
    return AnimatedContainer(
      duration: _anim,
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF006766),
        borderRadius: BorderRadius.circular(24),
      ),
      child: AnimatedDefaultTextStyle(
        duration: _anim,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        child: Text(text),
      ),
    );
  }

  Widget _inactivePill(String text) {
    return constPadding(
      child: AnimatedContainer(
        duration: _anim,
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        child: AnimatedDefaultTextStyle(
          duration: _anim,
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
          child: Text(text),
        ),
      ),
    );
  }

  // same padding as your original "Unread" text
  Widget constPadding({required Widget child}) =>
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: child);

  // ---- Helpers ----
  int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  String _timeAgo(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }

  String _plainText(String html) {
    try {
      final doc = html_parser.parse(html);
      final text = doc.body?.text ?? '';
      return text.replaceAll('\u00A0', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    } catch (_) {
      return html
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll('&nbsp;', ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }
  }
}

class _NotificationSkeletonList extends StatelessWidget {
  const _NotificationSkeletonList({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView.separated(
        padding: const EdgeInsets.only(top: 0, bottom: 8),
        itemCount: 6, // 6 fake notifications
        separatorBuilder: (_, __) => const Divider(
          color: Color(0xFFCED4DA),
          thickness: 1,
          height: 20,
        ),
        itemBuilder: (context, index) => const _NotificationSkeletonTile(),
      ),
    );
  }
}


class _NotificationSkeletonTile extends StatelessWidget {
  const _NotificationSkeletonTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, // unread ka light blue yahan bhi feel aa jayega shimmer se
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Notification title placeholder',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    fontFamily: 'Inter',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8),
              Text(
                '2h ago',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            'This is a short notification description placeholder text.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF005E6A),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}


// Lightweight local model only for Unread API mapping
class _LocalNotif {
  final int id;
  final String title;
  final String description;
  final String readStatus; // "No"/"Yes"
  final String timeAgo;

  _LocalNotif({
    required this.id,
    required this.title,
    required this.description,
    required this.readStatus,
    required this.timeAgo,
  });

  _LocalNotif copyWith({
    int? id,
    String? title,
    String? description,
    String? readStatus,
    String? timeAgo,
  }) {
    return _LocalNotif(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      readStatus: readStatus ?? this.readStatus,
      timeAgo: timeAgo ?? this.timeAgo,
    );
  }
}
