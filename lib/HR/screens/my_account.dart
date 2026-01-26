import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter, LengthLimitingTextInputFormatter;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillsconnect/Services/api_services.dart';

import '../bloc/My_Account/my_account_bloc.dart';
import '../bloc/My_Account/my_account_event.dart';
import '../bloc/My_Account/my_account_state.dart';
import 'EnterOtpScreen.dart';

/// Call this from anywhere to open the edit profile sheet
Future<void> showEditProfileSheet(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true, // 👈 important
    backgroundColor: Colors.white,
    builder: (sheetCtx) {
      return SizedBox(
        height: 700,
        child: BlocProvider(
          create: (_) =>
          ProfileBloc(repository: HrProfile())..add(LoadProfile()),
          child: const _EditProfileSheet(),
        ),
      );
    },
  );
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({super.key});
  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final firstnameController = TextEditingController();
  final lastnameController = TextEditingController();
  final emailController = TextEditingController();
  final mobileController = TextEditingController();
  final whatsappController = TextEditingController();
  final linkedinController = TextEditingController();

  String selectedGender = 'Male';
  bool _hasWhatsapp = false; // ✅ new state
  // ✅ State variables for error messages
  String? firstNameError;
  String? lastNameError;
  String? emailError;
  String? mobileError;
  String? whatsappError;
  String? linkedinError;



  @override
  void dispose() {
    firstnameController.dispose();
    lastnameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    whatsappController.dispose();
    linkedinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: viewInsets.bottom,
          top: 20,
          left: 16,
          right: 16,
        ),
        child: BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state is ProfileLoaded) {
              final u = state.user;
              firstnameController.text = (u.firstname ?? '');
              lastnameController.text = (u.lastname ?? '');
              emailController.text = (u.email ?? '');
              mobileController.text = (u.phone ?? '');
              whatsappController.text = (u.whatsapp ?? '');
              linkedinController.text = (u.linkedin ?? '');
              // ✅ checkbox state update
              setState(() {
                _hasWhatsapp = u.whatsapp.isNotEmpty;
              });
            }
          },
          builder: (context, state) {
            if (state is ProfileLoading || state is ProfileInitial) {
              return const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (state is ProfileError) {
              return SizedBox(
                height: 200,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      "Failed to load profile",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Text(state.message ?? "Unknown error"),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<ProfileBloc>().add(LoadProfile()),
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              );
            }

            if (state is ProfileLoaded) {
              final u = state.user;

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
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // First / Last name
                    if ((u.firstname ?? '').isNotEmpty ||
                        (u.lastname ?? '').isNotEmpty)
                      Row(
                        children: [
                          if ((u.firstname ?? '').isNotEmpty)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // _labelText('First name *'),
                                  const SizedBox(height: 10),
                                  _inputField('First Name',
                                      controller: firstnameController,  errorText: firstNameError,required: true
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(width: 12),
                          if ((u.lastname ?? '').isNotEmpty)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // _labelText('Last name *'),
                                  const SizedBox(height: 10),
                                  _inputField('Last Name',
                                      controller: lastnameController,  errorText: lastNameError, required: true
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                    // const SizedBox(height: 10),

                    // Email
                    if ((u.email ?? '').isNotEmpty) ...[
                      // _labelText('Email'),
                      const SizedBox(height: 10),
                      _inputField('Email',
                          controller: emailController, readOnly: true,required: false),
                    ],


                    // Contact no
                    if ((u.phone ?? '').isNotEmpty) ...[

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
                                  setState(() {
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
                      //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //   children: [
                      //     const Padding(
                      //       padding: EdgeInsets.only(left: 6.0),
                      //       child: Text(
                      //         'Contact no*',
                      //         style: TextStyle(
                      //           fontSize: 14,
                      //           color: Color(0xFF003840),
                      //           fontWeight: FontWeight.w500,
                      //         ),
                      //       ),
                      //     ),
                      //     Row(
                      //       children: [
                      //         const Text(
                      //           'not whatsapp no',
                      //           style: TextStyle(
                      //             fontSize: 12,
                      //             color: Color(0xFF707070),
                      //           ),
                      //         ),
                      //         Checkbox(
                      //           value: _hasWhatsapp,
                      //           onChanged: (val) {
                      //             setState(() {
                      //               _hasWhatsapp = val ?? false;
                      //             });
                      //           },
                      //           activeColor: const Color(0xff005E6A),
                      //         ),
                      //       ],
                      //     ),
                      //   ],
                      // ),


                      // const SizedBox(height: 10),
                      _inputField('Mobile no.',
                          controller: mobileController, readOnly: true),
                      const SizedBox(height: 0),
                    ],


                    // Whatsapp
                    if (_hasWhatsapp)
                      if ((u.whatsapp ?? '').isNotEmpty) ...[
                        // _labelText('WhatsApp no *'),
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
                    // if ((u.linkedin ?? '').isNotEmpty) ...[
                    //   _labelText('Linkedin profile'),
                      const SizedBox(height: 10),
                      _inputField('Linkedin', controller: linkedinController,required: false),
                      const SizedBox(height: 20),
                    // ],



                    // Submit
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF005E6A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 2,
                          ),
                        ),
                        onPressed: () async {

                          setState(() {
                            firstNameError = firstnameController.text.trim().isEmpty ? " required" : null;
                            lastNameError  = lastnameController.text.trim().isEmpty ? "required" : null;
                            // emailError     = emailController.text.trim().isEmpty ? "This field is required" : null;
                            // mobileError    = mobileController.text.trim().isEmpty ? "This field is required" : null;
                            if (_hasWhatsapp) {
                              whatsappError = whatsappController.text.trim().isEmpty ? "required" : null;
                            } else {
                              whatsappError = null;
                            }
                            // linkedinError  = linkedinController.text.trim().isEmpty ? "This field is required" : null;
                          });

                          // ❌ Stop if any error
                          if (firstNameError != null ||
                              lastNameError != null ||
                              // emailError != null ||
                              // mobileError != null ||
                              whatsappError != null ) {
                            return;
                          }

                          final confirmed = await _showConfirmDialog(
                            context,
                            "Are you sure you want to change your details?",
                          );
                          if (confirmed != true) return;

                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                                child: CircularProgressIndicator()),
                          );

                          final success = await HrProfile().hrupdateProfile(
                            firstname: firstnameController.text.trim(),
                            lastname: lastnameController.text.trim(),
                            email: emailController.text.trim(),
                            mobile: mobileController.text.trim(),
                            whatsappno: whatsappController.text.trim(),
                            linkedin: linkedinController.text.trim(),
                            gender: selectedGender,
                          );

                          Navigator.pop(context); // close loader

                          if (!mounted) return;
                          if (success) {

                            // 1) SharedPreferences me turant cache update
                            final prefs = await SharedPreferences.getInstance();

                            // Full name compose
                            final newFullName = '${firstnameController.text.trim()} ${lastnameController.text.trim()}'.trim();
                            await prefs.setString('profile_name', newFullName);


                            context.read<ProfileBloc>().add(LoadProfile());
                            Navigator.pop(context); // close sheet
                            showSuccessSnackBar(context,"Profile updated successfully!");
                          } else {
                            // ScaffoldMessenger.of(context).showSnackBar(
                            //   const SnackBar(
                            //     content: Text("Failed to update profile"),
                            //   ),
                            // );
                            showErrorSnackBar(context, "Failed to update profile");
                          }
                        },
                        child: const Text(
                          'Submit',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
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
      ),
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


  // Widget _inputField(
  //     String hint, {
  //       TextEditingController? controller,
  //       bool readOnly = false,
  //     }) {
  //   return SizedBox(
  //     width: 300,
  //     height: 50,
  //     child: TextField(
  //       controller: controller,
  //       readOnly: readOnly,
  //       style: TextStyle(
  //         color: readOnly ? Colors.grey : const Color(0xFF003840),
  //       ),
  //       decoration: InputDecoration(
  //         hintText: hint,
  //         hintStyle: TextStyle(
  //           color: readOnly ? Colors.grey.shade600 : const Color(0xFF445458),
  //         ),
  //         fillColor: readOnly ? Colors.grey.shade200 : Colors.white,
  //         filled: true,
  //         contentPadding: const EdgeInsets.symmetric(
  //           horizontal: 16,
  //           vertical: 14,
  //         ),
  //         border: OutlineInputBorder(
  //           borderRadius: BorderRadius.circular(30),
  //         ),
  //         enabledBorder: OutlineInputBorder(
  //           borderRadius: BorderRadius.circular(30),
  //           borderSide: BorderSide(
  //             color: readOnly ? Colors.grey.shade300 : const Color(0x30005E6A),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Future<bool> _showConfirmDialog(BuildContext context, String message) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.help_outline,
                    size: 48, color: Color(0xff005E6A)),
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
                  style:
                  const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("No",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff005E6A),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Yes",
                            style: TextStyle(color: Colors.white)),
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


}
