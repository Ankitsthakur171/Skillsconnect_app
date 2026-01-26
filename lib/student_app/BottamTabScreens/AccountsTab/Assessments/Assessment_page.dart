import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import '../../../Utilities/ApiConstants.dart';
import '../../../Utilities/assessment_api.dart';

class AssessmentPage extends StatefulWidget {
  const AssessmentPage({super.key});

  @override
  State<AssessmentPage> createState() => _AssessmentPageState();
}

class _AssessmentPageState extends State<AssessmentPage> {
  static const double _scale = 0.95;

  bool _loading = true;
  String? _error;
  List<Assessment> _items = [];

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await AssessmentApi.fetchAssessments();
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openLink(String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No assessment link available')));
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid URL')));
      return;
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not open link')));
    }
  }

  Widget _buildShimmerCard() {
    return Container(
      margin:
          EdgeInsets.symmetric(horizontal: 16 * _scale, vertical: 12 * _scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)
        ],
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 60 * _scale,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12.0 * _scale),
              child: Column(children: [
                Container(height: 14 * _scale, color: Colors.white),
                SizedBox(height: 8 * _scale),
                Container(height: 14 * _scale, color: Colors.white),
                SizedBox(height: 10 * _scale),
                Row(children: [
                  Expanded(
                      child:
                          Container(height: 28 * _scale, color: Colors.white)),
                  SizedBox(width: 8 * _scale),
                  Container(
                      width: 110 * _scale,
                      height: 36 * _scale,
                      color: Colors.white),
                ]),
              ]),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Assessment a) {
    final teal = const Color(0xFF007D7D);
    final double iconSize = 18.0 * _scale;
    final double headerFontSize = 16.0 * _scale;
    final double contentFontSize = 14.0 * _scale;
    final double buttonHeight = 44.0 * _scale;

    // final bool isPastDeadline =
    //     a.endDate != null && DateTime.now().isAfter(a.endDate!);

    final ButtonStyle submitButtonStyle = ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
        if (states.contains(MaterialState.disabled)) return Colors.red.shade700;
        return teal;
      }),
      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24 * _scale)),
      ),
    );

    return Container(
      margin:
          EdgeInsets.symmetric(horizontal: 16 * _scale, vertical: 12 * _scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)
        ],
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 16 * _scale, vertical: 14 * _scale),
              color: teal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.work_outline,
                      color: Colors.white, size: 20 * _scale),
                  SizedBox(width: 10 * _scale),
                  Expanded(
                    child: Text(
                      '${a.title} - ${a.companyName}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: headerFontSize,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: 14.0 * _scale, vertical: 12 * _scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.description_outlined,
                          size: iconSize, color: Colors.black54),
                      SizedBox(width: 8 * _scale),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Process Name',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: contentFontSize)),
                            SizedBox(height: 6 * _scale),
                            Text(
                              a.processName,
                              style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: contentFontSize),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12 * _scale),
                  Row(
                    children: [
                      Expanded(
                        child: _dateColumn(
                          icon: Icons.calendar_today_outlined,
                          label: 'Start Date',
                          date: a.invitedOn,
                          iconSize: iconSize,
                          fontSize: contentFontSize,
                        ),
                      ),
                      SizedBox(width: 12 * _scale),
                      Expanded(
                        child: _dateColumn(
                          icon: Icons.calendar_today,
                          label: 'End Date',
                          date: a.endDate,
                          iconSize: iconSize,
                          fontSize: contentFontSize,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12 * _scale),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.link, size: iconSize, color: Colors.black54),
                      SizedBox(width: 8 * _scale),
                      Text('Assessment Link',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: contentFontSize)),
                    ],
                  ),
                  SizedBox(height: 6 * _scale),
                  GestureDetector(
                    onTap: () => _openLink(a.assessmentUrl),
                    child: Text(
                      a.assessmentUrl.isEmpty
                          ? 'Assessment URL (not available)'
                          : a.assessmentUrl,
                      style: TextStyle(
                        color:
                            a.assessmentUrl.isEmpty ? Colors.grey : Colors.blue,
                        decoration: a.assessmentUrl.isEmpty
                            ? null
                            : TextDecoration.underline,
                        fontSize: contentFontSize,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: 70.0 * _scale, vertical: 14 * _scale),
              child: SizedBox(
                width: double.infinity,
                height: buttonHeight,
                child: ElevatedButton(
                  onPressed:
                      // isPastDeadline
                      //     ? null
                      //     :
                      () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => AssessmentSubmitSheet(assessment: a),
                    );
                  },
                  style: submitButtonStyle,
                  child: Text(
                    // isPastDeadline ? 'Deadline crossed' :
                    'Submit Assessment',
                    style: TextStyle(
                      fontSize: 16 * _scale,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateColumn({
    required IconData icon,
    required String label,
    required DateTime? date,
    required double iconSize,
    required double fontSize,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: iconSize, color: Colors.black54),
            SizedBox(width: 6 * _scale),
            Text(label,
                style:
                    TextStyle(fontWeight: FontWeight.w600, fontSize: fontSize)),
          ],
        ),
        SizedBox(height: 6 * _scale),
        _datePill(date, fontSize: fontSize),
      ],
    );
  }

  Widget _datePill(DateTime? dt, {double fontSize = 14.0}) {
    final bg = Colors.blue.shade50;
    final label = dt == null ? '-' : DateFormat('dd MMM yyyy').format(dt);
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: 10 * _scale, vertical: 6 * _scale),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(8 * _scale)),
      child: Text(label,
          style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.w600,
              fontSize: fontSize)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Assessments',
          style: TextStyle(
            color: Color(0xFF003840),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF003840)),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView.builder(
                padding: EdgeInsets.only(top: 12 * _scale, bottom: 24 * _scale),
                itemCount: 3,
                itemBuilder: (_, __) => _buildShimmerCard(),
              )
            : _error != null
                ? Builder(builder: (context) {
                    final err = _error!.toLowerCase();
                    final bool isNotFoundError =
                        err.contains('assessment not found') ||
                            err.contains('no assessment') ||
                            err.contains('not found');
                    if (isNotFoundError) {
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight),
                              child: Center(
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/No_Assessment.png',
                                        width: 320 * _scale,
                                        height: 240 * _scale,
                                        fit: BoxFit.contain,
                                      ),
                                      SizedBox(height: 18 * _scale),
                                      Text(
                                        'No assessments found',
                                        style: TextStyle(
                                          fontSize: 18 * _scale,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: 8 * _scale),
                                      Text(
                                        'We couldn’t find any assessments for you at the moment.',
                                        style: TextStyle(
                                          fontSize: 13 * _scale,
                                          color: Colors.black54,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    } else {
                      return ListView(
                        padding: EdgeInsets.only(
                            top: 28 * _scale, bottom: 24 * _scale),
                        children: [
                          Center(
                            child: Text('Error: $_error',
                                style: TextStyle(color: Colors.red)),
                          ),
                          SizedBox(height: 20 * _scale),
                          Center(
                            child: ElevatedButton(
                              onPressed: _load,
                              child: const Text('Retry'),
                            ),
                          ),
                        ],
                      );
                    }
                  })
                : _items.isEmpty
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight),
                              child: IntrinsicHeight(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/No_Assessment.png',
                                      width: 220 * _scale,
                                      height: 140 * _scale,
                                      fit: BoxFit.contain,
                                    ),
                                    SizedBox(height: 18 * _scale),
                                    Text(
                                      'No assessments found',
                                      style: TextStyle(
                                        fontSize: 18 * _scale,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 8 * _scale),
                                    Text(
                                      'We\'ll let you know when new assessments are available.',
                                      style: TextStyle(
                                        fontSize: 13 * _scale,
                                        color: Colors.black54,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : ListView.builder(
                        padding: EdgeInsets.only(
                            top: 12 * _scale, bottom: 24 * _scale),
                        itemCount: _items.length,
                        itemBuilder: (_, i) => _buildCard(_items[i]),
                      ),
      ),
    );
  }
}

class AssessmentSubmitSheet extends StatefulWidget {
  final Assessment assessment;

  const AssessmentSubmitSheet({required this.assessment, super.key});

  @override
  State<AssessmentSubmitSheet> createState() => _AssessmentSubmitSheetState();
}

class _AssessmentSubmitSheetState extends State<AssessmentSubmitSheet> {
  String? _pickedFileName;
  File? _pickedFile;
  final TextEditingController _descriptionController = TextEditingController();
  bool _submitting = false;
  String? _detailName;
  DateTime? _detailStart;
  DateTime? _detailEnd;
  String? _detailProcessId;
  String? _detailJobId;
  String? _uploadedBlobUrl;
  bool _detailsLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAssessmentDetails();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Widget _shimmerBox(
      {double width = double.infinity,
      double height = 100.0,
      BorderRadius? radius}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: radius ?? BorderRadius.circular(6),
        ),
      ),
    );
  }

  Future<void> _fetchAssessmentDetails() async {
    setState(() {
      _detailsLoading = true;
    });

    String processIdForRequest = '';
    try {
      final dynamic a = widget.assessment;
      if ((a as dynamic).processId != null) {
        processIdForRequest = (a.processId).toString();
      } else if ((a as dynamic).process_id != null) {
        processIdForRequest = (a.process_id).toString();
      } else if ((a as dynamic).id != null) {
        processIdForRequest = (a.id).toString();
      }
    } catch (_) {
      processIdForRequest = widget.assessment.processName ?? '';
    }

    if (processIdForRequest.isEmpty) {
      setState(() {
        _detailsLoading = false;
      });
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      final connectSid = prefs.getString('connectSid') ?? '';

      final url = '${ApiConstantsStu.subUrl}jobs/assessment-details';
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (authToken.isNotEmpty)
          'Cookie': 'authToken=$authToken; connect.sid=$connectSid',
      };

      final body = json.encode({"process_id": processIdForRequest});

      final resp = await http
          .post(Uri.parse(url), headers: headers, body: body)
          .timeout(const Duration(seconds: 30));

      if (resp.statusCode == 200 && resp.body.isNotEmpty) {
        final parsed = json.decode(resp.body);
        if (parsed is Map<String, dynamic> &&
            parsed['status'] == true &&
            parsed['data'] is List &&
            (parsed['data'] as List).isNotEmpty) {
          final Map<String, dynamic> d0 =
              (parsed['data'] as List).first as Map<String, dynamic>;
          setState(() {
            _detailName = (d0['name'] ?? '').toString();
            _detailProcessId = d0['process_id']?.toString();
            _detailJobId = d0['job_id']?.toString();
            _detailEnd = d0['end_date'] != null
                ? DateTime.tryParse(d0['end_date'].toString())
                : null;
            _detailStart = d0['start_date'] != null
                ? DateTime.tryParse(d0['start_date'].toString())
                : null;
          });
        }
      }
    } catch (_) {
      // silent fail
    } finally {
      if (mounted) {
        setState(() {
          _detailsLoading = false;
        });
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null) return;
      final path = result.files.single.path;
      if (path == null) return;

      setState(() {
        _pickedFile = File(path);
        _pickedFileName = result.files.single.name;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('File pick failed: $e')));
      }
    }
  }

  String _generateRandomCode(int length) {
    final rnd = Random.secure();
    const digits = '0123456789abcdef';
    return List.generate(length, (_) => digits[rnd.nextInt(digits.length)])
        .join();
  }

  Future<Map<String, String>?> _requestSasToken(
      {required String fileName,
      required int fileSize,
      required String fileType}) async
  {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      final connectSid = prefs.getString('connectSid') ?? '';

      final now = DateTime.now();
      final folder = 'manual_assessment/${DateFormat('MMM-yyyy').format(now)}';

      final base = '${ApiConstantsStu.subUrl}common/sas-token';
      final url =
          '$base?folderName=${Uri.encodeComponent(folder)}&filesName=${Uri.encodeComponent(fileName)}&filesSize=$fileSize&filesType=${Uri.encodeComponent(fileType)}';

      final headers = <String, String>{
        if (authToken.isNotEmpty)
          'Cookie': 'authToken=$authToken; connect.sid=$connectSid',
        'Content-Type': 'application/json'
      };

      final resp = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 30));

      if (resp.statusCode == 200 && resp.body.isNotEmpty) {
        try {
          final parsed = json.decode(resp.body);
          if (parsed is Map<String, dynamic>) {
            final sasUrl = parsed['sas_url']?.toString();
            final blobUrl = parsed['blob_url']?.toString();
            if (sasUrl != null && sasUrl.isNotEmpty) {
              return {
                'sas_url': sasUrl,
                'blob_url': blobUrl ?? sasUrl.split('?').first
              };
            }
          }
        } catch (_) {}
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _uploadToSas(
      String sasUrl, File file, String contentType) async
  {
    try {
      final bytes = await file.readAsBytes();

      final putHeaders = {
        'x-ms-blob-type': 'BlockBlob',
        'Content-Type': contentType,
      };

      final resp = await http
          .put(Uri.parse(sasUrl), headers: putHeaders, body: bytes)
          .timeout(const Duration(minutes: 2));
      return resp.statusCode == 201 || resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<http.Response?> _postSubmitApi(Map<String, dynamic> body) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      final connectSid = prefs.getString('connectSid') ?? '';

      final url = '${ApiConstantsStu.subUrl}jobs/submit-assessment';
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (authToken.isNotEmpty)
          'Cookie': 'authToken=$authToken; connect.sid=$connectSid',
      };

      final resp = await http
          .post(Uri.parse(url), headers: headers, body: json.encode(body))
          .timeout(const Duration(seconds: 30));
      return resp;
    } catch (_) {
      return null;
    }
  }

  Future<void> _submitAssessment() async {
    final desc = _descriptionController.text.trim();
    final hasDesc = desc.isNotEmpty;
    final hasFile = _pickedFile != null;

    if (!hasDesc || !hasFile) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Missing details'),
          content: const Text(
              'Please provide both a file and a description before submitting.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    String? cleanUrl;
    try {
      if (_pickedFile != null) {
        final originalName = _pickedFileName ?? p.basename(_pickedFile!.path);
        final ext = p.extension(originalName);
        final random = _generateRandomCode(12);
        final studentPrefix =
            originalName.replaceAll(RegExp(r'[^A-Za-z0-9\-_\.]'), '-');
        final finalFileName = '${studentPrefix.split('.').first}-$random$ext';

        final int fileSize = await _pickedFile!.length();

        final lc = ext.toLowerCase();
        String contentType = 'application/octet-stream';
        if (lc == '.pdf') {
          contentType = 'application/pdf';
        } else if (lc == '.png') {
          contentType = 'image/png';
        } else if (lc == '.jpg' || lc == '.jpeg') {
          contentType = 'image/jpeg';
        } else if (lc == '.txt') {
          contentType = 'text/plain';
        }

        final sasResp = await _requestSasToken(
            fileName: finalFileName, fileSize: fileSize, fileType: contentType
        );

        if (sasResp == null) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to obtain SAS token')));
          setState(() => _submitting = false);
          return;
        }

        final sasUrl = sasResp['sas_url']!;
        final blobUrlExpected = sasResp['blob_url'] ?? sasUrl.split('?').first;

        final ok = await _uploadToSas(sasUrl, _pickedFile!, contentType);

        if (!ok) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Upload failed')));
          setState(() => _submitting = false);
          return;
        }

        cleanUrl = blobUrlExpected.isNotEmpty
            ? blobUrlExpected
            : sasUrl.split('?').first;
        setState(() {
          _uploadedBlobUrl = cleanUrl;
        });
      }

      dynamic processVal = _detailProcessId;
      dynamic jobVal = _detailJobId;
      try {
        if (_detailProcessId != null) processVal = int.parse(_detailProcessId!);
      } catch (_) {}
      try {
        if (_detailJobId != null) jobVal = int.parse(_detailJobId!);
      } catch (_) {}

      final baseBody = <String, dynamic>{
        'fileUploadName': cleanUrl ?? '',
        'process_id': processVal ?? '',
        'job_id': jobVal ?? '',
      };

      final bodyAttempt1 = Map<String, dynamic>.from(baseBody);
      bodyAttempt1['assessment_description'] = desc;

      final resp1 = await _postSubmitApi(bodyAttempt1);

      if (resp1 != null && resp1.statusCode == 200) {
        try {
          final parsed = json.decode(resp1.body);
          final ok = parsed is Map && parsed['status'] == true;
          if (ok) {
            if (mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Assessment submitted successfully'),
                  duration: const Duration(seconds: 1),
                  backgroundColor: Colors.green,
                ),
              );
            }
            return;
          }
        } catch (_) {}
      }

      final bodyAttempt2 = Map<String, dynamic>.from(baseBody);
      bodyAttempt2['description'] = desc;

      final resp2 = await _postSubmitApi(bodyAttempt2);

      if (resp2 != null && resp2.statusCode == 200) {
        try {
          final parsed = json.decode(resp2.body);
          final ok = parsed is Map && parsed['status'] == true;
          if (ok) {
            if (mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Assessment submitted successfully'),
                  duration: const Duration(seconds: 1),
                  backgroundColor: Colors.green,
                ),
              );
            }
            return;
          }
        } catch (_) {}
      }

      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Submission failed'),
            content: const Text('Submission failed. Please try again later.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK')),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Submission failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teal = const Color(0xFF005E6A);
    final radius = 12.0;
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom;

    final deadline = _detailEnd ?? widget.assessment.endDate;
    final deadlineText = deadline == null
        ? 'No deadline'
        : DateFormat('dd MMM yyyy').format(deadline);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.7,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return Container(
          padding: EdgeInsets.only(
              left: 16, right: 16, top: 12, bottom: 16 + bottomInset),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        'Submit Your Assessment Here',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Divider(),
                if (_detailsLoading) ...[
                  _shimmerBox(
                      width: 220, height: 18, radius: BorderRadius.circular(4)),
                  SizedBox(height: 8),
                  _shimmerBox(
                      width: 140, height: 14, radius: BorderRadius.circular(4)),
                  SizedBox(height: 12),
                ] else ...[
                  if (_detailName != null) ...[
                    Text(_detailName!,
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    SizedBox(height: 8),
                  ],
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                            text: 'Deadline: ',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                        TextSpan(
                            text: deadlineText,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent)),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                ],
                Text('Please Upload Assessment :',
                    style: TextStyle(fontSize: 14, color: Colors.black87)),
                SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Material(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: _pickFile,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                Icon(Icons.upload_file, color: teal),
                                SizedBox(width: 8),
                                Text('Choose File',
                                    style: TextStyle(color: Colors.black87)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _pickedFileName ?? 'No file chosen',
                                  style: TextStyle(
                                      color: _pickedFileName == null
                                          ? Colors.grey
                                          : Colors.black87),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_pickedFile != null)
                                IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _pickedFile = null;
                                      _pickedFileName = null;
                                      _uploadedBlobUrl = null;
                                    });
                                  },
                                )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Text('Description :',
                    style: TextStyle(fontSize: 14, color: Colors.black87)),
                SizedBox(height: 6),
                TextField(
                  controller: _descriptionController,
                  minLines: 4,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: 'Write a short description...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submitAssessment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: teal,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2)
                        )
                            : const Text(
                                'Submit Assessment',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                    SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 18),
                        side: BorderSide(color: teal),
                        backgroundColor: Colors.white,
                      ),
                      child: const Text('Close',
                          style: TextStyle(color: Color(0xFF005E6A))),
                    ),
                  ],
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
