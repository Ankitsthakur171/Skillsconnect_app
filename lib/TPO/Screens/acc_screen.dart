// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:skillsconnect/TPO/My_Account/api_services.dart';
// import 'package:skillsconnect/TPO/Screens/my_account.dart';
// import 'package:skillsconnect/TPO/Screens/tpo_custom_app_bar.dart';
// import 'package:skillsconnect/TPO/Screens/tpo_update_passwordscreen.dart';
// import 'package:skillsconnect/TPO/My_Account/my_account_bloc.dart';
// import 'package:skillsconnect/TPO/My_Account/my_account_event.dart';
// import 'package:skillsconnect/TPO/My_Account/my_account_state.dart';
// import '../../Constant/constants.dart';
// import '../../Error_Handler/app_error.dart';
// import '../../Error_Handler/oops_screen.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import '../../HR/Calling/call_incoming_watcher.dart';
// import 'package:http/http.dart' as http;
// import '../../HR/screens/login_screen.dart';
// import '../../utils/tpo_info_manager.dart';
// import '../TPO_Accounts/account_bloc.dart';
// import '../TPO_Accounts/account_event.dart';
// import '../TPO_Accounts/account_state.dart';
//
// class AccountScreen extends StatefulWidget {
//   const AccountScreen({super.key});
//
//   @override
//   State<AccountScreen> createState() => _AccountScreenState();
// }
//
// class _AccountScreenState extends State<AccountScreen> {
//   String? userImg;
//   String? role;
//   String? full_name;
//   String? college_name;
//
//   // ---- NEW: selection index (0 = “Edit Profile” already selected) ----
//   int selectedIndex = 0;
//   // cache keys
//   static const _kProfileName  = 'profile_name';
//   static const _kProfileRole  = 'profile_role';
//   static const _kProfileImage = 'profile_image';
//
//   @override
//   void initState() {
//     super.initState();
//     // loadUserData();
//     _loadCachedProfile();
//   }
//
//   Future<void> _loadCachedProfile() async {
//     final prefs = await SharedPreferences.getInstance();
//     if (!mounted) return;
//     setState(() {
//       full_name = prefs.getString(_kProfileName)  ?? full_name ?? '';
//       role      = prefs.getString(_kProfileRole)  ?? role      ?? '';
//       userImg   = prefs.getString(_kProfileImage) ?? userImg   ?? '';
//     });
//   }
//
//   Future<void> _saveProfileToCache({
//     required String name,
//     required String role,
//     required String image,
//   }) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(_kProfileName,  name);
//     await prefs.setString(_kProfileRole,  role);
//     await prefs.setString(_kProfileImage, image);
//   }
//
//
//   // Future<void> loadUserData() async {
//   //   final data = await getUserData();
//   //   setState(() {
//   //     userImg = data['user_image'];
//   //     role = data['role'];
//   //     full_name = data['full_name'];
//   //     college_name = data['college_name'];
//   //   });
//   // }
//
//   // Common confirm dialog function
//   Future<bool> _showConfirmDialog(BuildContext context, String message) async {
//     final result = await showDialog<bool>(
//       context: context,
//       barrierDismissible: false, // User must tap a button
//       builder: (context) {
//         return Dialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           elevation: 8,
//           backgroundColor: Colors.white,
//           child: Padding(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(Icons.help_outline, size: 48, color: Color(0xff005E6A)),
//                 const SizedBox(height: 16),
//                 Text(
//                   "Confirmation",
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black87,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 Text(
//                   message,
//                   textAlign: TextAlign.center,
//                   style: TextStyle(fontSize: 16, color: Colors.black54),
//                 ),
//                 const SizedBox(height: 24),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     Expanded(
//                       child: ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.red,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(30),
//                           ),
//                           padding: const EdgeInsets.symmetric(vertical: 12),
//                         ),
//                         onPressed: () => Navigator.pop(context, false),
//                         child: const Text(
//                           "No",
//                           style: TextStyle(color: Colors.white),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Color(0xff005E6A),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(30),
//                           ),
//                           padding: const EdgeInsets.symmetric(vertical: 12),
//                         ),
//                         onPressed: () => Navigator.pop(context, true),
//                         child: const Text(
//                           "Yes",
//                           style: TextStyle(color: Colors.white),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//     return result ?? false;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // return BlocProvider(
//     //   create: (_) => TpoAccountBloc()..add(LoadAccountEvent()),
//
//     return MultiBlocProvider(
//       providers: [
//         BlocProvider(create: (_) => TpoAccountBloc()..add(LoadAccountEvent())),
//         BlocProvider(
//           create: (_) =>
//           ProfileBloc(repository: Tpoprofile())..add(LoadProfile()),
//         ),
//       ],
//         child: Scaffold(
//         // ---------- Custom APP BAR ----------
//         appBar: const TpoCustomAppBar(),
//
//         // ---------- BODY ----------
//         body: SafeArea(
//           child: BlocBuilder<TpoAccountBloc, AccountState>(
//             builder: (context, state) {
//               if (state is! AccountLoaded) {
//                 // 🔥 check agar error state hai
//                 if (state is AccountError) {
//                   final failure = ApiHttpFailure(
//                     statusCode: state
//                         .code, // agar tumhare AccountError state me code field hai
//                     body: state.message,
//                   );
//                   return OopsPage(failure: failure);
//                 }
//
//                 return const Center(child: CircularProgressIndicator());
//               }
//
//               return Column(
//                 children: [
//                   const SizedBox(height: 16),
//                   // 🔽🔽🔽 Header ab ProfileBloc se bind (fallback tumhare local vars)
//                   BlocBuilder<ProfileBloc, ProfileState>(
//
//                     builder: (context, pstate) {
//                       String displayImg = userImg ?? '';
//                       String displayName = full_name ?? '';
//                       String displayRole = role ?? '';
//
//                       if (pstate is ProfileLoaded) {
//                         final u = pstate.user; // tumhare bloc me field 'user'
//                         displayImg = (u.imageUrl ?? '').toString();
//                         displayName = (u.fullname ?? '').toString();
//                         displayRole = (u.role ?? '').toString();
//
//                         // persist to SharedPreferences and also update local state
//                         WidgetsBinding.instance.addPostFrameCallback((_) {
//                           _saveProfileToCache(name: displayName, role: displayRole, image: displayImg);
//                           if (mounted) {
//                             setState(() {
//                               userImg   = displayImg;
//                               full_name = displayName;
//                               role      = displayRole;
//                             });
//                           }
//                         });
//
//                       }
//
//
//                       // ---- PROFILE AVATAR ----
//                   // Container(
//                   //   width: 90,
//                   //   height: 90,
//                   //   decoration: BoxDecoration(
//                   //     shape: BoxShape.circle,
//                   //     border: Border.all(color: const Color(0xff003840), width: 1),
//                   //   ),
//                   //   child: CircleAvatar(
//                   //     backgroundColor: Colors.grey.shade200,
//                   //     child: ClipOval(
//                   //       child: userImg != null && userImg!.isNotEmpty
//                   //           ? Image.network(userImg!, height: 80, width: 80, fit: BoxFit.cover)
//                   //           : const Icon(
//                   //         Icons.person,
//                   //         size: 40,
//                   //         color: Colors.grey,
//                   //       ),
//                   //     ),
//                   //   ),
//                   // ),
//                       return Column(
//                         children: [
//                   Container(
//                     width: 80,
//                     height: 80,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       border: Border.all(
//                         color: const Color(0xff003840),
//                         width: 2,
//                       ),
//                     ),
//                     child: ClipOval(
//                       child: (userImg != null && userImg!.isNotEmpty)
//                           ? (userImg!.toLowerCase().endsWith(".svg")
//                                 ? SvgPicture.network(
//                                     userImg!,
//                                     width: 80,
//                                     height: 80,
//                                     fit: BoxFit.cover,
//                                     placeholderBuilder: (_) => Container(
//                                       color: Colors.grey.shade200,
//                                       child: const Icon(
//                                         Icons.person,
//                                         color: Colors.grey,
//                                       ),
//                                     ),
//                                   )
//                                 : Image.network(
//                                     userImg!,
//                                     width: 80,
//                                     height: 80,
//                                     fit: BoxFit.cover,
//                                     errorBuilder: (_, __, ___) => Image.asset(
//                                       'assets/placeholder.png',
//                                       fit: BoxFit.cover,
//                                       width: 80,
//                                       height: 80,
//                                     ),
//                                   ))
//                           : Image.asset(
//                               'assets/placeholder.png',
//                               fit: BoxFit.cover,
//                               width: 80,
//                               height: 80,
//                             ),
//                     ),
//                   ),
//
//                   const SizedBox(height: 10),
//                   Text(
//                     full_name ?? 'Na',
//                     style: const TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xff003840),
//                     ),
//                   ),
//                   Text(
//                     (college_name != null && college_name!.isNotEmpty)
//                         ? college_name!
//                         : 'College Name',
//                     style: const TextStyle(
//                       color: Color(0xff707070),
//                       fontFamily: "Inter",
//                       fontSize: 16,
//                     ),
//                   ),
//
//                   Text(
//                     role ?? 'na',
//                     style: const TextStyle(color: Colors.grey),
//                       ),
//                       ),
//                       ],
//                       );
//                     },
//                   ),
//                   // 🔼🔼🔼 Header end
//                   const SizedBox(height: 5),
//                   const Divider(color: Color(0x3080AFB4), thickness: 2),
//                   const SizedBox(height: 20),
//
//                   // ---- OPTION LIST ----
//                   Expanded(
//                     child: ListView(
//                       children: [
//                         // 0 ▸ Edit Profile — already selected
//                         AccountOptionTile(
//                           icon: Image.asset(
//                             'assets/account.png',
//                             height: 24,
//                             width: 24,
//                             color: selectedIndex == 0
//                                 ? Colors.white
//                                 : Colors.black,
//                           ),
//                           title: 'Edit Profile',
//                           selected: selectedIndex == 0,
//                           onTap: () async {
//                             setState(() => selectedIndex = 0);
//                             await showTpoEditDetailsFullSheet(
//                               context,
//                             ); // ⬅️ navigate नहीं, popup open
//                             setState(
//                               () {},
//                             ); // sheet बंद होने पर refresh (optional)
//                           },
//
//                           // onTap: () async {
//                           //   final confirmed = await _showConfirmDialog(
//                           //     context,
//                           //     "Are you sure you want to edit your profile?",
//                           //   );
//                           //   if (confirmed) {
//                           //     setState(() => selectedIndex = 0);
//                           //     await Navigator.push(
//                           //       context,
//                           //       MaterialPageRoute(builder: (_) => const ProfileScreen()),
//                           //     );
//                           //     setState(() {});
//                           //   }
//                           // },
//                         ),
//
//                         // 1 ▸ Change Password
//                         AccountOptionTile(
//                           icon: Image.asset(
//                             'assets/changepsswd.png',
//                             height: 20,
//                             width: 20,
//                             color: selectedIndex == 1
//                                 ? Colors.white
//                                 : Colors.black,
//                           ),
//                           title: 'Change Password',
//                           selected: selectedIndex == 1,
//                           onTap: () {
//                             setState(() => selectedIndex = 1);
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (_) => const TpoUpdatePasswordScreen(),
//                               ),
//                             );
//                           },
//
//                           //
//                           // onTap: () async {
//                           //   final confirmed = await _showConfirmDialog(
//                           //     context,
//                           //     "Are you sure you want to change your password?",
//                           //   );
//                           //   if (confirmed) {
//                           //     setState(() => selectedIndex = 1);
//                           //     Navigator.push(
//                           //       context,
//                           //       MaterialPageRoute(builder: (_) => const UpdatePasswordScreen()),
//                           //     );
//                           //   }
//                           // },
//                         ),
//                         //
//                         // // 2 ▸ Settings
//                         // AccountOptionTile(
//                         //   icon: Image.asset('assets/settings.png',
//                         //       height: 24, width: 24, color: selectedIndex == 2 ? Colors.white : Colors.black),
//                         //   title: 'Settings',
//                         //   selected: selectedIndex == 2,
//                         //   onTap: () {
//                         //     setState(() => selectedIndex = 2);
//                         //     // Settings screen navigation if any
//                         //     Navigator.push(
//                         //       context,
//                         //       MaterialPageRoute(builder: (_) => const SettingsPage()),
//                         //     );
//                         //   },
//                         // ),
//
//                         // 3 ▸ Logout
//                         AccountOptionTile(
//                           icon: Image.asset(
//                             'assets/logout.png',
//                             height: 24,
//                             width: 24,
//                             color: selectedIndex == 3
//                                 ? Colors.white
//                                 : Colors.black,
//                           ),
//                           title: 'Logout',
//                           selected: selectedIndex == 3,
//
//                           onTap: () async {
//                             final confirmed = await _showConfirmDialog(
//                               context,
//                               "Are you sure you want to logout?",
//                             );
//                             if (confirmed) {
//                               setState(() => selectedIndex = 3);
//
//                               final prefs =
//                                   await SharedPreferences.getInstance();
//                               final token = prefs.getString(
//                                 "auth_token",
//                               ); // 👈 token le aao
//
//                               try {
//                                 final response = await http.post(
//                                   Uri.parse(
//                                     "${BASE_URL}auth/logout",
//                                   ),
//                                   headers: {
//                                     "Content-Type": "application/json",
//                                     if (token != null)
//                                       "Authorization":
//                                           "Bearer $token", // 👈 token bhejo
//                                   },
//                                 );
//
//                                 if (response.statusCode == 200) {
//                                   print(
//                                     "✅ Logout successful: ${response.body}",
//                                   );
//                                 } else {
//                                   print(
//                                     "⚠️ Logout API failed: ${response.statusCode} ${response.body}",
//                                   );
//                                 }
//                               } catch (e) {
//                                 print("❌ Logout API error: $e");
//                               }
//
//                               // 🔴 API ke baad local data clear karo
//                               await prefs.clear();
//                               final p = await SharedPreferences.getInstance();
//                               await p.remove('pending_join');
//
//                               // 👇 Listener band karna zaroori hai logout ke time
//                               CallIncomingWatcher.stop();
//
//                               // 4) Clear local caches (prefs + in-memory)
//                               //    (a) App-wide user info cache
//                               try {
//                                 await UserInfoManager().clearOnLogout(); // <-- in-memory + its keys removed
//                               } catch (_) {}
//
//                               //    (b) Remove other app keys (use clear for a full reset)
//                               try {
//                                 await prefs.clear(); // nukes all stored keys including auth_token
//                               } catch (_) {}
//
//
//                               Navigator.of(context).pushAndRemoveUntil(
//                                 MaterialPageRoute(
//                                   builder: (_) => LoginScreen(),
//                                 ),
//                                 (route) => false,
//                               );
//                             }
//                           },
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               );
//             },
//           ),
//         ),
//       )
//     );
//   }
// }
//
// // ---------------------------------------------------------------
// //            AccountOptionTile  (with green‑selection)
// // ---------------------------------------------------------------
// class AccountOptionTile extends StatelessWidget {
//   final Widget icon;
//   final String title;
//   final VoidCallback onTap;
//   final bool selected;
//
//   const AccountOptionTile({
//     Key? key,
//     required this.icon,
//     required this.title,
//     required this.onTap,
//     this.selected = false,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     const green = Color(0xFF005E6A);
//
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//       decoration: BoxDecoration(
//         color: selected ? green : Colors.transparent,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: ListTile(
//         contentPadding: const EdgeInsets.symmetric(horizontal: 12),
//         leading: icon,
//         title: Text(
//           title,
//           style: TextStyle(
//             color: selected ? Colors.white : Color(0xFF445458),
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         onTap: onTap,
//       ),
//     );
//   }
// }

import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillsconnect/TPO/My_Account/api_services.dart';
import 'package:skillsconnect/TPO/Screens/my_account.dart';
import 'package:skillsconnect/TPO/Screens/tpo_custom_app_bar.dart';
import 'package:skillsconnect/TPO/Screens/tpo_update_passwordscreen.dart';
import 'package:skillsconnect/TPO/My_Account/my_account_bloc.dart';
import 'package:skillsconnect/TPO/My_Account/my_account_event.dart';
import 'package:skillsconnect/TPO/My_Account/my_account_state.dart';
import '../../Constant/constants.dart';
import '../../Error_Handler/app_error.dart';
import '../../Error_Handler/oops_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../HR/Calling/call_incoming_watcher.dart';
import 'package:http/http.dart' as http;
import '../../HR/screens/login_screen.dart';
import '../../utils/tpo_info_manager.dart';
import '../../utils/session_guard.dart';
import '../TPO_Accounts/account_bloc.dart';
import '../TPO_Accounts/account_event.dart';
import '../TPO_Accounts/account_state.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String? userImg;
  String? role;
  String? full_name;
  String? college_name;

  // UI selection (0 = Edit Profile)
  int selectedIndex = 0;

  // cache keys
  static const _kProfileName = 'profile_name';
  static const _kProfileRole = 'profile_role';
  static const _kProfileImage = 'profile_image';
  static const _kcollegeName = 'college_name';
  bool isLoggingOut = false; // ⬅️ Add this in your State if not already added


  @override
  void initState() {
    super.initState();
    _loadCachedProfile();
  }

  Future<void> _loadCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      full_name = prefs.getString(_kProfileName) ?? full_name ?? '';
      role = prefs.getString(_kProfileRole) ?? role ?? '';
      userImg = prefs.getString(_kProfileImage) ?? userImg ?? '';
      college_name = prefs.getString(_kcollegeName) ?? college_name ?? '';
    });
  }

  Future<void> _saveProfileToCache({
    required String name,
    required String role,
    required String image,
    required String college,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kProfileName, name);
    await prefs.setString(_kProfileRole, role);
    await prefs.setString(_kProfileImage, image);
    await prefs.setString(_kcollegeName, college);
  }

  // Common confirm dialog
  Future<bool> _showConfirmDialog(BuildContext context, String message) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.help_outline,
                  size: 48,
                  color: Color(0xff005E6A),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Confirmation",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text(
                          "No",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff005E6A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          "Yes",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => TpoAccountBloc()..add(LoadAccountEvent())),
        BlocProvider(
          create: (_) =>
              ProfileBloc(repository: Tpoprofile())..add(LoadProfile()),
        ),
      ],
      child: Scaffold(
        appBar: const TpoCustomAppBar(),

        body: SafeArea(
          child: BlocBuilder<TpoAccountBloc, AccountState>(
            builder: (context, state) {
              if (state is! AccountLoaded) {
                if (state is AccountError) {
                  final failure = ApiHttpFailure(
                    statusCode: state.code,
                    body: state.message,
                  );
                  return OopsPage(failure: failure);
                }
                return const Center(child: CircularProgressIndicator());
              }

              return Column(
                children: [
                  const SizedBox(height: 16),

                  // -------- Header (bloc + cache fallback) --------
                  BlocBuilder<ProfileBloc, ProfileState>(
                    builder: (context, pstate) {
                      String displayImg = userImg ?? '';
                      String displayName = full_name ?? '';
                      String displayRole = role ?? '';
                      String displayCollege = college_name ?? '';

                      if (pstate is ProfileLoaded) {
                        final u = pstate.user;
                        debugPrint(
                          "🟢 [ProfileLoaded] role from API = '${u.role}'",
                        );
                        debugPrint(
                          "🟢 [ProfileLoaded] name='${u.name}', image='${u.imageUrl}', college='${u.collegename}'",
                        );
                        displayImg = (u.imageUrl ?? '').toString();
                        displayName = (u.name ?? '').toString();
                        displayRole = (u.role ?? '').toString();
                        displayCollege = (u.collegename ?? '').toString();

                        // Persist + local setState after frame (no build-loop)
                        WidgetsBinding.instance.addPostFrameCallback((_) async {
                          await _saveProfileToCache(
                            name: displayName,
                            role: displayRole,
                            image: displayImg,
                            college: displayCollege,
                          );
                          if (!mounted) return;
                          setState(() {
                            userImg = displayImg;
                            full_name = displayName;
                            role = displayRole;
                          });
                          debugPrint("💾 [Saved to prefs] role='${u.role}'");
                        });
                      }

                      return Column(
                        children: [
                          // Avatar
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xff003840),
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: (userImg != null && userImg!.isNotEmpty)
                                  ? (userImg!.toLowerCase().endsWith(".svg")
                                        ? SvgPicture.network(
                                            userImg!,
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                            placeholderBuilder: (_) =>
                                                Image.asset(
                                                  'assets/placeholder.png',
                                                  fit: BoxFit.cover,
                                                  width: 80,
                                                  height: 80,
                                                ),
                                          )
                                        : Image.network(
                                            userImg!,
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Image.asset(
                                                  'assets/placeholder.png',
                                                  fit: BoxFit.cover,
                                                  width: 80,
                                                  height: 80,
                                                ),
                                          ))
                                  : Image.asset(
                                      'assets/placeholder.png',
                                      fit: BoxFit.cover,
                                      width: 80,
                                      height: 80,
                                    ),
                            ),
                          ),

                          const SizedBox(height: 10),
                          // Name
                          Text(
                            full_name ?? 'Na',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff003840),
                            ),
                          ),
                          // College
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ), // 👈 left-right padding
                            child: Center(
                              child: Text(
                                (college_name != null &&
                                        college_name!.isNotEmpty)
                                    ? college_name!
                                    : 'College Name',
                                textAlign:
                                    TextAlign.center, // center align text
                                maxLines: 3, // limit to 3 lines
                                overflow: TextOverflow
                                    .ellipsis, // show ... if text overflows
                                style: const TextStyle(
                                  color: Color(0xff707070),
                                  fontFamily: "Inter",
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 4),
                          // Role
                          Text(
                            role ?? 'na',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 5),
                  const Divider(color: Color(0x3080AFB4), thickness: 2),
                  const SizedBox(height: 20),

                  // -------- Options --------
                  Expanded(
                    child: ListView(
                      children: [
                        // 0: Edit Profile (bottom sheet)
                        AccountOptionTile(
                          icon: Image.asset(
                            'assets/account.png',
                            height: 24,
                            width: 24,
                            color: selectedIndex == 0
                                ? Colors.white
                                : Colors.black,
                          ),
                          title: 'Edit Profile',
                          selected: selectedIndex == 0,
                          onTap: () async {
                            setState(() => selectedIndex = 0);
                            await showTpoEditDetailsFullSheet(
                              context,
                            ); // void, just await

                            // sheet band: prefs se instantly UI refresh
                            final prefs = await SharedPreferences.getInstance();
                            if (!mounted) return;
                            setState(() {
                              full_name =
                                  prefs.getString(_kProfileName) ??
                                  full_name ??
                                  '';
                              role =
                                  prefs.getString(_kProfileRole) ?? role ?? '';
                              userImg =
                                  prefs.getString(_kProfileImage) ??
                                  userImg ??
                                  '';
                            });

                            if (mounted) {
                              context.read<ProfileBloc>().add(
                                LoadProfile(),
                              ); // optional fresh pull
                            }
                          },
                        ),

                        // 1: Change Password
                        AccountOptionTile(
                          icon: Image.asset(
                            'assets/changepsswd.png',
                            height: 20,
                            width: 20,
                            color: selectedIndex == 1
                                ? Colors.white
                                : Colors.black,
                          ),
                          title: 'Change Password',
                          selected: selectedIndex == 1,
                          onTap: () {
                            setState(() => selectedIndex = 1);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TpoUpdatePasswordScreen(),
                              ),
                            );
                          },
                        ),

                        // 2: Logout
                        AccountOptionTile(
                          icon: Image.asset(
                            'assets/logout.png',
                            height: 24,
                            width: 24,
                            color: selectedIndex == 3 ? Colors.white : Colors.black,
                          ),
                          title: 'Logout',
                          selected: selectedIndex == 3,
                          onTap: () async {
                            if (isLoggingOut) return; // 🔒 double-tap stop

                            final confirmed = await _showConfirmDialog(
                              context,
                              "Are you sure you want to logout?",
                            );
                            if (confirmed != true) return;

                            setState(() {
                              selectedIndex = 3;
                              isLoggingOut = true; // 🔐 lock logout
                            });

                            // 🔥 Non-closable loader dialog
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xff003840),)),
                            );

                            final prefs = await SharedPreferences.getInstance();
                            final token = prefs.getString("auth_token");

                            // 🚀 FCM token detach
                            try {
                              if (token != null && token.isNotEmpty) {
                                await http.post(
                                  Uri.parse('${BASE_URL}common/update-fcm-token'),
                                  headers: {
                                    'Content-Type': 'application/json',
                                    'Authorization': 'Bearer $token',
                                  },
                                  body: jsonEncode({'fcmToken': ''}),
                                );
                              }
                            } catch (_) {}
                            try {
                              await FirebaseMessaging.instance.deleteToken();
                            } catch (_) {}

                            // 🚀 Logout API
                            try {
                              final response = await http.post(
                                Uri.parse("${BASE_URL}auth/logout"),
                                headers: {
                                  "Content-Type": "application/json",
                                  if (token != null) "Authorization": "Bearer $token",
                                },
                              );
                              debugPrint("Logout => ${response.statusCode}  ${response.body}");
                            } catch (e) {
                              debugPrint("Logout API error: $e");
                            }

                            // 🚀 Cleanup
                            CallIncomingWatcher.stop();

                            try {
                              await UserInfoManager().clearOnLogout();
                            } catch (_) {}
                            try {
                              await prefs.remove('pending_join');
                            } catch (_) {}
                            try {
                              await prefs.clear();
                            } catch (_) {}

                            // Disable global 401 guard after logout
                            SessionGuard.disable();

                            if (Navigator.canPop(context)) {
                              Navigator.pop(context); // close loader
                            }

                            if (!mounted) return;

                            setState(() => isLoggingOut = false);

                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => LoginScreen()),
                                  (route) => false,
                            );
                          },
                        ),

                        // AccountOptionTile(
                        //   icon: Image.asset(
                        //     'assets/logout.png',
                        //     height: 24,
                        //     width: 24,
                        //     color: selectedIndex == 3
                        //         ? Colors.white
                        //         : Colors.black,
                        //   ),
                        //   title: 'Logout',
                        //   selected: selectedIndex == 3,
                        //   onTap: () async {
                        //     final confirmed = await _showConfirmDialog(
                        //       context,
                        //       "Are you sure you want to logout?",
                        //     );
                        //     if (confirmed != true) return;
                        //
                        //     setState(() => selectedIndex = 3);
                        //
                        //     final prefs = await SharedPreferences.getInstance();
                        //     final token = prefs.getString("auth_token");
                        //
                        //     // ✅ Multi-login fix: logout par FCM token ko old user se detach karo.
                        //     // (Same device token -> old account ko call bhejne par bhi is phone par popup aa jata tha.)
                        //     try {
                        //       if (token != null && token.isNotEmpty) {
                        //         await http.post(
                        //           Uri.parse('${BASE_URL}common/update-fcm-token'),
                        //           headers: {
                        //             'Content-Type': 'application/json',
                        //             'Authorization': 'Bearer $token',
                        //           },
                        //           body: jsonEncode({'fcmToken': ''}),
                        //         );
                        //       }
                        //     } catch (_) {}
                        //     try { await FirebaseMessaging.instance.deleteToken(); } catch (_) {}
                        //
                        //     try {
                        //       final response = await http.post(
                        //         Uri.parse("${BASE_URL}auth/logout"),
                        //         headers: {
                        //           "Content-Type": "application/json",
                        //           if (token != null)
                        //             "Authorization": "Bearer $token",
                        //         },
                        //       );
                        //       if (response.statusCode == 200) {
                        //         debugPrint(
                        //           "✅ Logout successful: ${response.body}",
                        //         );
                        //       } else {
                        //         debugPrint(
                        //           "⚠️ Logout API failed: ${response.statusCode} ${response.body}",
                        //         );
                        //       }
                        //     } catch (e) {
                        //       debugPrint("❌ Logout API error: $e");
                        //     }
                        //
                        //     // stop incoming watcher
                        //     CallIncomingWatcher.stop();
                        //
                        //     // clear in-memory user info + prefs
                        //     try {
                        //       await UserInfoManager().clearOnLogout();
                        //     } catch (_) {}
                        //     try {
                        //       await prefs.remove('pending_join');
                        //     } catch (_) {}
                        //     try {
                        //       await prefs.clear();
                        //     } catch (_) {}
                        //
                        //     if (!mounted) return;
                        //     Navigator.of(context).pushAndRemoveUntil(
                        //       MaterialPageRoute(builder: (_) => LoginScreen()),
                        //       (route) => false,
                        //     );
                        //   },
                        // ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------
//            AccountOptionTile (with green selection)
// ---------------------------------------------------------------
class AccountOptionTile extends StatelessWidget {
  final Widget icon;
  final String title;
  final VoidCallback onTap;
  final bool selected;

  const AccountOptionTile({
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.selected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF005E6A);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? green : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: icon,
        title: Text(
          title,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF445458),
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
