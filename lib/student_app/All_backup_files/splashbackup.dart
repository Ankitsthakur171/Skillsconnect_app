// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:sk_loginscreen1/blocpage/bloc_event.dart';
// import 'package:sk_loginscreen1/blocpage/bloc_logic.dart';
// import 'package:jwt_decode/jwt_decode.dart';
//
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});
//
//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen>
//     with SingleTickerProviderStateMixin {
//   final bool _internetToastShown = false;
//   bool _snackBarShown = false;
//
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//   late Animation<Offset> _slideAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 800),
//     );
//     _fadeAnimation =
//         CurvedAnimation(
//             parent: _animationController, curve: Curves.easeIn
//         );
//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 0.05),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeOut,
//     ));
//
//     Future.delayed(const Duration(milliseconds: 300), () {
//       if (mounted) _animationController.forward();
//     });
//
//     WidgetsBinding.instance.addPostFrameCallback((_) => checkLoginStatus());
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }
//
//   Future<bool> _hasInternetConnection() async {
//     try {
//       final result = await InternetAddress.lookup('google.com');
//       return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
//     } catch (_) {
//       return false;
//     }
//   }
//
//   void _showSnackBarOnce(BuildContext context, String message,
//       {int cooldownSeconds = 3}) {
//     if (_snackBarShown) return;
//     _snackBarShown = true;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//         duration: Duration(seconds: cooldownSeconds),
//       ),
//     );
//     Future.delayed(Duration(seconds: cooldownSeconds), () {
//       _snackBarShown = false;
//     });
//   }
//
//   Future<void> checkLoginStatus() async {
//     await Future.delayed(const Duration(seconds: 2));
//
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('auth_token');
//
//     if (!mounted) return;
//
//     if (_hasInternetConnection == false) {
//       context.read<NavigationBloc>().add(SplashToLogin());
//       _showSnackBarOnce(context, "No internet, Please login again");
//       return;
//     }
//
//     if (token == null || token.isEmpty || token.trim().isEmpty) {
//       context.read<NavigationBloc>().add(SplashToLogin());
//       return;
//     }
//
//     try {
//       if (!token.contains('.') || token.split('.').length != 3) {
//         if (kDebugMode) {
//           print("Invalid JWT format");
//         }
//         await prefs.remove('auth_token');
//         context.read<NavigationBloc>().add(SplashToLogin());
//         return;
//       }
//
//       if (Jwt.isExpired(token)) {
//         print("Token expired");
//         await prefs.remove('auth_token');
//         context.read<NavigationBloc>().add(SplashToLogin());
//         return;
//       }
//       context.read<NavigationBloc>().add(GotoHomeScreen2());
//     } catch (e) {
//       print("Token validation error: $e");
//       await prefs.remove('auth_token');
//       context.read<NavigationBloc>().add(SplashToLogin());
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF003840),
//       body: Stack(
//         children: [
//           Positioned(
//             top: 0,
//             right: 0,
//             left: 100,
//             child: FadeTransition(
//               opacity: _fadeAnimation,
//               child: SlideTransition(
//                 position: _slideAnimation,
//                 child: SvgPicture.asset(
//                   'assets/design.svg',
//                   height: 370,
//                   width: 288,
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             ),
//           ),
//           Center(
//             child: FadeTransition(
//               opacity: _fadeAnimation,
//               child: SlideTransition(
//                 position: _slideAnimation,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const SizedBox(height: 10),
//                     SvgPicture.asset("assets/Logo.svg",
//                         width: 193, height: 64, fit: BoxFit.contain),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }