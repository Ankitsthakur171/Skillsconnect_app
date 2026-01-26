
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../utils/company_info_manager.dart';
import 'notification_screen.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final bool showBack;
  const CustomAppBar({super.key, this.showBack = false});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  static const _notifCountKey = 'notif_count';

  // ---- NEW: shared cache + broadcaster ----
  static int? _cachedNotifCount;
  static final ValueNotifier<int> _badgeVN = ValueNotifier<int>(0);
  static StreamSubscription<RemoteMessage>? _globalNotifSub;

  int _notifCount = 0;
  VoidCallback? _vnListener;

  @override
  void initState() {
    super.initState();
    CompanyInfoManager().load(); // 🔥 AppBar ko reload kar dega

    // 1) seed from cache or prefs (no flicker)
    if (_cachedNotifCount != null) {
      _notifCount = _cachedNotifCount!;
      _badgeVN.value = _cachedNotifCount!;
    } else {
      _loadNotifCountOnce();
    }

    // 2) listen to broadcaster so all instances repaint instantly
    _vnListener = () {
      if (mounted) setState(() => _notifCount = _badgeVN.value);
    };
    _badgeVN.addListener(_vnListener!);

    // 3) single global FCM listener → update cache + notifier
    if (_globalNotifSub == null) {
      _globalNotifSub = FirebaseMessaging.onMessage.listen((RemoteMessage m) async {
        final next = ((_cachedNotifCount ?? 0) + 1).clamp(0, 9999);
        _cachedNotifCount = next;
        final sp = await SharedPreferences.getInstance();
        await sp.setInt(_notifCountKey, next);
        _badgeVN.value = next; // 🔔 broadcast to all app bars
      });
    }
  }

  Future<void> _loadNotifCountOnce() async {
    final sp = await SharedPreferences.getInstance();
    final v = sp.getInt(_notifCountKey) ?? 0;
    _cachedNotifCount = v;
    _badgeVN.value = v; // notify all listeners (including this one)
  }

  Future<void> _saveAndBroadcast(int v) async {
    _cachedNotifCount = v.clamp(0, 9999);
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_notifCountKey, _cachedNotifCount!);
    _badgeVN.value = _cachedNotifCount!;
  }

  @override
  void dispose() {
    if (_vnListener != null) {
      _badgeVN.removeListener(_vnListener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final manager = CompanyInfoManager();

    return AnimatedBuilder(
      animation: manager,
      builder: (context, _) {
        final logoUrl = manager.companyLogo;
        return AppBar(
          backgroundColor: const Color(0xffebf6f7),
          elevation: 0,
          automaticallyImplyLeading: widget.showBack,
          leading: widget.showBack ? const BackButton(color: Color(0xff003840)) : null,
          title: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: _buildCompanyLogo(logoUrl),
            title: Text(
              _trimCompanyName(manager.companyName),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xff25282B)),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => NotificationsScreen()),
                      );
                      // Clear ONLY when the bell is opened
                      if ((_cachedNotifCount ?? 0) > 0) {
                        _saveAndBroadcast(0);
                      }
                    },
                    child: const CircleAvatar(
                      backgroundColor: Color(0xffEBF6F7),
                      radius: 20,
                      child: ClipOval(
                        child: Image(
                          image: AssetImage('assets/notification.png'),
                          height: 40, width: 40, fit: BoxFit.cover,
                        ),
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
                            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, height: 1.0,
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
  }

  Widget _buildCompanyLogo(String logoUrl) {
    const defaultLogo =
        'https://skillsconnect.blob.core.windows.net/skillsconnect-stage/uploads/company_logo/company_default_logo.png';

    if (logoUrl.isEmpty) {
      return const CircleAvatar(
        backgroundImage: NetworkImage(defaultLogo),
        backgroundColor: Colors.transparent,
      );
    }
    if (logoUrl.toLowerCase().endsWith(".svg")) {
      return CircleAvatar(
        backgroundColor: Colors.transparent,
        child: SvgPicture.network(
          logoUrl, height: 40, width: 40,
          placeholderBuilder: (context) =>
          const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    return CircleAvatar(
      key: ValueKey(logoUrl),
      backgroundImage: NetworkImage(logoUrl),
    );
  }

  // College Characters Ellipse ...
  String _trimCompanyName(String name) {
    if (name.length > 24) {
      return '${name.substring(0, 24)}...';
    }
    return name;
  }}
