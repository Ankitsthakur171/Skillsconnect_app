import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'blocpage/NotificationBloc/notification_bloc.dart';
import 'blocpage/NotificationBloc/notification_event.dart';
import 'blocpage/BookmarkBloc/bookmarkLogic.dart';
import 'blocpage/bloc_logic.dart';
import 'ProfileLogic/ProfileEvent.dart';
import 'ProfileLogic/ProfileLogic.dart';
import 'blocpage/jobFilterBloc/jobFilter_logic.dart';
import 'package:flutter/services.dart';
import '../firebase_options.dart';
import 'Model/Notification_Model.dart';
import 'student_root.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase initialized in background isolate.');
    } else {
      print('ℹ️ Firebase already initialized in background isolate.');
    }
  } catch (e, st) {
    print('⚠️ Error initializing Firebase in background isolate: $e\n$st');
  }

  print('📩 FCM BG message: ${message.messageId}, data: ${message.data}');

  // Handle background notification
  final notification = message.notification;
  final data = message.data;

  if (notification != null) {
    // Create notification model and add to bloc if possible
    final model = AppNotification(
      id: int.tryParse(data['id'] ?? '') ?? 0,
      title: notification.title ?? 'No title',
      body: notification.body ?? 'No body',
      readStatus: data['read_status'] ?? 'No',
      createdAt: DateTime.now(),
    );

    // Store in shared preferences for later retrieval
    final prefs = await SharedPreferences.getInstance();
    final existingNotifications = prefs.getStringList('pending_notifications') ?? [];
    existingNotifications.add(jsonEncode(model.toJson()));
    await prefs.setStringList('pending_notifications', existingNotifications);
  }
}
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase initialized in main isolate.');
    } else {
      print('ℹ️ Firebase already initialized in main isolate.');
    }
  } catch (e, st) {
    print('🚨 Error initializing Firebase in main isolate: $e\n$st');
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  const AndroidInitializationSettings androidInit =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
  const InitializationSettings initSettings =
  InitializationSettings(android: androidInit, iOS: iosInit);

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      print('🔔 Notification tapped with payload: ${response.payload}');
    },
  );

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => NavigationBloc()),
          BlocProvider(create: (_) => ProfileBloc()..add(LoadProfileData())),
          BlocProvider(create: (_) => BookmarkBloc()),
          BlocProvider(create: (_) => JobFilterBloc()),
          BlocProvider(create: (_) => NotificationBloc()..add(LoadNotifications())),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: rootNavigatorKey,
          home: const StudentRoot(),
        ),
      ),
    );
  }
}
//
// class MainApp extends StatefulWidget {
//   const MainApp({super.key});
//
//   @override
//   State<MainApp> createState() => _MainAppState();
// }
//
// class _MainAppState extends State<MainApp> {
//   bool _isCheckingToken = true;
//   bool _isLoggedIn = false;
//   bool _showSplashScreen = true;
//   String _fcmToken = 'loading...';
//
//   @override
//   void initState() {
//     super.initState();
//     _initFCM();
//     _showSplashScreenWithDelay();
//   }
//
//   Future<void> _initFCM() async {
//     try {
//       final messaging = FirebaseMessaging.instance;
//
//       await messaging.requestPermission();
//
//       final token = await messaging.getToken();
//       if (token != null) {
//         setState(() => _fcmToken = token);
//         print('✅ FCM token: $token');
//       }
//
//       FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
//         print('🔄 FCM token refreshed: $newToken');
//         setState(() => _fcmToken = newToken);
//         final prefs = await SharedPreferences.getInstance();
//         final isLoggedIn = (prefs.getString('authToken') ?? '').isNotEmpty;
//         if (!isLoggedIn) return;
//         try {
//           await UpdateFcmApi.sendFcmToken(newToken);
//         } catch (_) {}
//       });
//
//       FirebaseMessaging.onMessage.listen((RemoteMessage msg) async {
//         print('📩 FCM foreground message: ${msg.data}');
//         final notif = msg.notification;
//         if (notif != null) {
//           const AndroidNotificationDetails androidDetails =
//           AndroidNotificationDetails(
//             'fcm_channel',
//             'FCM Notifications',
//             channelDescription: 'This channel is used for FCM notifications',
//             importance: Importance.max,
//             priority: Priority.high,
//             playSound: true,
//           );
//
//           const NotificationDetails platformDetails =
//           NotificationDetails(android: androidDetails);
//
//           await flutterLocalNotificationsPlugin.show(
//             notif.hashCode,
//             notif.title ?? 'Notification',
//             notif.body ?? '',
//             platformDetails,
//             payload: msg.data.toString(),
//           );
//         }
//       });
//
//       FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage msg) {
//         print('📲 User opened app from notification: ${msg.data}');
//       });
//     } catch (e, st) {
//       print('⚠️ Error initializing FCM: $e\n$st');
//     }
//   }
//
//   Future<void> _showSplashScreenWithDelay() async {
//     await Future.delayed(const Duration(seconds: 2));
//     if (!mounted) return;
//     setState(() {
//       _showSplashScreen = false;
//     });
//     _checkToken();
//   }
//
//   Future<void> _checkToken() async {
//     final loginService = loginUser();
//     final token = await loginService.getToken();
//     if (!mounted) return;
//
//     setState(() {
//       _isLoggedIn = token != null;
//       _isCheckingToken = false;
//     });
//
//     if (_isLoggedIn) {
//       context.read<NavigationBloc>().add(GotoHomeScreen2());
//     } else {
//       context.read<NavigationBloc>().add(SplashToLogin());
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return BlocListener<NavigationBloc, NavigationState>(
//       listener: (context, state) {
//         if (state is NavigateToLoginPage || state is NavigateBacktoLoginin) {
//           Navigator.popUntil(context, (route) => route.isFirst);
//         } else if (state is NavigatetoForgotPassword) {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (_) => const ForgotpasswordPage()),
//           ).then((_) {
//             context.read<NavigationBloc>().add(GobackToLoginPage());
//           });
//         } else if (state is NavigateToMyAccount) {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (_) => const MyAccount()),
//           ).then((_) {
//             context.read<NavigationBloc>().add(GoToAccountScreen2());
//           });
//         }
//       },
//
//       child: BlocBuilder<NavigationBloc, NavigationState>(
//         builder: (context, state) {
//           if (_showSplashScreen) return const SplashScreen();
//           if (_isCheckingToken) {
//             return const Scaffold(
//               body: Center(
//                   child: CircularProgressIndicator()
//               ),
//             );
//           }
//           if (state is NavigateToLoginPage ||
//               state is NavigateBacktoLoginin ||
//               state is NavigatetoForgotPassword) {
//             return const Loginpage();
//           } else if (state is NavigateToHomeScreen2) {
//             return const HomeScreen2();
//           } else if (state is NavigateToJobSecreen2) {
//             return const Jobscreenbt();
//           } else if (state is NavigateToInterviewScreen) {
//             return const InterviewScreen();
//           } else if (state is NavigateToContactsScreen) {
//             return const Contactsscreen();
//           } else if (state is NavigateToAccountScreen) {
//             return const AccountScreen();
//           }
//
//           return Scaffold(
//             body: Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const CircularProgressIndicator(),
//                   const SizedBox(height: 18),
//                   SelectableText('FCM token: $_fcmToken'),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
