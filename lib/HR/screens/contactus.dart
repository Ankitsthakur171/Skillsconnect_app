import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skillsconnect/HR/screens/setting_screen.dart';

import '../bloc/Contact_Us_page/contactus_bloc.dart';
import '../bloc/Contact_Us_page/contactus_event.dart';
import '../bloc/Contact_Us_page/contactus_state.dart';
import 'EnterOtpScreen.dart';

class ContactUsPage extends StatelessWidget {
  ContactUsPage({Key? key}) : super(key: key);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ContactUsBloc(ContactRepository()),
      child: Scaffold(
        backgroundColor: Colors.white,

        /// ✅ AppBar added
        appBar: AppBar(
          title: const Text(
            "Contact Us",
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: const Color(0xffEBF6F7),
          centerTitle: true,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),

        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: BlocConsumer<ContactUsBloc, ContactUsState>(
            listener: (context, state) {
              if (state is ContactUsSuccess) {
                showSuccessSnackBarr(context, state.message);
                _formKey.currentState?.reset();

                // ✅ Go back to previous screen (SettingsPage)
                Navigator.pop(context);


              } else if (state is ContactUsFailure) {
                showErrorSnackBar(context, state.error);
              }
            },
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  // const Text(
                  //   "Contact Us",
                  //   style: TextStyle(
                  //     fontSize: 28,
                  //     fontWeight: FontWeight.bold,
                  //     color: Color(0xff003840),
                  //   ),
                  // ),
                  const SizedBox(height: 10),
                  const Text(
                    "Contact us using the form below,\nand our team will get back to you\nas soon as possible to provide the\nnecessary assistance.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 30),

                  /// 📌 Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildInputField(_nameController, "Enter name"),
                        _buildInputField(
                          _emailController,
                          "Enter email",
                          inputType: TextInputType.emailAddress,
                        ),
                        _buildInputField(
                          _phoneController,
                          "Enter phone number",
                          inputType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                        ),
                        _buildInputField(_subjectController, "Enter subject"),
                        _buildInputField(
                          _messageController,
                          "Write your message...",
                          maxLines: 5,
                        ),
                        const SizedBox(height: 20),

                        state is ContactLoading
                            ? const Center(child: CircularProgressIndicator())
                            : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff005E6A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16),
                            ),
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                context.read<ContactUsBloc>().add(
                                  SubmitContactForm(
                                    name: _nameController.text,
                                    phone: _phoneController.text,
                                    email: _emailController.text,
                                    subject: _subjectController.text,
                                    message: _messageController.text,
                                  ),
                                );
                              }
                            },
                            child: const Text(
                              "SEND MESSAGE",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
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

  Widget _buildInputField(
      TextEditingController controller,
      String hint, {
        int maxLines = 1,
        TextInputType inputType = TextInputType.text,
        List<TextInputFormatter>? inputFormatters,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: inputType,
        inputFormatters: inputFormatters,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return hint;
          }
          if (hint == "Enter email" &&
              !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
            return "Enter valid email";
          }
          if (hint == "Enter phone number" && value.length != 10) {
            return "Phone number must be 10 digits";
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: hint, // 👈 Label added
          labelStyle: const TextStyle(
            color: Color(0xff003840),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black45),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xff005E6A), width: 1.2),
          ),
        ),
      ),
    );
  }

  void showSuccessSnackBarr(BuildContext context, String message) {
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
        duration: const Duration(seconds: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
