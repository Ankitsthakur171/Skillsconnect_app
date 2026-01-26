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

  late String _fromMonth;
  late String _fromYear;
  late String _toMonth;
  late String _toYear;

  late String experienceInYear;
  late String experienceInMonths;
  late String salaryInLakhs;
  late String salaryInThousands;

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
    print('🔍 [EditWorkExperienceBottomSheet] Initializing');

    const validMonths = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    final currentYear = DateTime.now().year;
    final validYears =
        List<String>.generate(30, (i) => (currentYear - i).toString());

    _jobTitleController = TextEditingController(
      text: widget.initialData?.jobTitle ?? '',
    );
    _organizationController = TextEditingController(
      text: widget.initialData?.organization ?? '',
    );
    _skillsController = TextEditingController(
      text: widget.initialData?.skills ?? '',
    );
    _jobDescriptionController = TextEditingController(
      text: widget.initialData?.jobDescription ?? '',
    );

    _fromMonth = validMonths.contains(widget.initialData?.exStartMonth)
        ? widget.initialData!.exStartMonth
        : 'Jan';

    _fromYear = validYears.contains(widget.initialData?.exStartYear)
        ? widget.initialData!.exStartYear
        : currentYear.toString();

    _toMonth = validMonths.contains(widget.initialData?.exEndMonth)
        ? widget.initialData!.exEndMonth
        : 'Jan';

    _toYear = validYears.contains(widget.initialData?.exEndYear)
        ? widget.initialData!.exEndYear
        : currentYear.toString();

    experienceInYear = widget.initialData?.totalExperienceYears ?? '0';
    experienceInMonths = widget.initialData?.totalExperienceMonths ?? '0';
    salaryInLakhs = widget.initialData?.salaryInLakhs ?? '0';
    salaryInThousands = widget.initialData?.salaryInThousands ?? '0';

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _animationController.forward();
    });
  }

  @override
  void dispose() {
    _jobTitleController.dispose();
    _organizationController.dispose();
    _skillsController.dispose();
    _jobDescriptionController.dispose();
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
      if (result is Future) await result;

      if (mounted) {
        setState(() => saving = false);
        _showSnackBarOnce(
          context,
          'Work experience saved successfully',
          backgroundColor: Colors.green,
        );
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
      maxChildSize: 0.9,
      minChildSize: 0.9,
      builder: (context, scrollController) {
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
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.only(
                        bottom: 24.h,
                      ),
                      children: [
                        _buildLabel("Job Title"),
                        _buildTextField("Enter Job name", _jobTitleController, required: true),
                        _buildLabel("Company Name"),
                        _buildTextField("Enter issuing organization",
                            _organizationController, required: true),
                        _buildLabel("Add Skills"),
                        _buildTextField("Enter skills", _skillsController, required: true),
                        _buildLabel("From Date"),
                        _buildDateRow(
                          _fromMonth,
                          _fromYear,
                          (val) => setState(() => _fromMonth = val),
                          (val) => setState(() => _fromYear = val),
                        ),
                        _buildLabel("To Date"),
                        _buildDateRow(
                          _toMonth,
                          _toYear,
                          (val) => setState(() => _toMonth = val),
                          (val) => setState(() => _toYear = val),
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
                                    items: List.generate(31, (i) => "$i"),
                                    onChanged: (val) =>
                                        setState(() => experienceInYear = val!),
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
                                    items: List.generate(12, (i) => "${i + 1}"),
                                    onChanged: (val) => setState(
                                        () => experienceInMonths = val!),
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
                                    items: List.generate(31, (i) => "$i"),
                                    onChanged: (val) =>
                                        setState(() => salaryInLakhs = val!),
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
                                    items: [
                                      "0",
                                      "5",
                                      "10",
                                      "15",
                                      "20",
                                      "25",
                                      "30",
                                      "35",
                                      "40",
                                      "45",
                                      "50",
                                      "55",
                                      "60",
                                      "65",
                                      "70",
                                      "75",
                                      "80",
                                      "85",
                                      "90",
                                      "95"
                                    ],
                                    onChanged: (val) => setState(
                                        () => salaryInThousands = val!),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        _buildLabel("Add Details"),
                        _buildTextField(
                            "Job details ", _jobDescriptionController, required: true),
                        SizedBox(height: 27.1.h),
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
                        SizedBox(height: 9.h),
                      ],
                    ),
                  ),
                ],
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
  }) {
    final focusNode = FocusNode();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.4.h),
      child: EnsureVisibleWhenFocused(
        focusNode: focusNode,
        child: NonSearchableDropdownField(
          value:
              value.isNotEmpty && items.contains(value) ? value : items.first,
          items: items,
          onChanged: onChanged,
          label: 'Please select',
        ),
      ),
    );
  }

  Widget _buildTextField(String hintText, TextEditingController controller,
      {IconData? suffixIcon, bool readOnly = false, VoidCallback? onTap, bool required = false}) {
    final focusNode = FocusNode();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.4.h),
      child: EnsureVisibleWhenFocused(
        focusNode: focusNode,
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          readOnly: readOnly,
          onTap: onTap,
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
      ),
    );
  }

  Widget _buildDateRow(String month, String year,
      Function(String) onMonthChanged, Function(String) onYearChanged) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final years = List.generate(30, (index) => (2000 + index).toString());
    return Row(
      children: [
        Expanded(
          child: _dropdownField(
            value: month,
            items: months,
            onChanged: (val) => onMonthChanged(val!),
          ),
        ),
        SizedBox(width: 14.4.w),
        Expanded(
          child: _dropdownField(
            value: year,
            items: years,
            onChanged: (val) => onYearChanged(val!),
          ),
        ),
      ],
    );
  }
}

class EnsureVisibleWhenFocused extends StatefulWidget {
  final FocusNode focusNode;
  final Widget child;

  const EnsureVisibleWhenFocused({
    super.key,
    required this.focusNode,
    required this.child,
  });

  @override
  State<EnsureVisibleWhenFocused> createState() =>
      _EnsureVisibleWhenFocusedState();
}

class _EnsureVisibleWhenFocusedState extends State<EnsureVisibleWhenFocused> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_ensureVisible);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_ensureVisible);
    super.dispose();
  }

  void _ensureVisible() {
    if (widget.focusNode.hasFocus) {
      final RenderObject? object = context.findRenderObject();
      if (object is RenderBox) {
        final ScrollableState? scrollable = Scrollable.of(context);
        if (scrollable != null) {
          final position = scrollable.position;
          position.ensureVisible(
            object,
            alignment: 0.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
