// // contact_screen.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../Calling/call_service.dart';
// import '../bloc/Contacts_page/contact_bloc.dart';
// import '../bloc/Contacts_page/contact_state.dart';
// import '../bloc/Contacts_page/contact_event.dart';
// import '../model/contact_model.dart';
// import 'custom_app_bar.dart';
//
// class ContactScreen extends StatefulWidget {
//   const ContactScreen({super.key});
//
//   @override
//   State<ContactScreen> createState() => _ContactState();
// }
//
// class _ContactState extends State<ContactScreen> {
//   String companyName = '';
//   String companyLogo = '';
//   final ScrollController _scrollController = ScrollController();
//   int currentPage = 1;
//   final int limit = 30;
//
//   @override
//   void initState() {
//     super.initState();
//     loadCompanyName();
//
//     // pehle 10 load karo
//     context.read<ContactBloc>().add(LoadContacts(page: currentPage, limit: limit));
//
//     _scrollController.addListener(() {
//       if (_scrollController.position.pixels >=
//           _scrollController.position.maxScrollExtent - 200) {
//         final state = context.read<ContactBloc>().state;
//         if (state is ContactLoaded && state.hasMore) {
//           currentPage++;
//           context.read<ContactBloc>().add(LoadContacts(page: currentPage, limit: limit));
//         }
//       }
//     });
//   }
//
//   Future<void> loadCompanyName() async {
//     final prefs = await SharedPreferences.getInstance();
//     final name = prefs.getString('company_name') ?? '';
//     final logoUrl = prefs.getString('company_logo');
//     setState(() {
//       companyName = name;
//       companyLogo = logoUrl ?? '';
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5FDFD),
//       appBar: const CustomAppBar(),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
//             child: TextField(
//               decoration: InputDecoration(
//                 prefixIcon: const Icon(Icons.search),
//                 hintText: 'Search Contacts',
//                 filled: true,
//                 fillColor: Colors.white,
//                 contentPadding: const EdgeInsets.symmetric(vertical: 14),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(30),
//                   borderSide: const BorderSide(color: Colors.black38),
//                 ),
//                 enabledBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(30),
//                   borderSide: const BorderSide(color: Color(0xff003840)),
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(30),
//                   borderSide: const BorderSide(color: Color(0xff003840), width: 2),
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 10),
//           Expanded(
//             child: BlocBuilder<ContactBloc, ContactState>(
//               builder: (context, state) {
//                 if (state is ContactLoading && currentPage == 1) {
//                   return const Center(child: CircularProgressIndicator());
//                 } else if (state is ContactLoaded) {
//                   return ListView.builder(
//                     controller: _scrollController,
//                     itemCount: state.contacts.length + 1,
//                     itemBuilder: (context, index) {
//                       if (index < state.contacts.length) {
//                         return ContactTile(contact: state.contacts[index]);
//                       } else {
//                         return state.hasMore
//                             ? const Padding(
//                           padding: EdgeInsets.all(8.0),
//                           child: Center(child: CircularProgressIndicator()),
//                         )
//                             : const SizedBox();
//                       }
//                     },
//                   );
//                 } else if (state is ContactError) {
//                   return Center(child: Text(state.message));
//                 }
//                 return const Center(child: CircularProgressIndicator());
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class ContactTile extends StatelessWidget {
//   final Contact contact;
//   const ContactTile({super.key, required this.contact});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//       padding: const EdgeInsets.all(10),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 48,
//             height: 48,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               border: Border.all(color: Color(0xFF003840), width: 2),
//             ),
//             child: CircleAvatar(
//               radius: 22,
//               backgroundColor: Colors.transparent,
//             ),
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   contact.calleeName,
//                   style: const TextStyle(
//                       fontWeight: FontWeight.bold, color: Color(0xff003840)),
//                 ),
//                 Row(
//                   children: [
//                     Icon(
//                       // Conditional icon based on call type
//                       contact.callType == "incoming"
//                           ? Icons.call_received // outgoing call
//                           : contact.callType == "outgoing"
//                           ? Icons.call_made   // incoming call
//                           : Icons.call_missed,    // missed call
//                       size: 16,
//                       color: contact.callType == "missed" ? Colors.red : Colors.grey,
//                     ),
//                     const SizedBox(width: 4),
//                     Text(contact.formattedInitiatedAt,
//                         style: const TextStyle(fontSize: 12, color: Colors.grey)),
//                   ],
//                 ),
//                 // Row(
//                 //   children: [
//                 //     const Icon(Icons.arrow_outward_outlined,
//                 //         size: 12, color: Colors.grey),
//                 //     const SizedBox(width: 2),
//                 //     const SizedBox(width: 50),
//                 //     Text(contact.formattedInitiatedAt,
//                 //         style:
//                 //         const TextStyle(fontSize: 12, color: Colors.grey)),
//                 //   ],
//                 // )
//               ],
//             ),
//           ),
//           InkWell(
//             onTap: () async {
//               await CallService.startCall(
//
//                 context: context,
//                 callerId: contact.callerId.toString() ,        // ✅ TPO ka ID
//                 callerName: contact.callerName.toString(),   // ✅ TPO ka Name
//                 receiverId: contact.calleeId.toString(),       // ✅ HR ka ID
//                 receiverName: contact.calleeName,   // ✅ HR ka Name
//               );
//             },
//             child: Image.asset(
//               'assets/phone.png',
//               height: 24,
//               width: 24,
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }

// contact_screen.dart


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../Error_Handler/app_error.dart';
import '../../Error_Handler/oops_screen.dart';
import '../../Error_Handler/subscription_expired_screen.dart';
import '../Calling/call_provider.dart';
import '../Calling/call_service.dart';
import '../bloc/Contacts_page/contact_bloc.dart';
import '../bloc/Contacts_page/contact_state.dart';
import '../bloc/Contacts_page/contact_event.dart';
import '../model/contact_model.dart';
import 'ForceUpdate/Forcelogout.dart';
import 'custom_app_bar.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactState();
}

class _ContactState extends State<ContactScreen> {
  String companyName = '';
  String companyLogo = '';
  final ScrollController _scrollController = ScrollController();

  int currentPage = 1;
  final int perPage = 10; // ✅ har baar 10 record load karenge
  bool _isAnyCalling = false; // 👈 yeh flag sab call buttons ko manage karega

  String searchQuery = ''; // 👈 search ke liye

  @override
  void initState() {
    super.initState();
    loadCompanyName();

    // Page 1 load
    context.read<ContactBloc>().add(
      LoadContacts(page: currentPage, limit: perPage),
    );

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        final state = context.read<ContactBloc>().state;
        if (state is ContactLoaded && state.hasMore) {
          currentPage++;
          context.read<ContactBloc>().add(
            LoadContacts(page: currentPage, limit: perPage),
          );
        }
      }
    });
  }

  Future<void> loadCompanyName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('company_name') ?? '';
    final logoUrl = prefs.getString('company_logo');
    setState(() {
      companyName = name;
      companyLogo = logoUrl ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FDFD),
      appBar: const CustomAppBar(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search Contacts',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.black38),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Color(0xff003840)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(
                    color: Color(0xff003840),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: BlocBuilder<ContactBloc, ContactState>(
              builder: (context, state) {
                if (state is ContactLoading && currentPage == 1) {
                  return const _ContactSkeletonList();
                } else if (state is ContactError) {
                  print('🟠 Contacts Error Occurred!');
                  print('🔹 Status Code: ${state.statusCode}');
                  print('🔹 Message: ${state.message}');

                  int? extractedCode;
                  if (state.statusCode == null && state.message != null) {
                    final match = RegExp(
                      r'\b(\d{3})\b',
                    ).firstMatch(state.message!);
                    if (match != null) {
                      extractedCode = int.tryParse(match.group(1)!);
                      print(
                        '🧩 Extracted Status Code from message: $extractedCode',
                      );
                    }
                  }

                  final actualCode = state.statusCode ?? extractedCode;
                  print('✅ Final Status Code Used: $actualCode');

                  // 🔴 NEW: 401 → force logout
                  if (actualCode == 401) {
                    ForceLogout.run(context, message: 'You are currently logged in on another device. '
                        'Logging in here will log you out from the other device');
                    return const SizedBox.shrink(); // UI placeholder while navigating
                  }

                  // 🔴 NEW: 403 → force logout
                  if (actualCode == 403) {
                    ForceLogout.run(context, message: "session expired.");
                    return const SizedBox.shrink();
                  }

                  // 🔹 403 detect hone par direct subscription page
                  final isExpired403 = actualCode == 406;

                  if (isExpired403) {
                    print('⚠️ Subscription expired detected (403)');
                    return const SubscriptionExpiredScreen();
                  }

                  final failure = ApiHttpFailure(
                    statusCode: actualCode,
                    // ✅ yahan null mat do, actual code bhejo
                    body: state
                        .message, // ✅ body ke jagah message (agar class me message hai)
                  );

                  return OopsPage(failure: failure);
                }
                // else if (state is ContactError) {
                //   final failure = ApiHttpFailure(
                //     statusCode: null,   // abhi tumhare ContactError me code nahi hai
                //     body: state.message,
                //   );
                //   return OopsPage(failure: failure);
                // }
                else if (state is ContactLoaded) {
                  // 👇 Filter list based on search
                  final filteredContacts = state.contacts.where((c) {
                    return c.calleeName.toLowerCase().contains(searchQuery);
                  }).toList();

                  if (filteredContacts.isEmpty) {
                    return const Center(
                      child: Text(
                        "No Data Found",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff003840),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: filteredContacts.length + 1,
                    itemBuilder: (context, index) {
                      if (index < filteredContacts.length) {
                        return ContactTile(
                          contact: filteredContacts[index],
                          isAnyCalling: _isAnyCalling, // 👈 yeh bhejna hai
                          onCallStateChanged: (value) {
                            setState(
                              () => _isAnyCalling = value,
                            ); // 👈 update from child
                          },
                        );
                      } else {
                        return state.hasMore
                            ? const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : const SizedBox();
                      }
                    },
                  );
                } else if (state is ContactError) {
                  return Center(child: Text(state.message));
                }
                // return const Center(child: CircularProgressIndicator());
                return const _ContactSkeletonList();

              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactSkeletonList extends StatelessWidget {
  const _ContactSkeletonList({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 8),
        itemCount: 8, // 8 fake contacts
        itemBuilder: (context, index) => const _ContactSkeletonTile(),
      ),
    );
  }
}

class _ContactSkeletonTile extends StatelessWidget {
  const _ContactSkeletonTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 🟢 Avatar skeleton (same size as real)
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF003840),
                width: 2,
              ),
            ),
            child: const CircleAvatar(
              radius: 22,
              backgroundColor: Colors.transparent,
              child: Text(
                'A', // Skeletonizer is text ko grey block bana dega
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003840),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // 🟢 Name, belonging, time row skeletons
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // calleeName
                Text(
                  'Callee Name Placeholder',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xff003840),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),

                // calleeBelonging
                Text(
                  'Belonging / Company Placeholder',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: Color(0xff005E6A),
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),

                // call icon + time
                Row(
                  children: [
                    Icon(
                      Icons.call_made,
                      size: 16,
                      color: Colors.grey,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Just now',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 🟢 Call button skeleton (phone icon)
          const SizedBox(width: 8),
          SizedBox(
            height: 24,
            width: 24,
            child: Icon(
              Icons.phone,
              size: 20,
              color: Color(0xFF003840),
            ),
          ),
        ],
      ),
    );
  }
}

class ContactTile extends StatefulWidget {
  final Contact contact;
  final bool isAnyCalling; // 👈 new prop
  final ValueChanged<bool> onCallStateChanged; // 👈 callback

  const ContactTile({
    super.key,
    required this.contact,
    required this.isAnyCalling,
    required this.onCallStateChanged,
  });

  @override
  State<ContactTile> createState() => _ContactTileState();
}

class _ContactTileState extends State<ContactTile> {
  bool _isCalling = false;

  @override
  Widget build(BuildContext context) {
    final contact = widget.contact;

    final isButtonDisabled =
        _isCalling ||
        widget.isAnyCalling; // 👈 agar koi call chal rahi hai, sab disable

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF003840), width: 2),
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: Colors.transparent,
              child: Text(
                contact.calleeName.isNotEmpty
                    ? contact.calleeName[0].toUpperCase()
                    : '',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003840),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.calleeName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xff003840),
                    fontSize: 13,
                  ),
                ),
                Text(
                  contact.calleeBelonging,
                  style: const TextStyle(
                    fontWeight: FontWeight.w400,
                    color: Color(0xff005E6A),
                    fontSize: 14,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      contact.callType == "incoming"
                          ? Icons.call_received
                          : contact.callType == "outgoing"
                          ? Icons.call_made
                          : Icons.call_missed,
                      size: 16,
                      color: contact.callType == "missed"
                          ? Colors.red
                          : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      contact.formattedInitiatedAt,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 📞 Call Button
          InkWell(
            onTap: isButtonDisabled
                ? null
                : () async {
                    setState(() => _isCalling = true);
                    widget.onCallStateChanged(true); // 🔥 sab buttons disable

                    try {
                      await CallService.startCall(
                        context: context,
                        callerId: contact.callerId.toString(),
                        callerName: contact.callerName.toString(),
                        receiverId: contact.calleeId.toString(),
                        receiverName: contact.calleeName,
                      );
                    } catch (e) {
                      debugPrint("❌ Call start failed: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to start call'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    } finally {
                      setState(() => _isCalling = false);
                      widget.onCallStateChanged(
                        false,
                      ); // ✅ buttons enable again
                    }
                  },
            child: _isCalling
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Opacity(
                    opacity: isButtonDisabled ? 0.5 : 1, // 👈 visual feedback
                    child: Image.asset(
                      'assets/phone.png',
                      height: 24,
                      width: 24,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
