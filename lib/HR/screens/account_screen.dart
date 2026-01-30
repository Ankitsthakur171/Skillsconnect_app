import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillsconnect/HR/Screens/update_password_screen.dart';
import 'package:skillsconnect/HR/bloc/Account/account_block.dart';
import 'package:skillsconnect/HR/bloc/Account/account_event.dart';
import 'package:skillsconnect/HR/bloc/Account/account_state.dart';
import 'package:skillsconnect/HR/screens/company_profile_screen.dart';
import 'package:skillsconnect/HR/screens/custom_app_bar.dart';
import 'package:skillsconnect/HR/screens/my_account.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:skillsconnect/HR/screens/setting_screen.dart';
import '../../Constant/constants.dart';
import '../../Error_Handler/app_error.dart';
import '../../Error_Handler/oops_screen.dart';
import '../../Services/api_services.dart';
import '../../utils/company_service.dart';
import '../Calling/call_incoming_watcher.dart';
import '../bloc/Login/login_bloc.dart';
import '../bloc/My_Account/my_account_bloc.dart' show ProfileBloc;
import '../bloc/My_Account/my_account_event.dart' show LoadProfile;
import '../bloc/My_Account/my_account_state.dart';
import '../model/service_api_model.dart';
import '../widgets/account_option_tile.dart';
import 'package:http/http.dart' as http;
import 'EnterOtpScreen.dart';
import 'delete_account_page.dart';
import 'login_screen.dart';
import 'notification_screen.dart';

class HrAccountScreen extends StatefulWidget {
  const HrAccountScreen({super.key});

  @override
  State<HrAccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<HrAccountScreen> {

  String? userImg;
  String? role;
  String? full_name;
  String companyName = '';
  String companyLogo = '';
  int selectedIndex = 0;
  // cache keys
  static const _kProfileName  = 'profile_name';
  static const _kProfileRole  = 'profile_role';
  static const _kProfileImage = 'profile_image';
  bool isLoggingOut = false;


  @override
  void initState() {
    super.initState();
    // loadUserData();
    loadCompanyName();
    _initAsync();
    _loadCachedProfile();   // ⬅️ show cached name/role/image instantly (no flicker)

  }

  Future<void> _loadCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      full_name = prefs.getString(_kProfileName)  ?? full_name ?? '';
      role      = prefs.getString(_kProfileRole)  ?? role      ?? '';
      userImg   = prefs.getString(_kProfileImage) ?? userImg   ?? '';
    });
  }

  Future<void> _saveProfileToCache({
    required String name,
    required String role,
    required String image,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kProfileName,  name);
    await prefs.setString(_kProfileRole,  role);
    await prefs.setString(_kProfileImage, image);
  }


  // Helper async function
  Future<void> _initAsync() async {
    await CompanyInfoService.refreshSilently();
  }

  // Future<void> loadUserData() async {
  //   final data = await getUserData();
  //   setState(() {
  //     userImg = data['user_image'];
  //     role = data['role'];
  //     full_name = data['full_name'];
  //   });
  // }

  Future<void> loadCompanyName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('company_name') ?? '';
    final logoUrl = prefs.getString('company_logo');
    setState(() {
      companyName = name;
      companyLogo = logoUrl ?? '';
    });
  }

  // Common confirm dialog function
  Future<bool> _showConfirmDialog(BuildContext context, String message) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must tap a button
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
                Icon(Icons.help_outline, size: 48, color: Color(0xff005E6A)),
                const SizedBox(height: 16),
                Text(
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
                  style: TextStyle(fontSize: 16, color: Colors.black54),
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
                          backgroundColor: Color(0xff005E6A),
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
    // return BlocProvider(
    //   create: (_) => AccountBloc()..add(HrAccountEvent()),

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AccountBloc()..add(HrAccountEvent())),
        BlocProvider(
          create: (_) =>
              ProfileBloc(repository: HrProfile())..add(LoadProfile()),
        ),
      ],

      child: Scaffold(
        appBar: const CustomAppBar(),
        body: SafeArea(
          child: BlocBuilder<AccountBloc, AccountState>(
            builder: (context, state) {
              if (state is! AccountLoaded) {
                // 🔥 check agar error state hai
                if (state is AccountError) {
                  final failure = ApiHttpFailure(
                    statusCode: state
                        .code, // agar tumhare AccountError state me code field hai
                    body: state.message,
                  );
                  return OopsPage(failure: failure);
                }

                return const Center(child: CircularProgressIndicator());
              }

              return Column(
                children: [
                  const SizedBox(height: 16),
                  // 🔽🔽🔽 Header ab ProfileBloc se bind (fallback tumhare local vars)
                  BlocBuilder<ProfileBloc, ProfileState>(

                    builder: (context, pstate) {
                      String displayImg = userImg ?? '';
                      String displayName = full_name ?? '';
                      String displayRole = role ?? '';

                      if (pstate is ProfileLoaded) {
                        final u = pstate.user; // tumhare bloc me field 'user'
                        displayImg = (u.imageUrl ?? '').toString();
                        displayName = (u.fullname ?? '').toString();
                        displayRole = (u.role ?? '').toString();

                        // persist to SharedPreferences and also update local state
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _saveProfileToCache(name: displayName, role: displayRole, image: displayImg);
                          if (mounted) {
                            setState(() {
                              userImg   = displayImg;
                              full_name = displayName;
                              role      = displayRole;
                            });
                          }
                        });
                      }

                      return Column(
                        children: [
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
                            child: CircleAvatar(
                              backgroundColor: Colors.grey.shade200,
                              child: (displayImg != null && displayImg!.isNotEmpty)
                                  ? (displayImg!.toLowerCase().endsWith(".svg")
                                        ? ClipOval(
                                            child: SvgPicture.network(
                                              displayImg,
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                              placeholderBuilder: (_) => Image.asset(
                                                'assets/placeholder.png',
                                                fit: BoxFit.cover,
                                                width: 80,
                                                height: 80,
                                              ),
                                            ),
                              )
                                        : ClipOval(
                                            child: Image.network(
                                              displayImg!,
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
                                            ),
                                          ))
                                  : ClipOval(
                                      child: Image.asset(
                                        'assets/placeholder.png',
                                        fit: BoxFit.cover,
                                        width: 80,
                                        height: 80,
                                      ),
                                    ),
                            ),
                          ),
                          // Container(
                          //   width: 80,
                          //   height: 80,
                          //   decoration: BoxDecoration(
                          //     shape: BoxShape.circle,
                          //     border: Border.all(color: const Color(0xff003840), width: 2),
                          //   ),
                          //   child: CircleAvatar(
                          //     backgroundColor: Colors.grey.shade200,
                          //     backgroundImage: (userImg != null && userImg!.isNotEmpty)
                          //         ? NetworkImage(userImg!)
                          //         : null,
                          //     child: (userImg == null || userImg!.isEmpty)
                          //         ? ClipOval(
                          //       child: Image.asset(
                          //         'assets/placeholder.png',
                          //         fit: BoxFit.cover,
                          //         width: 80,
                          //         height: 80,
                          //       ),
                          //     )
                          //         : null,
                          //   ),
                          // ),
                          const SizedBox(height: 10),
                          Text(
                            displayName ,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff003840),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16), // 👈 left-right padding
                            child: Center(
                              child: Text(
                                companyName.isNotEmpty ? companyName : 'Loading...',
                                textAlign: TextAlign.center, // 👈 center align
                                maxLines: 2, // 👈 limit to 2 lines
                                overflow: TextOverflow.ellipsis, // 👈 show "..." when overflow
                                style: const TextStyle(
                                  color: Color(0xff707070),
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 4,),
                          Text(
                            displayRole ?? '',
                            style: const TextStyle(
                              color: Color(0xff9AAFB3),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  // 🔼🔼🔼 Header end
                  const SizedBox(height: 5),
                  const Divider(color: Color.fromARGB(47, 21, 26, 27), thickness: 2),
                  // const SizedBox(height: 10),
                  // Option Tiles
                  Expanded(
                    child: ListView(
                      children: [
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

                          // onTap: () async {
                          //   setState(() => selectedIndex = 0);
                          //   await showEditProfileSheet(
                          //     context,
                          //   ); // 👈 direct bottom-sheet
                          //   setState(
                          //     () {},
                          //   ); // refresh after sheet closes (optional)
                          // },
                            onTap: () async {
                              setState(() => selectedIndex = 0);

                              await showEditProfileSheet(context); // void, just await

                              // Sheet/Screen SAVE par aapne prefs update kiye hon (or bloc emit)
                              final prefs = await SharedPreferences.getInstance();
                              setState(() {
                                full_name = prefs.getString('profile_name') ?? full_name ?? '';
                              });

                              if (mounted) {
                                context.read<ProfileBloc>().add(LoadProfile());
                              }
                            }
                        ),

                        AccountOptionTile(
                          icon: Image.asset(
                            'assets/estate.png',
                            height: 24,
                            width: 24,
                            color: selectedIndex == 1
                                ? Colors.white
                                : Colors.black,
                          ),
                          title: 'Company Detail',
                          selected: selectedIndex == 1,

                          onTap: () {
                            setState(() => selectedIndex = 1);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CompanyProfileScreen(),
                              ),
                            );
                          },
                        ),

                        AccountOptionTile(
                          icon: Image.asset(
                            'assets/changepsswd.png',
                            height: 20,
                            width: 20,
                            color: selectedIndex == 2
                                ? Colors.white
                                : Colors.black,
                          ),
                          title: 'Change Password',
                          selected: selectedIndex == 2,

                          // onTap: () async {
                          //   final confirmed = await _showConfirmDialog(
                          //     context,
                          //     "Are you sure you want to change your password?",
                          //   );
                          //   if (confirmed) {
                          //     setState(() => selectedIndex = 2);
                          //     Navigator.push(
                          //       context,
                          //       MaterialPageRoute(builder: (_) => const UpdatePasswordScreen()),
                          //     );
                          //   }
                          // },
                          onTap: () {
                            setState(() => selectedIndex = 2);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const UpdatePasswordScreen(),
                              ),
                            );
                          },
                        ),

                        AccountOptionTile(
                          icon: Image.asset(
                            'assets/settings.png',
                            height: 24,
                            width: 24,
                            color: selectedIndex == 3
                                ? Colors.white
                                : Colors.black,
                          ),  
                          title: 'Settings',
                          selected: selectedIndex == 3,
                          onTap: () {
                            setState(() => selectedIndex = 3);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SettingsPage(),
                              ),
                            );
                          },
                        ),

                        AccountOptionTile(
                          icon: Image.asset(
                            'assets/logout.png',
                            height: 24,
                            width: 24,
                            color: selectedIndex == 4
                                ? Colors.white
                                : Colors.black,
                          ),
                          title: 'Delete Account',
                          selected: selectedIndex == 4,
                          onTap: () async {
                            setState(() => selectedIndex = 4);

                            final confirm = await _showConfirmDialog(
                              context,
                              'Are you sure you want to delete your account?\n\nYou will receive an OTP to verify this action.',
                            );
                            if (confirm != true) return;

                            // small loader dialog
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );

                            final res = await HrProfile.deleteAccountStep1();

                            if (!mounted) return;
                            Navigator.pop(context); 

                            if (res.ok) {
                              showSuccessSnackBar(context, res.message);
                              // ScaffoldMessenger.of(context).showSnackBar(
                              //   SnackBar(
                              //     content: Text(res.message),
                              //     backgroundColor: Colors.green,
                              //   ),
                              // );
                              // go to verify screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const DeleteAccountVerifyScreen(),
                                ),
                              );
                            } else {
                              showErrorSnackBar(context,res.message);
                              // ScaffoldMessenger.of(context).showSnackBar(
                              //   SnackBar(
                              //     content: Text(res.message),
                              //     backgroundColor: Colors.red,
                              //   ),
                              // );
                            }
                          },
                        ),

                        AccountOptionTile(
                          icon: Image.asset(
                            'assets/logout.png',
                            height: 24,
                            width: 24,
                            color: selectedIndex == 5 ? Colors.white : Colors.black,
                          ),
                          title: 'Logout',
                          selected: selectedIndex == 5,
                          onTap: () async {

                            if (isLoggingOut) return; // 🔒 double-tap safety

                            final confirmed = await _showConfirmDialog(
                              context,
                              "Are you sure you want to logout?",
                            );
  
                            if (!confirmed) return;

                            setState(() {
                              selectedIndex = 5;
                              isLoggingOut = true; // 🔐 logout lock
                            });

                            // Loader dialog (can't close)
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xff003840),)),
                            );

                            final prefs = await SharedPreferences.getInstance();
                            final token = prefs.getString("auth_token");

                            // 🔵 Detach FCM token
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

                            // 🔵 Device FCM delete
                            try {
                              await FirebaseMessaging.instance.deleteToken();
                            } catch (_) {}

                            // 🔵 Logout API
                            try {
                              final response = await http.post(
                                Uri.parse("${BASE_URL}auth/logout"),
                                headers: {
                                  "Content-Type": "application/json",
                                  if (token != null) "Authorization": "Bearer $token",
                                },
                              );
                              print("Logout: ${response.statusCode}  ${response.body}");
                            } catch (e) {
                              print("Logout API error: $e");
                            }

                            // 🔵 Local cleanup
                            final p = await SharedPreferences.getInstance();
                            await p.remove('pending_join');
                            await prefs.clear();
                            CallIncomingWatcher.stop();

                            if (Navigator.canPop(context)) {
                              Navigator.pop(context); // close loader
                            }

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
                        //     color: selectedIndex == 5
                        //         ? Colors.white
                        //         : Colors.black,
                        //   ),
                        //   title: 'Logout',
                        //   selected: selectedIndex == 5,
                        //   onTap: () async {
                        //     final confirmed = await _showConfirmDialog(
                        //       context,
                        //       "Are you sure you want to logout?",
                        //     );
                        //     if (confirmed) {
                        //       setState(() => selectedIndex = 5);
                        //
                        //       final prefs =
                        //           await SharedPreferences.getInstance();
                        //       final token = prefs.getString(
                        //         "auth_token",
                        //       ); // 👈 token le aao
                        //       // ✅ Multi-login fix: logout par FCM token ko old user se detach karo.
                        //       // (Same device token -> old user ko call bhejne par bhi is device par popup aa jata tha.)
                        //       try {
                        //         if (token != null && token.isNotEmpty) {
                        //           await http.post(
                        //             Uri.parse('${BASE_URL}common/update-fcm-token'),
                        //             headers: {
                        //               'Content-Type': 'application/json',
                        //               'Authorization': 'Bearer $token',
                        //             },
                        //             body: jsonEncode({'fcmToken': ''}),
                        //           );
                        //         }
                        //       } catch (_) {}
                        //       try { await FirebaseMessaging.instance.deleteToken(); } catch (_) {}
                        //
                        //       try {
                        //         final response = await http.post(
                        //           Uri.parse("${BASE_URL}auth/logout"),
                        //           headers: {
                        //             "Content-Type": "application/json",
                        //             if (token != null)
                        //               "Authorization":
                        //                   "Bearer $token", // 👈 token bhejo
                        //           },
                        //         );
                        //
                        //         if (response.statusCode == 200) {
                        //           print(
                        //             "✅ Logout successful: ${response.body}",
                        //           );
                        //         } else {
                        //           print(
                        //             "⚠️ Logout API failed: ${response.statusCode} ${response.body}",
                        //           );
                        //         }
                        //       } catch (e) {
                        //         print("❌ Logout API error: $e");
                        //       }
                        //       final p = await SharedPreferences.getInstance();
                        //       await p.remove('pending_join');
                        //
                        //       // 🔴 API ke baad local data clear karo
                        //       await prefs.clear();
                        //
                        //       // 👇 Listener band karna zaroori hai logout ke time
                        //       CallIncomingWatcher.stop();
                        //
                        //       Navigator.of(context).pushAndRemoveUntil(
                        //         MaterialPageRoute(
                        //           builder: (_) => LoginScreen(),
                        //         ),
                        //         (route) => false,
                        //       );
                        //     }
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

void showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      backgroundColor: Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      duration: const Duration(seconds: 2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );
}


