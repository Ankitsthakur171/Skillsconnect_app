import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../Model/BasicEducation_Model.dart';
import '../../../Model/CertificateDetails_Model.dart';
import '../../../Model/EducationDetail_Model.dart';
import '../../../Model/Image_update_Model.dart';
import '../../../Model/Internship_Projects_Model.dart';
import '../../../Model/Languages_Model.dart';
import '../../../Model/Percentage_bar_Model.dart';
import '../../../Model/PersonalDetail_Model.dart';
import '../../../Model/Skiils_Model.dart';
import '../../../Model/WorkExperience_Model.dart';
import '../../../Pages/noInternetPage_jobs.dart';
import '../../../Utilities/MyAccount_Get_Post/CertificateDetails_APi.dart';
import '../../../Utilities/MyAccount_Get_Post/EducationDetail_Api.dart';
import '../../../Utilities/MyAccount_Get_Post/Image_Api.dart';
import '../../../Utilities/MyAccount_Get_Post/InternshipProject_Api.dart';
import '../../../Utilities/MyAccount_Get_Post/LanguagesGet_Api.dart';
import '../../../Utilities/MyAccount_Get_Post/PersonalDetail_Api.dart';
import '../../../Utilities/MyAccount_Get_Post/ProfilePicture_Api.dart';
import '../../../Utilities/MyAccount_Get_Post/Skills_Api.dart';
import '../../../Utilities/MyAccount_Get_Post/WorkExperience_Api.dart';
import '../BottomSheets/EditCertificateBottomSheet.dart';
import '../BottomSheets/EditEducationBottomSheet.dart';
import '../BottomSheets/EditLanguageBottomSheet.dart';
import '../BottomSheets/EditPersonalDetailSheet.dart';
import '../BottomSheets/EditProjectBottomSheet.dart';
import '../BottomSheets/EditSkillsBottomSheet.dart';
import '../BottomSheets/EditWorkExperienceBottomSheet.dart';
import 'MyAccountAppbar.dart';
import 'MyaccountElements/CertificateDetails.dart';
import 'MyaccountElements/EducationDetails.dart';
import 'MyaccountElements/LanguageDetails.dart';
import 'MyaccountElements/Personaldetails.dart';
import 'MyaccountElements/Profile_Completition_Bar.dart';
import 'MyaccountElements/ProjectDetails.dart';
import 'MyaccountElements/SkillsDetails.dart';
import 'MyaccountElements/WorkExperienceDetails.dart';
import 'MyaccountElements/resumeDetails.dart';
import 'package:shimmer/shimmer.dart';

class MyAccount extends StatefulWidget {
  const MyAccount({super.key});

  @override
  State<MyAccount> createState() => _MyAccountState();
}

class _MyAccountState extends State<MyAccount> {
  String fullname = "John";
  EducationDetailModel? educationDetail;
  PersonalDetailModel? personalDetail;
  List<SkillsModel> skillList = [];
  List<InternshipProjectModel> projects = [];
  List<CertificateModel> certificatesList = [];
  List<WorkExperienceModel> workExperiences = [];
  List<LanguagesModel> languageList = [];
  List<EducationDetailModel> educationDetails = [];
  List<BasicEducationModel> basicEducationDetails = [];
  List<PersonalDetailModel> personalDetails = [];
  ImageUpdateModel? _imageUpdateData;
  bool isLoadingImage = true;
  bool isLoadingEducation = true;
  bool isLoadingProject = true;
  bool isLoadingWorkExperience = true;
  bool isLoadingCertificate = true;
  bool isLoadingSkills = true;
  bool isLoadingLanguages = true;
  bool isLoadingPersonalDetail = true;
  File? _profileImage;
  bool _isUploadingProfilePicture = false;
  ProfileCompletionModel? profileCompletion;
  bool isLoadingProfilePercentage = true;
  bool _snackBarShown = false;
  bool _hasInternet = true;
  bool _isRetrying = false;
  bool _showShimmer = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _checkInternetAndFetch();

    // void _showSnackBarOnce(BuildContext context, String message,
    //     {int cooldownSeconds = 3}) {
    //   if (_snackBarShown) return;
    //   _snackBarShown = true;
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text(message, style: TextStyle(fontSize: 13.sp)),
    //       backgroundColor: Colors.red,
    //       duration: Duration(seconds: cooldownSeconds),
    //     ),
    //   );
    //   Future.delayed(Duration(seconds: cooldownSeconds), () {
    //     _snackBarShown = false;
    //   });
    // }

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _showShimmer = false);
    });
  }

  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _checkInternetAndFetch() async {
    setState(() {
      _isRetrying = true;
      _showShimmer = true;
      _loadFailed = false;
    });

    final connected = await _hasInternetConnection();

    if (!connected) {
      await Future.delayed(const Duration(seconds: 3));
      final recheck = await _hasInternetConnection();
      setState(() {
        _hasInternet = recheck;
        _isRetrying = false;
        _showShimmer = false;
      });
      if (!recheck) return;
    }

    setState(() {
      _hasInternet = true;
      _isRetrying = false;
    });

    await Future.wait([
      _loadProfileImageFromApi(),
      fetchEducationDetails(),
      fetchInternShipProjectDetails(),
      _fetchPersonalDetails(),
      fetchWorkExperienceDetails(),
      fetchCertificateDetails(),
      fetchSkills(),
      fetchLanguageData(),
    ]);

    if (!mounted) return;
    setState(() => _showShimmer = false);
  }

  Future<void> _loadProfileImageFromApi() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';
    final connectSid = prefs.getString('connectSid') ?? '';
    final data = await LoadImageApi.fetchUserImage(
      authToken: authToken,
      connectSid: connectSid,
    );
    if (mounted && data != null) {
      setState(() {
        _imageUpdateData = data;
      });
    }
  }

  int _basicEducationPriority(String? degreeName) {
    final name = (degreeName ?? '').toLowerCase().trim();
    if (name.isEmpty) return 999;

    final isX = RegExp(r'\bx\b').hasMatch(name);
    if (isX || name.contains('10th') || name.contains('class 10') || name.contains('class x') || name.contains('10 ')) {
      return 0; // Class X first
    }

    if (name.contains('xii') || name.contains('12th') || name.contains('class 12') || name.contains('class xii') || name.contains('12 ')) {
      return 1; // Class XII second
    }
    return 999;
  }

  int _higherEducationPriority(String? degreeName) {
    final name = (degreeName ?? '').toLowerCase().trim();
    if (name.isEmpty) return 999;

    if (name.contains('doctorate') || name.contains('doctoral') || name.contains('phd')) {
      return 0; // Doctorate first
    }

    final isPostGrad = name.contains('post graduate') || name.contains('postgraduate') || name.contains('pg') || name.contains('master') || name.contains('m.tech') || name.contains('mtech') || name.contains('m.e') || name.contains('me') || name.contains('msc') || name.contains('ma') || name.contains('mcom') || name.contains('mba');
    if (isPostGrad) {
      return 1; // Postgraduate second
    }

    if ((name.contains('graduate') || name.contains('graduation')) &&
        !name.contains('undergraduate') &&
        !name.contains('under graduate') &&
        !name.contains('undergrad')) {
      return 2; // Graduate third
    }

    if (name.contains('undergraduate') || name.contains('under graduate') || name.contains('undergrad') || name.contains('ug') || name.contains('bachelor') || name.contains('b.tech') || name.contains('btech') || name.contains('b.e') || name.contains('be') || name.contains('bsc') || name.contains('ba') || name.contains('bcom')) {
      return 3; // Undergraduate fourth
    }

    return 999;
  }

  int _compareEducation(EducationDetailModel a, EducationDetailModel b) {
    final aPriority = _higherEducationPriority(a.degreeName);
    final bPriority = _higherEducationPriority(b.degreeName);
    if (aPriority != bPriority) {
      return aPriority.compareTo(bPriority);
    }
    final aId = a.educationId ?? 0;
    final bId = b.educationId ?? 0;
    return bId.compareTo(aId);
  }

  int _compareBasicEducation(BasicEducationModel a, BasicEducationModel b) {
    final aPriority = _basicEducationPriority(a.degreeName);
    final bPriority = _basicEducationPriority(b.degreeName);
    if (aPriority != bPriority) {
      return aPriority.compareTo(bPriority);
    }
    final aId = a.basicEducationId ?? 0;
    final bId = b.basicEducationId ?? 0;
    return bId.compareTo(aId);
  }

  void _insertEducationByLevel(EducationDetailModel ed) {
    final index = educationDetails.indexWhere((item) {
      return _compareEducation(ed, item) < 0;
    });

    if (index == -1) {
      educationDetails.add(ed);
    } else {
      educationDetails.insert(index, ed);
    }
  }

  void _insertBasicEducationByLevel(BasicEducationModel ed) {
    final index = basicEducationDetails.indexWhere((item) {
      return _compareBasicEducation(ed, item) < 0;
    });

    if (index == -1) {
      basicEducationDetails.add(ed);
    } else {
      basicEducationDetails.insert(index, ed);
    }
  }

  Future<void> fetchEducationDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';
    final connectSid = prefs.getString('connectSid') ?? '';

    setState(() {
      isLoadingEducation = true;
    });

    try {
      dynamic rawResult;
      try {
        rawResult = await EducationDetailApi.fetchAllEducationDetails(
          authToken: authToken,
          connectSid: connectSid,
        );
      } catch (_) {
        rawResult = await EducationDetailApi.fetchAllEducationDetails();
      }

      String _readFromMap(Map m, List<String> keys) {
        for (final k in keys) {
          if (m.containsKey(k) && m[k] != null) return m[k].toString();
        }
        return '';
      }

      bool looksLikeBasicDegree(String? degreeName) {
        if (degreeName == null) return false;
        final n = degreeName.toLowerCase();
        return n.contains('class x') ||
            n.contains('class xii') ||
            n.contains('class 10') ||
            n.contains('class 12') ||
            n.contains('10th') ||
            n.contains('12th') ||
            n == 'x' ||
            n == 'xii';
      }

      List<dynamic> higherRaw = [];
      List<dynamic> basicRaw = [];

      if (rawResult is Map<String, dynamic>) {
        if (rawResult['educationDetails'] is List) {
          higherRaw = rawResult['educationDetails'] as List;
        }
        if (rawResult['basicEducationDetails'] is List) {
          basicRaw = rawResult['basicEducationDetails'] as List;
        }

        if (higherRaw.isEmpty && basicRaw.isEmpty && rawResult['data'] is Map) {
          final d = rawResult['data'] as Map<String, dynamic>;
          if (d['educationDetails'] is List) {
            higherRaw = d['educationDetails'] as List;
          }
          if (d['basicEducationDetails'] is List) {
            basicRaw = d['basicEducationDetails'] as List;
          }
        }

        if (higherRaw.isEmpty &&
            basicRaw.isEmpty &&
            rawResult['data'] is List) {
          higherRaw = rawResult['data'] as List;
        }
      } else if (rawResult is List) {
        higherRaw = rawResult;
      }

      final List<EducationDetailModel> higher = [];
      final List<BasicEducationModel> basicModels = [];

      if (basicRaw.isNotEmpty) {
        for (final item in basicRaw) {
          if (item == null) continue;
          if (item is BasicEducationModel) {
            basicModels.add(item);
            continue;
          }
          if (item is Map<String, dynamic>) {
            final board = _readFromMap(item, [
              'board_name',
              'boardName',
              'board',
            ]);
            final medium = _readFromMap(item, [
              'medium_name',
              'mediumName',
              'medium',
            ]);
            final marks = _readFromMap(item, ['marks', 'grade', 'percentage']);
            final year = _readFromMap(item, [
              'passing_year',
              'passingYear',
              'year',
            ]);
            final degree = _readFromMap(item, [
              'degree_name',
              'degreeName',
              'degree',
            ]);

            basicModels.add(
              BasicEducationModel(
                userId:
                    int.tryParse(_readFromMap(item, ['user_id', 'userId'])) ??
                    0,
                marks: marks,
                passingYear: year,
                boardType:
                    int.tryParse(_readFromMap(item, ['board_type'])) ?? 0,
                boardId:
                    int.tryParse(_readFromMap(item, ['board_id', 'boardId'])) ??
                    0,
                basicEducationId:
                    int.tryParse(
                      _readFromMap(item, [
                        'basic_education_id',
                        'basicEducationId',
                      ]),
                    ) ??
                    0,
                degreeName: degree,
                boardName: board.isNotEmpty ? board : '',
                mediumName: medium.isNotEmpty ? medium : '',
              ),
            );
            continue;
          }
          try {
            final m = Map<String, dynamic>.from(item);
            basicModels.add(BasicEducationModel.fromJson(m));
          } catch (_) {}
        }
      }

      for (final item in higherRaw) {
        if (item == null) continue;

        if (item is EducationDetailModel) {
          final deg = item.degreeName;
          if (looksLikeBasicDegree(deg)) {
            final boardVal =
                (item.boardName != null && item.boardName!.isNotEmpty)
                ? item.boardName!
                : (item.collegeMasterName != null &&
                      item.collegeMasterName!.isNotEmpty)
                ? item.collegeMasterName!
                : '';
            basicModels.add(
              BasicEducationModel(
                userId: item.userId ?? 0,
                marks: item.marks,
                passingYear: item.passingYear,
                boardType: item.boardType ?? 0,
                boardId: item.boardId ?? 0,
                basicEducationId: item.basicEducationId ?? 0,
                degreeName: item.degreeName,
                boardName: boardVal,
                mediumName: item.mediumName ?? '',
              ),
            );
          } else {
            higher.add(item);
          }
          continue;
        }

        if (item is Map<String, dynamic>) {
          final degreeName = _readFromMap(item, [
            'degree_name',
            'degreeName',
            'degree',
          ]);
          if (looksLikeBasicDegree(degreeName)) {
            final board = _readFromMap(item, [
              'board_name',
              'boardName',
              'board',
            ]);
            final medium = _readFromMap(item, [
              'medium_name',
              'mediumName',
              'medium',
            ]);
            final marks = _readFromMap(item, ['marks', 'grade', 'percentage']);
            final year = _readFromMap(item, [
              'passing_year',
              'passingYear',
              'year',
            ]);

            basicModels.add(
              BasicEducationModel(
                userId:
                    int.tryParse(_readFromMap(item, ['user_id', 'userId'])) ??
                    0,
                marks: marks,
                passingYear: year,
                boardType:
                    int.tryParse(_readFromMap(item, ['board_type'])) ?? 0,
                boardId:
                    int.tryParse(_readFromMap(item, ['board_id', 'boardId'])) ??
                    0,
                basicEducationId:
                    int.tryParse(
                      _readFromMap(item, [
                        'basic_education_id',
                        'basicEducationId',
                      ]),
                    ) ??
                    0,
                degreeName: degreeName,
                boardName: board.isNotEmpty ? board : '',
                mediumName: medium.isNotEmpty ? medium : '',
              ),
            );
          } else {
            try {
              final ed = EducationDetailModel.fromJson(
                Map<String, dynamic>.from(item),
              );
              higher.add(ed);
            } catch (_) {
              final ed = EducationDetailModel(
                userId:
                    int.tryParse(_readFromMap(item, ['user_id', 'userId'])) ??
                    0,
                marks: _readFromMap(item, ['marks', 'grade', 'percentage']),
                passingMonth: _readFromMap(item, [
                  'passing_month',
                  'passingMonth',
                ]),
                passingYear: _readFromMap(item, [
                  'passing_year',
                  'passingYear',
                  'year',
                ]),
                educationId:
                    int.tryParse(
                      _readFromMap(item, ['educationid', 'educationId']),
                    ) ??
                    0,
                customCollegeName: _readFromMap(item, [
                  'custom_college_name',
                  'customCollegeName',
                ]),
                degreeName: degreeName,
                courseName: _readFromMap(item, [
                  'course_name',
                  'courseName',
                  'course',
                ]),
                gradeName: _readFromMap(item, ['grade_name', 'gradeName']),
                grade: _readFromMap(item, ['grade']),
                specializationName: _readFromMap(item, [
                  'specilization_name',
                  'specialization_name',
                  'specializationName',
                ]),
                collegeMasterName: _readFromMap(item, [
                  'clgmastername',
                  'college_master_name',
                  'collegeMasterName',
                ]),
                boardType:
                    int.tryParse(_readFromMap(item, ['board_type'])) ?? 0,
                boardId:
                    int.tryParse(_readFromMap(item, ['board_id', 'boardId'])) ??
                    0,
                basicEducationId:
                    int.tryParse(
                      _readFromMap(item, [
                        'basic_education_id',
                        'basicEducationId',
                      ]),
                    ) ??
                    0,
                boardName: _readFromMap(item, [
                  'board_name',
                  'boardName',
                  'board',
                ]),
                mediumName: _readFromMap(item, [
                  'medium_name',
                  'mediumName',
                  'medium',
                ]),
                courseType: _readFromMap(item, ['course_type', 'courseType']),
              );
              higher.add(ed);
            }
          }
          continue;
        }

        try {
          final m = Map<String, dynamic>.from(item);
          final degreeName = _readFromMap(m, [
            'degree_name',
            'degreeName',
            'degree',
          ]);
          if (looksLikeBasicDegree(degreeName)) {
            basicModels.add(BasicEducationModel.fromJson(m));
          } else {
            higher.add(EducationDetailModel.fromJson(m));
          }
        } catch (_) {}
      }

      higher.sort(_compareEducation);
      basicModels.sort(_compareBasicEducation);

      if (!mounted) return;
      setState(() {
        educationDetails = higher;
        basicEducationDetails = basicModels;
        educationDetail = educationDetails.isNotEmpty
            ? educationDetails.first
            : null;
        isLoadingEducation = false;
        _showShimmer = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isLoadingEducation = false;
        _showShimmer = false;
        _loadFailed = true;
      });
    }
  }

  EducationDetailModel _mapPayloadToEducationDetail(
    Map<String, dynamic> payload,
  ) {
    final ed = payload['educationDetail'];
    if (ed is EducationDetailModel) return ed;

    if (ed is Map<String, dynamic>) {
      return EducationDetailModel.fromJson(ed);
    }

    String? pickString(Map m, List<String> keys) {
      for (final k in keys) {
        if (m.containsKey(k) && m[k] != null) {
          final v = m[k];
          if (v is String && v.trim().isNotEmpty) return v.trim();
          if (v is int) return v.toString();
        }
      }
      return null;
    }

    int? pickInt(Map m, List<String> keys) {
      for (final k in keys) {
        if (m.containsKey(k) && m[k] != null) {
          final v = m[k];
          if (v is int) return v;
          final s = v.toString();
          final parsed = int.tryParse(s);
          if (parsed != null) return parsed;
        }
      }
      return null;
    }

    final Map top = payload;

    final degreeName = pickString(top, ['degreeName', 'degree_name']) ?? '';
    final passingYear =
        pickString(top, ['passingYear', 'passing_year', 'year']) ?? '';
    final passingMonth = pickString(top, [
      'passingMonth',
      'passing_month',
      'month',
    ]);
    final marks = pickString(top, ['marks', 'percentage']) ?? '';
    final courseName =
        pickString(top, ['courseName', 'course_name', 'course']) ?? '';
    final specializationName =
        pickString(top, [
          'specializationName',
          'specialization_name',
          'specialization',
        ]) ??
        '';
    final collegeMasterName =
        pickString(top, [
          'collegeMasterName',
          'college_master_name',
          'collegeName',
          'college_name',
        ]) ??
        '';
    final gradeName = pickString(top, ['gradeName', 'grade_name']);
    final grade = pickString(top, ['grade']);
    final courseType = pickString(top, ['courseType', 'course_type']);

    final educationId = pickInt(top, ['educationid', 'educationId']);
    final boardId = pickInt(top, ['board_id', 'boardId']);
    final basicEducationId = pickInt(top, [
      'basic_education_id',
      'basicEducationId',
    ]);
    final gradingType = pickInt(top, ['grading_type', 'gradingType']);

    return EducationDetailModel(
      marks: marks,
      passingMonth: passingMonth,
      passingYear: passingYear,
      educationId: educationId,
      customCollegeName: null,
      degreeName: degreeName,
      courseName: courseName.isNotEmpty ? courseName : null,
      gradeName: gradeName,
      grade: grade,
      specializationName: specializationName.isNotEmpty
          ? specializationName
          : null,
      collegeMasterName: collegeMasterName.isNotEmpty
          ? collegeMasterName
          : null,
      boardType: null,
      boardId: boardId,
      basicEducationId: basicEducationId,
      boardName: pickString(top, ['boardName', 'board_name']),
      mediumName: pickString(top, ['medium', 'mediumName', 'medium_name']),
      courseType: courseType,
      gradingType: gradingType,
      userId: null,
    );
  }

  BasicEducationModel _mapPayloadToBasicEducation(
    Map<String, dynamic> payload,
  ) {
    final ed = payload['educationDetail'];

    if (ed is BasicEducationModel) return ed;

    if (ed is Map<String, dynamic>) {
      return BasicEducationModel.fromJson(ed);
    }

    String? pickString(Map m, List<String> keys) {
      for (final k in keys) {
        if (m.containsKey(k) && m[k] != null) {
          final v = m[k];
          if (v is String && v.trim().isNotEmpty) return v.trim();
          if (v is int) return v.toString();
        }
      }
      return null;
    }

    int? pickInt(Map m, List<String> keys) {
      for (final k in keys) {
        if (m.containsKey(k) && m[k] != null) {
          final v = m[k];
          if (v is int) return v;
          final s = v.toString();
          final parsed = int.tryParse(s);
          if (parsed != null) return parsed;
        }
      }
      return null;
    }

    final Map top = payload;

    final degreeName =
        pickString(top, [
          'degreeName',
          'degree_name',
          'educationDegree',
          'education_name',
        ]) ??
        'Class X';

    final marks = pickString(top, ['percentage', 'marks']) ?? '';
    final passingYear =
        pickString(top, [
          'yearOfPassing',
          'passingYear',
          'passing_year',
          'year',
        ]) ??
        '';
    final boardName = pickString(top, ['boardName', 'board_name']) ?? '';
    final mediumName =
        pickString(top, ['medium', 'mediumName', 'medium_name']) ?? '';

    final boardId = pickInt(top, ['boardId', 'board_id']);
    final basicEducationId = pickInt(top, [
      'basicEducationId',
      'basic_education_id',
    ]);
    final boardType = pickInt(top, ['boardType', 'board_type']);

    return BasicEducationModel(
      userId: null,
      marks: marks,
      passingYear: passingYear,
      boardType: boardType,
      boardId: boardId,
      basicEducationId: basicEducationId,
      degreeName: degreeName,
      boardName: boardName,
      mediumName: mediumName,
    );
  }

  Future<void> fetchInternShipProjectDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';
    final connectSid = prefs.getString('connectSid') ?? '';
    try {
      final internshipProjectApi =
          await InternshipProjectApi.fetchInternshipProjects(
            authToken: authToken,
            connectSid: connectSid,
          );
      if (mounted) {
        setState(() {
          projects = internshipProjectApi;
          isLoadingProject = false;
          print('Projects Fetched');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingProject = false;
          _loadFailed = true;
        });
        print("❌ Error fetching project details: $e");
      }
    }
  }

  Future<void> _fetchPersonalDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';
    final connectSid = prefs.getString('connectSid') ?? '';
    try {
      final results = await PersonalDetailApi.fetchPersonalDetails(
        authToken: authToken,
        connectSid: connectSid,
      );
      setState(() {
        if (results.isNotEmpty) {
          personalDetail = results.first as PersonalDetailModel?;
        } else {
          personalDetail = null;
        }
        isLoadingPersonalDetail = false;
        print('✅ Fetched personal detail');
      });
    } catch (e) {
      print('❌ Personal details fetch error: $e');
      setState(() {
        isLoadingPersonalDetail = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> fetchWorkExperienceDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';
    final connectSid = prefs.getString('connectSid') ?? '';
    setState(() {
      isLoadingWorkExperience = true;
    });
    try {
      final workExperienceApi = await WorkExperienceApi.fetchWorkExperienceApi(
        authToken: authToken,
        connectSid: connectSid,
      );
      setState(() {
        workExperiences = workExperienceApi;
        isLoadingWorkExperience = false;
        print(' Work experience fetched');
      });
    } catch (e) {
      print("❌ Error fetching work experience: $e");
      setState(() {
        isLoadingWorkExperience = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> fetchCertificateDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';
    final connectSid = prefs.getString('connectSid') ?? '';
    setState(() {
      isLoadingCertificate = true;
    });
    try {
      final certificates = await CertificateApi.fetchCertificateApi(
        authToken: authToken,
        connectSid: connectSid,
      );
      setState(() {
        certificatesList = certificates;
        isLoadingCertificate = false;
        print(' Certificates fetched successfully');
      });
    } catch (e) {
      print('❌ Error fetching certificates: $e');
      setState(() {
        isLoadingCertificate = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> fetchSkills() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';
    final connectSid = prefs.getString('connectSid') ?? '';
    setState(() {
      isLoadingSkills = true;
    });
    try {
      final result = await SkillsApi.fetchSkills(
        authToken: authToken,
        connectSid: connectSid,
      );
      setState(() {
        skillList = result;
        isLoadingSkills = false;
      });
    } catch (e) {
      print(' Error fetching skills: $e');
      if (mounted) {
        setState(() {
          isLoadingSkills = false;
          _loadFailed = true;
        });
      }
    }
  }

  Future<void> fetchLanguageData() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';
    final connectSid = prefs.getString('connectSid') ?? '';
    try {
      final fetchedLanguages = await LanguageDetailApi.fetchLanguages(
        authToken: authToken,
        connectSid: connectSid,
      );
      setState(() {
        languageList = fetchedLanguages;
        isLoadingLanguages = false;
      });
    } catch (e) {
      print('❌ Error fetching languages: $e');
      if (mounted) {
        setState(() {
          isLoadingLanguages = false;
          _loadFailed = true;
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 85);
    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      setState(() {
        _profileImage = imageFile;
      });
      
      // Upload the image to server
      await _uploadProfilePicture(imageFile);
    }
  }

  Future<void> _uploadProfilePicture(File imageFile) async {
    setState(() {
      _isUploadingProfilePicture = true;
    });

    try {
      final blobUrl = await ProfilePictureApi.uploadProfilePicture(
        imageFile: imageFile,
      );

      if (!mounted) return;

      if (blobUrl != null) {
        // Success - reload profile image from API to get the updated image
        await _loadProfileImageFromApi();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Profile picture updated successfully',
                style: TextStyle(fontSize: 13.sp),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Failed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to upload profile picture. Please try again.',
                style: TextStyle(fontSize: 13.sp),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ [MyAccount] Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error uploading profile picture: $e',
              style: TextStyle(fontSize: 13.sp),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingProfilePicture = false;
        });
      }
    }
  }

  void _showImagePickerOption() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 8.h),
                ListTile(
                  leading: Icon(
                    Icons.photo_library_outlined,
                    color: const Color(0xFF005E6A),
                    size: 22.w,
                  ),
                  title: Text(
                    'Choose from Gallery',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xFF003840),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.camera_alt_outlined,
                    color: const Color(0xFF005E6A),
                    size: 22.w,
                  ),
                  title: Text(
                    'Take a Photo',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xFF003840),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                if (_profileImage != null)
                  ListTile(
                    leading: Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 22.w,
                    ),
                    title: Text(
                      'Clear Local Preview',
                      style: TextStyle(fontSize: 14.sp, color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _profileImage = null);
                    },
                  ),
                SizedBox(height: 8.h),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSnackBarOnce(
    BuildContext context,
    String message, {
    int cooldownSeconds = 3,
  }) {
    if (_snackBarShown) return;
    _snackBarShown = true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontSize: 12.sp)),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );

    Future.delayed(Duration(seconds: cooldownSeconds), () {
      _snackBarShown = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(
      context,
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
    );

    return Scaffold(
      appBar: const AccountAppBar(),
      backgroundColor: Colors.white,
      body: _isRetrying || _showShimmer
          ? _buildShimmerLoading()
          : !_hasInternet
              ? NoInternetPage(onRetry: _checkInternetAndFetch)
              : _loadFailed
                  ? _buildLoadError()
                  : Builder(
                      builder: (innerContext) => SafeArea(
                        child: RefreshIndicator(
                          onRefresh: _checkInternetAndFetch,
                          child: SingleChildScrollView(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 17.h,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _buildProfileHeader(),
                                SizedBox(height: 22.h),
                                const ProfileCompletionBar(),
                                SizedBox(height: 22.h),
                                PersonalDetailsSection(
                                  personalDetail: personalDetail,
                                  isLoading: isLoadingPersonalDetail || _showShimmer,
                                  onEdit: () {
                                    showModalBottomSheet(
                                      context: innerContext,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.white,
                                      builder: (_) => EditPersonalDetailsSheet(
                                        initialData: personalDetail,
                                        onSave: (updatedData) {
                                          setState(() {
                                            personalDetail = updatedData;
                                          });
                                        },
                                      ),
                                    );
                                  },
                                ),
                                SizedBox(height: 17.h),
                                EducationSection(
                                  educationDetails: educationDetails,
                                  basicEducationDetails: basicEducationDetails,
                                  isLoading: isLoadingEducation || _showShimmer,
                                  onAdd: () {
                                    final existingDegrees = <String>[
                                      ...educationDetails
                                          .map((e) => (e.degreeName ?? '').trim())
                                          .where((s) => s.isNotEmpty),
                                      ...basicEducationDetails
                                          .map((b) => (b.degreeName ?? '').trim())
                                          .where((s) => s.isNotEmpty),
                                    ];

                            showModalBottomSheet(
                              context: innerContext,
                              isScrollControlled: true,
                              backgroundColor: Colors.white,
                              builder: (_) => EditEducationBottomSheet(
                                existingDegrees: existingDegrees,
                                onSave: (data) {
                                  final isBasic =
                                      (data['boardName'] != null) ||
                                      (data['medium'] != null) ||
                                      (data['percentage'] != null);

                                  if (isBasic) {
                                    final basic = _mapPayloadToBasicEducation(
                                      data,
                                    );
                                    setState(() => _insertBasicEducationByLevel(basic));
                                  } else {
                                    final ed = _mapPayloadToEducationDetail(
                                      data,
                                    );
                                    setState(() => _insertEducationByLevel(ed));
                                  }
                                  Navigator.pop(innerContext);
                                },
                              ),
                            );
                          },
                          onEdit: (edu, index) {
                            final existingDegrees =
                                <String>[
                                  ...educationDetails
                                      .map((e) => (e.degreeName ?? '').trim())
                                      .where((s) => s.isNotEmpty),
                                  ...basicEducationDetails
                                      .map((b) => (b.degreeName ?? '').trim())
                                      .where((s) => s.isNotEmpty),
                                ]..removeWhere(
                                  (d) =>
                                      d.toLowerCase() ==
                                      (edu.degreeName ?? '').toLowerCase(),
                                );
                            showModalBottomSheet(
                              context: innerContext,
                              isScrollControlled: true,
                              backgroundColor: Colors.white,
                              builder: (_) => EditEducationBottomSheet(
                                initialData: edu,
                                existingDegrees: existingDegrees,
                                onSave: (data) {
                                  final isBasic =
                                      (data['boardName'] != null) ||
                                      (data['medium'] != null) ||
                                      (data['percentage'] != null);

                                  if (isBasic) {
                                    final basic = _mapPayloadToBasicEducation(
                                      data,
                                    );
                                    setState(() {
                                      final idx = basicEducationDetails
                                          .indexWhere(
                                            (b) =>
                                                b.basicEducationId ==
                                                basic.basicEducationId,
                                          );
                                      if (idx != -1) {
                                        basicEducationDetails[idx] = basic;
                                      }
                                    });
                                  } else {
                                    final ed = _mapPayloadToEducationDetail(
                                      data,
                                    );
                                    setState(() {
                                      if (index >= 0 &&
                                          index < educationDetails.length) {
                                        educationDetails[index] = ed;
                                      }
                                    });
                                  }
                                  Navigator.pop(innerContext);
                                },
                              ),
                            );
                          },
                          onDelete: (index) {
                            setState(() {
                              if (index >= 0 &&
                                  index < educationDetails.length) {
                                educationDetails.removeAt(index);
                              }
                            });
                          },
                          onEditBasic: (basicModel, index) {
                            final existingDegrees =
                                <String>[
                                  ...educationDetails
                                      .map((e) => (e.degreeName ?? '').trim())
                                      .where((s) => s.isNotEmpty),
                                  ...basicEducationDetails
                                      .map((b) => (b.degreeName ?? '').trim())
                                      .where((s) => s.isNotEmpty),
                                ]..removeWhere(
                                  (d) =>
                                      d.toLowerCase() ==
                                      (basicModel.degreeName ?? '')
                                          .toLowerCase(),
                                );

                            showModalBottomSheet(
                              context: innerContext,
                              isScrollControlled: true,
                              backgroundColor: Colors.white,
                              builder: (_) => EditEducationBottomSheet(
                                initialData: EducationDetailModel(
                                  degreeName: (basicModel.degreeName ?? '')
                                      .toString(),
                                  passingYear: (basicModel.passingYear ?? '')
                                      .toString(),
                                  marks: (basicModel.marks ?? '').toString(),
                                  basicEducationId: basicModel.basicEducationId,
                                  boardId: basicModel.boardId,
                                  boardType: basicModel.boardType,
                                  boardName: (basicModel.boardName ?? '')
                                      .toString(),
                                  mediumName: (basicModel.mediumName ?? '')
                                      .toString(),
                                ),
                                existingDegrees: existingDegrees,
                                onSave: (data) {
                                  final basic = _mapPayloadToBasicEducation(
                                    data,
                                  );
                                  setState(() {
                                    if (index >= 0 &&
                                        index < basicEducationDetails.length) {
                                      basicEducationDetails[index] = basic;
                                    }
                                  });
                                  Navigator.pop(innerContext);
                                },
                              ),
                            );
                          },
                          onDeleteBasic: (index) {
                            setState(() {
                              if (index >= 0 &&
                                  index < basicEducationDetails.length) {
                                basicEducationDetails.removeAt(index);
                              }
                            });
                          },
                        ),
                        SizedBox(height: 17.h),
                        const ResumeSection(),
                        SizedBox(height: 17.h),
                        SkillsSection(
                          skillList: skillList,
                          isLoading: isLoadingSkills || _showShimmer,

                          // ➕ ADD SKILL
                          onAdd: () {
                            showModalBottomSheet(
                              context: innerContext,
                              isScrollControlled: true,
                              builder: (_) => EditSkillsBottomSheet(
                                initialSkills: skillList,
                                onSave: (updatedSkills) async {
                                  setState(() => skillList = updatedSkills);
                                  await fetchSkills(); // ✅ re-sync from backend
                                },
                              ),
                            );
                          },

                          // ✏️ EDIT SKILL
                          onEdit: () {
                            showModalBottomSheet(
                              context: innerContext,
                              isScrollControlled: true,
                              builder: (_) => EditSkillsBottomSheet(
                                initialSkills: skillList,
                                onSave: (updatedSkills) async {
                                  setState(() => skillList = updatedSkills);
                                  await fetchSkills(); // ✅ re-sync
                                },
                              ),
                            );
                          },

                          // 🗑️ DELETE SINGLE SKILL (UI-only; backend handled on save)
                          onDeleteSkill: (skill, singleSkill) {
                            setState(() {
                              final parsedSkills = skill.skills
                                  .split(RegExp(r',(?![^()]*\))'))
                                  .map((s) => s.trim())
                                  .where((s) => s.isNotEmpty)
                                  .toList();

                              final updatedSkills = parsedSkills
                                  .where((s) => s != singleSkill)
                                  .toList();

                              if (updatedSkills.isEmpty) {
                                skillList.remove(skill);
                              } else {
                                skill.skills = updatedSkills.join(', ');
                              }
                            });
                          },
                        ),

                        SizedBox(height: 17.h),
                        ProjectsSection(
                          projects: projects,
                          isLoading: isLoadingProject,
                          onAdd: () async {
                            final prefs = await SharedPreferences.getInstance();
                            final authToken =
                                prefs.getString('authToken') ?? '';

                            if (authToken.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please login again'),
                                ),
                              );
                              return;
                            }

                            print("🆕 Opening Add Project BottomSheet");

                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(14.r),
                                ),
                              ),
                              builder: (context) =>
                                  EditProjectDetailsBottomSheet(
                                    initialData: null,
                                    onSave: (newData) async {
                                      await fetchInternShipProjectDetails();
                                    },
                                  ),
                            );
                          },

                          onEdit: (project, index) async {
                            final prefs = await SharedPreferences.getInstance();
                            final authToken =
                                prefs.getString('authToken') ?? '';
                            if (authToken.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: Please log in again.'),
                                ),
                              );
                              return;
                            }

                            bool isSaveComplete = false;
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(14.r),
                                ),
                              ),
                              builder: (context) => EditProjectDetailsBottomSheet(
                                initialData: project,
                                onSave: (updatedData) async {
                                  if (!isSaveComplete) {
                                    print(
                                      "✅ [onEdit -> onSave] Updated project: ${updatedData.projectName} | Type: ${updatedData.type}",
                                    );
                                    isSaveComplete = true;
                                    await fetchInternShipProjectDetails();
                                  }
                                },
                              ),
                            );
                          },
                          onDelete: (int index) async {
                            final internshipId = int.tryParse(
                              projects[index].internshipId ?? '',
                            );
                            if (internshipId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Invalid internship ID'),
                                ),
                              );
                              return;
                            }

                            final prefs = await SharedPreferences.getInstance();
                            final authToken =
                                prefs.getString('authToken') ?? '';
                            final connectSid =
                                prefs.getString('connectSid') ?? '';

                            final success =
                                await InternshipProjectApi.deleteProjectInternship(
                                  internshipId: internshipId,
                                  authToken: authToken,
                                  connectSid: connectSid,
                                );

                            if (success) {
                              setState(() {
                                projects.removeAt(index);
                              });
                              _showSnackBarOnce(
                                context,
                                "Internship deleted successfully ",
                              );
                            } else {
                              _showSnackBarOnce(
                                context,
                                "Failed to delete Internship",
                              );
                            }
                          },
                        ),
                        SizedBox(height: 17.h),
                        CertificatesSection(
                          certificatesList: certificatesList,
                          isLoading: isLoadingCertificate,
                          onAdd: () {
                            showModalBottomSheet(
                              context: innerContext,
                              isScrollControlled: true,
                              backgroundColor: Colors.white,
                              builder: (_) => EditCertificateBottomSheet(
                                initialData: null,
                                onSave: (certif) async {
                                  try {
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    final authToken =
                                        prefs.getString('authToken') ?? '';
                                    final connectSid =
                                        prefs.getString('connectSid') ?? '';

                                    if (authToken.isEmpty) {
                                      throw Exception('Missing auth token');
                                    }
                                    await CertificateApi.saveCertificateApi(
                                      model: certif,
                                      authToken: authToken,
                                      connectSid: connectSid,
                                    );
                                    await fetchCertificateDetails();
                                    if (innerContext.mounted)
                                      Navigator.pop(innerContext);
                                  } catch (e) {
                                    print('❌ Failed to add certificate: $e');
                                    ScaffoldMessenger.of(
                                      innerContext,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to add certificate: $e',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                          onEdit: (certificate, index) {
                            showModalBottomSheet(
                              context: innerContext,
                              isScrollControlled: true,
                              backgroundColor: Colors.white,
                              builder: (_) => EditCertificateBottomSheet(
                                initialData: certificate,
                                onSave: (updatedCert) async {
                                  try {
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    final authToken =
                                        prefs.getString('authToken') ?? '';
                                    final connectSid =
                                        prefs.getString('connectSid') ?? '';

                                    if (authToken.isEmpty) {
                                      throw Exception('Missing auth token');
                                    }

                                    await CertificateApi.saveCertificateApi(
                                      model: updatedCert,
                                      authToken: authToken,
                                      connectSid: connectSid,
                                    );

                                    await fetchCertificateDetails();
                                    if (innerContext.mounted)
                                      Navigator.pop(innerContext);
                                  } catch (e) {
                                    print('❌ Failed to update certificate: $e');
                                    ScaffoldMessenger.of(
                                      innerContext,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to update certificate: $e',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                          onDelete: (int index) async {
                            final certificationId = int.tryParse(
                              certificatesList[index].certificationId ?? '',
                            );
                            if (certificationId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Invalid certificate ID'),
                                ),
                              );
                              return;
                            }
                            final prefs = await SharedPreferences.getInstance();
                            final authToken =
                                prefs.getString('authToken') ?? '';
                            final connectSid =
                                prefs.getString('connectSid') ?? '';
                            final success =
                                await CertificateApi.deleteCertificate(
                                  certificationId: certificationId,
                                  authToken: authToken,
                                  connectSid: connectSid,
                                );
                            if (success) {
                              setState(() {
                                certificatesList.removeAt(index);
                              });
                              _showSnackBarOnce(
                                context,
                                "Certificate deleted successfully ",
                              );
                            } else {
                              _showSnackBarOnce(
                                context,
                                "Failed to delete certificate",
                              );
                            }
                          },
                        ),
                        SizedBox(height: 17.h),
                        WorkExperienceSection(
                          workExperiences: workExperiences,
                          isLoading: isLoadingWorkExperience,
                          onAdd: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.white,
                              builder: (_) => EditWorkExperienceBottomSheet(
                                initialData: null,
                                onSave: (WorkExperienceModel newData) async {
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  final authToken =
                                      prefs.getString('authToken') ?? '';
                                  final connectSid =
                                      prefs.getString('connectSid') ?? '';
                                  final success =
                                      await WorkExperienceApi.saveWorkExperience(
                                        model: newData,
                                        authToken: authToken,
                                        connectSid: connectSid,
                                      );
                                  if (success) {
                                    await fetchWorkExperienceDetails();
                                    Navigator.pop(context);
                                  }
                                  return success;
                                },
                              ),
                            );
                          },
                          onEdit: (workExperience, index) {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.white,
                              builder: (_) => EditWorkExperienceBottomSheet(
                                initialData: workExperience,
                                onSave: (WorkExperienceModel updated) async {
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  final authToken =
                                      prefs.getString('authToken') ?? '';
                                  final connectSid =
                                      prefs.getString('connectSid') ?? '';
                                  final success =
                                      await WorkExperienceApi.saveWorkExperience(
                                        model: updated,
                                        authToken: authToken,
                                        connectSid: connectSid,
                                      );
                                  if (success) {
                                    await fetchWorkExperienceDetails();
                                    Navigator.pop(context);
                                  }
                                  return success;
                                },
                              ),
                            );
                          },
                          onDelete: (int index) async {
                            final workExperienceId = int.tryParse(
                              workExperiences[index].workExperienceId ?? '',
                            );
                            final prefs = await SharedPreferences.getInstance();
                            final authToken =
                                prefs.getString('authToken') ?? '';
                            final connectSid =
                                prefs.getString('connectSid') ?? '';

                            final success =
                                await WorkExperienceApi.deleteWorkExperience(
                                  workExperienceId: workExperienceId,
                                  authToken: authToken,
                                  connectSid: connectSid,
                                );
                            if (success) {
                              setState(() {
                                workExperiences.removeAt(index);
                              });
                              _showSnackBarOnce(
                                context,
                                "Work Experience deleted successfully ",
                              );
                            } else {
                              _showSnackBarOnce(
                                context,
                                "Failed to delete Work Experience",
                              );
                            }
                          },
                        ),
                        SizedBox(height: 17.h),
                        LanguagesSection(
                          languageList: languageList,
                          isLoading: isLoadingLanguages,
                          onAdd: () {
                            showModalBottomSheet(
                              context: innerContext,
                              isScrollControlled: true,
                              backgroundColor: Colors.white,
                              builder: (_) => LanguageBottomSheet(
                                initialData: null,
                                existingLanguages: languageList,
                                onSave: (LanguagesModel data) {
                                  setState(() {
                                    languageList.add(data);
                                  });
                                },
                              ),
                            );
                          },
                          onDelete: (int index) async {
                            final languageId = languageList[index].id;
                            final prefs = await SharedPreferences.getInstance();
                            final authToken =
                                prefs.getString('authToken') ?? '';
                            final connectSid =
                                prefs.getString('connectSid') ?? '';
                            final success =
                                await LanguageDetailApi.deleteLanguage(
                                  id: languageId,
                                  authToken: authToken,
                                  connectSid: connectSid,
                                );
                            if (success) {
                              setState(() {
                                languageList.removeAt(index);
                              });
                              _showSnackBarOnce(
                                context,
                                "Language deleted successfully ",
                              );
                            } else {
                              _showSnackBarOnce(
                                context,
                                "Failed to delete language, try again",
                              );
                            }
                          },
                        ),
                        SizedBox(height: 17.h),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    Widget displayedImage;

    Future<bool> hasNetwork() async {
      if (kIsWeb) return true;
      try {
        final result = await InternetAddress.lookup(
          'example.com',
        ).timeout(const Duration(seconds: 2));
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } catch (_) {
        return false;
      }
    }

    void handleTap(BuildContext context, VoidCallback callback) async {
      final ok = await hasNetwork();
      if (!ok) {
        _showSnackBarOnce(context, "No internet available");
        return;
      }
      callback();
    }

    if (_profileImage != null) {
      displayedImage = Image.file(_profileImage!, fit: BoxFit.cover);
    } else if (_imageUpdateData?.userImage != null &&
        _imageUpdateData!.userImage!.isNotEmpty) {
      displayedImage = Image.network(
        _imageUpdateData!.userImage!,
        fit: BoxFit.cover,
      );
    } else {
      displayedImage = const Image(
        image: AssetImage('assets/placeholder.jpg'),
        fit: BoxFit.cover,
      );
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 140.w,
              height: 140.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF005E6A), width: 2.w),
              ),
              child: ClipOval(
                child: SizedBox.expand(
                  child: Transform.scale(
                    scale: 1.08,
                    child: displayedImage is Image
                        ? Image(
                            image: displayedImage.image,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            filterQuality: FilterQuality.high,
                          )
                        : displayedImage,
                  ),
                ),
              ),
            ),
            // Show uploading indicator
            if (_isUploadingProfilePicture)
              Container(
                width: 140.w,
                height: 140.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black54,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3.w,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Uploading...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              bottom: 8.h,
              right: 8.w,
              child: GestureDetector(
                onTap: _isUploadingProfilePicture 
                  ? null 
                  : () {
                      handleTap(context, _showImagePickerOption);
                    },
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 16.r,
                  child: _isUploadingProfilePicture
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.w,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFF005E6A),
                          ),
                        ),
                      )
                    : Icon(
                        Icons.camera_alt_outlined,
                        size: 20.w,
                        color: const Color(0xFF005E6A),
                      ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Text(
          '${_imageUpdateData?.firstName ?? ''} ${_imageUpdateData?.lastName ?? ''}'
              .trim(),
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF005E6A),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadError() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48.sp,
              color: Colors.red.shade400,
            ),
            SizedBox(height: 12.h),
            Text(
              'Unable to load account data',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF003840),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6.h),
            Text(
              'Please try again or pull to refresh.',
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _checkInternetAndFetch,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005E6A),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildShimmerHeader() {
  //   return Container(
  //     width: 145.w,
  //     height: 145.h,
  //     decoration: BoxDecoration(
  //       shape: BoxShape.circle,
  //       color: Colors.grey.shade300,
  //     ),
  //   );
  // }
}

Widget _buildShimmerLoading() {
  return SingleChildScrollView(
    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 17.h),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            width: 145.w,
            height: 145.h,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 22.h),

        // Name shimmer
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            width: 120.w,
            height: 20.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        ),
        SizedBox(height: 22.h),

        // Profile completion bar shimmer
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            width: double.infinity,
            height: 20.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        ),
        SizedBox(height: 22.h),

        // Section cards shimmer (repeatable blocks)
        ...List.generate(4, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: 17.h),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                width: double.infinity,
                height: 100.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          );
        }),
      ],
    ),
  );
}
