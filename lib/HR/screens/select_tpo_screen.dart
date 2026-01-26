import 'package:flutter/material.dart';

import '../bloc/Login/login_bloc.dart';
import '../model/college_invitation_model.dart';
import '../Calling/call_service.dart';

class SelectTpoScreen extends StatefulWidget {
  final List<TpoUser> tpoUsers;

  const SelectTpoScreen({Key? key, required this.tpoUsers}) : super(key: key);

  @override
  State<SelectTpoScreen> createState() => _SelectTpoScreenState();
}

class _SelectTpoScreenState extends State<SelectTpoScreen> {
  String? Hrid ;
  String? Hrname ;
  final Set<String> _loadingTpoIds = {}; // jo-jo TPO load ho rahe hain unke id yahan




  @override
  void initState() {
    super.initState();
    loadUserData();
  }


  Future<void> loadUserData() async {
    final data = await getUserData();
    setState(() {
      Hrid  = data['id'].toString();
      Hrname  = data['full_name'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: getUserData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final Hrid = snapshot.data!['id'].toString();
        final Hrname = snapshot.data!['full_name'].toString();

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Color(0xff003840)),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Select TPO',
              style: TextStyle(color: Color(0xff003840)),
            ),
          ),      body: ListView.builder(
          itemCount: widget.tpoUsers.length,
          itemBuilder: (context, index) {
            final tpo = widget.tpoUsers[index];
            final isLoading = _loadingTpoIds.contains(tpo.id.toString());

            return Card(
              margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: Text(
                    (tpo.firstName != null && tpo.firstName!.isNotEmpty)
                        ? tpo.firstName![0].toUpperCase()
                        : "?",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(tpo.fullName ?? "${tpo.firstName ?? ''} ${tpo.lastName ?? ''}"),
                // subtitle: Text(tpo.email ?? "No Email"),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff005E6A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isLoading ? null : () async {
                    // ⏳ loader ON (sirf is TPO ke liye)
                    setState(() => _loadingTpoIds.add(tpo.id.toString()));

                    try {
                      // tumhara hi guard — bas loader off hone ka dhyaan
                      if (Hrid == null || Hrname == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("User data loading... Please wait")),
                        );
                        // loader OFF aur return
                        setState(() => _loadingTpoIds.remove(tpo.id.toString()));
                        return;
                      }

                      await CallService.startCall(
                        context: context,
                        callerId: Hrid!,            // (tumhare hi vars use kiye)
                        callerName: Hrname!,
                        receiverId: tpo.id.toString(),
                        receiverName: tpo.fullName.toString(),
                      );

                      print("📞 CallerId: $Hrid");
                      print("📞 CallerName: $Hrname");
                      print("🎯 ReceiverId: ${tpo.id}");
                      print("🎯 ReceiverName: ${tpo.fullName}");
                    } catch (e) {
                      debugPrint("❌ startCall error: $e");
                    } finally {
                      // ✅ loader OFF (chahe success ho ya error)
                      if (mounted) setState(() => _loadingTpoIds.remove(tpo.id.toString()));
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isLoading) ...[
                        const Icon(Icons.call, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        const Text("Call", style: TextStyle(color: Colors.white)),
                      ] else ...[
                        const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        const Text("Calling…", style: TextStyle(color: Colors.white)),
                      ],
                    ],
                  ),
                ),

                // trailing: ElevatedButton(
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: const Color(0xff005E6A),
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(12),
                //     ),
                //   ),
                //   onPressed: () async {
                //     if (Hrid == null || Hrname == null) {
                //       ScaffoldMessenger.of(context).showSnackBar(
                //         SnackBar(content: Text("User data loading... Please wait")),
                //       );
                //       return;
                //     }
                //
                //     await CallService.startCall(
                //       context: context,
                //       callerId: Hrid!,
                //       callerName: Hrname!,
                //       receiverId: tpo.id.toString(),
                //       receiverName: tpo.fullName.toString(),
                //     );
                //
                //     print("📞 CallerId: $Hrid");
                //     print("📞 CallerName: $Hrname");
                //     print("🎯 ReceiverId: ${tpo.id}");
                //     print("🎯 ReceiverName: ${tpo.fullName}");
                //   },
                //   child: Row(
                //     mainAxisSize: MainAxisSize.min,
                //     children: [
                //       Icon(Icons.call, color: Colors.white, size: 18),
                //       SizedBox(width: 6),
                //       Text("Call", style: TextStyle(color: Colors.white)),
                //     ],
                //   ),
                // ),
              ),
            );
          },
        ),
        );    },
    );
  }















  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       backgroundColor: Colors.white,
  //       leading: IconButton(
  //         icon: const Icon(Icons.arrow_back_ios, color: Color(0xff003840)),
  //         onPressed: () => Navigator.pop(context),
  //       ),
  //       title: const Text(
  //         'Select TPO',
  //         style: TextStyle(color: Color(0xff003840)),
  //       ),
  //     ),      body: ListView.builder(
  //       itemCount: widget.tpoUsers.length,
  //       itemBuilder: (context, index) {
  //         final tpo = widget.tpoUsers[index];
  //         return Card(
  //           margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //           child: ListTile(
  //             leading: CircleAvatar(
  //               backgroundColor: Colors.teal,
  //               child: Text(
  //                 (tpo.firstName != null && tpo.firstName!.isNotEmpty)
  //                     ? tpo.firstName![0].toUpperCase()
  //                     : "?",
  //                 style: TextStyle(color: Colors.white),
  //               ),
  //             ),
  //             title: Text(tpo.fullName ?? "${tpo.firstName ?? ''} ${tpo.lastName ?? ''}"),
  //             // subtitle: Text(tpo.email ?? "No Email"),
  //             trailing: ElevatedButton(
  //               style: ElevatedButton.styleFrom(
  //                 backgroundColor: const Color(0xff005E6A),
  //                 shape: RoundedRectangleBorder(
  //                   borderRadius: BorderRadius.circular(12),
  //                 ),
  //               ),
  //               onPressed: () async {
  //                 if (Hrid == null || Hrname == null) {
  //                   ScaffoldMessenger.of(context).showSnackBar(
  //                     SnackBar(content: Text("User data loading... Please wait")),
  //                   );
  //                   return;
  //                 }
  //
  //                 await CallService.startCall(
  //                   context: context,
  //                   callerId: Hrid!,
  //                   callerName: Hrname!,
  //                   receiverId: tpo.id.toString(),
  //                   receiverName: tpo.fullName.toString(),
  //                 );
  //
  //                 print("📞 CallerId: $Hrid");
  //                 print("📞 CallerName: $Hrname");
  //                 print("🎯 ReceiverId: ${tpo.id}");
  //                 print("🎯 ReceiverName: ${tpo.fullName}");
  //               },
  //               child: Row(
  //                 mainAxisSize: MainAxisSize.min,
  //                 children: [
  //                   Icon(Icons.call, color: Colors.white, size: 18),
  //                   SizedBox(width: 6),
  //                   Text("Call", style: TextStyle(color: Colors.white)),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         );
  //       },
  //     ),
  //   );
  // }
}







// import 'package:flutter/material.dart';
//
// import '../bloc/Login/login_bloc.dart';
// import '../model/college_invitation_model.dart';
// import '../Calling/call_service.dart';
//
// class SelectTpoScreen extends StatefulWidget {
//   final List<TpoUser> tpoUsers;
//
//   const SelectTpoScreen({Key? key, required this.tpoUsers}) : super(key: key);
//
//   @override
//   State<SelectTpoScreen> createState() => _SelectTpoScreenState();
// }
//
// class _SelectTpoScreenState extends State<SelectTpoScreen> {
//   bool isCalling = false; // agar call chal rahi hai to track karne ke liye
//   String? Hrid ;
//
//
//
//   @override
//   void initState() {
//     super.initState();
//     loadUserData();
//   }
//
//
//   Future<void> loadUserData() async {
//     final data = await getUserData();
//     setState(() {
//       Hrid  = data['id'];
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text("Select TPO", style: TextStyle(color: Colors.white)),
//         backgroundColor: const Color(0xff005E6A),
//       ),
//       body: ListView.builder(
//         itemCount: widget.tpoUsers.length,
//         itemBuilder: (context, index) {
//           final tpo = widget.tpoUsers[index];
//           return Card(
//             margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             child: ListTile(
//               leading: CircleAvatar(
//                 backgroundColor: Colors.teal,
//                 child: Text(
//                   (tpo.firstName != null && tpo.firstName!.isNotEmpty)
//                       ? tpo.firstName![0].toUpperCase()
//                       : "?",
//                   style: const TextStyle(color: Colors.white),
//                 ),
//               ),
//               title: Text(
//                 tpo.fullName ?? "${tpo.firstName ?? ''} ${tpo.lastName ?? ''}",
//               ),
//               subtitle: Text(tpo.email ?? "No Email"),
//               trailing: ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xff005E6A),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 onPressed: isCalling
//                     ? null // agar already call ho rahi hai to disable
//                     : () async {
//                   setState(() {
//                     isCalling = true; // calling state ON
//                   });
//
//                   await CallService.startCall(
//                     context: context,
//                     callerId: Hrid.toString(),
//                     callerName: "",
//                     receiverId: tpo.id.toString(),
//                     receiverName: "",
//                   );
//
//                   setState(() {
//                     isCalling = false; // calling state OFF
//                   });
//                 },
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     if (isCalling) ...[
//                       const SizedBox(
//                         width: 16,
//                         height: 16,
//                         child: CircularProgressIndicator(
//                           color: Colors.white,
//                           strokeWidth: 2,
//                         ),
//                       ),
//                       const SizedBox(width: 6),
//                       const Text("Calling...",
//                           style: TextStyle(color: Colors.white)),
//                     ] else ...[
//                       const Icon(Icons.call, color: Colors.white, size: 18),
//                       const SizedBox(width: 6),
//                       const Text("Call",
//                           style: TextStyle(color: Colors.white)),
//                     ],
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
