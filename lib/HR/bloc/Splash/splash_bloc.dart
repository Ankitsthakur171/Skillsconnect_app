// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../../TPO/Model/tpo_home_job_model.dart';
// import '../../../utils/company_info_manager.dart';
// import '../../../utils/tpo_info_manager.dart';
// import '../Login/login_bloc.dart';
// import 'splash_event.dart';
// import 'splash_state.dart';
//
// class SplashBloc extends Bloc<SplashEvent, SplashState> {
//   SplashBloc() : super(SplashInitial()) {
//     // Delay for splash animation
//     on<StartSplash>((event, emit) async {
//       await Future.delayed(const Duration(seconds: 2));
//       add(CheckAuthStatus()); // Trigger auth check after splash
//     });
//
//     // Check token and user type
//     on<CheckAuthStatus>((event, emit) async {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('auth_token');
//       final userData = prefs.getString('user_data');
//
//       if (token != null && token.isNotEmpty && userData != null) {
//         try {
//           final userMap = jsonDecode(userData);
//           final userType = userMap['user_type'];
//
//           if (userType == 5) {
//             // ✅ Load TPO data once
//             await UserInfoManager().loadUserDataOnce(getUserData);
//
//             final userId = prefs.getString('user_id') ?? '';
//             if (userId.isNotEmpty) {
//               CallIncomingWatcher.start(userId); // 👈 Listener start
//             }
//
//             emit(AuthenticatedTPO());
//           }
//
//          else if (userType == 7) {
//             await CompanyInfoManager().load();
//
//             // 🔹 SharedPrefs se user_id read
//             final userId = prefs.getString('user_id') ?? '';
//             if (userId.isNotEmpty) {
//               CallIncomingWatcher.start(userId); // 👈 Listener start
//             }
//
//
//             emit(AuthenticatedJob());
//           } else {
//             emit(Unauthenticated()); // unknown user_type
//           }
//         } catch (e) {
//           emit(Unauthenticated()); // error decoding
//         }
//       } else {
//         emit(Unauthenticated());
//       }
//     });
//   }
// }


import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../TPO/Model/tpo_home_job_model.dart';
import '../../../utils/company_info_manager.dart';
import '../../../utils/tpo_info_manager.dart';
import '../Login/login_bloc.dart';
import 'splash_event.dart';
import 'splash_state.dart';

// 👇 Ye import add karo (listener ke liye)
import '../../Calling/call_incoming_watcher.dart';

// class SplashBloc extends Bloc<SplashEvent, SplashState> {
//   SplashBloc() : super(SplashInitial()) {
//     // 🔹 Delay for splash animation
//     on<StartSplash>((event, emit) async {
//       await Future.delayed(const Duration(seconds: 2));
//       add(CheckAuthStatus()); // Trigger auth check after splash
//     });
//
//     // 🔹 Check token and user type
//     on<CheckAuthStatus>((event, emit) async {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('auth_token');
//       final userData = prefs.getString('user_data');
//
//       if (token != null && token.isNotEmpty && userData != null) {
//         try {
//           final userMap = jsonDecode(userData);
//           final userType = userMap['user_type'];
//
//           // ✅ TPO User
//           if (userType == 5) {
//             await UserInfoManager().loadUserDataOnce(getUserData);
//
//
//             final userId = prefs.getString('user_id') ?? '';
//             if (userId.isNotEmpty) {
//               CallIncomingWatcher.start(userId); // 👈 Listener start
//             }
//
//             emit(AuthenticatedTPO());
//           }
//
//           // ✅ HR User
//           else if (userType == 7) {
//             await CompanyInfoManager().load();
//
//             final userId = prefs.getString('user_id') ?? '';
//             if (userId.isNotEmpty) {
//               CallIncomingWatcher.start(userId); // 👈 Listener start
//             }
//
//             emit(AuthenticatedJob());
//           }
//
//           // ❌ Unknown user type
//           else {
//             emit(Unauthenticated());
//           }
//         } catch (e) {
//           emit(Unauthenticated()); // JSON parse ya koi aur error
//         }
//       } else {
//         emit(Unauthenticated()); // Token/userData missing
//       }
//     });
//   }
// }

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc() : super(SplashInitial()) {
    on<StartSplash>((event, emit) async {
      await Future.delayed(const Duration(seconds: 2));
      await _checkAuthAndEmit(emit);
    });
  }

  Future<void> _checkAuthAndEmit(Emitter<SplashState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userData = prefs.getString('user_data');

    if (token == null || token.isEmpty || userData == null) {
      emit(Unauthenticated());
      return;
    }

    try {
      final userMap = jsonDecode(userData);
      final userType = userMap['user_type'];

      if (userType == 5) { // TPO
        await UserInfoManager().loadUserDataOnce(getUserData);
        final userId = prefs.getString('user_id') ?? '';
        if (userId.isNotEmpty) CallIncomingWatcher.start(userId);
        emit(AuthenticatedTPO());
      } else if (userType == 4) { // Student
        final userId = prefs.getString('user_id') ?? '';
        if (userId.isNotEmpty) CallIncomingWatcher.start(userId);
        emit(AuthenticatedStudent());
      } else if (userType == 7) { // HR
        await CompanyInfoManager().load();
        final userId = prefs.getString('user_id') ?? '';
        if (userId.isNotEmpty) CallIncomingWatcher.start(userId);
        emit(AuthenticatedJob());
      } else {
        emit(Unauthenticated());
      }
    } catch (_) {
      emit(Unauthenticated());
    }
  }
}
