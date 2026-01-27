import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../Model/Internship_Projects_Model.dart';
import '../../../Utilities/MyAccount_Get_Post/InternshipProject_Api.dart';
import 'CustomDropDowns/CustomDropDownProjectIntern.dart';

class EditProjectDetailsBottomSheet extends StatefulWidget {
  final InternshipProjectModel? initialData;
  final Function(InternshipProjectModel) onSave;

  const EditProjectDetailsBottomSheet({
    Key? key,
    this.initialData,
    required this.onSave,
  }) : super(key: key);

  @override
  State<EditProjectDetailsBottomSheet> createState() => _EditProjectDetailsBottomSheetState();
}

class _EditProjectDetailsBottomSheetState extends State<EditProjectDetailsBottomSheet> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  ScrollController? _sheetScrollController;

  late String type;
  late TextEditingController projectNameController;
  late TextEditingController companyNameController;
  late TextEditingController skillsController;
  late TextEditingController durationController;
  late String durationPeriod;
  late TextEditingController detailsController;
  bool saving = false;
  final GlobalKey _typeKey = GlobalKey();
  final GlobalKey _projectNameKey = GlobalKey();
  final GlobalKey _companyNameKey = GlobalKey();
  final GlobalKey _skillsKey = GlobalKey();
  final GlobalKey _durationKey = GlobalKey();
  final GlobalKey _durationPeriodKey = GlobalKey();
  final GlobalKey _detailsKey = GlobalKey();
  final FocusNode _typeFocusNode = FocusNode();
  final FocusNode _projectNameFocusNode = FocusNode();
  final FocusNode _companyNameFocusNode = FocusNode();
  final FocusNode _skillsFocusNode = FocusNode();
  final FocusNode _durationFocusNode = FocusNode();
  final FocusNode _durationPeriodFocusNode = FocusNode();
  final FocusNode _detailsFocusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _snackBarShown = false;
  OverlayEntry? _overlayEntry;

  void _showSnackBarOnce(BuildContext context, String message,
      {Color backgroundColor = Colors.red, int cooldownSeconds = 2}) {
    if (_snackBarShown) return;
    _snackBarShown = true;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              message,
              style: TextStyle(color: Colors.white, fontSize: 13.sp),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    Future.delayed(Duration(seconds: cooldownSeconds), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _snackBarShown = false;
    });
  }

  @override
  void initState() {
    super.initState();

    type = widget.initialData?.type ?? 'Project';
    durationPeriod = widget.initialData?.durationPeriod ?? 'Days';

    projectNameController = TextEditingController(text: widget.initialData?.projectName ?? '');
    companyNameController = TextEditingController(text: widget.initialData?.companyName ?? '');
    skillsController = TextEditingController(text: widget.initialData?.skills ?? '');
    durationController = TextEditingController(text: widget.initialData?.duration ?? '');
    detailsController = TextEditingController(text: widget.initialData?.details ?? '');

    _projectNameFocusNode.addListener(() => _onFieldFocus(_projectNameFocusNode, _projectNameKey));
    _companyNameFocusNode.addListener(() => _onFieldFocus(_companyNameFocusNode, _companyNameKey));
    _skillsFocusNode.addListener(() => _onFieldFocus(_skillsFocusNode, _skillsKey));
    _durationFocusNode.addListener(() => _onFieldFocus(_durationFocusNode, _durationKey));
    _detailsFocusNode.addListener(() => _onFieldFocus(_detailsFocusNode, _detailsKey));

    _animationController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _animationController.forward();
    });
  }

  void _onFieldFocus(FocusNode node, GlobalKey key) {
    if (!node.hasFocus) return;
    _scrollIntoView(key);
  }

  void _scrollIntoView(GlobalKey targetKey) {
    final ctx = targetKey.currentContext;
    if (ctx == null) return;

    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        alignment: 0.12,
      );
    });
  }

  @override
  void dispose() {
    projectNameController.dispose();
    companyNameController.dispose();
    skillsController.dispose();
    durationController.dispose();
    detailsController.dispose();
    _typeFocusNode.dispose();
    _projectNameFocusNode.dispose();
    _companyNameFocusNode.dispose();
    _skillsFocusNode.dispose();
    _durationFocusNode.dispose();
    _durationPeriodFocusNode.dispose();
    _detailsFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String? getUserIdFromToken(String authToken) {
    try {
      final parts = authToken.split('.');
      if (parts.length != 3) return null;
      final payload = parts[1];
      final decoded = utf8.decode(base64Url.decode(base64Url.normalize(payload)));
      final payloadMap = jsonDecode(decoded) as Map<String, dynamic>;
      return payloadMap['id']?.toString();
    } catch (e) {
      print("❌ [EditProjectDetailsBottomSheet] Error decoding authToken: $e");
      return null;
    }
  }

  Future<void> _handleSave() async {
    if (saving) {
      print("⚠️ [EditProjectDetailsBottomSheet] Already saving, ignoring duplicate press");
      return;
    }

    if (!_formKey.currentState!.validate()) {
      print("⚠️ [EditProjectDetailsBottomSheet] Form validation failed");
      _showSnackBarOnce(context, 'Please correct the errors before saving', backgroundColor: Colors.red);
      return;
    }

    print('🔍 [EditProjectDetailsBottomSheet] Initiating save');
    setState(() => saving = true);

    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';
    final connectSid = prefs.getString('connectSid') ?? '';
    final userId = getUserIdFromToken(authToken) ?? prefs.getString('user_id') ?? '';

    print('[DEBUG] EditProjectBottomSheet authToken length: ${authToken.length}');
    print('[DEBUG] EditProjectBottomSheet connectSid length: ${connectSid.length}');

    if (authToken.isEmpty) {
      print('⚠️ [EditProjectDetailsBottomSheet] Missing authToken');
      _showSnackBarOnce(context, 'Error: Please log in again.', backgroundColor: Colors.red);
      setState(() => saving = false);
      return;
    }

    print('🔍 [EditProjectDetailsBottomSheet] authToken valid, connectSid optional');

    final newData = InternshipProjectModel(
      internshipId: widget.initialData?.internshipId,
      userId: userId.isNotEmpty ? userId : null,
      type: type,
      projectName: projectNameController.text.trim(),
      companyName: companyNameController.text.trim(),
      skills: skillsController.text.trim(),
      duration: durationController.text.trim(),
      durationPeriod: durationPeriod,
      details: detailsController.text.trim(),
    );

    try {
      final success = await InternshipProjectApi.saveInternshipProject(
        model: newData,
        authToken: authToken,
        connectSid: connectSid,
      );

      if (success) {
        print('✅ [EditProjectDetailsBottomSheet] Save successful');
        // call parent callback (support sync or future)
        final result = widget.onSave(newData);
        if (result is Future) await result;

        // Show success snackbar (do NOT pop)
        _showSnackBarOnce(context, 'Project saved successfully', backgroundColor: Colors.green);
        Navigator.of(context).pop();
      } else {
        print('⚠️ [EditProjectDetailsBottomSheet] Save failed');
        _showSnackBarOnce(context, 'Failed to save project. Please try again.', backgroundColor: Colors.red);
      }
    } catch (e, st) {
      print("❌ [EditProjectDetailsBottomSheet] Error saving project: $e\n$st");
      _showSnackBarOnce(context, 'Error: $e', backgroundColor: Colors.red);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.8,
      builder: (context, scrollController) {
        _sheetScrollController = scrollController;
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              padding: EdgeInsets.only(
                left: 14.4.w,
                right: 14.4.w,
                top: 9.h,
                bottom: MediaQuery.of(context).viewInsets.bottom + 9.h,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(18.1.r)),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Add Project Details',
                          style: TextStyle(
                            fontSize: 16.2.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF003840),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: const Color(0xFF005E6A), size: 17.7.w),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.only(bottom: 18.h),
                        children: [
                        _buildLabel("Project Type"),
                        GestureDetector(
                          key: _typeKey,
                          onTap: () => _scrollIntoView(_typeKey),
                          child: CustomFieldProjectDropdown(
                            ['Internship', 'Project'],
                            type,
                            (val) {
                              setState(() => type = val ?? 'Project');
                            },
                            label: 'Please select',
                          ),
                        ),
                    _buildLabel("Project Name"),
                    _buildTextField(
                      "Project Name",
                      projectNameController,
                      key: _projectNameKey,
                      focusNode: _projectNameFocusNode,
                      hintText: 'Enter project name',
                    ),
                    _buildLabel("Company Name"),
                    _buildTextField(
                      "Company Name",
                      companyNameController,
                      key: _companyNameKey,
                      focusNode: _companyNameFocusNode,
                      hintText: 'Enter company name',
                    ),
                    _buildLabel("Skills (comma-separated)"),
                    _buildTextField(
                      "Add Skills",
                      skillsController,
                      key: _skillsKey,
                      focusNode: _skillsFocusNode,
                      hintText: 'e.g. Flutter, Firebase, REST',
                    ),
                    _buildLabel("Duration (number only)"),
                    _buildTextField(
                      "Numbers only",
                      durationController,
                      keyboardType: TextInputType.number,
                      key: _durationKey,
                      focusNode: _durationFocusNode,
                      hintText: 'Enter duration like 14',
                    ),
                        _buildLabel("Duration Period"),
                        GestureDetector(
                          key: _durationPeriodKey,
                          onTap: () => _scrollIntoView(_durationPeriodKey),
                          child: CustomFieldProjectDropdown(
                            ['Days', 'Weeks', 'Month'],
                            durationPeriod,
                            (val) {
                              setState(() => durationPeriod = val ?? 'Days');
                            },
                            label: 'Please select',
                          ),
                        ),
                        _buildLabel("Project Details"),
                        _buildTextField(
                          "Add Details",
                          detailsController,
                          maxLines: 4,
                          key: _detailsKey,
                          focusNode: _detailsFocusNode,
                          hintText: 'Describe the project and your role',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 5.h),
                  ElevatedButton(
                    onPressed: saving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF005E6A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27.1.r),
                      ),
                      minimumSize: Size.fromHeight(45.1.h),
                    ),
                    child: saving
                        ? SizedBox(
                      height: 18.1.h,
                      width: 18.1.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8.w,
                        color: Colors.white,
                      ),
                    )
                        : Text(
                      'Save',
                      style: TextStyle(color: Colors.white, fontSize: 13.7.sp),
                    ),
                  ),
                  SizedBox(height: 30.h),
                ],
              ),
            ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: EdgeInsets.only(top: 10.8.h, bottom: 5.4.h),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 14.4.sp,
        fontWeight: FontWeight.w700,
        color: const Color(0xff003840),
      ),
    ),
  );

  Widget _buildTextField(
      String label,
      TextEditingController controller, {
        TextInputType keyboardType = TextInputType.text,
        int maxLines = 1,
        Key? key,
        FocusNode? focusNode,
        String hintText = '',
      }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.4.h),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        key: key,
        focusNode: focusNode,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 12.4.sp),
          hintText: hintText,
          hintStyle: TextStyle(fontSize: 12.4.sp),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.8.r)),
        ),
        style: TextStyle(fontSize: 12.4.sp),
        validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
      ),
    );
  }
}
