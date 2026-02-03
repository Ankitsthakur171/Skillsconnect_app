import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../utils/device_fingerprint.dart';
import '../../../utils/tpo_info_manager.dart';
import 'otp_login_event.dart';
import 'otp_login_state.dart';

// === Your project imports (same as your LoginBloc) ===
import 'package:skillsconnect/Constant/constants.dart';
import 'package:skillsconnect/TPO/Model/tpo_home_job_model.dart';
import 'package:skillsconnect/TPO/Screens/tpo_home_screen.dart';
import 'package:skillsconnect/student_app/student_root.dart';
import 'package:skillsconnect/TPO/TPO_Home/tpo_home_bloc.dart';
import 'package:skillsconnect/TPO/TPO_Home/tpo_home_event.dart';
import 'package:skillsconnect/HR/bloc/Job/job_bloc.dart';
import 'package:skillsconnect/HR/bloc/Job/job_event.dart';
import 'package:skillsconnect/HR/screens/bottom_nav_bar.dart';
import 'package:skillsconnect/api/firebase_api.dart' hide globalFcmToken;
import 'package:skillsconnect/globals.dart';
import 'package:skillsconnect/utils/company_info_manager.dart';
import 'package:skillsconnect/utils/company_service.dart';
import 'package:skillsconnect/TPO/My_Account/api_services.dart';
import 'package:skillsconnect/HR/Calling/call_incoming_watcher.dart';
import 'package:skillsconnect/HR/Calling/call_listener.dart';

// ---------- ENDPOINTS ----------
const String _REQUEST_OTP_PATH = 'auth/request-login-otp';
// If your backend verifies OTP on a different path, change below:
const String _VERIFY_OTP_PATH  = 'auth/login';

class OtpLoginBloc extends Bloc<OtpLoginEvent, OtpLoginState> {
  OtpLoginBloc() : super(OtpLoginState.initial()) {
    on<OtpEmailChanged>((event, emit) {
      emit(state.copyWith(email: event.email, errorMessage: '', successMessage: ''));
    });

    // on<OtpEditEmailPressed>((event, emit) {
    //   emit(state.copyWith(
    //     step: OtpLoginStep.enterEmail,
    //     otp: '',
    //     errorMessage: '',
    //     successMessage: '',
    //   ));
    // });

    on<OtpRequestSubmitted>(_onRequestOtp);
    on<OtpResendRequested>(_onResendOtp);
    // ⬇️ NEW: cooldown event handlers
    on<OtpCooldownTick>((event, emit) {
      final left = state.resendSecondsLeft - 1;
      emit(state.copyWith(resendSecondsLeft: left <= 0 ? 0 : left));
    });
    on<OtpCooldownFinished>((event, emit) {
      _cooldown?.cancel();
      emit(state.copyWith(resendSecondsLeft: 0));
    });

    on<OtpEditEmailPressed>((event, emit) {
      _cooldown?.cancel();
      emit(state.copyWith(
        step: OtpLoginStep.enterEmail,
        otp: '',
        errorMessage: '',
        successMessage: '',
        resendSecondsLeft: 0,
      ));
    });

    // on<OtpRequestSubmitted>((event, emit) async {
    //   final email = state.email.trim();
    //   if (email.isEmpty) {
    //     emit(state.copyWith(errorMessage: 'Email or phone is required'));
    //     return;
    //   }
    //   // basic format check (optional – phone/emails both allowed)
    //   final emailLike = RegExp(r"^[\w\.\-+]+@[A-Za-z0-9\.\-]+\.[A-Za-z]{2,}$").hasMatch(email);
    //   if (!emailLike && email.length < 8) {
    //     emit(state.copyWith(errorMessage: 'Please enter a valid email/phone'));
    //     return;
    //   }
    //
    //   emit(state.copyWith(isLoading: true, errorMessage: '', successMessage: ''));
    //   try {
    //     final res = await http.post(
    //       Uri.parse('${BASE_URL}${_REQUEST_OTP_PATH}'),
    //       headers: {'Content-Type': 'application/json'},
    //       body: jsonEncode({'username': email}),
    //     );
    //
    //     final body = _safeJson(res.body);
    //     if (res.statusCode == 200) {
    //       emit(state.copyWith(
    //         isLoading: false,
    //         step: OtpLoginStep.enterOtp,
    //         successMessage: (body['message']?.toString().isNotEmpty ?? false)
    //             ? body['message'].toString()
    //             : 'OTP sent successfully',
    //         errorMessage: '',
    //       ));
    //     } else {
    //       final msg = (body['message'] ?? body['msg'] ?? 'Failed to send OTP').toString();
    //       emit(state.copyWith(isLoading: false, errorMessage: _cleanMsg(msg)));
    //     }
    //   } catch (e) {
    //     emit(state.copyWith(isLoading: false, errorMessage: 'Network error: $e'));
    //   }
    // });

    on<OtpCodeChanged>((event, emit) {
      emit(state.copyWith(otp: event.code, errorMessage: '', successMessage: ''));
    });

    on<OtpVerifySubmitted>((event, emit) async {
      final email = state.email.trim();
      final code  = state.otp.trim();

      if (email.isEmpty) {
        emit(state.copyWith(errorMessage: 'Email/phone missing'));
        return;
      }
      if (code.length < 4) {
        emit(state.copyWith(errorMessage: 'Enter valid OTP'));
        return;
      }

      emit(state.copyWith(isLoading: true, errorMessage: '', successMessage: ''));
      try {
        // ⬇️ new: collect device bits
        final deviceCtx = await DeviceFingerprint.getDeviceContext();
        final devInfo   = await _collectDeviceInfo();
        print('👉 [OTP-VERIFY] device_id=${deviceCtx['device_id']} info=$devInfo');

        final res = await http.post(
          Uri.parse('${BASE_URL}${_VERIFY_OTP_PATH}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': email, 'LoginOTP': code,
            // ⬇️ NEW
            'device_id' : deviceCtx['device_id'],
            'device'    : devInfo,}),
        );

        final data = _safeJson(res.body);

        // Expecting the same structure as your password login:
        // { token: "...", userData: "<encrypted base64 json>" , ... }
        if (res.statusCode == 200 && data['token'] != null) {
          await _handleLoginSuccess(data, event.context);
          emit(state.copyWith(isLoading: false, successMessage: 'Login successful', errorMessage: ''));
        } else {
          final msg = (data['msg'] ?? data['message'] ?? 'OTP verification failed').toString();
          emit(state.copyWith(isLoading: false, errorMessage: _cleanMsg(msg)));
        }
      } catch (e) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: _sanitizeErrorMessage(e),
        ));
      }
    });

    // on<OtpResendRequested>((event, emit) async {
    //   // Simply call request again with same email
    //   add(const OtpRequestSubmitted());
    // });
  }

  // ---------- Helpers ----------

  Map<String, dynamic> _safeJson(String raw) {
    try {
      final obj = jsonDecode(raw);
      return (obj is Map<String, dynamic>) ? obj : {};
    } catch (_) {
      return {};
    }
  }

  String _cleanMsg(String raw) => raw.split('<').first.trim();

  /// Convert technical errors to user-friendly messages
  String _sanitizeErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    // Firebase Messaging errors
    if (errorStr.contains('firebase_messaging')) {
      if (errorStr.contains('service_not_available')) {
        return 'Connection error. Please check your internet and try again.';
      }
      return 'Service temporarily unavailable. Please try again in a moment.';
    }

    // Network/IO errors
    if (errorStr.contains('socket') || errorStr.contains('ioexception')) {
      return 'Network error. Please check your internet connection and try again.';
    }

    // Timeout errors
    if (errorStr.contains('timeout') || errorStr.contains('deadline')) {
      return 'Request timed out. Please check your connection and try again.';
    }

    // Connection refused
    if (errorStr.contains('connection refused') || errorStr.contains('econnrefused')) {
      return 'Unable to connect to server. Please try again later.';
    }

    // SSL/Certificate errors
    if (errorStr.contains('ssl') || errorStr.contains('certificate')) {
      return 'Secure connection failed. Please check your internet and try again.';
    }

    // Generic fallback
    return 'Something went wrong. Please try again.';
  }

  Future<void> _handleLoginSuccess(Map data, BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', data['token']);

    // Decrypt userData (same as your LoginBloc)
    const secretKey = "RGjB6qIBXGz9mmNVCpwwiHpW0N3s3jR+"; // 32-byte key
    final decryptedUserData = _decryptUserData(data['userData'], secretKey);
    await prefs.setString('user_data', decryptedUserData);

    final userMap = jsonDecode(decryptedUserData);
    final userType = (userMap['user_type'] is int)
        ? userMap['user_type'] as int
        : int.tryParse('${userMap['user_type']}') ?? 0;

    await prefs.setString('user_id', userMap['id'].toString());

    // FCM handling (same as your LoginBloc)
    final fcmNow = await FirebaseMessaging.instance.getToken();
    if (fcmNow != null && fcmNow.isNotEmpty) {
      await FirebaseApi().sendFcmTokenToServer(fcmNow);
    } else {
      FirebaseMessaging.instance.onTokenRefresh.first.then((t) {
        FirebaseApi().sendFcmTokenToServer(t);
      });
    }

    if (userType == 5) {
      // ---- TPO USER ----
      try {
        final Map<String, dynamic> userJson = await getUserData();
        await UserInfoManager().loadUserDataOnce(() async => userJson);
        await _primeTpoHeader(userJson);
        await UserInfoManager().initFromPrefs();
        await Tpoprofile.refreshHeaderFromServer();
      } catch (e) {
        debugPrint('⚠️ TPO post-login init ignored: $e');
      }

      CallIncomingWatcher.start(userMap['id'].toString());

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => CallListener(
            currentUserId: userMap['id'].toString(),
            child: BlocProvider(
              create: (_) => TpoHomeBloc()..add(LoadTpoJobsEvent()),
              child: TpoHomeScreen(),
            ),
          ),
        ),
            (route) => false, // <-- clear entire back stack
      );

      // CallIncomingWatcher.start(userMap['id'].toString());
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(
      //     builder: (_) => CallListener(
      //       currentUserId: userMap['id'].toString(),
      //       child: BlocProvider(
      //         create: (_) => TpoHomeBloc()..add(LoadTpoJobsEvent()),
      //         child: TpoHomeScreen(),
      //       ),
      //     ),
      //   ),
      //
      // );
    } else if (userType == 4) {
      // ---- STUDENT USER ----
      // Store token in legacy student format for backward compatibility
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('authToken', data['token']);  // Legacy student format
      await prefs.setString('connectSid', '');            // Empty connect.sid for compatibility

      CallIncomingWatcher.start(userMap['id'].toString());
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => CallListener(
            currentUserId: userMap['id'].toString(),
            child: const StudentRoot(),
          ),
        ),
            (route) => false,
      );
    } else if (userType == 7) {
      // ---- HR USER ----
      try {
        await CompanyInfoService.refresh(notify: true);
        await CompanyInfoManager().load();
      } catch (e) {
        debugPrint('⚠️ CompanyInfo refresh ignored: $e');
      }

      CallIncomingWatcher.start(userMap['id'].toString());
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => CallListener(
            currentUserId: userMap['id'].toString(),
            child: BlocProvider(
              create: (_) => JobBloc()..add(LoadJobsEvent()),
              child: const BottomNavBar(),
            ),
          ),
        ),
            (route) => false, // <-- clear entire back stack
      );
    } else {
      // Unknown user type
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unknown user type')),
      );
    }
  }

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
      debugPrint("Final Decryption Error: $e");
      return '{}';
    }
  }

  Uint8List _hexToBytes(String hex) {
    hex = hex.replaceAll(' ', '');
    return Uint8List.fromList(List.generate(
      hex.length ~/ 2,
          (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
    ));
  }

  Future<void> _primeTpoHeader(Map<String, dynamic> user) async {
    final collegeName = (user['college']?['name'] ??
        user['college_name'] ??
        user['collegeName'] ??
        '')
        .toString();

    final collegeLogo = (user['college']?['image'] ??
        user['college_image'] ??
        user['collegeLogo'] ??
        user['logo'] ??
        '')
        .toString();

    final sp = await SharedPreferences.getInstance();
    await sp.setString('college_name', collegeName);
    await sp.setString('college_logo', collegeLogo);

    await UserInfoManager().initFromPrefs();
  }
  Timer? _cooldown;

  // === handlers ===
  Future<void> _onRequestOtp(OtpRequestSubmitted event, Emitter<OtpLoginState> emit) async {
    final email = state.email.trim();
    if (email.isEmpty) {
      emit(state.copyWith(errorMessage: 'Email or phone is required'));
      return;
    }
    emit(state.copyWith(isLoading: true, errorMessage: '', successMessage: ''));
    try {
      // ⬇️ new: collect device bits
      final deviceCtx = await DeviceFingerprint.getDeviceContext(); // { device_id, ... } (aapke project ka helper)
      final devInfo   = await _collectDeviceInfo();                 // { platform, manufacturer, model, os_version }

      print('👉 [OTP-REQUEST] device_id=${deviceCtx['device_id']} info=$devInfo');

      final res = await http.post(
        Uri.parse('${BASE_URL}${_REQUEST_OTP_PATH}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': email,


          // ⬇️ NEW
          'device_id' : deviceCtx['device_id'],
          'device'    : devInfo,}
        ),
      );
      final body = _safeJson(res.body);
      if (res.statusCode == 200) {
        emit(state.copyWith(
          isLoading: false,
          step: OtpLoginStep.enterOtp,
          successMessage: (body['message']?.toString().isNotEmpty ?? false)
              ? body['message'].toString()
              : 'OTP sent successfully',
          errorMessage: '',
        ));
        _beginCooldown(emit, seconds: 30); // ⬅️ start 30s
      } else {
        emit(state.copyWith(isLoading: false, errorMessage: _cleanMsg((body['message'] ?? body['msg'] ?? 'Failed to send OTP').toString())));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: _sanitizeErrorMessage(e),
      ));
    }
  }

  Future<void> _onResendOtp(OtpResendRequested event, Emitter<OtpLoginState> emit) async {
    // Guard: if still cooling down, ignore
    if (state.resendSecondsLeft > 0 || state.isLoading) return;
    add(const OtpRequestSubmitted()); // reuse request flow
  }

  void _beginCooldown(Emitter<OtpLoginState> emit, {int seconds = 30}) {
    _cooldown?.cancel();
    emit(state.copyWith(resendSecondsLeft: seconds));
    _cooldown = Timer.periodic(const Duration(seconds: 1), (t) {
      final left = state.resendSecondsLeft;
      if (left <= 1) {
        t.cancel();
        add(const OtpCooldownFinished());
      } else {
        add(const OtpCooldownTick());
      }
    });
  }

  @override
  Future<void> close() {
    _cooldown?.cancel();
    return super.close();
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
}

// Same helper you already have elsewhere
Future<Map<String, dynamic>> getUserData() async {
  final prefs = await SharedPreferences.getInstance();
  final s = prefs.getString('user_data');
  if (s == null) return {};
  try {
    return jsonDecode(s);
  } catch (_) {
    return {};
  }
}
