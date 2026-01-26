import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillsconnect/TPO/TPO_Home/tpo_home_bloc.dart';
import 'package:skillsconnect/TPO/TPO_Home/tpo_home_event.dart';
import '../../TPO/Screens/tpo_home_screen.dart';
import '../../student_app/student_root.dart';
import '../../utils/session_guard.dart';
import '../Calling/call_listener.dart';
import '../bloc/Job/job_bloc.dart';
import '../bloc/Job/job_event.dart';
import '../bloc/Splash/splash_bloc.dart';
import '../bloc/Splash/splash_event.dart';
import '../bloc/Splash/splash_state.dart';
import 'ForceUpdate/force_update.dart';
import 'login_screen.dart';
import 'bottom_nav_bar.dart';



/// -------- Developer Options guard (Flutter side) --------
const _devCh = MethodChannel('app.security.devoptions');
// TOP: imports ke niche hi yeh key add karo
const _kDevGateEnforceKey = 'dev_gate_enforce';
/// Build-time flag (can be overridden via --dart-define)
/// if true then show developer Option and false off developer optionc
const bool kEnforceDevGateDefault =
bool.fromEnvironment('ENFORCE_DEV_GATE', defaultValue: false);



Future<bool> _isDevOn() async {
  try {
    final v = await _devCh.invokeMethod<bool>('isDevOptionsEnabled');
    return v == true;
  } catch (_) {
    return false;
  }
}

Future<void> _openDevSettings() async {
  try { await _devCh.invokeMethod('openDevOptions'); } catch (_) {}
}

/// --------------------------------------------------------


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _devBlocked = false;
  Timer? _devPoll;
  // NEW: tester flag (default: true = enforce gate)
  bool _enforceDevGate = true;

  Future<void> _wipePendingOnSplash() async {
    try {
      // koi bhi latka hua OS popup ho to khatam
      await FlutterCallkitIncoming.endAllCalls();
    } catch (_) {}

    final p = await SharedPreferences.getInstance();
    await p.setBool('call_join_active', false); // UI locks off
    await p.remove('pending_join'); // stale join data
    await p.remove('pending_join_at'); // stale timestamp (agar use kar rahe ho)
  }

  @override
  void initState() {
    super.initState();
    // App launch होते ही sab stale pending ko saaf kar do
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _wipePendingOnSplash();
    });

    // 2) Start DevOptions check/poll
    _loadEnforceFlag().then((_) => _checkDevNow());

  }

  // NEW: load/save flag helpers
  Future<void> _loadEnforceFlag() async {
    final p = await SharedPreferences.getInstance();
    // default true = enforce
    final v = p.getBool(_kDevGateEnforceKey) ?? kEnforceDevGateDefault;
    if (mounted) setState(() => _enforceDevGate = v);
  }

  Future<void> _setEnforceFlag(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kDevGateEnforceKey, v);
    if (!mounted) return;
    setState(() => _enforceDevGate = v);
    // flag change par dobara check
    _checkDevNow();
  }


  Future<void> _checkDevNow() async {
    // ⚠️ Agar enforce OFF hai → kabhi block mat karo
    if (!_enforceDevGate) {
      if (!mounted) return;
      setState(() => _devBlocked = false);
      _devPoll?.cancel();
      return;
    }

    final on = await _isDevOn();
    if (!mounted) return;
    setState(() => _devBlocked = on);

    _devPoll?.cancel();
    // optional: jab tak ON hai, har 2s me re-check
    if (on) {
      _devPoll = Timer.periodic(const Duration(seconds: 2), (_) async {
        final again = await _isDevOn();
        if (!mounted) return;
        if (!again) {
          setState(() => _devBlocked = false);
          _devPoll?.cancel();
        }
      });
    }
  }


  /// Guarded navigate helper: dev ON hai to navigation block karo
  Future<bool> _devGateBeforeNavigate() async {

    // ⚠️ Enforce OFF → navigation allow
    if (!_enforceDevGate) return true;
    if (_devBlocked) {
      // optional toast/snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please turn off Developer Options to continue')),
      );
      return false;
    }
    // double-check just before navigating
    final on = await _isDevOn();
    if (on) {
      setState(() => _devBlocked = true);
      return false;
    }
    return true;
  }



  @override
  Widget build(BuildContext context) {

    // Agar Developer Options ON hai → blocking UI (no navigation)
    if (_enforceDevGate && _devBlocked) {
      return Scaffold(
        backgroundColor: Color(0xff003840), // Dim background
        body: SafeArea(
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFB3261E),
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Developer Options Enabled',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'For your security, this app cannot run while Developer Options or USB Debugging are enabled. Please disable them to continue.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _openDevSettings,
                        icon: const Icon(Icons.settings),
                        label: const Text('Open Developer Options'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xff005E6A),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => SystemNavigator.pop(),
                        child: const Text(
                          'Exit App',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return BlocProvider(
      create: (_) => SplashBloc()..add(StartSplash()),
      child: BlocListener<SplashBloc, SplashState>(
        listener: (context, state) async {
          await _wipePendingOnSplash(); // double-sure before we leave Splash
          // 👇 Add this here
          if (mounted) {
            await checkAndForceUpdate(context);
          }
          final p = await SharedPreferences.getInstance();

          final userId = p.getString('user_id') ?? '';
          print("⚠️ BG: =$userId");
          if (state is AuthenticatedJob) {
            SessionGuard.enable();   // 🔸 ab se scan kaam karega

            // Navigator.pushReplacement(
            //   context,
            //   MaterialPageRoute(
            //     builder: (_) => BlocProvider(
            //       create: (_) => JobBloc()..add(LoadJobsEvent()),
            //       child: const BottomNavBar(),
            //     ),
            //   ),
            // );
            // HR home
            if (!context.mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => CallListener(
                  // ⬅️ WRAP ONCE HERE
                  currentUserId: userId,
                  child: BlocProvider(
                    create: (_) => JobBloc()..add(LoadJobsEvent()),
                    child: const BottomNavBar(),
                  ),
                ),
              ),
              (_) => false,
            );
          } else if (state is AuthenticatedTPO) {
            SessionGuard.enable();   // 🔸 ab se scan kaam karega
            if (!context.mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => CallListener(
                  // ⬅️ WRAP ONCE HERE
                  currentUserId: userId,
                  child: BlocProvider(
                    create: (_) => TpoHomeBloc()..add(LoadTpoJobsEvent()),
                    child: const TpoHomeScreen(),
                  ),
                ),
              ),
              (_) => false,
            );
            // Navigator.pushReplacement(
            //   context,
            //   // MaterialPageRoute(builder: (_) =>  TpoHomeScreen()),
            //   MaterialPageRoute(
            //     builder: (_) => BlocProvider(
            //       create: (_) => TpoHomeBloc()..add(LoadTpoJobsEvent()),
            //       child: TpoHomeScreen(), // fixed here
            //     ),
            //   ),
            //
            // );
          } else if (state is AuthenticatedStudent) {
            SessionGuard.enable();   // 🔸 ab se scan kaam karega
            if (!context.mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => CallListener(
                  // ⬅️ WRAP ONCE HERE
                  currentUserId: userId,
                  child: const StudentRoot(),
                ),
              ),
              (_) => false,
            );
          } else if (state is Unauthenticated) {
            SessionGuard.disable();  // 🔸 unauth state me guard ko mute rakho
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => LoginScreen()),
            );
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xff003840),
          body: Stack(
            children: [
              // Positioned(
              //   left: 118,
              //   child: Image.asset(
              //     'assets/logo2.png',
              //     width: 250,
              //     height: 250,
              //   ),
              // ),
              Center(
                child: Image.asset('assets/logo.png', width: 200, height: 200),
              ),
            ],
          ),
        ),
      ),
    );
  }
}





























