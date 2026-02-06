import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';

import '../../../Model/PersonalDetailPost_Model.dart';
import '../../../ProfileLogic/ProfileEvent.dart';
import '../../../ProfileLogic/ProfileLogic.dart';
import '../../../Utilities/ApiConstants.dart';
import '../../../Utilities/MyAccount_Get_Post/PostApi_Personal_Detail.dart';
import '../../../Utilities/StateList_Api.dart';
import '../../../Utilities/CityList_Api.dart';
import '../../../Model/PersonalDetail_Model.dart';
import 'CustomDropDowns/CustomDropDownPersonalDetail.dart';

import 'UpdateEmailBottomSheet.dart';
import 'UpdateMobileNumberBottomSheet.dart';
import 'UpdateWhatsappNumberBottomSheet.dart';
import 'package:skillsconnect/utils/session_guard.dart';

class EditPersonalDetailsSheet extends StatefulWidget {
  final PersonalDetailModel? initialData;
  final Function(PersonalDetailModel) onSave;

  const EditPersonalDetailsSheet({
    super.key,
    required this.initialData,
    required this.onSave,
  });

  @override
  State<EditPersonalDetailsSheet> createState() =>
      _EditPersonalDetailsSheetState();
}

class _EditPersonalDetailsSheetState extends State<EditPersonalDetailsSheet>
    with SingleTickerProviderStateMixin {
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController dobController;
  late TextEditingController phoneController;
  late TextEditingController whatsappController;
  late TextEditingController emailController;
  late String selectedState;
  late String selectedCity;
  bool isLoadingStates = true;
  bool isLoadingCities = false;
  bool isSubmitting = false;
  List<String> states = [];
  List<String> cities = ['Select a state first'];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final GlobalKey _firstNameKey = GlobalKey();
  final GlobalKey _lastNameKey = GlobalKey();
  final GlobalKey _dobKey = GlobalKey();
  final GlobalKey _phoneKey = GlobalKey();
  final GlobalKey _whatsappKey = GlobalKey();
  final GlobalKey _emailKey = GlobalKey();
  final GlobalKey _stateKey = GlobalKey();
  final GlobalKey _cityKey = GlobalKey();
  final GlobalKey _saveButtonKey = GlobalKey();
  final FocusNode _firstNameFocusNode = FocusNode();
  final FocusNode _lastNameFocusNode = FocusNode();
  final FocusNode _dobFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _whatsappFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final Color _titleColor = const Color(0xFF003840);
  final Color _borderColor = const Color(0xFFD0DDDC);
  final Color _fieldFill = const Color(0xFFF0F7F7);
  final Color _accent = const Color(0xFF005E6A);
  bool _snackBarShown = false;
  OverlayEntry? _overlayEntry;
  ScrollController? _scrollController;

  void _showSnackBarOnce(String message,
      {Color bg = Colors.red, int seconds = 2}) {
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
              color: bg,
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

    Future.delayed(Duration(seconds: seconds), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _snackBarShown = false;
    });
  }

  @override
  void initState() {
    super.initState();
    firstNameController =
        TextEditingController(text: widget.initialData?.firstName ?? '');
    lastNameController =
        TextEditingController(text: widget.initialData?.lastName ?? '');
    dobController =
        TextEditingController(text: widget.initialData?.dateOfBirth ?? '');
    phoneController =
        TextEditingController(text: widget.initialData?.mobile ?? '');
    
    whatsappController = TextEditingController(
      text: widget.initialData?.whatsAppNumber ?? '');
    
    emailController =
        TextEditingController(text: widget.initialData?.email ?? '');
    selectedState = widget.initialData?.state ?? '';
    selectedCity = widget.initialData?.city ?? '';
    

    _animationController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);

    // Add listeners to scroll fields into view when focused
    _firstNameFocusNode.addListener(() => _scrollToField(_firstNameKey));
    _lastNameFocusNode.addListener(() => _scrollToField(_lastNameKey));
    _dobFocusNode.addListener(() => _scrollToField(_dobKey));

    _fetchStateList();
  }

  void _scrollToField(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
      }
    });
  }

  Future<void> _fetchStateList() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedStates = prefs.getStringList('cached_states');

    if (cachedStates != null && cachedStates.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        states = cachedStates;
        selectedState =
            states.contains(selectedState) ? selectedState : states.first;
        isLoadingStates = false;
      });
      _animationController.forward();
      await _fetchCityList();
      return;
    }

    final authToken = prefs.getString('authToken') ?? '';
    final connectSid = prefs.getString('connectSid') ?? '';

    try {
      final fetchedStates = await StateListApi.fetchStates(
          countryId: '101', authToken: authToken, connectSid: connectSid);
      if (!mounted) return;
      setState(() {
        states =
            fetchedStates.isNotEmpty ? fetchedStates : ['No States Available'];
        selectedState =
            states.contains(selectedState) ? selectedState : states.first;
        isLoadingStates = false;
      });
      prefs.setStringList('cached_states', states);
      _animationController.forward();
      await _fetchCityList();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        states = ['No States Available'];
        selectedState = states.first;
        isLoadingStates = false;
      });
      _animationController.forward();
    }
  }

  Future<void> _fetchCityList() async {
    if (selectedState == 'No States Available' || selectedState.isEmpty) {
      setState(() {
        cities = ['Select a state first'];
        selectedCity = cities.first;
        isLoadingCities = false;
      });
      return;
    }

    setState(() => isLoadingCities = true);

    final prefs = await SharedPreferences.getInstance();
    final cachedCities = prefs.getStringList('cached_cities_$selectedState');
    if (cachedCities != null && cachedCities.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        cities = cachedCities;
        selectedCity =
            cities.contains(selectedCity) ? selectedCity : cities.first;
        isLoadingCities = false;
      });
      return;
    }

    final authToken = prefs.getString('authToken') ?? '';
    final connectSid = prefs.getString('connectSid') ?? '';
    final stateId = await _resolveStateId(selectedState);

    try {
      final fetchedCities = await CityListApi.fetchCities(
          cityName: '',
          stateId: stateId,
          authToken: authToken,
          connectSid: connectSid);
      if (!mounted) return;
      setState(() {
        cities =
            fetchedCities.isNotEmpty ? fetchedCities : ['No Cities Available'];
        selectedCity =
            cities.contains(selectedCity) ? selectedCity : cities.first;
        isLoadingCities = false;
      });
      prefs.setStringList('cached_cities_$selectedState', cities);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        cities = ['No Cities Available'];
        selectedCity = cities.first;
        isLoadingCities = false;
      });
    }
  }

  Future<String> _resolveStateId(String stateName) async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';
    final connectSid = prefs.getString('connectSid') ?? '';

    try {
      final response = await http.post(
        Uri.parse('${ApiConstantsStu.subUrl}master/state/list'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'authToken=$authToken; connect.sid=$connectSid',
        },
        body: jsonEncode({"country_id": 101, "state_name": stateName}),
      );

      // 🔸 Scan for session issues (401 logout)
      await SessionGuard.scan(statusCode: response.statusCode);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true &&
            data['data'] is List &&
            data['data'].isNotEmpty) {
          return data['data'][0]['id'].toString();
        }
      }
    } catch (_) {}
    return '';
  }

  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(widget.initialData?.dateOfBirth ?? '') ??
          DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF005E6A),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      dobController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      setState(() {});
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    dobController.dispose();
    phoneController.dispose();
    whatsappController.dispose();
    emailController.dispose();
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _dobFocusNode.dispose();
    _phoneFocusNode.dispose();
    _whatsappFocusNode.dispose();
    _emailFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    // When keyboard opens, scroll to show all content above it
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (keyboardHeight > 0 && _scrollController != null && _scrollController!.hasClients) {
        final maxScroll = _scrollController!.position.maxScrollExtent;
        _scrollController!.jumpTo(maxScroll);
      }
    });

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.9,
      builder: (_, scrollController) {
        _scrollController = scrollController;
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Container(
            padding: EdgeInsets.only(
              left: 18.1.w,
              right: 18.1.w,
              top: 18.1.h,
              bottom: MediaQuery.of(context).viewInsets.bottom + 18.1.h,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18.1.r)),
            ),
            child: isLoadingStates
                ? const Center(child: CircularProgressIndicator())
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: ListView(
                      controller: scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Edit Personal Details',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.2.sp,
                                color: _titleColor,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: Icon(Icons.close,
                                  color: _accent, size: 17.7.w),
                            ),
                          ],
                        ),
                        _buildLabel('First Name'),
                        _buildTextField('Enter first name', firstNameController,
                            key: _firstNameKey, focusNode: _firstNameFocusNode),
                        _buildLabel('Last Name'),
                        _buildTextField('Enter last name', lastNameController,
                            key: _lastNameKey, focusNode: _lastNameFocusNode),
                        _buildLabel('Date of Birth'),
                        _buildTextField('Select DOB', dobController,
                            readOnly: true,
                            suffixIcon: Icons.calendar_today,
                            onTap: () {
                              _scrollToField(_dobKey);
                              Future.delayed(const Duration(milliseconds: 50), _selectDate);
                            },
                            key: _dobKey,
                            focusNode: _dobFocusNode),
                        _buildLabelWithEdit(
                          'Mobile Number', _openUpdateMobileSheet),
                        _buildMobileField(),
                        _buildLabelWithEdit(
                          'WhatsApp', _openUpdateWhatsAppSheet),
                        _buildWhatsAppField(),
                        _buildLabelWithEdit('Email', _openUpdateEmailSheet),
                        _buildRoundedEmailField(),
                        _buildLabel('State'),
                        CustomFieldPersonalDetail(
                          key: _stateKey,
                          states,
                          selectedState,
                          (val) async {
                            setState(() {
                              selectedState = val ?? states.first;
                              selectedCity = '';
                              cities = ['Select a state first'];
                              isLoadingCities = true;
                            });
                            await _fetchCityList();
                          },
                          label: 'Select a state',
                          onBeforeTap: () => _scrollToField(_stateKey),
                        ),
                        _buildLabel('City'),
                        Stack(
                          children: [
                            CustomFieldPersonalDetail(
                              key: _cityKey,
                              cities,
                              selectedCity,
                              (val) {
                                setState(
                                    () => selectedCity = val ?? cities.first);
                              },
                              label: 'Select a city',
                              onBeforeTap: () => _scrollToField(_cityKey),
                            ),
                            if (isLoadingCities)
                              const Positioned.fill(
                                child: IgnorePointer(
                                  child: Center(
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2)),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 27.1.h),
                        ElevatedButton(
                          onPressed: isSubmitting ? null : _onSavePressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(27.1.r)),
                            minimumSize: Size.fromHeight(45.1.h),
                          ),
                          child: isSubmitting
                              ? SizedBox(
                                  height: 18.1.h,
                                  width: 18.1.w,
                                  child: const CircularProgressIndicator(
                                      strokeWidth: 1.8, color: Colors.white),
                                )
                              : Text(
                              'Save',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 13.7.sp)
                          ),
                        ),
                        SizedBox(height: 9.h),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  void _onSavePressed() async {
    setState(() => isSubmitting = true);

    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final dob = dobController.text.trim();
    final mobile = phoneController.text.trim();
    final whatsapp = whatsappController.text.trim();
    final email = emailController.text.trim();

    // Basic required validation
    if (firstName.isEmpty || lastName.isEmpty || dob.isEmpty) {
      _showSnackBarOnce('Please fill all required fields (First, Last, DOB)');
      setState(() => isSubmitting = false);
      return;
    }

    // State/City validation
    if (selectedState == 'No States Available' ||
        selectedState.isEmpty ||
        selectedCity.isEmpty ||
        selectedCity == 'Select a state first' ||
        selectedCity.contains('No')) {
      _showSnackBarOnce('Please select a valid state and city');
      setState(() => isSubmitting = false);
      return;
    }

    // Mobile validation
    final mobileValid = RegExp(r'^[6-9][0-9]{9}$').hasMatch(mobile);
    if (mobile.isNotEmpty && !mobileValid) {
      _showSnackBarOnce('Please enter a valid 10-digit mobile number');
      setState(() => isSubmitting = false);
      return;
    }

    // WhatsApp validation (optional, but if provided, must be 10 digits)
    if (whatsapp.isNotEmpty && !RegExp(r'^[6-9][0-9]{9}$').hasMatch(whatsapp)) {
      _showSnackBarOnce('Please enter a valid 10-digit WhatsApp number');
      setState(() => isSubmitting = false);
      return;
    }

    // Email format validation (if not empty)
    if (email.isNotEmpty && !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      _showSnackBarOnce('Please enter a valid email address');
      setState(() => isSubmitting = false);
      return;
    }

    final request = PersonalDetailUpdateRequest(
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: dob,
      state: selectedState,
      city: selectedCity,
    );

    await PersonalDetailPostApi.updatePersonalDetails(
      context: context,
      request: request,
      onSuccess: () {
        final updatedData = PersonalDetailModel(
          firstName: firstName,
          lastName: lastName,
          mobile: mobile,
          whatsAppNumber: whatsapp,
          dateOfBirth: dob,
          email: email,
          state: selectedState,
          city: selectedCity,
        );
        widget.onSave(updatedData);
        if (context.mounted) {
          context.read<ProfileBloc>().add(LoadProfileData());
          _showSnackBarOnce('Personal details updated', bg: Colors.green);
          Navigator.of(context).pop();
        }
      },
      firstName: firstName,
      lastName: lastName,
      dob: dob,
      state: selectedState,
      city: selectedCity,
    );

    if (mounted) setState(() => isSubmitting = false);
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(top: 14.4.h, bottom: 5.4.h),
      child: Text(text,
          style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14.4.sp,
              color: _titleColor)),
    );
  }

  Widget _buildLabelWithEdit(String text, VoidCallback onEdit) {
    return Padding(
      padding: EdgeInsets.only(top: 14.4.h, bottom: 5.4.h),
      child: Row(
        children: [
          Text(text,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.4.sp,
                  color: _titleColor)),
          const Spacer(),
          IconButton(
            onPressed: onEdit,
            icon: Icon(Icons.edit, color: _accent, size: 17.7.w),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Edit $text',
          ),
        ],
      ),
    );
  }

  Widget _roundedPhoneField({
    required TextEditingController controller,
    required String hint,
    required FocusNode? focusNode,
    required Key? key,
    bool showTick = false,
    bool readOnly = false,
  }) {
    final fillColor = readOnly ? Colors.grey.shade200 : _fieldFill;
    final textColor = readOnly ? Colors.grey.shade700 : Colors.black;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: _borderColor, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20.r)),
            child: Text(
                '+91',
                style: TextStyle(
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.4.sp)),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: TextField(
              key: key,
              focusNode: focusNode,
              controller: controller,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10)
              ],
              readOnly: readOnly,
              enableInteractiveSelection: !readOnly,
              showCursor: !readOnly,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(fontSize: 12.4.sp),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
              ),
              style: TextStyle(fontSize: 12.4.sp, color: textColor),
              onChanged: readOnly ? null : (_) => setState(() {}),
            ),
          ),
          if (showTick)
            Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: Icon(Icons.check_circle, color: Colors.green, size: 18.w),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileField() {
    final mobileText = phoneController.text.trim();
    final mobileValid = RegExp(r'^[6-9][0-9]{9}$').hasMatch(mobileText);
    return _roundedPhoneField(
      controller: phoneController,
      hint: 'Enter mobile',
      focusNode: _phoneFocusNode,
      key: _phoneKey,
      showTick: mobileValid,
      readOnly: true,
    );
  }

  Widget _buildWhatsAppField() {
    final whatsappText = whatsappController.text.trim();
    final whatsappValid = RegExp(r'^[6-9][0-9]{9}$').hasMatch(whatsappText);
    return _roundedPhoneField(
      controller: whatsappController,
      hint: 'Enter WhatsApp number',
      focusNode: _whatsappFocusNode,
      key: _whatsappKey,
      showTick: whatsappValid,
      readOnly: true,
    );
  }

  Widget _buildRoundedEmailField() {
    bool emailLooksValid(String e) {
      final v = e.trim();
      final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
      return regex.hasMatch(v);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(color: _borderColor, width: 1.2)),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
            child: Icon(Icons.mail_outline, size: 17.7.w, color: _titleColor),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: TextField(
              key: _emailKey,
              focusNode: _emailFocusNode,
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              readOnly: true,
              enableInteractiveSelection: false,
              showCursor: false,
              decoration: InputDecoration(
                hintText: 'Enter Email',
                hintStyle: TextStyle(fontSize: 12.4.sp),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
              ),
              style: TextStyle(fontSize: 12.4.sp, color: Colors.grey.shade700),
              onChanged: null,
            ),
          ),
          if (emailLooksValid(emailController.text))
            Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: Icon(Icons.check_circle, color: Colors.green, size: 18.w),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String hint,
    TextEditingController controller, {
    bool readOnly = false,
    IconData? suffixIcon,
    VoidCallback? onTap,
    Key? key,
    FocusNode? focusNode,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      key: key,
      focusNode: focusNode,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 12.4.sp),
        suffixIcon: suffixIcon != null ? Icon(suffixIcon, size: 17.7.w) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.8.r)),
      ),
      style: TextStyle(fontSize: 12.4.sp),
    );
  }

  Future<void> _openUpdateMobileSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UpdateMobileBottomSheet(
        initialNumber: phoneController.text,
        onSuccess: (String newNumber) async {
          phoneController.text = newNumber;
          whatsappController.text = newNumber;
          setState(() {});
        },
      ),
    );
  }

  Future<void> _openUpdateWhatsAppSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UpdateWhatsAppBottomSheet(
        initialNumber: whatsappController.text,
        onSuccess: (String newNumber) async {
          whatsappController.text = newNumber;
          setState(() {});
        },
      ),
    );
  }

  Future<void> _openUpdateEmailSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const UpdateEmailBottomSheet(),
    );
  }
}
