import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillsconnect/TPO/Screens/tpo_notification.dart';
import '../../utils/tpo_info_manager.dart';

class TpoCustomAppBar extends StatefulWidget  implements PreferredSizeWidget {
  final bool showNotification;
  final VoidCallback? onNotificationTap;
  final String? pageTitle;

  const TpoCustomAppBar({
    Key? key,
    this.showNotification = true,
    this.onNotificationTap,
    this.pageTitle,
  }) : super(key: key);
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<TpoCustomAppBar> createState() => _TpoCustomAppBarState();
}

class _TpoCustomAppBarState extends State<TpoCustomAppBar> {
  static const _notifCountKey = 'tpo_notif_count';
  static int? _cachedNotifCount;
  static final ValueNotifier<int> _badgeVN = ValueNotifier<int>(0);
  static StreamSubscription<RemoteMessage>? _globalNotifSub;

  int _notifCount = 0;
  VoidCallback? _vnListener;

  @override
  void initState() {
    super.initState();

    // Seed from cache or prefs (no flicker)
    if (_cachedNotifCount != null) {
      _notifCount = _cachedNotifCount!;
      _badgeVN.value = _cachedNotifCount!;
    } else {
      _loadNotifCountOnce();
    }

    // Listen for notifier updates
    _vnListener = () {
      if (mounted) setState(() => _notifCount = _badgeVN.value);
    };
    _badgeVN.addListener(_vnListener!);

    // Global FCM listener — increment count globally
    if (_globalNotifSub == null) {
      _globalNotifSub = FirebaseMessaging.onMessage.listen((RemoteMessage m) async {
        final next = ((_cachedNotifCount ?? 0) + 1).clamp(0, 9999);
        _cachedNotifCount = next;
        final sp = await SharedPreferences.getInstance();
        await sp.setInt(_notifCountKey, next);
        _badgeVN.value = next;
      });
    }
  }

  Future<void> _loadNotifCountOnce() async {
    final sp = await SharedPreferences.getInstance();
    final v = sp.getInt(_notifCountKey) ?? 0;
    _cachedNotifCount = v;
    _badgeVN.value = v;
  }

  Future<void> _saveAndBroadcast(int v) async {
    _cachedNotifCount = v.clamp(0, 9999);
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_notifCountKey, _cachedNotifCount!);
    _badgeVN.value = _cachedNotifCount!;
  }

  @override
  void dispose() {
    if (_vnListener != null) _badgeVN.removeListener(_vnListener!);
    super.dispose();
  }


  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final userMgr = UserInfoManager();

    return FutureBuilder<void>(
      future: userMgr.initFromPrefs(),
      builder: (context, _) {
        return AnimatedBuilder(
          animation: userMgr,
          builder: (context, __) {
            final img = userMgr.userImg ?? '';
            final college = userMgr.collegeName ?? 'College Name';

            return AppBar(
              backgroundColor: const Color(0xffebf6f7),
              elevation: 0,
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              title: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ClipOval(child: _buildUserImage(img)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _trimCollegeName(college),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xff25282B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                if (widget.showNotification)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: widget.onNotificationTap ??
                                  () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const TpoNotification(),
                                  ),
                                );
                                // clear count when opened
                                if ((_cachedNotifCount ?? 0) > 0) {
                                  _saveAndBroadcast(0);
                                }
                              },
                          child: CircleAvatar(
                            backgroundColor: Colors.green.shade50,
                            radius: 18,
                            child: Image.asset(
                              'assets/notification.png',
                              height: 44,
                              width: 44,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        if (_notifCount > 0)
                          Positioned(
                            top: -6,
                            right: -5,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Color(0xFFCAFEE3), width: 1),
                              ),
                              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                              child: Text(
                                _notifCount > 99 ? '99+' : '$_notifCount',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
  /// ✅ Handle SVG, PNG, JPG, JPEG for user image
  Widget _buildUserImage(String url) {
    // 🔹 Default SVG URL for empty images
    const defaultLogo =
        'https://skillsconnect.blob.core.windows.net/skillsconnect-stage/assets/frontend/images/v2/college-logo.svg';
    // Agar URL empty hai → default college logo lagao
    if (url.trim().isEmpty) {
      return SvgPicture.network(
        defaultLogo,
        width: 36,
        height: 36,
        fit: BoxFit.cover,
        placeholderBuilder: (context) =>
        const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (url.toLowerCase().endsWith(".svg")) {
      return SvgPicture.network(
        url,
        key: ValueKey(url),              // 👈 important
        width: 36,
        height: 36,
        fit: BoxFit.cover,
        placeholderBuilder: (context) =>
        const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    } else {
      return Image.network(
        url,
        key: ValueKey(url),
        width: 36,
        height: 36,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => SvgPicture.network(
          defaultLogo,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
        ),
      );
    }
  }



  // College Characters Ellipse ...
  String _trimCollegeName(String name) {
    if (name.length > 28) {
      return '${name.substring(0, 28)}...';
    }
    return name;
  }
}
