import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../Utilities/AllCourse_Api.dart';
import 'AsyncSearchDropDownField.dart';

/// CourseDropdownField
/// - value: Map like {'id': '123', 'text': 'B.Sc'}
/// - degreeId: id of selected degree (filters courses)
/// - onChanged: returns selected item map or null
///
/// Extra options:
/// - placeholder: text shown when nothing selected (falls back to label)
/// - allowClear: show a small clear button to clear selection
class CourseDropdownField extends StatefulWidget {
  final Map<String, String>? value;
  final String? degreeId;
  final void Function(Map<String, String>?) onChanged;
  final String label;
  final String? placeholder;
  final bool allowClear;

  const CourseDropdownField({
    Key? key,
    required this.value,
    required this.onChanged,
    this.degreeId,
    this.label = 'Select Course',
    this.placeholder,
    this.allowClear = true,
  }) : super(key: key);

  @override
  State<CourseDropdownField> createState() => _CourseDropdownFieldState();
}

class _CourseDropdownFieldState extends State<CourseDropdownField> {
  Map<String, String>? _currentValue;
  String? _lastDegreeId;
  bool _isClearingProgrammatically = false;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
    _lastDegreeId = widget.degreeId;
  }

  @override
  void didUpdateWidget(covariant CourseDropdownField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If degree changed externally, clear selection so user picks a course for the new degree.
    if ((oldWidget.degreeId ?? '') != (widget.degreeId ?? '')) {
      // Avoid re-notifying parent if we ourselves triggered the clear.
      _isClearingProgrammatically = true;
      setState(() {
        _currentValue = null;
      });
      // Notify parent the selection was cleared (useful so parent can react).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onChanged(null);
        _isClearingProgrammatically = false;
      });
    } else if ((oldWidget.value ?? {}) != (widget.value ?? {})) {
      // External value update -> reflect it
      setState(() {
        _currentValue = widget.value;
      });
    }

    _lastDegreeId = widget.degreeId;
  }

  Future<List<Map<String, String>>> _fetcher(
      {int page = 1, String? query}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      final connectSid = prefs.getString('connectSid') ?? '';

      // Uses your existing AllCourse_Api (CourseListApi) which must support pagination.
      // Signature expected:
      // fetchCoursesWithIds({int page = 1, String? query, String? degreeId, required String authToken, required String connectSid, int limit = 10})
      return await CourseListApi.fetchCoursesWithIds(
        page: page,
        query: query,
        degreeId: widget.degreeId,
        authToken: authToken,
        connectSid: connectSid,
      );
    } catch (e, st) {
      debugPrint('CourseDropdownField.fetcher error: $e\n$st');
      return [];
    }
  }

  void _handleChanged(Map<String, String>? item) {
    setState(() => _currentValue = item);
    if (!_isClearingProgrammatically) widget.onChanged(item);
  }

  void _clearSelection() {
    setState(() {
      _currentValue = null;
    });
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final placeholderText = widget.placeholder ?? widget.label;

    return Row(
      children: [
        Expanded(
          child: AsyncSearchableDropdownField(
            value: _currentValue,
            fetcher: ({int page = 1, String? query}) =>
                _fetcher(page: page, query: query),
            onChanged: _handleChanged,
            label: placeholderText,
          ),
        ),

        if (widget.allowClear)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: GestureDetector(
              onTap: () {
                if (_currentValue != null) {
                  _clearSelection();
                }
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _currentValue == null
                      ? Colors.transparent
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.clear,
                  size: 20,
                  color: _currentValue == null
                      ? Colors.grey.shade400
                      : Colors.black,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
