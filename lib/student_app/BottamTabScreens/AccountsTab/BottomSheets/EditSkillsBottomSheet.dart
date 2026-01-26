import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:skillsconnect/utils/session_guard.dart';
import '../../../Model/Skiils_Model.dart';
import '../../../Utilities/ApiConstants.dart';

class EditSkillsBottomSheet extends StatefulWidget {
  final List<SkillsModel> initialSkills;
  final Function(List<SkillsModel>) onSave;

  const EditSkillsBottomSheet({
    super.key,
    required this.initialSkills,
    required this.onSave,
  });

  @override
  State<EditSkillsBottomSheet> createState() => _EditSkillsBottomSheetState();
}

class _EditSkillsBottomSheetState extends State<EditSkillsBottomSheet>
    with SingleTickerProviderStateMixin {
  late List<SkillsModel> skills;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _saving = false;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  bool _snackBarShown = false;
  OverlayEntry? _overlayEntry;

  void _showSnackBarOnce(
    BuildContext context,
    String message, {
    Color backgroundColor = Colors.red,
    int cooldownSeconds = 2,
  }) {
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
    print('🔍 [EditSkillsBottomSheet] Initializing');
    skills = List.from(widget.initialSkills);
    print(
        '🔍 [EditSkillsBottomSheet] Loaded initial skills: ${skills.map((s) => s.skills).toList()}');

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _animationController.forward();
    });
  }

  @override
  void dispose() {
    print('🔍 [EditSkillsBottomSheet] Disposing controller and focus node');
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _addSkill() {
    final text = _controller.text.trim();

    if (text.isEmpty) {
      _showSnackBarOnce(context, 'Please type a skill before adding');
      print('⚠️ [EditSkillsBottomSheet] Skill not added: empty');
      return;
    }

    // Optional: basic length validation (kept reasonable for UI)
    if (text.length > 40) {
      _showSnackBarOnce(context, 'Skill is too long (max 40 characters)');
      print('⚠️ [EditSkillsBottomSheet] Skill too long: $text');
      return;
    }

    if (skills
        .any((skill) => skill.skills.toLowerCase() == text.toLowerCase())) {
      _showSnackBarOnce(context, 'That skill is already in the list');
      print('⚠️ [EditSkillsBottomSheet] Skill duplicate: $text');
      return;
    }

    setState(() {
      skills.add(SkillsModel(skills: text));
      _controller.clear();
      print('✅ [EditSkillsBottomSheet] Added skill: $text');
    });
  }

  Future<void> _save() async {
    print('🔍 [EditSkillsBottomSheet] Initiating save');

    final updatedSkills = skills
        .map((s) => s.skills.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();

    if (updatedSkills.isEmpty) {
      _showSnackBarOnce(context, 'Please add at least one skill');
      print('⚠️ [EditSkillsBottomSheet] Save blocked: no skills');
      return;
    }

    setState(() => _saving = true);
    try {
      await _postUpdatedSkills(
        context: context,
        updatedSkills: updatedSkills,
        onSuccess: () {
          widget.onSave(
              updatedSkills.map((s) => SkillsModel(skills: s)).toList());
          _showSnackBarOnce(
            context,
            'Skills updated successfully',
            backgroundColor: Colors.green,
          );
          print('✅ [EditSkillsBottomSheet] Save successful');
          Navigator.of(context).pop();
        },
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {


    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.85,
        maxChildSize: 0.85,
        builder: (_, scrollController) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              padding: EdgeInsets.only(
                left: 18.1.w,
                right: 18.1.w,
                top: 18.1.h,
                bottom: MediaQuery.of(context).padding.bottom + 24.h,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(18.1.r)),
              ),
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),

                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Edit Skills',
                            style: TextStyle(
                              fontSize: 16.2.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF003840),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close,
                                color: const Color(0xFF005E6A), size: 17.7.w),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),

                      SizedBox(height: 14.h),

                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.only(
                            bottom: 20.h,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 7.2.w,
                                runSpacing: 7.2.h,
                                children: skills.map((skill) {
                                  return Chip(
                                    label: Text(skill.skills,
                                        style: TextStyle(fontSize: 12.4.sp)),
                                    deleteIcon: Icon(Icons.close, size: 16.2.w),
                                    onDeleted: () => setState(() => skills.remove(skill)),
                                  );
                                }).toList(),
                              ),

                              SizedBox(height: 18.h),

                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _controller,
                                      focusNode: _focusNode,
                                      decoration: InputDecoration(
                                        labelText: 'Add a skill',
                                        labelStyle: TextStyle(fontSize: 12.4.sp),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10.8.r),
                                        ),
                                      ),
                                      onSubmitted: (_) => _addSkill(),
                                    ),
                                  ),
                                  SizedBox(width: 9.w),
                                  ElevatedButton(
                                    onPressed: _saving ? null : _addSkill,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF005E6A),
                                      padding: EdgeInsets.all(12.w),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10.8.r),
                                      ),
                                    ),
                                    child: Icon(Icons.add, color: Colors.white, size: 18.w),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 14.h),

                      SizedBox(
                        width: double.infinity,
                        height: 45.h,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF005E6A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(27.r),
                            ),
                          ),
                          child: _saving
                              ? SizedBox(
                            height: 18.h,
                            width: 18.h,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : Text(
                            "Save",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.7.sp,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
            ),
          );
        },
      ),
    );
  }

  Future<void> _postUpdatedSkills({
    required BuildContext context,
    required List<String> updatedSkills,
    required VoidCallback onSuccess,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';
    final connectSid = prefs.getString('connectSid') ?? '';

    final cleanedSkills = updatedSkills
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    print('📤 [EditSkillsBottomSheet] Sending skills update: $cleanedSkills');

    try {
      final url =
          Uri.parse("${ApiConstantsStu.subUrl}profile/student/update-skills");
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
        'Cookie': connectSid,
      };
      final body = jsonEncode({"skills": cleanedSkills.join(', ')});

      print("🔍 [EditSkillsBottomSheet] URL: $url");
      print("🔍 [EditSkillsBottomSheet] Headers: $headers");
      print("🔍 [EditSkillsBottomSheet] Body: $body");

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      // 🔸 Scan for session issues (401 logout)
      await SessionGuard.scan(statusCode: response.statusCode);

      print(
          "📩 [EditSkillsBottomSheet] Response Status: ${response.statusCode}");
      print("📩 [EditSkillsBottomSheet] Response Body: ${response.body}");

      if (response.statusCode == 200) {
        print("✅ [EditSkillsBottomSheet] Skills updated successfully");
        onSuccess();
      } else {
        print(
            "⚠️ [EditSkillsBottomSheet] Failed to update skills. Status: ${response.statusCode}");
        _showSnackBarOnce(
          context,
          "Failed to update skills",
        );
      }
    } catch (e) {
      print("❌ [EditSkillsBottomSheet] Error updating skills: $e");
      _showSnackBarOnce(
        context,
        "Something went wrong",
      );
    }
  }
}
