import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:skillsconnect/TPO/Model/tpo_home_job_model.dart';
import 'package:skillsconnect/TPO/Screens/tpo_home_screen.dart';
import 'package:skillsconnect/student_app/student_root.dart';
import 'package:skillsconnect/TPO/TPO_Home/tpo_home_bloc.dart';
import 'package:skillsconnect/TPO/TPO_Home/tpo_home_event.dart';
import 'package:skillsconnect/HR/bloc/Job/job_bloc.dart';
import 'package:skillsconnect/HR/bloc/Job/job_event.dart';
import 'package:skillsconnect/HR/bloc/Login/login_event.dart';
import 'package:skillsconnect/HR/bloc/Login/login_state.dart';
import 'package:skillsconnect/HR/screens/bottom_nav_bar.dart';
import 'package:skillsconnect/HR/screens/job_screen.dart';

import '../../../Constant/constants.dart';
import '../../../TPO/My_Account/api_services.dart';
import '../../../api/firebase_api.dart' hide globalFcmToken;
import '../../../app_globals.dart';
import '../../../globals.dart';
import '../../../utils/company_info_manager.dart';
import '../../../utils/company_service.dart';
import '../../../utils/device_fingerprint.dart';
import '../../../utils/tpo_info_manager.dart';
import '../../Calling/call_incoming_watcher.dart';
import '../../Calling/call_listener.dart';
// import '../../Calling/call_listener.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(LoginState.initial()) {
    on<EmailChanged>((event, emit) {
      final updatedEmail = event.email;
      final password = state.password;

      emit(state.copyWith(
        email: updatedEmail,
        isValid: _isValid(updatedEmail, password),
        errorMessage: null,
      ));
    });

    on<PasswordChanged>((event, emit) {
      final updatedPassword = event.password;
      final email = state.email;

      emit(state.copyWith(
        password: updatedPassword,
        isValid: _isValid(email, updatedPassword),
        errorMessage: null,
      ));
    });

    on<LoginSubmitted>((event, emit) async {
      emit(state.copyWith(isValid: false, isLoading: true, errorMessage: null));
      final deviceCtx = await DeviceFingerprint.getDeviceContext();
      print('👉 Sending device_id: ${deviceCtx['device_id']}');


      try {
        final deviceCtx = await DeviceFingerprint.getDeviceContext();
        print('👉 Sending device_id: ${deviceCtx['device_id']}');

        final hw = await _collectDeviceInfo();

        // API ko array bhejna hai:
        final deviceInfoArray = [
          {'key': 'device_id',     'value': '${deviceCtx['device_id']}'},
          {'key': 'manufacturer',  'value': hw['manufacturer'] ?? ''},
          {'key': 'model',         'value': hw['model'] ?? ''},
          {'key': 'os_version',    'value': hw['os_version'] ?? ''},
          {'key': 'platform',      'value': hw['platform'] ?? ''},
        ];

          // Debug prints
        print('📱 device_info =>');
        for (final kv in deviceInfoArray) {
          print('  • ${kv['key']}: ${kv['value']}');
        }

        final response = await http.post(
          Uri.parse(
              '${BASE_URL}auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': state.email,
            'password': state.password,

            //  add these for backend
            'device_id': deviceCtx['device_id'],
            'device': deviceCtx,

            'device_info': deviceInfoArray,
          }),
        );

        final data = jsonDecode(response.body);

        if (response.statusCode == 200 && data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', data['token']);

          //  Decrypt userData
          const secretKey = "RGjB6qIBXGz9mmNVCpwwiHpW0N3s3jR+"; // 32-byte key
          final decryptedUserData =
              _decryptUserData(data['userData'], secretKey);
          print(" Decrypted userData: $decryptedUserData");

          await prefs.setString('user_data', decryptedUserData);

          final userMap  = jsonDecode(decryptedUserData);
          final userType = (userMap['user_type'] is int)
              ? userMap['user_type'] as int
              : int.tryParse('${userMap['user_type']}') ?? 0;

          await prefs.setString('user_id', userMap['id'].toString());
          print("👤 User ID: ${userMap['id']}");   // <-- Ye userId print karega



// Save user_data for both types
          await prefs.setString('user_data', decryptedUserData);

          // // ✅ Yahan FCM token server par bhejna hai
          // if (globalFcmToken != null && globalFcmToken!.isNotEmpty) {
          //   print("🚀 Sending FCM Token after login...");
          //   await FirebaseApi().sendFcmTokenToServer(globalFcmToken!);
          // } else {
          //   print("⚠️ FCM token not available yet");
          // }


          // ✅ naya (fresh getToken -> send)
          final fcmNow = await FirebaseMessaging.instance.getToken();
          print("🔑 FCM (fresh getToken): $fcmNow");
          if (fcmNow != null && fcmNow.isNotEmpty) {
            await FirebaseApi().sendFcmTokenToServer(fcmNow);
          } else {
            // fallback: ek baar next refresh aate hi bhej do
            // (permanent listener mat lagao)
            FirebaseMessaging.instance.onTokenRefresh.first.then((t) {
              print("🔄 FCM (onTokenRefresh): $t");
              FirebaseApi().sendFcmTokenToServer(t);
            });
          }


//  TPO USER
          if (userType == 5) {

            try {
              // 1) pehle user JSON laao
              final Map<String, dynamic> userJson = await getUserData();   // 👈 CALL + AWAIT

              // 2) agar loadUserDataOnce ko function chahiye, to resolved value se wrapper de do
              await UserInfoManager().loadUserDataOnce(() async => userJson);

              // 3) header ko prime karo (prefs + in-memory) — yahan Map pass hoga
              await _primeTpoHeader(userJson);                              // 👈 PASS MAP, not function

              await UserInfoManager().initFromPrefs();
              // Splash / login success ke baad, user logged-in path me:
              await Tpoprofile.refreshHeaderFromServer();  // 👈 latest header pull
            }  catch (e) {
              debugPrint('⚠️ TPO post-login init ignored: $e');
            }



            // Navigator.pushReplacement(
            //   event.context,
            //   MaterialPageRoute(
            //     builder: (_) => BlocProvider(
            //       create: (_) => TpoHomeBloc()..add(LoadTpoJobsEvent()),
            //       child: TpoHomeScreen(),
            //     ),
            //   ),
            // );

            // TPO
            CallIncomingWatcher.start(userMap['id'].toString()); // 👈 ADD THIS LINE
            Navigator.pushReplacement(
              event.context,
              MaterialPageRoute(
                builder: (_) => CallListener(
                  currentUserId: userMap['id'].toString(), // TPO ID
                  child: BlocProvider(
                    create: (_) => TpoHomeBloc()..add(LoadTpoJobsEvent()),
                    child: TpoHomeScreen(),
                  ),
                ),
              ),
            );
          }

// STUDENT USER
          else if (userType == 4) {
            // Store token in legacy student format for backward compatibility
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('authToken', data['token']);  // Legacy student format
            await prefs.setString('connectSid', '');            // Empty connect.sid for compatibility

            CallIncomingWatcher.start(userMap['id'].toString()); // 👈 ADD THIS LINE
            Navigator.pushReplacement(
              event.context,
              MaterialPageRoute(
                builder: (_) => CallListener(
                  currentUserId: userMap['id'].toString(), // Student ID
                  child: const StudentRoot(),
                ),
              ),
            );
          }

// HR USER
          else if (userType == 7) {
            try {
// fetch company detail + SharedPreferences update + notifyListeners()
              await CompanyInfoService.refresh(notify: true);

// (defensive) ensure manager ne latest prefs read kar li
              await CompanyInfoManager().load();
            }catch (e) {
              debugPrint('⚠️ CompanyInfo refresh ignored: $e');
            }

            // final token = prefs.getString('auth_token') ?? '';
            //
            // // Fetch company details
            // final companyResponse = await http.post(
            //   Uri.parse(
            //       '${BASE_URL}profile'),
            //   headers: {
            //     'Content-Type': 'application/json',
            //     'Authorization': 'Bearer $token',
            //   },
            //   body: jsonEncode({'action': 'company_detail'}),
            // );
            //
            // if (companyResponse.statusCode == 200) {
            //   final companyData = jsonDecode(companyResponse.body);
            //   final companyDetails = companyData['data']?['companyDetails'];
            //
            //   if (companyDetails is List && companyDetails.isNotEmpty) {
            //     final company = companyDetails[0];
            //     final companyName = company['company_name'];
            //     final companyLogo = company['company_logo'];
            //
            //     if (companyName != null)
            //       await prefs.setString('company_name', companyName);
            //     if (companyLogo != null)
            //       await prefs.setString('company_logo', companyLogo);
            //
            //     print(' Company Logo : ${companyLogo}');
            //
            //     // Load company info ONLY for user_type 7
            //     await CompanyInfoManager().load();
            //   }
            // }
            // //
            // Navigator.pushReplacement(
            //   event.context,
            //   MaterialPageRoute(
            //     builder: (_) => BlocProvider(
            //       create: (_) => JobBloc()..add(LoadJobsEvent()),
            //       child: const BottomNavBar(),
            //     ),
            //   ),
            // );

            CallIncomingWatcher.start(userMap['id'].toString()); // 👈 ADD THIS LINE
            Navigator.pushReplacement(
              event.context,
              MaterialPageRoute(
                builder: (_) => CallListener(
                  currentUserId: userMap['id'].toString(), // HR ID
                  child: BlocProvider(
                    create: (_) => JobBloc()..add(LoadJobsEvent()),
                    child: const BottomNavBar(),
                  ),
                ),
              ),
            );
          } else {
            emit(LoginFailure(state, 'Unknown user type'));
            return;
          }

          emit(LoginSuccess(state));
        } else {
          final rawMsg = data['msg']?.toString() ?? 'Login failed';
          final cleanMsg = rawMsg.split('<').first.trim();
          emit(LoginFailure(state, cleanMsg));
        }
      } catch (e) {
        emit(LoginFailure(state, 'Network error: $e'));
        debugPrint('🔴 Network error during login: $e'); // 👈 ye console me show karega

      }
    });
  }

  //  Email and password validation
  bool _isValid(String email, String password) {
    return email.contains('@') && password.length >= 6;
  }

  //  Decrypt encrypted userData
  String _decryptUserData(String userData, String secretKey) {
    try {
      final decodedJson = utf8.decode(base64.decode(userData));
      final data = jsonDecode(decodedJson);

      final ivHex = data['iv'] as String;
      final contentHex = data['content'] as String;

      final ivBytes = _hexToBytes(ivHex);
      final contentBytes = _hexToBytes(contentHex);

      final key = encrypt.Key.fromUtf8(secretKey);
      final iv = encrypt.IV(ivBytes);

      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
      );

      final decrypted =
          encrypter.decrypt(encrypt.Encrypted(contentBytes), iv: iv);
      return decrypted;
    } catch (e) {
      print(" Final Decryption Error: $e");
      return '{}';
    }
  }

  // Helper to convert hex string to bytes
  Uint8List _hexToBytes(String hex) {
    hex = hex.replaceAll(' ', '');
    return Uint8List.fromList(List.generate(
      hex.length ~/ 2,
      (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
    ));
  }

  Future<void> _primeTpoHeader(Map<String, dynamic> user) async {
    // JSON se safe extraction (fallbacks rakhe)
    final collegeName = (user['college']?['name'] ??
        user['college_name'] ??
        user['collegeName'] ??
        '').toString();

    final collegeLogo = (user['college']?['image'] ??
        user['college_image'] ??
        user['collegeLogo'] ??
        user['logo'] ??
        '').toString();

    // 1) prefs me turant likho (AppBar ka FutureBuilder yahi padhta hai)
    final sp = await SharedPreferences.getInstance();
    await sp.setString('college_name', collegeName);
    await sp.setString('college_logo', collegeLogo);

    // 2) in-memory ko prime karo taaki first frame me hi value mil jaye
    // (UserInfoManager initFromPrefs ke baad first build me fallback nahi aayega)
    await UserInfoManager().initFromPrefs();

    // (agar UserInfoManager ChangeNotifier hai to yeh optional notify helpful hota)
    try {
      // ignore: invalid_use_of_protected_member
      // ignore: invalid_use_of_visible_for_testing_member
      // UserInfoManager().notifyListeners();
    } catch (_) {}
  }

  Future<Map<String, String>> _collectDeviceInfo() async {
    final plugin = DeviceInfoPlugin();

    try {
      if (Platform.isAndroid) {
        final a = await plugin.androidInfo;

        // Raw logs (helps you see what the device actually reports)
        // ignore: avoid_print
        print('[DEVINFO][ANDROID] '
            'manufacturer=${a.manufacturer}; brand=${a.brand}; model=${a.model}; '
            'device=${a.device}; product=${a.product}; hardware=${a.hardware}; '
            'release=${a.version.release}; sdk=${a.version.sdkInt}');

        // Prefer manufacturer, else brand, else hardware/product/device
        final manufacturer = (a.manufacturer?.trim().isNotEmpty == true)
            ? a.manufacturer!.trim()
            : (a.brand?.trim().isNotEmpty == true)
            ? a.brand!.trim()
            : (a.hardware?.trim().isNotEmpty == true)
            ? a.hardware!.trim()
            : (a.product?.trim().isNotEmpty == true)
            ? a.product!.trim()
            : (a.device?.trim().isNotEmpty == true)
            ? a.device!.trim()
            : 'Android';

        // Prefer model, else product/device/hardware
        final model = (a.model?.trim().isNotEmpty == true)
            ? a.model!.trim()
            : (a.product?.trim().isNotEmpty == true)
            ? a.product!.trim()
            : (a.device?.trim().isNotEmpty == true)
            ? a.device!.trim()
            : (a.hardware?.trim().isNotEmpty == true)
            ? a.hardware!.trim()
            : 'Unknown';

        return {
          'platform': 'android',
          'manufacturer': manufacturer,
          'model': model,
          'os_version': 'Android ${a.version.release} (SDK ${a.version.sdkInt})',
        };
      }

      if (Platform.isIOS) {
        final i = await plugin.iosInfo;

        // Raw logs
        // ignore: avoid_print
        print('[DEVINFO][IOS] '
            'model=${i.model}; name=${i.name}; system=${i.systemName} ${i.systemVersion}; '
            'utsname.machine=${i.utsname.machine}');

        final model = (i.utsname.machine?.trim().isNotEmpty == true)
            ? i.utsname.machine!.trim() // e.g. "iPhone15,4"
            : (i.model?.trim().isNotEmpty == true)
            ? i.model!.trim()       // often "iPhone"
            : 'iPhone';

        return {
          'platform': 'ios',
          'manufacturer': 'Apple',
          'model': model,
          'os_version': '${i.systemName} ${i.systemVersion}',
        };
      }
    } catch (e) {
      // ignore: avoid_print
      print('[DEVINFO][ERROR] $e');
    }

    // Fallback (web/desktop/unknown)
    return {
      'platform': Platform.operatingSystem,
      'manufacturer': '',
      'model': '',
      'os_version': Platform.operatingSystemVersion,
    };
  }

  /// 🔁 Company Info ko API se refresh karne wala helper function

}

Future<Map<String, dynamic>> getUserData() async {
  final prefs = await SharedPreferences.getInstance();
  final userDataString = prefs.getString('user_data');

  if (userDataString == null) return {};

  try {
    final userData = jsonDecode(userDataString);
    return userData;
  } catch (e) {
    print("Error decoding user_data: $e");
    return {};
  }
}
