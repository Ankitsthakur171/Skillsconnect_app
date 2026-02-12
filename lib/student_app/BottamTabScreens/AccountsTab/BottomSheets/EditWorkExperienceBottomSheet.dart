import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../Model/WorkExperience_Model.dart';
import 'CustomDropDowns/CustomDropdownEducation.dart';

class EditWorkExperienceBottomSheet extends StatefulWidget {
  final WorkExperienceModel? initialData;
  final Function(WorkExperienceModel) onSave;

  const EditWorkExperienceBottomSheet({
    super.key,
    required this.initialData,  
    required this.onSave,
  });

  @override
  State<EditWorkExperienceBottomSheet> createState() =>
      _EditWorkExperienceBottomSheetState();
}

class _EditWorkExperienceBottomSheetState
    extends State<EditWorkExperienceBottomSheet>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _jobTitleController;
  late TextEditingController _organizationController;
  late TextEditingController _skillsController;
  late TextEditingController _jobDescriptionController;

  late FocusNode _jobTitleFocus;
  late FocusNode _organizationFocus;
  late FocusNode _skillsFocus;
  late FocusNode _jobDescriptionFocus;

  final GlobalKey _jobTitleKey = GlobalKey();
  final GlobalKey _organizationKey = GlobalKey();
  final GlobalKey _skillsKey = GlobalKey();
  final GlobalKey _jobDescriptionKey = GlobalKey();
  final GlobalKey _fromDateKey = GlobalKey();
  final GlobalKey _toDateKey = GlobalKey();

  final GlobalKey _fromMonthDropdownKey = GlobalKey();
  final GlobalKey _fromYearDropdownKey = GlobalKey();
  final GlobalKey _toMonthDropdownKey = GlobalKey();
  final GlobalKey _toYearDropdownKey = GlobalKey();
  final GlobalKey _experienceYearDropdownKey = GlobalKey();
  final GlobalKey _experienceMonthDropdownKey = GlobalKey();
  final GlobalKey _salaryLakhsDropdownKey = GlobalKey();
  final GlobalKey _salaryThousandsDropdownKey = GlobalKey();

  ScrollController? _sheetScrollController;

  late String _fromMonth;
  late String _fromYear;
  late String _toMonth;
  late String _toYear;

  late String experienceInYear;
  late String experienceInMonths;
  late String salaryInLakhs;
  late String salaryInThousands;
  late bool _isNewEntry;

  bool saving = false;

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

    _isNewEntry = widget.initialData == null;
    final currentYear = DateTime.now().year;

    _jobTitleController =
        TextEditingController(text: widget.initialData?.jobTitle ?? '');
    _organizationController =
        TextEditingController(text: widget.initialData?.organization ?? '');
    _skillsController =
        TextEditingController(text: widget.initialData?.skills ?? '');
    _jobDescriptionController =
        TextEditingController(text: widget.initialData?.jobDescription ?? '');

    _jobTitleFocus = FocusNode()
      ..addListener(() =>
          _onFieldFocus(_jobTitleFocus, _jobTitleKey));
    _organizationFocus = FocusNode()
      ..addListener(() =>
          _onFieldFocus(_organizationFocus, _organizationKey));
    _skillsFocus = FocusNode()
      ..addListener(() =>
          _onFieldFocus(_skillsFocus, _skillsKey));
    _jobDescriptionFocus = FocusNode()
      ..addListener(() =>
          _onFieldFocus(_jobDescriptionFocus, _jobDescriptionKey));

    // Handle empty strings from API by providing defaults
    if (widget.initialData != null) {
      _fromMonth = (widget.initialData?.exStartMonth?.isEmpty ?? true)
          ? 'Jan'
          : widget.initialData!.exStartMonth;
      _fromYear = (widget.initialData?.exStartYear?.isEmpty ?? true)
          ? currentYear.toString()
          : widget.initialData!.exStartYear;
      _toMonth = (widget.initialData?.exEndMonth?.isEmpty ?? true)
          ? 'Jan'
          : widget.initialData!.exEndMonth;
      _toYear = (widget.initialData?.exEndYear?.isEmpty ?? true)
          ? currentYear.toString()
          : widget.initialData!.exEndYear;
    } else {
      // New work experience: use placeholder values
      _fromMonth = 'Please select';
      _fromYear = 'Please select';
      _toMonth = 'Please select';
      _toYear = 'Please select';
    }

    experienceInYear = (widget.initialData?.totalExperienceYears?.isEmpty ?? true)
        ? (widget.initialData == null ? 'Please select' : '0')
        : widget.initialData!.totalExperienceYears;
    experienceInMonths = (widget.initialData?.totalExperienceMonths?.isEmpty ?? true)
        ? (widget.initialData == null ? 'Please select' : '0')
        : widget.initialData!.totalExperienceMonths;
    salaryInLakhs = (widget.initialData?.salaryInLakhs?.isEmpty ?? true)
        ? (widget.initialData == null ? 'Please select' : '0')
        : widget.initialData!.salaryInLakhs;
    salaryInThousands = (widget.initialData?.salaryInThousands?.isEmpty ?? true)
        ? (widget.initialData == null ? 'Please select' : '0')
        : widget.initialData!.salaryInThousands;

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

  void _closeAllDropdowns() {
    (_fromMonthDropdownKey.currentState as dynamic)?.closeDropdown();
    (_fromYearDropdownKey.currentState as dynamic)?.closeDropdown();
    (_toMonthDropdownKey.currentState as dynamic)?.closeDropdown();
    (_toYearDropdownKey.currentState as dynamic)?.closeDropdown();
    (_experienceYearDropdownKey.currentState as dynamic)?.closeDropdown();
    (_experienceMonthDropdownKey.currentState as dynamic)?.closeDropdown();
    (_salaryLakhsDropdownKey.currentState as dynamic)?.closeDropdown();
    (_salaryThousandsDropdownKey.currentState as dynamic)?.closeDropdown();
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
    _jobTitleController.dispose();
    _organizationController.dispose();
    _skillsController.dispose();
    _jobDescriptionController.dispose();

    _jobTitleFocus.dispose();
    _organizationFocus.dispose();
    _skillsFocus.dispose();
    _jobDescriptionFocus.dispose();

    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBarOnce(context, 'Please correct the errors before saving');
      return;
    }

    // Additional validation for required fields
    if (_jobTitleController.text.trim().isEmpty) {
      _showSnackBarOnce(context, 'Job Title is required');
      return;
    }

    if (_organizationController.text.trim().isEmpty) {
      _showSnackBarOnce(context, 'Company Name is required');
      return;
    }

    if (_skillsController.text.trim().isEmpty) {
      _showSnackBarOnce(context, 'Skills are required');
      return;
    }

    if (_jobDescriptionController.text.trim().isEmpty) {
      _showSnackBarOnce(context, 'Job Details are required');
      return;
    }

    setState(() => saving = true);
    final workExperience = WorkExperienceModel(
      workExperienceId: widget.initialData?.workExperienceId,
      jobTitle: _jobTitleController.text.trim(),
      organization: _organizationController.text.trim(),
      skills: _skillsController.text.trim(),
      workFromDate: '$_fromMonth-$_fromYear',
      workToDate: '$_toMonth-$_toYear',
      totalExperienceYears: experienceInYear,
      totalExperienceMonths: experienceInMonths,
      salaryInLakhs: salaryInLakhs,
      salaryInThousands: salaryInThousands,
      jobDescription: _jobDescriptionController.text.trim(),
      exStartMonth: _fromMonth,
      exStartYear: _fromYear,
      exEndMonth: _toMonth,
      exEndYear: _toYear,
    );

    try {
      final result = widget.onSave(workExperience);
      bool success = false;
      if (result is Future<bool>) {
        success = await result;
      } else if (result is bool) {
        success = result;
      }

      if (mounted) {
        setState(() => saving = false);
        if (success) {
          _showSnackBarOnce(
            context,
            'Work experience saved successfully',
            backgroundColor: Colors.green,
          );
        } else {
          _showSnackBarOnce(
            context,
            'Failed to save work experience. Please check all required fields.',
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => saving = false);
        _showSnackBarOnce(
          context,
          'Failed to save work experience: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;
    
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.8,
      builder: (context, scrollController) {
        _sheetScrollController = scrollController;
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            padding: EdgeInsets.only(
              left: 18.1.w,
              right: 18.1.w,
              top: 9.h,
              bottom: keyboardPadding > 0 ? keyboardPadding : 9.h,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18.1.r)),
            ),
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) {
                _closeAllDropdowns();
                FocusScope.of(context).unfocus();
              },
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Work Experience',
                        style: TextStyle(
                          fontSize: 16.2.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF003840),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close,
                            color: const Color(0xFF005E6A), size: 17.7.w),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.only(
                        bottom: 18.h,
                      ),
                      children: [
                        _buildLabel("Job Title"),
                        _buildTextField("Enter Job name", _jobTitleController, required: true, focusNode: _jobTitleFocus, fieldKey: _jobTitleKey),
                        _buildLabel("Company Name"),
                        _buildTextField("Enter issuing organization",
                            _organizationController, required: true, focusNode: _organizationFocus, fieldKey: _organizationKey),
                        _buildLabel("Add Skills"),
                        _buildTextField("Enter skills", _skillsController, required: true, focusNode: _skillsFocus, fieldKey: _skillsKey),
                        _buildLabel("From Date"),
                        _buildDateRow(
                          _fromMonth,
                          _fromYear,
                          (val) => setState(() => _fromMonth = val),
                          (val) => setState(() => _fromYear = val),
                          rowKey: _fromDateKey,
                          monthDropdownKey: _fromMonthDropdownKey,
                          yearDropdownKey: _fromYearDropdownKey,
                        ),
                        _buildLabel("To Date"),
                        _buildDateRow(
                          _toMonth,
                          _toYear,
                          (val) => setState(() => _toMonth = val),
                          (val) => setState(() => _toYear = val),
                          rowKey: _toDateKey,
                          monthDropdownKey: _toMonthDropdownKey,
                          yearDropdownKey: _toYearDropdownKey,
                        ),
                        _buildLabel("Experience"),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel("Years"),
                                  _dropdownField(
                                    value: experienceInYear,
                                    items: (widget.initialData == null)
                                        ? ["Please select", ...List.generate(31, (i) => "$i")]
                                        : List.generate(31, (i) => "$i"),
                                    onChanged: (val) =>
                                        setState(() => experienceInYear = val!),
                                    dropdownKey: _experienceYearDropdownKey,
                                    onBeforeOpen: _closeAllDropdowns,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 14.4.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel("Months"),
                                  _dropdownField(
                                    value: experienceInMonths,
                                    items: (widget.initialData == null)
                                        ? ["Please select", ...List.generate(12, (i) => "${i + 1}")]
                                        : List.generate(12, (i) => "${i + 1}"),
                                    onChanged: (val) => setState(
                                        () => experienceInMonths = val!),
                                    dropdownKey: _experienceMonthDropdownKey,
                                    onBeforeOpen: _closeAllDropdowns,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        _buildLabel("Current Salary"),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel("Lakhs"),
                                  _dropdownField(
                                    value: salaryInLakhs,
                                    items: (widget.initialData == null)
                                        ? ["Please select", ...List.generate(31, (i) => "$i")]
                                        : List.generate(31, (i) => "$i"),
                                    onChanged: (val) =>
                                        setState(() => salaryInLakhs = val!),
                                    dropdownKey: _salaryLakhsDropdownKey,
                                    onBeforeOpen: _closeAllDropdowns,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 14.4.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel("Thousands"),
                                  _dropdownField(
                                    value: salaryInThousands,
                                    items: (widget.initialData == null)
                                        ? ["Please select", "0", "5", "10", "15", "20", "25", "30", "35", "40", "45", "50", "55", "60", "65", "70", "75", "80", "85", "90", "95"]
                                        : ["0", "5", "10", "15", "20", "25", "30", "35", "40", "45", "50", "55", "60", "65", "70", "75", "80", "85", "90", "95"],
                                    onChanged: (val) => setState(
                                        () => salaryInThousands = val!),
                                    dropdownKey: _salaryThousandsDropdownKey,
                                    onBeforeOpen: _closeAllDropdowns,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        _buildLabel("Add Details"),
                        _buildTextField(
                            "Job details ", _jobDescriptionController, required: true, focusNode: _jobDescriptionFocus, fieldKey: _jobDescriptionKey),
                      ],
                    ),
                  ),
                  SizedBox(height: 18.h),
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
                            child: const CircularProgressIndicator(
                              strokeWidth: 1.8,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Save',
                            style: TextStyle(
                                color: Colors.white, fontSize: 13.7.sp),
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(top: 14.4.h, bottom: 5.4.h),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14.4.sp,
          fontWeight: FontWeight.w700,
          color: const Color(0xff003840),
        ),
      ),
    );
  }

  Widget _dropdownField({
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    GlobalKey? dropdownKey,
    VoidCallback? onBeforeOpen,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.4.h),
      child: NonSearchableDropdownField(
        key: dropdownKey,
        value: (value.isNotEmpty && items.contains(value)) ? value : (items.isNotEmpty ? items.first : value),
        items: items,
        onChanged: onChanged,
        label: 'Please select',
        onBeforeOpen: onBeforeOpen,
      ),
    );
  }

  Widget _buildTextField(String hintText, TextEditingController controller,
      {IconData? suffixIcon, bool readOnly = false, VoidCallback? onTap, bool required = false, FocusNode? focusNode, GlobalKey? fieldKey}) {
    return Container(
      key: fieldKey,
      padding: EdgeInsets.symmetric(vertical: 5.4.h),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        readOnly: readOnly,
        onTap: () {
          _closeAllDropdowns();
          onTap?.call();
        },
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(fontSize: 12.4.sp),
          suffixIcon: suffixIcon != null
              ? IconButton(
                  icon: Icon(suffixIcon, size: 17.7.w), onPressed: onTap
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.8.r),
          ),
        ),
        style: TextStyle(fontSize: 12.4.sp),
        validator: (value) =>
            (required && (value == null || value.trim().isEmpty))
                ? 'Required'
                : null,
      ),
    );
  }

  Widget _buildDateRow(String month, String year,
      Function(String) onMonthChanged, Function(String) onYearChanged, {GlobalKey? rowKey, required GlobalKey monthDropdownKey, required GlobalKey yearDropdownKey}) {
    final months = _isNewEntry
        ? ['Please select', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
        : ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final years = _isNewEntry
        ? ['Please select', ...List.generate(30, (index) => (2000 + index).toString())]
        : List.generate(30, (index) => (2000 + index).toString());
    return GestureDetector(
      key: rowKey,
      onTap: () {
        if (rowKey != null) {
          _scrollIntoView(rowKey);
        }
      },
      child: Row(
        children: [
          Expanded(
            child: _dropdownField(
              value: month,
              items: months,
              onChanged: (val) => onMonthChanged(val!),
              dropdownKey: monthDropdownKey,
              onBeforeOpen: _closeAllDropdowns,
            ),
          ),
          SizedBox(width: 14.4.w),
          Expanded(
            child: _dropdownField(
              value: year,
              items: years,
              onChanged: (val) => onYearChanged(val!),
              dropdownKey: yearDropdownKey,
              onBeforeOpen: _closeAllDropdowns,
            ),
          ),
        ],
      ),
    );
  }
}
