import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:skillsconnect/utils/session_guard.dart';
import '../../../../Model/Resume_fetch_Model.dart';
import '../../../../Pages/Resume_Viewer.dart';
import '../../../../Utilities/ApiConstants.dart';

class ResumeSection extends StatefulWidget {
  const ResumeSection({super.key});

  @override
  State<ResumeSection> createState() => _ResumeSectionState();
}

class _ResumeSectionState extends State<ResumeSection> {
  File? _pdfFile;
  String? _resumeUrl;
  bool _isLoading = true;
  String? _error;
  bool _snackBarShown = false;
  String? _studentName;

  @override
  void initState() {
    super.initState();
    _fetchAndSaveResumePdf();
    _loadStudentName();
  }

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

  Future<bool> _hasNetwork() async {
    if (kIsWeb) return true;
    try {
      final result = await InternetAddress.lookup('example.com')
          .timeout(const Duration(seconds: 2));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _handleTap(BuildContext context, VoidCallback callback) async {
    final ok = await _hasNetwork();
    if (!ok) {
      _showSnackBarOnce(context, "No internet available");
      return;
    }
    callback();
  }

  String _generateRandomCode(int length) {
    final random = Random.secure();
    const digits = '0123456789';
    return List.generate(length, (_) => digits[random.nextInt(digits.length)])
        .join();
  }

  Future<void> _loadStudentName() async {
    final name = await _getStudentName();
    if (!mounted) return;
    setState(() {
      _studentName = name;
    });
  }

  Future<String> _getStudentName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      final connectSid = prefs.getString('connectSid') ?? '';

      final url = '${ApiConstantsStu.subUrl}profile/student/personal-details';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Cookie': 'authToken=$authToken; connect.sid=$connectSid'},
      );

      // 🔸 Scan for session issues (401 logout)
      await SessionGuard.scan(statusCode: response.statusCode);

      if (response.statusCode == 200) {
        final jsonResp = json.decode(response.body);
        if (jsonResp['personalDetails'] != null &&
            jsonResp['personalDetails'] is List &&
            (jsonResp['personalDetails'] as List).isNotEmpty) {
          final firstEntry = (jsonResp['personalDetails'] as List)[0];
          final firstName = firstEntry['first_name'] ?? '';
          final lastName = firstEntry['last_name'] ?? '';
          return "$firstName-$lastName".replaceAll(" ", "-");
        }
      }
      return "student";
    } catch (_) {
      return "student";
    }
  }

  Future<File?> _pickResumeFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  Future<void> _fetchAndSaveResumePdf() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      final connectSid = prefs.getString('connectSid') ?? '';

      final url = '${ApiConstantsStu.subUrl}profile/student/resume';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Cookie': 'authToken=$authToken; connect.sid=$connectSid'},
      );

      // 🔸 Scan for session issues (401 logout)
      await SessionGuard.scan(statusCode: response.statusCode);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        if (jsonData['videoIntro'] != null &&
            jsonData['videoIntro'] is List &&
            (jsonData['videoIntro'] as List).isNotEmpty) {
          final firstEntry =
              (jsonData['videoIntro'] as List)[0] as Map<String, dynamic>;
          final resumeModel = ResumeModel(
            resume: firstEntry['resume']?.toString() ?? '',
            resumeName: firstEntry['resume_name']?.toString() ?? '',
          );
          final resumeUrl = resumeModel.resume.trim();
          if (resumeUrl.isNotEmpty && resumeUrl.startsWith('http')) {
            final pdfResponse = await http.get(Uri.parse(resumeUrl));

            // 🔸 Scan for session issues (401 logout)
            await SessionGuard.scan(statusCode: pdfResponse.statusCode);

            if (pdfResponse.statusCode == 200) {
              final bytes = pdfResponse.bodyBytes;
              final dir = await getApplicationDocumentsDirectory();
              final file = File('${dir.path}/resume.pdf');
              await file.writeAsBytes(bytes);
              if (!mounted) return;
              setState(() {
                _pdfFile = file;
                _resumeUrl = resumeUrl;
                _isLoading = false;
                _error = null;
              });
            }
          }
        }
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Error fetching resume';
        _resumeUrl = null;
      });
    }
  }

  Future<String?> _getSasToken(File file) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      final connectSid = prefs.getString('connectSid') ?? '';

      final now = DateTime.now();
      final folderName = "uploads/${DateFormat('MMM-yyyy').format(now)}";

      final studentName = await _getStudentName();
      final randomCode = _generateRandomCode(11);

      final fileName = "$studentName-mobile-skillsconnect-$randomCode.pdf";
      final fileSize = file.lengthSync();

      final url =
          '${ApiConstantsStu.subUrl}common/sas-token?folderName=$folderName&filesName=$fileName&filesSize=$fileSize&filesType=application/pdf';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Cookie': 'authToken=$authToken; connect.sid=$connectSid'},
      );

      // 🔸 Scan for session issues (401 logout)
      await SessionGuard.scan(statusCode: response.statusCode);

      if (response.statusCode == 200) {
        final jsonResp = json.decode(response.body);
        return jsonResp['sas_url'];
      } else {
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  Future<String?> _uploadToAzure(String sasUrl, File file) async {
    try {
      final bytes = await file.readAsBytes();

      final request = http.Request("PUT", Uri.parse(sasUrl));
      request.headers.addAll({
        'x-ms-blob-type': 'BlockBlob',
        'Content-Type': 'application/pdf',
      });
      request.bodyBytes = bytes;

      final response = await request.send();

      final responseBody = await response.stream.bytesToString();

      print("Status Code: ${response.statusCode}");
      print("Response Body: $responseBody");
      print("sasUrl.split('?').first: ${sasUrl.split('?').first}");

      if (responseBody.isNotEmpty) {
        try {
          final decodedJson = json.decode(responseBody);
          print("Decoded JSON: $decodedJson");
        } catch (e) {
          print("Non-JSON response body or failed to decode JSON.");
        }
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        return sasUrl.split('?').first;
      }
      return null;
    } catch (e) {
      print("Upload error: $e");
      return null;
    }
  }

  Future<void> _updateResumeInfo(String resumeUrl, String resumeName) async {
    try {
      print("resumeUrl$resumeUrl");
      print("resumeName$resumeName");
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      final connectSid = prefs.getString('connectSid') ?? '';

      final body = json.encode({
        'resume_url': resumeUrl,
        'resume_name': resumeName,
      });

      final url = '${ApiConstantsStu.subUrl}profile/student/update-resume';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'authToken=$authToken; connect.sid=$connectSid',
        },
        body: body,
      );
      print("Raw response body PRINT: ${response.body}");

      // 🔸 Scan for session issues (401 logout)
      await SessionGuard.scan(statusCode: response.statusCode);

      final decodedJson = json.decode(response.body);
      print("Decoded JSON PRINT: $decodedJson");
      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              duration: Duration(seconds: 1),
              backgroundColor: Colors.green,
              content: Text(
                "Resume updated successfully",
              )),
        );
        _fetchAndSaveResumePdf();
      }
    } catch (_) {}
  }

  Future<int> _getAndroidVersion() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    return androidInfo.version.sdkInt;
  }

  Future<void> _downloadResume() async {
    final url = _resumeUrl;
    final name = _studentName;

    if (url == null || name == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("❌ No resume available")));
      return;
    }

    final base = name.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final filename = '${base}_${DateTime.now().millisecondsSinceEpoch}.pdf';

    try {
      // Permissions (Android)
      if (Platform.isAndroid) {
        final sdk = await _getAndroidVersion();
        bool granted;
        if (sdk >= 33) {
          granted = (await Permission.photos.request()).isGranted;
        } else {
          granted = (await Permission.storage.request()).isGranted;
        }
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please Storage Permission Allow")),
            );
          }
          return;
        }
      }

      // Fetch
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200 || res.bodyBytes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Download failed (${res.statusCode})")),
        );
        return;
      }

      if (Platform.isAndroid) {
        final sdk = await _getAndroidVersion();

        // Android 10+ : SAF dialog
        if (sdk >= 29) {
          final tmpDir = await getTemporaryDirectory();
          final tmpPath = '${tmpDir.path}/$filename';
          await File(tmpPath).writeAsBytes(res.bodyBytes);

          final savedPath = await FlutterFileDialog.saveFile(
            params: SaveFileDialogParams(
              sourceFilePath: tmpPath,
              fileName: filename,
              mimeTypesFilter: const ['application/pdf'],
              localOnly: true,
            ),
          );

          if (savedPath == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Download cancelled")),
              );
            }
            return;
          }
        } else {
          // Android 9 and below: public Downloads
          final downloads = Directory('/storage/emulated/0/Download');
          final out = File('${downloads.path}/$filename');
          await out.writeAsBytes(res.bodyBytes);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Resume downloaded")),
          );
        }
        return;
      }

      // iOS
      final docs = await getApplicationDocumentsDirectory();
      final out = File('${docs.path}/$filename');
      await out.writeAsBytes(res.bodyBytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Resume downloaded")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(
      context,
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_resumeUrl != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Resume",
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
              SizedBox(
                width: 100.w,
                child: TextButton(
                  style: TextButton.styleFrom(
                    side: BorderSide(color: const Color(0xFF005E6A), width: 1.1.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25.r),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: _isLoading
                      ? null
                      : () {
                          _handleTap(context, () async {
                            File? file = await _pickResumeFile();
                            if (file == null) return;

                            if (!file.path.toLowerCase().endsWith('.pdf')) {
                              _showSnackBarOnce(context, "Please select a PDF");
                              return;
                            }

                            setState(() => _isLoading = true);
                            try {
                              final sasUrl = await _getSasToken(file);
                              if (sasUrl != null) {
                                final cleanUrl =
                                    await _uploadToAzure(sasUrl, file);
                                if (cleanUrl != null) {
                                  final blobFileName =
                                      Uri.parse(cleanUrl).pathSegments.last;
                                  await _updateResumeInfo(cleanUrl, blobFileName);

                                  if (mounted) {
                                    setState(() {
                                      _resumeUrl = cleanUrl;
                                    });
                                  }
                                } else {
                                  _showSnackBarOnce(
                                      context, "Failed to upload to storage");
                                }
                              } else {
                                _showSnackBarOnce(
                                    context, "Failed to get SAS URL");
                              }
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                          });
                        },
                  child: Text(
                    _resumeUrl == null ? "Upload" : "Update",
                    style: TextStyle(
                      color: const Color(0xFF005E6A),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        SizedBox(height: 8.h),
        if (_resumeUrl != null)
          Container(
            width: double.infinity,
            height: 70.h,
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 14.w),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFBCD8DB)),
              borderRadius: BorderRadius.circular(10.r),
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ResumeViewer(resumeUrl: _resumeUrl!),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf_outlined,
                          size: 35.w, color: const Color(0xFF005E6A)),
                      SizedBox(width: 8.w),
                      Text(
                        _studentName ?? "Your Resume",
                        style: TextStyle(
                            fontSize: 14.sp, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.download,
                      color: Color(0xFF005E6A), size: 28),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Download Resume"),
                        content: const Text(
                            "Do you want to download your resume PDF?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text("No"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text("Yes"),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await _downloadResume();
                    }
                  },
                ),
              ],
            ),
          )
        else
          GestureDetector(
            onTap: () {
              _handleTap(context, () async {
                File? file = await _pickResumeFile();
                if (file == null) return;

                if (!file.path.toLowerCase().endsWith('.pdf')) {
                  _showSnackBarOnce(context, "Please select a PDF");
                  return;
                }

                setState(() => _isLoading = true);
                try {
                  final sasUrl = await _getSasToken(file);
                  if (sasUrl != null) {
                    final cleanUrl =
                        await _uploadToAzure(sasUrl, file);
                    if (cleanUrl != null) {
                      final blobFileName =
                          Uri.parse(cleanUrl).pathSegments.last;
                      await _updateResumeInfo(cleanUrl, blobFileName);

                      if (mounted) {
                        setState(() {
                          _resumeUrl = cleanUrl;
                        });
                      }
                    } else {
                      _showSnackBarOnce(
                          context, "Failed to upload to storage");
                    }
                  } else {
                    _showSnackBarOnce(
                        context, "Failed to get SAS URL");
                  }
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              });
            },
            child: Container(
              width: double.infinity,
              height: 70.h,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFBCD8DB)),
                borderRadius: BorderRadius.circular(10.r),
                color: Colors.white,
              ),
              child: Text(
                "Upload resume",
                style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(0xFF005E6A),
                    fontWeight: FontWeight.w600),
              ),
            ),
          )
      ],
    );
  }
}
