import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:skillsconnect/HR/screens/package_transaction.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../Constant/constants.dart';
import 'contactus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'in_app_webview_screen.dart';
import 'my_transaction_detail.dart';
import 'notification_screen.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int selectedIndex = 0; // default -> "Language"
  int _notifCount = 0;
  StreamSubscription<RemoteMessage>? _notifSub;

  // ⬇️ NEW
  String _appVersion = '-';

  Future<void> _loadLocalAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      // eg. "2.0.3 (203)" ya sirf "2.0.3"
      // final v = '${info.version} (${info.buildNumber})';
      final v = '${info.version}';
      if (mounted) setState(() => _appVersion = v);
    } catch (_) {
      if (mounted) setState(() => _appVersion = '-');
    }
  }
  static const _notifCountKey = 'notif_count';

  Future<void> _loadNotifCount() async {
    final sp = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _notifCount = sp.getInt(_notifCountKey) ?? 0);
  }

  Future<void> _saveNotifCount(int v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_notifCountKey, v.clamp(0, 9999));
  }

  @override
  void initState() {
    super.initState();

    _loadNotifCount(); // ← persisted value

    _loadLocalAppVersion(); // ⬅️ yahan
    _notifSub = FirebaseMessaging.onMessage.listen((RemoteMessage m) {
      setState(() {
        _notifCount = (_notifCount + 1).clamp(0, 9999);
      });
      _saveNotifCount(_notifCount); // ← persist increment
    });
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }

  final Color primaryColor = const Color(0xff003840);
  final Color highlightColor = const Color(0xff005E6A);

  final List<Map<String, dynamic>> settingsOptions = [
    {"icon": Icons.receipt_long_rounded, "title": "My Transaction"},
    {"icon": Icons.subscriptions_outlined, "title": "Active Package"},
    {"icon": Icons.description_outlined, "title": "Terms and Condition"},
    {"icon": Icons.contact_page, "title": "Contact Us"},
    // {"icon": Icons.info_outline_rounded, "title": "Version"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xffEBF6F7), // AppBar background
        // backgroundColor:  Colors.white, // AppBar background
        elevation: 0, // shadow remove
        automaticallyImplyLeading: false, // default back button hide
        title: Padding(
          padding: const EdgeInsets.fromLTRB(10, 40, 10, 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back Button in Circle
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0x40005E6A),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.keyboard_arrow_left,
                      color: Color(0xff003840),
                    ),
                  ),
                ),
              ),

              // Center Title
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Inter",
                  color: Color(0xff003840),
                ),
              ),

              // Notification Icon with Count Badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationsScreen(),
                        ),
                      );
                      // User ne notifications dekh li — ab clear
                      if (mounted && _notifCount > 0) {
                        setState(() => _notifCount = 0);
                        await _saveNotifCount(0);
                      }
                    },
                    child: const CircleAvatar(
                      backgroundColor: Color(0xffEBF6F7),
                      radius: 20,
                      child: ClipOval(
                        child: Image(
                          image: AssetImage('assets/notification.png'),
                          height: 40,
                          width: 40,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  // --- COUNT BADGE (top-right) ---
                  if (_notifCount > 0)
                    Positioned(
                      top: -6,
                      right: -5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Color(0xFFCAFEE3),
                            width: 1,
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
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
            ],
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: settingsOptions.length,
        itemBuilder: (context, index) {
          final option = settingsOptions[index];
          final bool isSelected = selectedIndex == index;

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? highlightColor : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: Icon(
                option["icon"],
                color: isSelected ? Colors.white : Colors.black87,
              ),
              title: Text(
                option["title"],
                style: TextStyle(
                  fontSize: 16,
                  color: isSelected ? Colors.white : primaryColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              // ⬇️ ONLY for Version: show fetched version at right
              trailing: option["title"] == "Version"
                  ? Text(
                _appVersion,
                style: TextStyle(
                  color: isSelected ? Colors.white : primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              )
                  : null,

              onTap: () {
                setState(() {
                  selectedIndex = index;
                });

                // 👇 Navigation logic
                if (option["title"] == "My Transaction") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TransactionsPage()),
                  );
                } else if (option["title"] == "Active Package") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PackageFeaturesPage(), // 👈 yeh aapka new screen
                    ),
                  );
                } else if (option["title"] == "Contact Us") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ContactUsPage()),
                  );
                } else if (option["title"] == "Terms and Condition") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InAppWebViewScreen(
                        url: "https://skillsconnect.in/terms-conditions",
                        title: "Terms & Conditions",
                      ),
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
      // 3) Bottom version bar (exact footer jahan aapne mark kiya)
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline,color: Color(0xff003840),),
              SizedBox(width: 6),
              const Text(
                'App Version',
                style: TextStyle(
                  color: Color(0xff003840),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _appVersion, // e.g. 2.0.0
                style: const TextStyle(
                  color: Color(0xff003840),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
}
