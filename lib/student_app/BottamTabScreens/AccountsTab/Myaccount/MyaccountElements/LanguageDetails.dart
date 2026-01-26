import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../Model/Languages_Model.dart';
import '../../../../Utilities/MyAccount_Get_Post/LanguagesGet_Api.dart';
import '../../BottomSheets/EditLanguageBottomSheet.dart';
import 'SectionHeader.dart';

bool _snackBarShown = false;

void _showSnackBarOnce(BuildContext context, String message,
    {int cooldownSeconds = 3}) {
  if (_snackBarShown) return;
  _snackBarShown = true;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: TextStyle(fontSize: 13.sp)),
      backgroundColor: Colors.red,
      duration: Duration(seconds: cooldownSeconds),
    ),
  );
  Future.delayed(Duration(seconds: cooldownSeconds), () {
    _snackBarShown = false;
  });
}

class LanguagesSection extends StatelessWidget {
  final List<LanguagesModel> languageList;
  final bool isLoading;
  final VoidCallback onAdd;
  final Function(int) onDelete;

  const LanguagesSection({
    super.key,
    required this.languageList,
    required this.isLoading,
    required this.onAdd,
    required this.onDelete,
  });

  Future<bool> _hasNetwork() async {
    if (kIsWeb) return true;
    try {
      final result =
      await InternetAddress.lookup('example.com').timeout(const Duration(seconds: 2));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context,
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: "Languages",
          showAdd: true,
          onAdd: onAdd,
        ),
        if (isLoading)
          Center(
            child: CircularProgressIndicator(
              valueColor:
              const AlwaysStoppedAnimation<Color>(Color(0xFF005E6A)),
              strokeWidth: 3.w,
            ),
          )
        else if (languageList.isEmpty)
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Text(
              'No Languages available',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          )

        else
          for (var i = 0; i < languageList.length; i++)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              margin: EdgeInsets.only(top: 8.h),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFBCD8DB)),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(5.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBF6F7),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          Icons.language_rounded,
                          size: 22.w,
                          color: const Color(0xFF005E6A),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          languageList[i].languageName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15.sp,
                            color: const Color(0xFF005E6A),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        iconSize: 18.w,
                        onPressed: () async {
                          final ok = await _hasNetwork();
                          if (!ok) {
                          _showSnackBarOnce(context, "No internet available");
                            return;
                          }

                          final shouldDelete = await showDialog<bool>(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => AlertDialog(
                              backgroundColor: Colors.white,
                              title: const Text('Confirm Delete'),
                              content: const Text('Are you sure you want to delete this language?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Cancel', style: TextStyle(color: Colors.black)),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                          if (shouldDelete == true) {
                            onDelete(i);
                          }
                        },
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    languageList[i].proficiency,
                    style: TextStyle(fontSize: 13.sp, color: Colors.black54),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
