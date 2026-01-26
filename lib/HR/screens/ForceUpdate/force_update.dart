import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 👈 for SystemNavigator.pop
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../Constant/constants.dart';

/// Your API endpoint (minimum required version for HR app)
const _versionApi = '${BASE_URL}common/app-version?AppName=HR';
bool _fuDialogShowing = false;

/// Compare "x.y.z" semver strings. returns: -1 if a<b, 0 if =, 1 if a>b
int _compareSemver(String a, String b) {
  List<int> parse(String v) {
    final parts = v.split('.');
    final nums = <int>[];
    for (int i = 0; i < 3; i++) {
      nums.add(i < parts.length ? int.tryParse(parts[i]) ?? 0 : 0);
    }
    return nums;
  }

  final A = parse(a);
  final B = parse(b);
  for (int i = 0; i < 3; i++) {
    if (A[i] < B[i]) return -1;
    if (A[i] > B[i]) return 1;
  }
  return 0;
}

/// Open store page (Play/App Store). Uses package name automatically.
Future<void> _openStore({required String packageName,  String? iosAppId,}) async {
  if (Platform.isAndroid) {
    final marketUri = Uri.parse('market://details?id=$packageName');
    final webUri    = Uri.parse('https://play.google.com/store/apps/details?id=com.skillsconnect.app');
    if (await canLaunchUrl(marketUri)) {
      await launchUrl(marketUri);
    } else {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  } else if (Platform.isIOS) {
    // 👇 अपनी असली App Store ID भरना मत भूलना
    final id = (iosAppId ?? 'XXXXXXXXX').trim();
    final webUri = Uri.parse('https://apps.apple.com/app/id$id');
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
  }
}

/// Hard exit app (use carefully; iOS rejects sometimes, but force-update demands it)
Future<void> _forceExitApp() async {
  if (Platform.isAndroid) {
    SystemNavigator.pop(); // graceful
  } else {
    // iOS पर Apple discourage करता है, but तुमने force बोला है:
    exit(0);
  }
}

/// Force-update dialog with nicer UI + Exit button.
/// [minVersion] = server’s minimum required version, [currentVersion] = app’s version.
Future<void> _showForceDialog(
    BuildContext context, {
      required String minVersion,
      required String currentVersion,
      required String packageName,
      String? serverMessage,
    }) async {
  final theme = Theme.of(context);
  final Color primary = const Color(0xFF005E6A); // 👈 Fixed color
  final Color onPrimary = Colors.white;

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) {
      return WillPopScope(
        onWillPop: () async => false, // back block
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.surface,
                  theme.colorScheme.surface.withOpacity(0.95),
                ],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon inside circle
                CircleAvatar(
                  radius: 34,
                  backgroundColor: primary.withOpacity(0.15),
                  child: Icon(Icons.system_update_alt_rounded,
                      color: primary, size: 40),
                ),

                const SizedBox(height: 16),

                // Title
                Text(
                  'Update Required',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 10),

                // Message
                // Text(
                //   serverMessage?.trim().isNotEmpty == true
                //       ? serverMessage!.trim()
                //       : 'A newer version of the app is required to continue.',
                //   textAlign: TextAlign.center,
                //   style: theme.textTheme.bodyMedium?.copyWith(
                //     color: theme.hintColor,
                //     height: 1.4,
                //   ),
                // ),

                const SizedBox(height: 18),

                // Version chips row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Chip(label: 'Current', value: currentVersion),
                    const SizedBox(width: 10),
                    Icon(Icons.arrow_forward_rounded,
                        size: 20, color: theme.hintColor),
                    const SizedBox(width: 10),
                    _Chip(
                      label: 'Required',
                      value: minVersion,
                      highlight: true,
                      color: primary,
                      onColor: onPrimary,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _forceExitApp,
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Exit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          side: BorderSide(color: theme.colorScheme.error),
                          padding:
                          const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await _openStore(
                            packageName: packageName,
                            iosAppId: '1234567890', // <-- अपनी असली App Store ID
                          );
                        },
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: const Text('Update Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: onPrimary,
                          padding:
                          const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          shadowColor: primary.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Small “pill” chip widget for versions
class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final Color? color;
  final Color? onColor;
  const _Chip({
    required this.label,
    required this.value,
    this.highlight = false,
    this.color,
    this.onColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = highlight
        ? (color ?? const Color(0xFF005E6A)) // 👈 fixed color if highlight
        : theme.colorScheme.surfaceVariant;
    final fg = highlight
        ? (onColor ?? Colors.white)
        : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
        boxShadow: highlight
            ? [
          BoxShadow(
            color: bg.withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ]
            : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: fg.withOpacity(0.8))),
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}




/// Call this from your LoginScreen (or splash) after build.
/// If currentVersion < serverVersion → force dialog opens & blocks the user.
Future<void> checkAndForceUpdate(BuildContext context) async {
  // ❌ duplicate dialogs se bachao
  if (_fuDialogShowing) return;


  try {
    // 1) Get local version
    final info = await PackageInfo.fromPlatform();
    final current = info.version.trim();      // e.g. "1.2.3"
    final pkg     = info.packageName;

    print("📱 Current App Version: $current");
    print("📦 Package Name: $pkg");
    // 2) Hit your API
    final res = await http
        .get(Uri.parse(_versionApi))
        .timeout(const Duration(seconds: 8));

    if (res.statusCode != 200) return;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final status = (data['status'] == true);


    // ✅ नई स्ट्रक्चर: version एक object है
    final verNode = (data['version'] is Map) ? (data['version'] as Map) : null;
    if (!status || verNode == null) return;

    // प्लेटफ़ॉर्म के हिसाब से required version निकालो
    final String serverVersion = Platform.isIOS
        ? (verNode['IosVersion'] ?? '').toString().trim()
        : (verNode['AndroidVersion'] ?? '').toString().trim();

    if (serverVersion.isEmpty) return;

    final String serverMsg = (data['msg'] ?? '').toString();

    // 3) Compare
    final cmp = _compareSemver(current, serverVersion);
    if (cmp < 0) {
      // Current < Required → force update
      if (!context.mounted) return;
      _fuDialogShowing = true;                // 👈 guard ON
      await _showForceDialog(
        context,
        minVersion: serverVersion,
        currentVersion: current,
        packageName: pkg,
        serverMessage: serverMsg,

      );
      // NOTE: yahan normal flow me dialog close nahi hota,
      // kyunki force-update hai. Agar kabhi programmatically
      // close karoge to neeche guard OFF kar dena.
      _fuDialogShowing = false;
    }
  } catch (_) {
    // Fail silently: don’t block login if API fails
  }
}

class ForceUpdateWatcher extends StatefulWidget {
  final Widget child;
  const ForceUpdateWatcher({Key? key, required this.child}) : super(key: key);

  @override
  State<ForceUpdateWatcher> createState() => _ForceUpdateWatcherState();
}

class _ForceUpdateWatcherState extends State<ForceUpdateWatcher>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 🔹 first paint ke turant baad bhi check (fresh launch)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) checkAndForceUpdate(context);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 🔁 app foreground aate hi dobara check
      if (mounted && !_fuDialogShowing) {
        checkAndForceUpdate(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
