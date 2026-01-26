// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:skillsconnect/TPO/Model/tpo_contact_model.dart';
// import 'package:skillsconnect/TPO/Screens/tpo_custom_app_bar.dart';
// import 'package:skillsconnect/TPO/Tpo_Contact/tpo_contact_event.dart';
// import 'package:skillsconnect/TPO/Tpo_Contact/tpo_contact_state.dart';
// import '../../HR/Calling/call_service.dart';
// import '../../HR/bloc/Login/login_bloc.dart';
// import '../Tpo_Contact/tpo_contact_bloc.dart';
//
//
//
// class TpoContactScreen extends StatefulWidget {
//   const TpoContactScreen({super.key});
//
//   @override
//   State<TpoContactScreen> createState() => _ContactState();
// }
//
// class _ContactState  extends State<TpoContactScreen> {
//
//   String? userImg;
//   String? role;
//   String? full_name;
//   String? college_name;
//   final ScrollController _scrollController = ScrollController();
//   int currentPage = 1;
//   final int limit = 10;
//
//   @override
//   void initState() {
//     super.initState();
//     loadUserData();
//
//
//     context.read<TpoContactBloc>().add(TpoLoadContact(page: currentPage, limit: limit));
//
//     _scrollController.addListener(() {
//       if (_scrollController.position.pixels >=
//           _scrollController.position.maxScrollExtent - 200) {
//         final state = context.read<TpoContactBloc>().state;
//         if (state is ContactLoaded && state.hasMore) {
//           currentPage++;
//           context.read<TpoContactBloc>().add(TpoLoadContact(page: currentPage, limit: limit));
//         }
//       }
//     });
//   }
//
//
//   Future<void> loadUserData() async {
//     final data = await getUserData();
//     setState(() {
//       userImg  = data['user_img'];
//       role     = data['role'];
//       full_name= data['full_name'];
//       college_name = data['college_name'];
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5FDFD),
//       appBar: const TpoCustomAppBar(),
//
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
//           // Expanded(
//           //   child: BlocBuilder<TpoContactBloc, TpoContactState>(
//           //     builder: (context, state) {
//           //       if (state is ContactLoaded) {
//           //         return ListView.builder(
//           //           itemCount: state.contacts.length,
//           //           itemBuilder: (context, index) {
//           //             return ContactTile(tpocontact: state.contacts[index]);
//           //           },
//           //         );
//           //       }
//           //       return const Center(child: CircularProgressIndicator());
//           //     },
//           //   ),
//           // ),
//           Expanded(
//             child: BlocBuilder<TpoContactBloc, TpoContactState>(
//               builder: (context, state) {
//                 if (state is ContactLoading && currentPage == 1) {
//                   return const Center(child: CircularProgressIndicator());
//                 } else if (state is ContactLoaded) {
//                   return ListView.builder(
//                     controller: _scrollController,
//                     itemCount: state.contacts.length + 1,
//                     itemBuilder: (context, index) {
//                       if (index < state.contacts.length) {
//                         return ContactTile(tpocontact: state.contacts[index], );
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
//   final TpoContactModel tpocontact;
//
//   const ContactTile({super.key, required this.tpocontact});
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
//             width: 48, // radius 22 + border 2*2 + spacing
//             height: 48,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               border: Border.all(
//                 color: Color(0xFF003840), // your desired border color
//                 width: 2,
//               ),
//             ),
//             child: CircleAvatar(
//               radius: 22,
//               // backgroundImage: NetworkImage(contact.imageUrl),
//               backgroundColor: Colors.transparent,
//             ),
//           ),
//
//           const SizedBox(width: 10),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Text(contact.role, style: const TextStyle(fontSize: 12,color: Color(0xff003840))),
//                 Text(
//                   tpocontact.callerName,
//                   style: const TextStyle(fontWeight: FontWeight.bold,color: Color(0xff003840)),
//                 ),
//                 Row(
//                   children: [
//                     Icon(
//                       // Conditional icon based on call type
//                       tpocontact.callType == "incoming"
//                           ? Icons.call_received // outgoing call
//                           : tpocontact.callType == "outgoing"
//                           ? Icons.call_made   // incoming call
//                           : Icons.call_missed,    // missed call
//                       size: 16,
//                       color: tpocontact.callType == "missed" ? Colors.red : Colors.grey,
//                     ),
//                     const SizedBox(width: 4),
//                     Text(tpocontact.formattedInitiatedAt,
//                         style: const TextStyle(fontSize: 12, color: Colors.grey)),
//                   ],
//                 ),
//
//
//               ],
//             ),
//           ),
//
//           InkWell(
//             onTap: () async {
//               await CallService.startCall(
//
//                 context: context,
//                 callerId: tpocontact.calleeId.toString(),        // ✅ TPO ka ID
//                 callerName: tpocontact.calleeName,   // ✅ TPO ka Name
//                 receiverId: tpocontact.callerId.toString(),       // ✅ HR ka ID
//                 receiverName: tpocontact.callerName,   // ✅ HR ka Name
//               );
//             },
//             child: Image.asset(
//               'assets/phone.png',
//               height: 24,
//               width: 24,
//             ),
//           )
//
//         ],
//       ),
//     );
//   }
// }
//
//











import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillsconnect/TPO/Model/tpo_contact_model.dart';
import 'package:skillsconnect/TPO/Screens/tpo_custom_app_bar.dart';
import 'package:skillsconnect/TPO/Tpo_Contact/tpo_contact_event.dart';
import 'package:skillsconnect/TPO/Tpo_Contact/tpo_contact_state.dart';
import '../../Error_Handler/app_error.dart';
import '../../Error_Handler/oops_screen.dart';
import '../../HR/Calling/call_provider.dart';
import '../../HR/Calling/call_service.dart';
import '../../HR/bloc/Login/login_bloc.dart';
import '../../HR/screens/ForceUpdate/Forcelogout.dart';
import '../Tpo_Contact/tpo_contact_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';


class TpoContactScreen extends StatefulWidget {
  const TpoContactScreen({super.key});

  @override
  State<TpoContactScreen> createState() => _ContactState();
}

class _ContactState extends State<TpoContactScreen> {
  String? userImg;
  String? role;
  String? full_name;
  String? college_name;
  final ScrollController _scrollController = ScrollController();
  int currentPage = 1;
  final int limit = 10;

  String searchQuery = ""; // 👈 search ke liye

  @override
  void initState() {
    super.initState();
    loadUserData();

    context
        .read<TpoContactBloc>()
        .add(TpoLoadContact(page: currentPage, limit: limit));

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        final state = context.read<TpoContactBloc>().state;
        if (state is ContactLoaded && state.hasMore) {
          currentPage++;
          context
              .read<TpoContactBloc>()
              .add(TpoLoadContact(page: currentPage, limit: limit));
        }
      }
    });
  }

  Future<void> loadUserData() async {
    final data = await getUserData();
    setState(() {
      userImg = data['user_img'];
      role = data['role'];
      full_name = data['full_name'];
      college_name = data['college_name'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FDFD),
      appBar: const TpoCustomAppBar(),
      body: Column(
        children: [
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
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
                contentPadding:
                const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.black38),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide:
                  const BorderSide(color: Color(0xff003840)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(
                      color: Color(0xff003840), width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: BlocBuilder<TpoContactBloc, TpoContactState>(
              builder: (context, state) {

                // if (state is ContactLoading && currentPage == 1) {
                //   return const Center(
                //       child: CircularProgressIndicator());
                // }

                if ((state is ContactLoading && currentPage == 1) ||
                    state is ContactInitial) {
                  return const _ContactSkeletonList();
                }
                else if (state is ContactError) {
                  print("❌ ContactError: ${state.message}");

                  int? actualCode;

                  // 🔹 Try extracting status code (agar message me 3-digit code likha ho)
                  if (state.message.isNotEmpty) {
                    final match = RegExp(r'\b(\d{3})\b').firstMatch(state.message);
                    if (match != null) {
                      actualCode = int.tryParse(match.group(1)!);
                    }
                  }

                  final txt = state.message.toLowerCase();

                  // 🔴 401 → force logout
                  if (actualCode == 401 || txt.contains('you are currently logged')) {
                    ForceLogout.run(
                      context,
                      message:
                      'You are currently logged in on another device. Logging in here will log you out from the other device.',
                    );
                    return const SizedBox.shrink(); // logout nav handle karega
                  }

                  // 🔴 403 → force logout
                  if (actualCode == 403 || txt.contains('session expired')) {
                    ForceLogout.run(
                      context,
                      message: "Session expired.",
                    );
                    return const SizedBox.shrink();
                  }

                  final failure = ApiHttpFailure(
                    statusCode: null,   // abhi tumhare ContactError me code nahi hai
                    body: state.message,
                  );
                  return OopsPage(failure: failure);
                }
                else if (state is ContactLoaded) {
                  // 👇 Filter contacts by search
                  final filteredContacts = state.contacts.where((c) {
                    return c.callerName
                        .toLowerCase()
                        .contains(searchQuery);
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
                            tpocontact: filteredContacts[index]);
                      } else {
                        return state.hasMore
                            ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(
                              child:
                              CircularProgressIndicator()),
                        )
                            : const SizedBox();
                      }
                    },
                  );
                }
                return const Center(
                    child: CircularProgressIndicator());
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
          // 🟢 Avatar skeleton (image look)
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
              child: Text(
                'A', // bas placeholder, Skeletonizer ise grey block bana dega
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003840),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // 🟢 Text skeletons (name, belonging, time)
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // caller name
                Text(
                  'Caller Name Placeholder',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xff003840),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                // belonging
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
        ],
      ),
    );
  }
}


class ContactTile extends StatefulWidget {
  final TpoContactModel tpocontact;

  const ContactTile({super.key, required this.tpocontact});

  @override
  State<ContactTile> createState() => _ContactTileState();
}

class _ContactTileState extends State<ContactTile> {
  bool _isCalling = false;

  @override
  Widget build(BuildContext context) {
    final tpocontact = widget.tpocontact;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 🟢 Avatar
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
                tpocontact.callerName.isNotEmpty
                    ? tpocontact.callerName[0].toUpperCase()
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

          // 🟢 Caller Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tpocontact.callerName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color(0xff003840),
                      fontSize: 13),
                ),
                Text(
                  tpocontact.callerBelonging,
                  style: const TextStyle(
                      fontWeight: FontWeight.w400,
                      color: Color(0xff005E6A),
                      fontSize: 14),
                ),
                Row(
                  children: [
                    Icon(
                      tpocontact.callType == "incoming"
                          ? Icons.call_received
                          : tpocontact.callType == "outgoing"
                          ? Icons.call_made
                          : Icons.call_missed,
                      size: 16,
                      color: tpocontact.callType == "missed"
                          ? Colors.red
                          : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      tpocontact.formattedInitiatedAt,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 🟢 Call Button
          // InkWell(
          //   onTap: _isCalling
          //       ? null
          //       : () async {
          //     setState(() => _isCalling = true);
          //     try {
          //       await CallService.startCall(
          //         context: context,
          //         callerId: tpocontact.calleeId.toString(),
          //         callerName: tpocontact.calleeName,
          //         receiverId: tpocontact.callerId.toString(),
          //         receiverName: tpocontact.callerName,
          //       );
          //     } catch (e) {
          //       debugPrint("❌ Call start failed: $e");
          //       ScaffoldMessenger.of(context).showSnackBar(
          //         const SnackBar(
          //           content: Text('Failed to start call'),
          //           backgroundColor: Colors.redAccent,
          //         ),
          //       );
          //     } finally {
          //       setState(() => _isCalling = false);
          //     }
          //   },
          //   child: _isCalling
          //       ? const SizedBox(
          //     height: 24,
          //     width: 24,
          //     child: CircularProgressIndicator(strokeWidth: 2),
          //   )
          //       : Image.asset(
          //     'assets/phone.png',
          //     height: 24,
          //     width: 24,
          //   ),
          // ),
        ],
      ),
    );
  }
}


