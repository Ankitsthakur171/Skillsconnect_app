import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:skillsconnect/student_app/ProfileLogic/ProfileEvent.dart';
import 'package:skillsconnect/utils/company_info_manager.dart';
import 'package:skillsconnect/utils/http_overrides_guard.dart';
import 'package:skillsconnect/utils/session_guard.dart';
import 'HR/Calling/call_screen.dart';
import 'HR/Calling/root_router.dart';
import 'NetworkUtils/global_internet_lisner.dart';
import 'firebase_options.dart';
import 'api/firebase_api.dart';
import 'app_globals.dart' hide navigatorKey;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'HR/screens/splash_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'student_app/blocpage/bloc_logic.dart';
import 'student_app/ProfileLogic/ProfileLogic.dart';
import 'student_app/blocpage/BookmarkBloc/bookmarkLogic.dart';
import 'student_app/blocpage/jobFilterBloc/jobFilter_logic.dart';
import 'student_app/blocpage/NotificationBloc/notification_bloc.dart';

// Global variable to store pending call data temporarily
Map<String, dynamic>? _pendingCallData;

Future<void> _primeCallkitAcceptBootstrap() async {
  // Listen as early as possible so Accept event isn't missed on cold-start
  FlutterCallkitIncoming.onEvent.listen((event) async {
    final ev = event?.event;
    if (ev == null) return;
    if (ev == Event.actionCallAccept) {
      final body  = Map<String, dynamic>.from(event?.body ?? {});
      final extra = Map<String, dynamic>.from(body['extra'] ?? {});
      // Store in memory first, will be saved to SharedPreferences after binding init
      _pendingCallData = extra;
    }
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 🔐 FRESH INSTALL GUARD — सबसे पहले!
  // await enforceFreshInstallGate(); // TODO: Implement if needed
  
 // // token expire then logout
  SessionGuard.init(navigatorKey);
  SessionGuard.disable(); // 🔸 boot par guard SLEEP me

  HttpOverrides.global = GuardedHttpOverrides(); // 👈 truly global

  await _primeCallkitAcceptBootstrap(); // 👈 VERY EARLY

  await CompanyInfoManager().load();   // <- prime once at boot

  // ✅ CallKit event listener (no async here)
  FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
    if (event == null) return;

    if (event.event == Event.actionCallAccept) {
      print('📞 Call accepted from CallKit');
      _handleCallAccept(); // 🔥 move async work into helper
    }
  }); 



  // 2️⃣ Pending call data check करो (जो MainActivity.kt ने store किया)
  final prefs = await SharedPreferences.getInstance();
  final pendingJson = prefs.getString('flutter.pending_join');

  Map<String, dynamic>? pendingCallData;
  if (pendingJson != null && pendingJson.isNotEmpty) {
    pendingCallData = jsonDecode(pendingJson);
    // साफ भी कर दो ताकि दोबारा auto-open ना हो
    await prefs.remove('flutter.pending_join');
  }

  // Also save any pending call data from early event listener
  if (_pendingCallData != null) { 
    await prefs.setString('pending_join', jsonEncode(_pendingCallData));
    pendingCallData = _pendingCallData;
    _pendingCallData = null; // Clear after saving
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );



  try { await FlutterCallkitIncoming.endAllCalls(); } catch (_) {}

  NetworkGuard.startMonitoring(); // ✅ start listener globally

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);


  // Sanity: should show [DEFAULT]
  print('Firebase apps: ${Firebase.apps.map((a) => a.name).toList()}');

  // Background FCM handler registration (MUST be before runApp)

  // ✅ Android 14+ full-screen intent permission (recommended)
  try {
    final ok = await FlutterCallkitIncoming.canUseFullScreenIntent();
    if (ok == false) {
      await FlutterCallkitIncoming.requestFullIntentPermission();
    }
  } catch (_) {}


  runApp(MyApp(initialCallData: pendingCallData));
}


// ✅ Fresh-install guard: first run par purane tokens cleanup
Future<void> enforceFreshInstallGate() async {
  final sp = await SharedPreferences.getInstance();
  final installId = sp.getString('install_id');

  if (installId == null || installId.isEmpty) {
    // Fresh install detected → wipe any stale auth/session
    await sp.remove('auth_token');
    await sp.remove('user_data');
    await sp.remove('user_id');
    await sp.remove('pending_join');           // safety (callkit carry-over)
    await sp.remove('flutter.pending_join');   // safety (android main activity)

    // generate & persist a device-local install id
    final newId = '${DateTime.now().millisecondsSinceEpoch}-${100000 + Random().nextInt(900000)}';
    await sp.setString('install_id', newId);

    // (optional) debug
    // print('🧹 Fresh install: cleared stale auth, set install_id=$newId');
  }
}


Future<void> _handleCallAccept() async {
  final calls = await FlutterCallkitIncoming.activeCalls();
  if (calls.isNotEmpty) {
    final data = calls.first;
    final extra = data['extra'] ?? {};

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pending_join', jsonEncode(extra));
    print("✅ Stored pending_join for navigation: $extra");
  }
}

class MyApp extends StatefulWidget {
  final Map<String, dynamic>? initialCallData;

  const MyApp({super.key,this.initialCallData});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = navigatorKey.currentContext ?? context;
      FirebaseApi().initNotifications(ctx);
      // ✅ Agar pending call data mila hai
      if (widget.initialCallData != null) {
        final data = widget.initialCallData!;
        print("🎯 Launching CallScreen with $data");

        try {
          Navigator.pushReplacement(
            ctx,
            MaterialPageRoute(
              builder: (_) => CallScreen(
                channelId: data['channelId']?.toString() ?? '',
                callerId: data['callerId']?.toString() ?? '',
                receiverId: data['receiverId']?.toString() ?? '',
                peerName: data['peerName']?.toString() ?? 'Unknown',
                isCaller: data['isCaller'] == true,
              ),
            ),
          );
        } catch (e) {
          print("❌ Error opening CallScreen: $e");
        }
      }
    });

  }



  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Student BLoCs - available globally for lazy loading
        BlocProvider(create: (_) => NavigationBloc()),
        BlocProvider(create: (_) => ProfileBloc()..add(LoadProfileData())),
        BlocProvider(create: (_) => BookmarkBloc()),
        BlocProvider(create: (_) => JobFilterBloc()),
        BlocProvider(create: (_) => NotificationBloc()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey, // ✅ use same navigatorKey
        debugShowCheckedModeBanner: false,
        home: RootRouter(), // 👈 your entry screen
        // home: const SplashScreen(), // 👈 your entry screen
      ),
    );
  }
}




