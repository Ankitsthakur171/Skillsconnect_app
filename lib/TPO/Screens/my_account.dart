// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:skillsconnect/TPO/My_Account/my_account_bloc.dart';
// import 'package:skillsconnect/TPO/My_Account/my_account_event.dart';
// import 'package:skillsconnect/TPO/My_Account/my_account_state.dart';
// import 'package:skillsconnect/TPO/Screens/tpo_notification.dart';
// import '../../HR/bloc/Login/login_bloc.dart';
// import '../My_Account/api_services.dart';
//
// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({super.key});
//
//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }
//
// class _ProfileScreenState extends State<ProfileScreen> {
//   final firstnameController = TextEditingController();
//   final lastnameController = TextEditingController();
//   final emailController = TextEditingController();
//   final mobileController = TextEditingController();
//   final whatsappnoController = TextEditingController();
//   final linkedinController = TextEditingController(); // Default empty
//   String? role;
//   String? userImg;
//
//   @override
//   void initState() {
//     super.initState();
//     loadUserData();
//   }
//
//   Future<void> loadUserData() async {
//     final data = await getUserData();
//     setState(() {
//       userImg = data['user_img'];
//       role = data['role'];
//       // full_name = data['full_name'];
//     });
//   }
//
//
//
//   @override
//   void dispose() {
//     firstnameController.dispose();
//     lastnameController.dispose();
//     emailController.dispose();
//     mobileController.dispose();
//     whatsappnoController.dispose();
//     linkedinController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (_) => ProfileBloc(repository: Tpoprofile())..add(LoadProfile()),
//       child: Scaffold(
//         backgroundColor: Colors.white,
//         body: BlocBuilder<ProfileBloc, ProfileState>(
//           builder: (context, state) {
//             if (state is ProfileLoaded) {
//               final user = state.user;
//               //  Assign values to controllers once data is loaded
//               firstnameController.text = state.user.name.split(' ').first;
//               lastnameController.text = state.user.name.split(' ').last;
//               emailController.text = state.user.email;
//               mobileController.text = state.user.phone;
//               whatsappnoController.text = state.user.whatsapp;
//               linkedinController.text = state.user.linkedin ?? '';
//
//               return SingleChildScrollView(
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.fromLTRB(10, 30, 10, 40),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           // Back Button in Circle
//                           GestureDetector(
//                             onTap: () {
//                               Navigator.pop(
//                                   context); // Go back to the previous screen
//                             },
//                             child: Container(
//                               height: 40,
//                               width: 40,
//                               decoration: BoxDecoration(
//                                 shape: BoxShape.circle,
//                                 border: Border.all(
//                                   color: Color(0x40005E6A),
//                                   width: 1.5,
//                                 ),
//                               ),
//                               child: const Center(
//                                 child: Icon(Icons.keyboard_arrow_left,
//                                     color: Color(0xff003840)),
//                               ),
//                             ),
//                           ),
//
//                           // Centered Title
//                           const Text(
//                             'My Account',
//                             style: TextStyle(
//                               fontSize: 24,
//                               fontWeight: FontWeight.bold,
//                               fontFamily: "Inter",
//                               color: Color(0xff003840),
//                             ),
//                           ),
//
//                           // Notification Icon in Circle
//                           GestureDetector(
//                               onTap: () {
//                                 Navigator.push(
//                                   context,
//                                   MaterialPageRoute(
//                                       builder: (context) => TpoNotification()),
//                                 );
//                               },
//                               child: Stack(
//                                 clipBehavior: Clip.none,
//                                 children: [
//                                   CircleAvatar(
//                                     backgroundColor: Colors.white,
//                                     radius: 20,
//                                     child: ClipOval(
//                                       child: Image.asset(
//                                         'assets/notification.png',
//                                         height: 40,
//                                         width: 40,
//                                         fit: BoxFit.cover,
//                                       ),
//                                     ),
//                                   ),
//                                   Positioned(
//                                     top: 2,
//                                     right: 2,
//                                     child: Container(
//                                       width: 10,
//                                       height: 10,
//                                       decoration: BoxDecoration(
//                                         color: Colors.red, // 🔴 red fill
//                                         shape: BoxShape.circle,
//                                         border: Border.all(
//                                           color: Color(
//                                               0xFFCAFEE3), // ✅ green border
//                                           width: 1,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               )),
//                         ],
//                       ),
//                     ),
//                     Stack(
//                       alignment: Alignment.center,
//                       clipBehavior: Clip.none,
//                       children: [
//                         //  Custom progress ring with rounded ends
//                         RoundedCircularProgressBar(
//                           progress: user.profileCompletion / 100,
//                           size: 140,
//                           strokeWidth: 8,
//                           backgroundColor: Color(0xffCCDFE1),
//                           progressColor: Color(0xff008080),
//                         ),
//
//                         // Profile image inside ring
//                         // Container(
//                         //   width: 110,
//                         //   height: 110,
//                         //   padding: const EdgeInsets.all(4),
//                         //   decoration: BoxDecoration(
//                         //     shape: BoxShape.circle,
//                         //     border: Border.all(
//                         //       color: const Color(0xFF005e6a),
//                         //       width: 1,
//                         //     ),
//                         //   ),
//                         //   child: SizedBox(
//                         //     height: 100,
//                         //     width: 100,
//                         //     child: user.imageUrl != null &&
//                         //             user.imageUrl!.isNotEmpty
//                         //         ? CircleAvatar(
//                         //             backgroundImage:
//                         //                 NetworkImage(user.imageUrl!),
//                         //           )
//                         //         : const CircleAvatar(
//                         //             backgroundImage:
//                         //                 AssetImage('assets/college.png'),
//                         //           ),
//                         //   ),
//                         // ),
//
//                         // Edit icon
//
//                         // Profile image inside ring
//
//                         Container(
//                           width: 110,
//                           height: 110,
//                           padding: const EdgeInsets.all(4),
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             border: Border.all(
//                               color: const Color(0xFF005e6a),
//                               width: 1,
//                             ),
//                           ),
//                           child: CircleAvatar(
//
//                             backgroundColor: Colors.grey.shade200,
//                             backgroundImage: (userImg != null && userImg!.isNotEmpty)
//                                 ? NetworkImage(userImg!)
//                                 : null,
//                             child: (userImg == null || userImg!.isEmpty)
//                                 ? ClipOval(
//                               child: Image.asset(
//                                 'assets/placeholder.png',
//                                 fit: BoxFit.cover,
//                                 width: 100,
//                                 height: 100,
//                               ),
//                             )
//                                 : null,
//                           ),
//
//                           // child: CircleAvatar(
//                           //   radius: 50,
//                           //   backgroundImage: NetworkImage(user.imageUrl),
//                           // ),
//                         ),
//
//
//                         Positioned(
//                           bottom: 22,
//                           right: 25,
//                           child: Container(
//                             padding: const EdgeInsets.all(2),
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               shape: BoxShape.circle,
//                               border: Border.all(
//                                 color: const Color(0x30005e6a),
//                                 width: 2,
//                               ),
//                             ),
//                             child: CircleAvatar(
//                               radius: 12,
//                               backgroundColor: Colors.white,
//                               child: Image.asset(
//                                 'assets/edit.png',
//                                 width: 16,
//                                 height: 16,
//                               ),
//                             ),
//                           ),
//                         ),
//
//                         // Profile completion percentage
//                         Positioned(
//                           top: 110,
//                           right: -30,
//                           child: Text(
//                             "${user.profileCompletion}%",
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 24,
//                               color: Color(0xff53A8A8),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 10),
//                     Text(state.user.name,
//                         style: const TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold,
//                             color: Color(0xff005E6A))),
//                     Text(user.role,
//                         style: const TextStyle(color: Color(0xff707070))),
//                     const SizedBox(height: 20),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         const Text(
//                           "Personal Details",
//                           style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               fontFamily: 'Inter'),
//                         ),
//                         GestureDetector(
//                           onTap: () {
//                             showEditDetailsBottomSheet(
//                                 context); // Show bottom sheet on tap
//                           },
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 12, vertical: 6),
//                             decoration: BoxDecoration(
//                               border: Border.all(
//                                   color: Color(0xFF005E6A), width: 1.5),
//                               borderRadius: BorderRadius.circular(22),
//                             ),
//                             child: Row(
//                               children: [
//                                 Image.asset(
//                                   'assets/edit2.png',
//                                   width: 18,
//                                   height: 18,
//                                   color: Color(0xFF005E6A),
//                                 ),
//                                 const SizedBox(width: 6),
//                                 const Text(
//                                   'Edit',
//                                   style: TextStyle(
//                                     color: Color(0xFF005E6A),
//                                     fontWeight: FontWeight.w500,
//                                     fontSize: 14,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         )
//                       ],
//                     ),
//                     const SizedBox(height: 10),
//                     Container(
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(
//                           color: Color(0x30005E6A),
//                           width: 1.5,
//                         ),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.05),
//                             blurRadius: 4,
//                             offset: const Offset(0, 2),
//                           ),
//                         ],
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 16, vertical: 12),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             // detailRow('assets/useridentify.png', user.gender),
//                             detailRow('assets/linkedin.png', user.name),
//                             detailRow('assets/mobile.png', user.phone),
//                             detailRow('assets/whatsapp.png', user.whatsapp),
//                             detailRow('assets/mailcheck.png', user.email),
//                             // detailRow('assets/location.png', user.location),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             } else {
//               return const Center(child: CircularProgressIndicator());
//             }
//           },
//         ),
//       ),
//     );
//   }
//
//   static Widget detailRow(String iconPath, String text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6.0),
//       child: Row(
//         children: [
//           Image.asset(
//             iconPath,
//             width: 20,
//             height: 20,
//             color: Color(
//                 0xff005E6A), // Optional: apply tint if icon is single-color
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//               child: Text(text,
//                   style:
//                       const TextStyle(fontSize: 15, color: Color(0xff707070)))),
//         ],
//       ),
//     );
//   }
//
//   /// Edit Pop - up start ////////////////////
//
//   void showEditDetailsBottomSheet(BuildContext context) {
//     String selectedGender = 'Male'; // default selection
//
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (_) {
//         return Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 14),
//           child: Container(
//             decoration: const BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//             ),
//             padding: EdgeInsets.only(
//               bottom: MediaQuery.of(context).viewInsets.bottom,
//               top: 20,
//               left: 16,
//               right: 16,
//             ),
//             child: StatefulBuilder(
//               builder: (context, setState) {
//                 return SingleChildScrollView(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       // Header
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           const Text(
//                             'Edit Personal Details',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: Color(0xFF003840),
//                             ),
//                           ),
//                           IconButton(
//                             icon: const Icon(Icons.close),
//                             onPressed: () => Navigator.pop(context),
//                           ),
//                         ],
//                       ),
//                       const Divider(),
//                       const SizedBox(height: 10),
//
//                       // First Name & Last Name in one row
//                       Row(
//                         children: [
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Padding(
//                                   padding: const EdgeInsets.only(left: 6.0),
//                                   child: labelText('First name*'),
//                                 ),
//                                 const SizedBox(height: 10),
//                                 inputField('First Name',
//                                     controller: firstnameController),
//                               ],
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Padding(
//                                   padding: const EdgeInsets.only(left: 6.0),
//                                   child: labelText('Last name*'),
//                                 ),
//                                 const SizedBox(height: 10),
//                                 inputField('Last Name',
//                                     controller: lastnameController),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//
//                       const SizedBox(height: 20),
//
//                       // // Gender in one row
//                       // Row(
//                       //   children: [
//                       //     Padding(
//                       //       padding: const EdgeInsets.only(left: 6.0, right: 12),
//                       //       child: labelText('Gender*'),
//                       //     ),
//                       //     InkWell(
//                       //       onTap: () => setState(() => selectedGender = 'Male'),
//                       //       child: genderOption(selectedGender == 'Male', 'Male'),
//                       //     ),
//                       //     const SizedBox(width: 20),
//                       //     InkWell(
//                       //       onTap: () => setState(() => selectedGender = 'Female'),
//                       //       child: genderOption(selectedGender == 'Female', 'Female'),
//                       //     ),
//                       //   ],
//                       // ),
//                       //
//                       // const SizedBox(height: 20),
//
//                       // Linkedin
//                       Padding(
//                         padding: const EdgeInsets.only(left: 6.0),
//                         child: labelText('Linkedin profile*'),
//                       ),
//                       const SizedBox(height: 10),
//                       inputField('linkedin', controller: linkedinController),
//
//                       const SizedBox(height: 20),
//
//                       // Contact No.
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.only(left: 6.0),
//                             child: labelText('Contact no*'),
//                           ),
//                           Row(
//                             children: const [
//                               Text(
//                                 'not whatsapp no',
//                                 style: TextStyle(
//                                     fontSize: 12, color: Color(0xFF707070)),
//                               ),
//                               SizedBox(width: 6),
//                               Image(
//                                 image: AssetImage('assets/checksquare.png'),
//                                 width: 18,
//                                 height: 18,
//                                 color: Color(0xff005E6A),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//
//                       const SizedBox(height: 10),
//                       inputField('Mobile no.',
//                           controller: mobileController, readOnly: true),
//
//                       const SizedBox(height: 20),
//
//                       // Email
//                       Padding(
//                         padding: const EdgeInsets.only(left: 6.0),
//                         child: labelText('Email*'),
//                       ),
//                       const SizedBox(height: 10),
//                       inputField('Email',
//                           controller: emailController, readOnly: true),
//
//                       // const SizedBox(height: 20),
//                       //
//                       // // State & City
//                       // Row(
//                       //   children: [
//                       //     Expanded(
//                       //       child: Padding(
//                       //         padding: const EdgeInsets.only(left: 6),
//                       //         child: labelText('State*'),
//                       //       ),
//                       //     ),
//                       //     const SizedBox(width: 10),
//                       //     Expanded(
//                       //       child: Padding(
//                       //         padding: const EdgeInsets.only(left: 6),
//                       //         child: labelText('City*'),
//                       //       ),
//                       //     ),
//                       //   ],
//                       // ),
//                       // const SizedBox(height: 10),
//                       // Row(
//                       //   children: [
//                       //     Expanded(child: dropdownField('Maharashtra')),
//                       //     const SizedBox(width: 10),
//                       //     Expanded(child: dropdownField('Mumbai')),
//                       //   ],
//                       // ),
//
//                       const SizedBox(height: 24),
//
//                       // Submit Button
//                       Center(
//                         child: ElevatedButton(
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFF005E6A),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(25),
//                             ),
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 30, vertical: 2),
//                           ),
//
//                           onPressed: () async {
//                             // ✅ Show confirm dialog using your custom function
//                             final confirmed = await _showConfirmDialog(
//                               context,
//                               "Are you sure you want to change your details?",
//                             );
//
//                             if (confirmed != true) return; // User pressed No or dismissed
//
//                             showDialog(
//                               context: context,
//                               barrierDismissible: false,
//                               builder: (context) => const Center(
//                                   child: CircularProgressIndicator()),
//                             );
//
//                             final success = await Tpoprofile().updateProfile(
//                               firstname: firstnameController.text.trim(),
//                               lastname: lastnameController.text.trim(),
//                               email: emailController.text.trim(),
//                               mobile: mobileController.text.trim(),
//                               whatsappno: whatsappnoController.text.trim(),
//                               linkedin: linkedinController.text.trim(),
//                               gender: selectedGender,
//                             );
//
//                             Navigator.pop(context); // Close loading indicator
//
//                             if (success) {
//                               Navigator.pop(context); // Close bottom sheet
//
//                               // Reload updated profile immediately
//                               context.read<ProfileBloc>().add(LoadProfile());
//
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 const SnackBar(
//                                     content:
//                                         Text("Profile updated successfully!")),
//                               );
//                             } else {
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 const SnackBar(
//                                     content: Text("Failed to update profile")),
//                               );
//                             }
//                           },
//
//                           child: const Text('Submit',
//                               style:
//                                   TextStyle(color: Colors.white, fontSize: 16)),
//                         ),
//                       ),
//
//                       const SizedBox(height: 24),
//                     ],
//                   ),
//                 );
//               },
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   /// Edit Pop - up end ////////////////////
//
//   /// edit pop up Text
//
//   Widget labelText(String text) {
//     // Check if text contains '*'
//     if (text.contains('*')) {
//       final parts = text.split('*');
//       return RichText(
//         text: TextSpan(
//           text: parts[0],
//           style: const TextStyle(
//               fontSize: 14,
//               color: Color(0xFF003840),
//               fontWeight: FontWeight.w500),
//           children: const [
//             TextSpan(
//               text: '*',
//               style: TextStyle(color: Colors.red),
//             ),
//           ],
//         ),
//       );
//     } else {
//       return Text(
//         text,
//         style: const TextStyle(
//             fontSize: 16,
//             color: Color(0xFF003840),
//             fontWeight: FontWeight.w500),
//       );
//     }
//   }
//
//   Widget inputField(
//     String hint, {
//     TextEditingController? controller,
//     bool readOnly = false,
//   }) {
//     return SizedBox(
//       width: 300,
//       height: 50,
//       child: TextField(
//         controller: controller,
//         readOnly: readOnly,
//         style: TextStyle(
//           color: readOnly ? Colors.grey : Color(0xFF003840),
//         ),
//         decoration: InputDecoration(
//           hintText: hint,
//           hintStyle: TextStyle(
//             color: readOnly ? Colors.grey.shade600 : Color(0xFF445458),
//           ),
//           fillColor: readOnly ? Colors.grey.shade200 : Colors.white,
//           filled: true,
//           contentPadding:
//               const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(30),
//             borderSide: BorderSide(
//               color: readOnly ? Colors.grey.shade300 : const Color(0x30005E6A),
//             ),
//           ),
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(30),
//             borderSide: BorderSide(
//               color: readOnly ? Colors.grey.shade300 : const Color(0x30005E6A),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget dropdownField(String value) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12),
//       decoration: BoxDecoration(
//         border: Border.all(color: const Color(0xFFCCDFE1)),
//         borderRadius: BorderRadius.circular(30),
//       ),
//       child: DropdownButtonFormField<String>(
//         value: value,
//         icon: const Icon(Icons.keyboard_arrow_down_outlined,
//             color: Color(0xff003840)), //  dropdown icon
//         items: [value].map((val) {
//           return DropdownMenuItem(
//             value: val,
//             child: Text(val),
//           );
//         }).toList(),
//         onChanged: (_) {},
//         decoration: const InputDecoration(border: InputBorder.none),
//       ),
//     );
//   }
//
//   Widget genderOption(bool selected, String label) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(
//           selected ? Icons.radio_button_checked : Icons.radio_button_off,
//           color: const Color(0xFF008080),
//           size: 20,
//         ),
//         const SizedBox(width: 6),
//         Text(label, style: TextStyle(color: Color(0xFF003840))),
//       ],
//     );
//   }
//
//
//   // Common confirm dialog function
//   Future<bool> _showConfirmDialog(BuildContext context, String message) async {
//     final result = await showDialog<bool>(
//       context: context,
//       barrierDismissible: false, // User must tap a button
//       builder: (context) {
//         return Dialog(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
//                         child: const Text("No", style: TextStyle(color: Colors.white)),
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
//                         child: const Text("Yes", style: TextStyle(color: Colors.white)),
//                       ),
//                     ),
//                   ],
//                 )
//               ],
//             ),
//           ),
//         );
//       },
//     );
//     return result ?? false;
//   }
// }
//
// class RoundedCircularProgressBar extends StatelessWidget {
//   final double progress;
//   final double size;
//   final double strokeWidth;
//   final Color backgroundColor;
//   final Color progressColor;
//
//   const RoundedCircularProgressBar({
//     super.key,
//     required this.progress,
//     this.size = 140,
//     this.strokeWidth = 8,
//     this.backgroundColor = Colors.grey,
//     this.progressColor = Colors.teal,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: size,
//       height: size,
//       child: CustomPaint(
//         painter: _RoundedProgressPainter(
//           progress: progress,
//           strokeWidth: strokeWidth,
//           backgroundColor: backgroundColor,
//           progressColor: progressColor,
//         ),
//       ),
//     );
//   }
// }
//
// class _RoundedProgressPainter extends CustomPainter {
//   final double progress;
//   final double strokeWidth;
//   final Color backgroundColor;
//   final Color progressColor;
//
//   _RoundedProgressPainter({
//     required this.progress,
//     required this.strokeWidth,
//     required this.backgroundColor,
//     required this.progressColor,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final center = size.center(Offset.zero);
//     final radius = (size.width / 2) - strokeWidth / 2;
//
//     final backgroundPaint = Paint()
//       ..color = backgroundColor
//       ..strokeWidth = strokeWidth
//       ..style = PaintingStyle.stroke
//       ..strokeCap = StrokeCap.round;
//
//     final progressPaint = Paint()
//       ..color = progressColor
//       ..strokeWidth = strokeWidth
//       ..style = PaintingStyle.stroke
//       ..strokeCap = StrokeCap.round;
//
//     // Background ring
//     canvas.drawCircle(center, radius, backgroundPaint);
//
//     // Progress arc starting from bottom (270 degrees or pi/2)
//     final startAngle = 3.14 / 3;
//     final sweepAngle = 2 * 3.14 * progress;
//
//     canvas.drawArc(
//       Rect.fromCircle(center: center, radius: radius),
//       startAngle,
//       sweepAngle,
//       false,
//       progressPaint,
//     );
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//



import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillsconnect/TPO/My_Account/my_account_bloc.dart';
import 'package:skillsconnect/TPO/My_Account/my_account_event.dart';
import 'package:skillsconnect/TPO/My_Account/my_account_state.dart';
import '../My_Account/api_services.dart'; // Tpoprofile()

Future<void> showTpoEditDetailsFullSheet(BuildContext context) async {
  final firstnameController = TextEditingController();
  final lastnameController = TextEditingController();
  final emailController = TextEditingController();
  final mobileController = TextEditingController();
  final whatsappController = TextEditingController();
  final linkedinController = TextEditingController();
  String selectedGender = 'Male';
  // ✅ State variables for error messages
  String? firstNameError;
  String? lastNameError;
  String? emailError;
  String? whatsappError;

  bool _hasWhatsapp = false; // ✅ whatsapp toggle
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final height = 700.0;

      return SizedBox(
        height: height,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Material(
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: BlocProvider(
                create: (_) =>
                ProfileBloc(repository: Tpoprofile())..add(LoadProfile()),
                child: StatefulBuilder(
                  builder: (ctx, setSheetState) {
                    return Padding(
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 20,
                        bottom: MediaQuery.of(ctx).viewInsets.bottom,
                      ),
                      child: BlocConsumer<ProfileBloc, ProfileState>(
                        listener: (ctx, state) {
                          if (state is ProfileLoaded) {
                            final u = state.user;
                            firstnameController.text = (u.name.split(' ').isNotEmpty)
                                ? u.name.split(' ').first
                                : '';
                            lastnameController.text =
                            (u.name.split(' ').length > 1)
                                ? u.name.split(' ').last
                                : '';
                            emailController.text = u.email ?? '';
                            mobileController.text = u.phone ?? '';
                            whatsappController.text = u.whatsapp ?? '';
                            linkedinController.text = u.linkedin ?? '';

                            // ✅ checkbox init
                            setSheetState(() {
                              _hasWhatsapp =
                              (u.whatsapp != null && u.whatsapp!.isNotEmpty);
                            });
                          }
                        },
                        builder: (ctx, state) {
                          if (state is ProfileLoading ||
                              state is ProfileInitial) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (state is ProfileError) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 24),
                                const Text("Failed to load profile",
                                    style:
                                    TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () =>
                                      ctx.read<ProfileBloc>().add(LoadProfile()),
                                  child: const Text("Retry"),
                                ),
                              ],
                            );
                          }

                          if (state is ProfileLoaded) {
                            return SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Header
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Center(
                                          child: Text(
                                            'Edit Personal Details',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF003840),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        height: 40,
                                        width: 40,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0x33005E6A),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: IconButton(
                                          padding: EdgeInsets.zero,
                                          icon: const Icon(
                                            Icons.close,
                                            color: Color(0xFF005E6A),
                                            size: 18,
                                          ),
                                          onPressed: () =>
                                              Navigator.pop(context),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 40),

                                  // First / Last
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // _label('First name*'),
                                            const SizedBox(height: 10),
                                            _inputField(
                                              'First Name',
                                              controller: firstnameController,
                                              errorText: firstNameError,
                                              required: true
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // _label('Last name*'),
                                            const SizedBox(height: 10),
                                            _inputField(
                                              'Last Name',
                                              controller: lastnameController,
                                              errorText: lastNameError,
                                              required: true
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),


                                  // _label('Email'),
                                  const SizedBox(height: 10),
                                  _inputField('Email',
                                      controller: emailController,
                                      readOnly: true),

                                  // Contact + checkbox

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(left: 6.0),
                                        child: Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(
                                                text: 'Contact no',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF003840),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              // TextSpan(
                                              //   text: ' *',
                                              //   style: TextStyle(
                                              //     fontSize: 14,
                                              //     color: Colors.red, // 🔴 sirf * red me
                                              //     fontWeight: FontWeight.w500,
                                              //   ),
                                              // ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          const Text(
                                            'not whatsapp no',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF707070),
                                            ),
                                          ),
                                          Checkbox(
                                            value: _hasWhatsapp,
                                            onChanged: (val) {
                                              setSheetState(() {
                                                _hasWhatsapp = val ?? false;
                                              });
                                            },
                                            activeColor: const Color(0xff005E6A),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  // Row(
                                  //   mainAxisAlignment:
                                  //   MainAxisAlignment.spaceBetween,
                                  //   children: [
                                  //     const Padding(
                                  //       padding: EdgeInsets.only(left: 6.0),
                                  //       child: Text('Contact no*',
                                  //           style: TextStyle(
                                  //               fontSize: 14,
                                  //               color: Color(0xFF003840),
                                  //               fontWeight: FontWeight.w500)),
                                  //     ),
                                  //     Row(
                                  //       children: [
                                  //         const Text('not whatsapp no',
                                  //             style: TextStyle(
                                  //                 fontSize: 12,
                                  //                 color: Color(0xFF707070))),
                                  //         Checkbox(
                                  //           value: _hasWhatsapp,
                                  //           onChanged: (val) {
                                  //             setSheetState(() {
                                  //               _hasWhatsapp = val ?? false;
                                  //             });
                                  //           },
                                  //           activeColor:
                                  //           const Color(0xff005E6A),
                                  //         ),
                                  //       ],
                                  //     ),
                                  //   ],
                                  // ),


                                  // const SizedBox(height: 10),
                                  _inputField('Mobile no.',
                                      controller: mobileController,required: false,
                                      readOnly: true),

                                  // ✅ WhatsApp field (only if checkbox enabled)
                                  if (_hasWhatsapp) ...[
                                    // _label('WhatsApp no *'),
                                    const SizedBox(height: 10),
                                    _inputField(
                                      'WhatsApp no',
                                      controller: whatsappController,
                                      errorText: whatsappError,
                                      isWhatsapp: true, // ✅ restrict input to 10 digits
                                      required: true
                                    ),
                                  ],

                                  // Linkedin
                                  // _label('Linkedin profile'),
                                  const SizedBox(height: 10),
                                  _inputField('Linkedin',
                                      controller: linkedinController,required: false
                                  ),
                                  const SizedBox(height: 20),




                                  // Submit
                                  Center(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                        const Color(0xFF005E6A),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(25)),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 30, vertical: 2),
                                      ),
                                      onPressed: () async {

                                        setSheetState(() {
                                          firstNameError = firstnameController.text.trim().isEmpty
                                              ? "This field is required"
                                              : null;
                                          lastNameError = lastnameController.text.trim().isEmpty
                                              ? "This field is required"
                                              : null;
                                          emailError = emailController.text.trim().isEmpty
                                              ? "This field is required"
                                              : null;

                                          if (_hasWhatsapp) {
                                            if (whatsappController.text.trim().isEmpty) {
                                              whatsappError = "This field is required";
                                            } else if (whatsappController.text.trim().length != 10) {
                                              whatsappError = "WhatsApp number must be 10 digits";
                                            } else {
                                              whatsappError = null;
                                            }
                                          } else {
                                            whatsappError = null;
                                          }
                                        });

                                        // ❌ Stop if any validation failed
                                        if (firstNameError != null ||
                                            lastNameError != null ||
                                            emailError != null ||
                                            whatsappError != null) {
                                          return;
                                        }


                                        final confirm = await _confirmDialog(
                                            ctx,
                                            "Are you sure you want to change your details?");
                                        if (confirm != true) return;

                                        showDialog(
                                          context: ctx,
                                          barrierDismissible: false,
                                          builder: (_) => const Center(
                                              child:
                                              CircularProgressIndicator()),
                                        );

                                        final ok =
                                        await Tpoprofile().updateProfile(
                                          firstname:
                                          firstnameController.text.trim(),
                                          lastname:
                                          lastnameController.text.trim(),
                                          email: emailController.text.trim(),
                                          mobile: mobileController.text.trim(),
                                          whatsappno: _hasWhatsapp
                                              ? whatsappController.text.trim()
                                              : '', // ✅ only if checked
                                          linkedin:
                                          linkedinController.text.trim(),
                                          gender: selectedGender,
                                        );

                                        Navigator.pop(ctx);
                                        if (!ctx.mounted) return;

                                        if (ok) {
                                          // 1) SharedPreferences me turant cache update
                                          final prefs = await SharedPreferences.getInstance();

                                          // Full name compose
                                          final newFullName = '${firstnameController.text.trim()} ${lastnameController.text.trim()}'.trim();
                                          await prefs.setString('profile_name', newFullName);

                                          ctx
                                              .read<ProfileBloc>()
                                              .add(LoadProfile());
                                          Navigator.pop(ctx);

                                          ShowSuccesSnackbar(context,"Profile updated successfully!");

                                          // ScaffoldMessenger.of(context)
                                          //     .showSnackBar(const SnackBar(
                                          //   content: Text(
                                          //       "Profile updated successfully!"),
                                          // ));
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                            content:
                                            Text("Failed to update profile"),
                                          ));
                                        }
                                      },
                                      child: const Text('Submit',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16)),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            );
                          }

                          return const SizedBox.shrink();
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
// ---------- small UI helpers ----------
Widget _label(String text) {
  if (text.contains('*')) {
    final parts = text.split('*');
    return RichText(
      text: TextSpan(
        text: parts[0],
        style: const TextStyle(fontSize: 14, color: Color(0xFF003840), fontWeight: FontWeight.w500),
        children: const [TextSpan(text: '*', style: TextStyle(color: Colors.red))],
      ),
    );
  }
  return Text(text, style: const TextStyle(fontSize: 16, color: Color(0xFF003840), fontWeight: FontWeight.w500));
}

Widget _inputBlock(String label, String hint, {required TextEditingController controller}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(padding: const EdgeInsets.only(left: 6.0), child: _label(label)),
      const SizedBox(height: 10),
      _inputField(hint, controller: controller),
    ],
  );
}


Widget _inputField(
    String label, {
      TextEditingController? controller,
      bool readOnly = false,
      String? errorText,
      bool isWhatsapp = false, // ✅ extra flag
      bool required = false,   // ✅ नया parameter (default false)

    }) {
  final baseBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(30),
    borderSide: const BorderSide(color: Colors.grey),
  );
  final focusBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(30),
    borderSide: const BorderSide(color: Color(0xff003840), width: 2),
  );

  return Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: isWhatsapp ? TextInputType.number : null, // ✅ only number pad
      inputFormatters: isWhatsapp
          ? [
        FilteringTextInputFormatter.digitsOnly, // ✅ only digits
        LengthLimitingTextInputFormatter(10),   // ✅ max 10 digits
      ]
          : null,
      style: TextStyle(
        color: readOnly ? Colors.grey : const Color(0xFF003840),
      ),
      decoration: InputDecoration(
        // 🔹 Label with optional red asterisk
        label: RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF003840),
              fontWeight: FontWeight.w500,
            ),
            children: required
                ? const [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ]
                : const [],
          ),
        ),
        hintText: label,
        hintStyle: TextStyle(
          color: readOnly ? Colors.grey.shade600 : const Color(0xFF445458),
        ),
        fillColor: readOnly ? Colors.grey.shade200 : Colors.white,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: baseBorder,
        focusedBorder: focusBorder,
        errorBorder: baseBorder,
        focusedErrorBorder: focusBorder,
        errorText: errorText, // 👈 directly show karega error
        errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
      ),
    ),
  );
}

// Widget _inputField(
//     String hint, {
//       TextEditingController? controller,
//       bool readOnly = false,
//       String? errorText,
//       bool isWhatsapp = false, // ✅ extra flag
//
//     }) {
//   final baseBorder = OutlineInputBorder(
//     borderRadius: BorderRadius.circular(30),
//     borderSide: const BorderSide(color: Colors.grey),
//   );
//   final focusBorder = OutlineInputBorder(
//     borderRadius: BorderRadius.circular(30),
//     borderSide: const BorderSide(color: Color(0xff003840), width: 2),
//   );
//
//   return Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       SizedBox(
//         width: 300,
//         height: 50,
//         child: TextFormField(
//           controller: controller,
//           readOnly: readOnly,
//           keyboardType: isWhatsapp ? TextInputType.number : null, // ✅ only number pad
//           inputFormatters: isWhatsapp
//               ? [
//             FilteringTextInputFormatter.digitsOnly, // ✅ only digits
//             LengthLimitingTextInputFormatter(10),   // ✅ max 10 digits
//           ]
//               : null,
//           style: TextStyle(
//             color: readOnly ? Colors.grey : const Color(0xFF003840),
//           ),
//           decoration: InputDecoration(
//             hintText: hint,
//             hintStyle: TextStyle(
//               color: readOnly ? Colors.grey.shade600 : const Color(0xFF445458),
//             ),
//             fillColor: readOnly ? Colors.grey.shade200 : Colors.white,
//             filled: true,
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 14,
//             ),
//             enabledBorder: baseBorder,
//             focusedBorder: focusBorder,
//             errorBorder: baseBorder,
//             focusedErrorBorder: focusBorder,
//             errorText: null,
//             errorStyle: const TextStyle(height: 0, fontSize: 0),
//           ),
//         ),
//       ),
//       SizedBox(
//         height: 18,
//         child: (errorText != null && errorText.isNotEmpty)
//             ? Padding(
//           padding: const EdgeInsets.only(left: 12, top: 2),
//           child: Text(
//             errorText,
//             style: const TextStyle(color: Colors.red, fontSize: 12),
//           ),
//         )
//             : null,
//       ),
//     ],
//   );
// }

Future<bool?> _confirmDialog(BuildContext context, String message) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.help_outline, size: 48, color: Color(0xff005E6A)),
            const SizedBox(height: 16),
            const Text("Confirmation", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.black54)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), padding: const EdgeInsets.symmetric(vertical: 12)),
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("No", style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff005E6A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), padding: const EdgeInsets.symmetric(vertical: 12)),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Yes", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    ),
  );
}


void ShowSuccesSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      duration: const Duration(seconds: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );
}
