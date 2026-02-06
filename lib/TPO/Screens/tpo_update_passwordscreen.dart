// lib/HR/screens/update_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skillsconnect/TPO/Screens/acc_screen.dart';


// ⚠️ jahan getUserData() defined hai uss file ko import karo:
import '../../HR/bloc/Login/login_bloc.dart';
import '../../HR/bloc/UpdatePassword/update_password_bloc.dart';
import '../../HR/bloc/UpdatePassword/update_password_event.dart';
import '../../HR/bloc/UpdatePassword/update_password_state.dart';

class TpoUpdatePasswordScreen extends StatefulWidget {
  const TpoUpdatePasswordScreen({super.key});

  @override
  State<TpoUpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<TpoUpdatePasswordScreen> {
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  final currentController = TextEditingController();
  final newController = TextEditingController();
  final confirmController = TextEditingController();

  String? email; // user email
  bool _submitted = false; // ✅ validations only after submit

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final data = await getUserData();
    if (!mounted) return;
    setState(() {
      email = data['email']?.toString();
    });
  }

  @override
  void dispose() {
    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  // ---------- Validation helpers (messages shown only when _submitted == true) ----------
  String? _currentError() {
    if (!_submitted) return null;
    final v = currentController.text.trim();
    if (v.isEmpty) return 'Please enter current password';
    // (Optional) uncomment if you also want min length for current:
    // if (v.length < 6) return 'Minimum password length should be 6 digits';
    return null;
  }

  String? _newError() {
    if (!_submitted) return null;
    final v = newController.text.trim();
    if (v.isEmpty) return 'Please enter 6-digit password';
    if (v.length < 6) return 'Minimum password length should be 6 characters';
    return null;
  }

  String? _confirmError() {
    if (!_submitted) return null;
    final v = confirmController.text.trim();
    final n = newController.text.trim();
    if (v.isEmpty) return 'Please enter confirm password';
    if (v.length < 6) return 'Minimum password length should be 6 characters';
    if (v != n) return 'New and Confirm password must match';
    return null;
  }

  bool _allValid() {
    return _currentError() == null && _newError() == null && _confirmError() == null;
  }

  void _trySubmit(BuildContext context) {
    setState(() => _submitted = true); // now show errors if any
    if (!_allValid()) {
      // Don’t call API; just show field errors. Optional overall note:
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill all Fields'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // ✅ All good -> fire API
    context.read<UpdatePasswordBloc>().add(SubmitPasswordUpdate(email ?? ''));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UpdatePasswordBloc(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Color(0xff003840)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "Update Password",
            style: TextStyle(
              color: Color(0xff003840),
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: BlocConsumer<UpdatePasswordBloc, UpdatePasswordState>(
          listenWhen: (previous, current) {
            return previous.isSuccess != current.isSuccess ||
                previous.isFailure != current.isFailure;
          },
          listener: (context, state) {
            if (state.isSuccess) {
              showErrorSnackBarGreen(context, "Password updated successfully");
              // Optional: clear fields after success and reset validation state
              setState(() {
                currentController.clear();
                newController.clear();
                confirmController.clear();
                _submitted = false;
              });

              // ✅ Go back to previous screen (SettingsPage)
              Navigator.pop(context);

            } else if (state.isFailure) {
              showErrorSnackBargreen(context, state.errorMessage);
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  passwordField(
                    label: "Current Password",
                    controller: currentController,
                    obscureText: _obscureCurrent,
                    toggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                    onChanged: (val) => context
                        .read<UpdatePasswordBloc>()
                        .add(CurrentPasswordChanged(val)),
                    errorText: _currentError(), // ✅ show only after submit
                    requiredMark: true, // 👈 NEW (लाल *)

                  ),
                  const SizedBox(height: 10),
                  passwordField(
                    label: "New Password",
                    controller: newController,
                    obscureText: _obscureNew,
                    toggle: () => setState(() => _obscureNew = !_obscureNew),
                    onChanged: (val) => context
                        .read<UpdatePasswordBloc>()
                        .add(NewPasswordChanged(val)),
                    errorText: _newError(), // ✅
                    requiredMark: true, // 👈 NEW (लाल *)

                  ),
                  const SizedBox(height: 10),
                  passwordField(
                    label: "Confirm Password",
                    controller: confirmController,
                    obscureText: _obscureConfirm,
                    toggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    onChanged: (val) => context
                        .read<UpdatePasswordBloc>()
                        .add(ConfirmPasswordChanged(val)),
                    errorText: _confirmError(), // ✅
                    requiredMark: true, // 👈 NEW (लाल *)

                  ),
                  const SizedBox(height: 30),
                  state.isSubmitting
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff005E6A),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () => _trySubmit(context), // ✅ guarded submit
                      child: const Text(
                        "Submit",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget passwordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback toggle,
    required Function(String) onChanged,
    String? errorText, // <- yahi aayega, par decoration.errorText me use nahi karenge
    bool requiredMark = false, // 👈 NEW

  }) {
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: const BorderSide(color: Colors.grey),
    );
    final focusBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: const BorderSide(color: Color(0xff003840), width: 2),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xff003840), fontFamily: 'Inter'),
              ),
              if (requiredMark) const Text(
                ' *',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // TextField — no decoration.errorText so it won't jump/red
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          onChanged: onChanged,
          style: const TextStyle(color: Color(0xff003840)),
          decoration: InputDecoration(
            hintText: "********",
            hintStyle: const TextStyle(color: Colors.grey),

            prefixIcon: const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                height: 20,
                width: 20,
                child: ImageIcon(
                  AssetImage('assets/lock.png'),
                  color: Color(0xff003840),
                  size: 18,
                ),
              ),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: const Color(0xff003840),
              ),
              onPressed: toggle,
            ),

            // keep borders same even when error so look doesn't change
            enabledBorder: baseBorder,
            focusedBorder: focusBorder,
            errorBorder: baseBorder,             // <- same as normal
            focusedErrorBorder: focusBorder,     // <- same as focused

            // don't show default error line (prevents height jump)
            errorText: null,
            errorStyle: const TextStyle(height: 0, fontSize: 0),
            helperText: null,
            helperStyle: const TextStyle(height: 0, fontSize: 0),
          ),
        ),

        // Fixed-height area for our custom error text (prevents layout jump)
        Visibility(
          visible: errorText != null,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              errorText ?? '',
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }


  void showErrorSnackBargreen(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        backgroundColor: Colors.red,
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

  void showErrorSnackBarGreen(BuildContext context, String message) {
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
        duration: const Duration(seconds: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
