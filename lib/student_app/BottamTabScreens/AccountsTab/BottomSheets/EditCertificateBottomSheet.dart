import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../Model/CertificateDetails_Model.dart';
import 'CustomDropDowns/CustomDropDownCertificate.dart';

class EditCertificateBottomSheet extends StatefulWidget {
  final CertificateModel? initialData;
  final Function(CertificateModel) onSave;

  const EditCertificateBottomSheet({
    super.key,
    this.initialData,
    required this.onSave,
  });

  @override
  State<EditCertificateBottomSheet> createState() =>
      _EditCertificateBottomSheetState();
}

class _EditCertificateBottomSheetState extends State<EditCertificateBottomSheet>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _certificateNameController;
  late TextEditingController _issuedOrgController;
  late TextEditingController _credIdController;
  late TextEditingController _urlController;
  late TextEditingController _descriptionController;

  // Focus + keys to auto-scroll the active control into view
  late FocusNode _certificateNameFocus;
  late FocusNode _issuedOrgFocus;
  late FocusNode _credIdFocus;
  late FocusNode _urlFocus;
  late FocusNode _descriptionFocus;

  final GlobalKey _certificateNameKey = GlobalKey();
  final GlobalKey _issuedOrgKey = GlobalKey();
  final GlobalKey _credIdKey = GlobalKey();
  final GlobalKey _urlKey = GlobalKey();
  final GlobalKey _descriptionKey = GlobalKey();
  final GlobalKey _issueDateKey = GlobalKey();
  final GlobalKey _expiryDateKey = GlobalKey();

  final GlobalKey _issueMonthDropdownKey = GlobalKey();
  final GlobalKey _issueYearDropdownKey = GlobalKey();
  final GlobalKey _expiryMonthDropdownKey = GlobalKey();
  final GlobalKey _expiryYearDropdownKey = GlobalKey();

  ScrollController? _sheetScrollController;



  String _issueMonth = 'Jan';
  String _issueYear = '2025';
  String _expiryMonth = 'Jan';
  String _expiryYear = '2025';
  bool isSaving = false;

  // Animation
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

    final data = widget.initialData;

    _certificateNameController =
        TextEditingController(text: data?.certificateName ?? '');
    _issuedOrgController =
        TextEditingController(text: data?.issuedOrgName ?? '');
    _credIdController = TextEditingController(text: data?.credId ?? '');
    _urlController = TextEditingController(text: data?.url ?? '');
    _descriptionController =
        TextEditingController(text: data?.description ?? '');

    _certificateNameFocus = FocusNode()
      ..addListener(() {
        _onFieldFocus(_certificateNameFocus, _certificateNameKey);
      });
    _issuedOrgFocus = FocusNode()
      ..addListener(() {
        _onFieldFocus(_issuedOrgFocus, _issuedOrgKey);
      });
    _credIdFocus = FocusNode()
      ..addListener(() {
        _onFieldFocus(_credIdFocus, _credIdKey);
      });
    _urlFocus = FocusNode()
      ..addListener(() {
        _onFieldFocus(_urlFocus, _urlKey);
      });
    _descriptionFocus = FocusNode()
      ..addListener(() {
        _onFieldFocus(_descriptionFocus, _descriptionKey);
      });

    if (data != null) {
      final issueParts = data.issueDate.split('-');
      final expiryParts = data.expiryDate.split('-');
      if (issueParts.length == 2) {
        _issueYear = issueParts[0];
        _issueMonth = CertificateModel.numberToMonth(issueParts[1]);
      }
      if (expiryParts.length == 2) {
        _expiryYear = expiryParts[0];
        _expiryMonth = CertificateModel.numberToMonth(expiryParts[1]);
      }
    }

    _animationController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnimation = CurvedAnimation(
        parent: _animationController, curve: Curves.easeIn);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _animationController.forward();
    });
  }

  void _onFieldFocus(FocusNode node, GlobalKey key) {
    // DON'T close dropdowns here - GestureDetector.onTap already handled it
    // Just handle scrolling when focus is acquired
    if (node.hasFocus) {
      _scrollIntoView(key);
    }
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

  void _closeAllDropdowns() {
    (_issueMonthDropdownKey.currentState as dynamic)?.closeDropdown();
    (_issueYearDropdownKey.currentState as dynamic)?.closeDropdown();
    (_expiryMonthDropdownKey.currentState as dynamic)?.closeDropdown();
    (_expiryYearDropdownKey.currentState as dynamic)?.closeDropdown();
  }

  @override
  void dispose() {
    _certificateNameController.dispose();
    _issuedOrgController.dispose();
    _credIdController.dispose();
    _urlController.dispose();
    _descriptionController.dispose();

    _certificateNameFocus.dispose();
    _issuedOrgFocus.dispose();
    _credIdFocus.dispose();
    _urlFocus.dispose();
    _descriptionFocus.dispose();

    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBarOnce(context, 'Please correct the errors before saving',
          backgroundColor: Colors.red);
      return;
    }

    setState(() => isSaving = true);

    final certificate = CertificateModel(
      certificationId: widget.initialData?.certificationId,
      certificateName: _certificateNameController.text.trim(),
      issuedOrgName: _issuedOrgController.text.trim(),
      credId: _credIdController.text.trim(),
      issueDate: '$_issueYear-${CertificateModel.monthToNumber(_issueMonth)}',
      expiryDate:
          '$_expiryYear-${CertificateModel.monthToNumber(_expiryMonth)}',
      description: _descriptionController.text.trim(),
      url: _urlController.text.trim(),
      userId: widget.initialData?.userId,
    );

    try {
      final result = widget.onSave(certificate);
      if (result is Future) await result;

      if (mounted) {
        setState(() => isSaving = false);
        _showSnackBarOnce(context, 'Certificate saved successfully',
            backgroundColor: Colors.green);
      }
    } catch (e, st) {
      if (mounted) {
        setState(() => isSaving = false);
        _showSnackBarOnce(context, 'Failed to save certificate: $e',
            backgroundColor: Colors.red);
      }
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
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
              padding: EdgeInsets.only(
                left: 14.4.w,
                right: 14.4.w,
                top: 9.h,
                bottom: MediaQuery.of(context).viewInsets.bottom + 18.h,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(18.1.r)),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Edit Certificate Details',
                          style: TextStyle(
                            fontSize: 16.2.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, size: 17.7.w),
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
                        children: [
                          _buildLabel('Certificate Name'),
                          _buildTextField(
                            _certificateNameController,
                            hintText: 'Enter certificate name',
                            focusNode: _certificateNameFocus,
                            fieldKey: _certificateNameKey,
                          ),
                          _buildLabel('Issued Organization'),
                          _buildTextField(
                            _issuedOrgController,
                            hintText: 'Enter issuing organization',
                            focusNode: _issuedOrgFocus,
                            fieldKey: _issuedOrgKey,
                          ),
                          _buildLabel('Credential ID'),
                          _buildTextField(
                            _credIdController,
                            hintText: 'Enter credential ID',
                            required: false,
                            focusNode: _credIdFocus,
                            fieldKey: _credIdKey,
                          ),
                          _buildLabel('Credential URL'),
                          _buildTextField(
                            _urlController,
                            hintText: 'Enter credential URL',
                            required: false,
                            focusNode: _urlFocus,
                            fieldKey: _urlKey,
                          ),
                          _buildLabel('Description'),
                          _buildTextField(
                            _descriptionController,
                            hintText: 'Enter description',
                            required: false,
                            focusNode: _descriptionFocus,
                            fieldKey: _descriptionKey,
                          ),
                          _buildLabel('Issued Date'),
                          _buildDateRow(_issueMonth, _issueYear, _issueDateKey, (m) {
                            setState(() => _issueMonth = m);
                          }, (y) {
                            setState(() => _issueYear = y);
                          },
                            monthDropdownKey: _issueMonthDropdownKey,
                            yearDropdownKey: _issueYearDropdownKey,
                          ),
                          _buildLabel('Expiry Date'),
                          _buildDateRow(_expiryMonth, _expiryYear, _expiryDateKey, (m) {
                            setState(() => _expiryMonth = m);
                          }, (y) {
                            setState(() => _expiryYear = y);
                          },
                            monthDropdownKey: _expiryMonthDropdownKey,
                            yearDropdownKey: _expiryYearDropdownKey,
                          ),
                          SizedBox(height: 27.1.h),
                          ElevatedButton(
                            onPressed: isSaving ? null : _handleSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF005E6A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(27.1.r),
                              ),
                              minimumSize: Size.fromHeight(45.1.h),
                            ),
                            child: isSaving
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
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 13.7.sp),
                                  ),
                          ),
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

  Widget _buildLabel(String text) => Padding(
        padding: EdgeInsets.only(top: 10.8.h, bottom: 5.4.h),
        child: Text(text,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12.4.sp,
                color: const Color(0xff003840))),
      );

  Widget _buildTextField(TextEditingController controller,
      {String hintText = '', bool required = true, FocusNode? focusNode, Key? fieldKey}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.8.h),
      child: TextFormField(
        key: fieldKey,
        controller: controller,
        focusNode: focusNode,
        onTap: () {
          _closeAllDropdowns();
          if (focusNode != null && !focusNode.hasFocus) {
            focusNode.requestFocus();
          }
        },
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(fontSize: 12.4.sp),
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(10.8.r)),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 10.8.w, vertical: 7.2.h),
        ),
        style: TextStyle(fontSize: 12.4.sp),
        validator: (value) =>
            (required && (value == null || value.trim().isEmpty))
                ? 'Required'
                : null,
      ),
    );
  }

    Widget _buildDateRow(String month, String year, GlobalKey rowKey,
      Function(String) onMonthChanged, Function(String) onYearChanged,
      {required GlobalKey monthDropdownKey, required GlobalKey yearDropdownKey}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.8.h),
      child: Row(
        key: rowKey,
        children: [
          Expanded(
            child: CustomFieldCertificateDropdown(
              const [
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
              ],
              month,
              (val) => onMonthChanged(val ?? 'Jan'),
              label: 'Month',
              onBeforeOpen: _closeAllDropdowns,
              key: monthDropdownKey,
            ),
          ),
          SizedBox(width: 10.8.w),
          Expanded(
            child: CustomFieldCertificateDropdown(
              _yearItems()
                  .map((item) => item.value!)
                  .whereType<String>()
                  .toList(),
              year,
              (val) => onYearChanged(val ?? '2025'),
              label: 'Year',
              onBeforeOpen: _closeAllDropdowns,
              key: yearDropdownKey,
            ),
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<String>> _yearItems() {
    final currentYear = DateTime.now().year;
    final selectedYears = {
      int.tryParse(_issueYear) ?? currentYear,
      int.tryParse(_expiryYear) ?? currentYear,
    };
    final startYear = currentYear - 35;
    final endYear = currentYear + 10;
    final allYears = {
      for (int year = startYear; year <= endYear; year++) year,
      ...selectedYears,
    }.toList()
      ..sort((a, b) => b.compareTo(a));

    return allYears.map((year) {
      final yearStr = year.toString();
      return DropdownMenuItem(
          value: yearStr,
          child: Text(yearStr, style: TextStyle(fontSize: 12.4.sp)));
    }).toList();
  }
}
