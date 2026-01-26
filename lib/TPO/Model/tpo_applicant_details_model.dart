
import 'dart:convert';

import 'package:intl/intl.dart';

String formatDate(String dateString) {
  try {
    DateTime dateTime = DateTime.parse(dateString).toLocal(); // Parse & Local
    return DateFormat("d MMM yyyy").format(dateTime); // Example: 24 Jan 2001
  } catch (e) {
    return dateString; // agar parse fail ho jaye to original string return
  }
}

class TPOApplicant {
  final String name;
  final String imageUrl;
  final String dob;
  final String gender;
  final String appliedate;
  final String designation;
  final String email;
  final String phone;
  final String statename;
  final String cityname;
  final String resumeUrl;
  final List<Education> tpoeducationList;
  final List<TpoExperience> experience;
  final List<TpoProject> project;
  final List<Certifications> certifications;
  final List<BasicEducation> basiceducation;
  final List<TpoVideoIntroduction> videoIntroduction;

  TPOApplicant({
    required this.name,
    required this.imageUrl,
    required this.dob,
    required this.gender,
    required this.appliedate,
    required this.designation,
    required this.email,
    required this.phone,
    required this.statename,
    required this.cityname,
    required this.resumeUrl,
    required this.tpoeducationList,
    required this.experience,
    required this.project,
    required this.certifications,
    required this.basiceducation,
    required this.videoIntroduction,
  });

  factory TPOApplicant.fromJson(Map<String, dynamic> data) {

    /// Candidate basic details
    final basicListRaw = data['candidateBasicDetails'];
    final basicList = basicListRaw is List ? basicListRaw : [];
    final basic = basicList.isNotEmpty ? basicList.first : {};

    /// Parse resume_parsed_json
    Map<String, dynamic> resumeParsed = {};
    if (basic['resume_parsed_json'] is String) {
      try {
        resumeParsed = jsonDecode(basic['resume_parsed_json']);
      } catch (e) {
        print(" Error decoding resume_parsed_json: $e");
      }
    }

    /// Education Details
    final degreeDetailsRaw = data['degree_details'];
    final degreeList = degreeDetailsRaw is List ? degreeDetailsRaw : [];

    final basicEduRaw = data['basic_education'];
    final basicEduList = basicEduRaw is List ? basicEduRaw : [];

    final educationItems = degreeList
        .map((e) => Education.fromDegreeDetails(e))
        .toList();    // final degreeDetailsRaw = data['degree_details'];
    // final degreeList = degreeDetailsRaw is List ? degreeDetailsRaw : [];
    //
    // final basicEduRaw = data['basic_education'];
    // final basicEduList = basicEduRaw is List ? basicEduRaw : [];
    //
    // final educationItems = [
    //   ...degreeList.map((e) => Education.fromDegreeDetails(e)),
    //   ...basicEduList.map((e) => Education.fromBasicEducation(e)),
    // ];

    /// Project / Internship
    final projectInternshipRaw = data['project_internship'];
    final internshipList = (projectInternshipRaw is Map &&
        projectInternshipRaw['Internship'] is List)
        ? projectInternshipRaw['Internship'] as List
        : [];

    final projectList =
    internshipList.map((e) => TpoProject.fromJson(e)).toList();

    /// Certifications
    final certListRaw = data['certification'];
    final certList = certListRaw is List ? certListRaw : [];
    final certifications =
    certList.map((e) => Certifications.fromJson(e)).toList();

    /// Experience
    final expRaw = data['user_workexperience'];
    final expList = expRaw is List ? expRaw : [];
    final experiences = expList.map((e) => TpoExperience.fromJson(e)).toList();

    /// Video Introduction
    // final videoIntroRaw = data['video_introduction'];
    // final videoList = (videoIntroRaw is List)
    //     ? videoIntroRaw.map((e) => VideoIntroduction.fromJson(e)).toList()
    //     : [];
    final videoListRaw = data['video_introduction'];
    final List<TpoVideoIntroduction> videoList = (videoListRaw is List)
        ? videoListRaw.map((e) => TpoVideoIntroduction.fromJson(e)).toList()
        : [];

    /// Format DOB safely
    String rawDob = basic['date_of_birth'] ?? '';
    String formattedDob = rawDob.isNotEmpty ? formatDate(rawDob) : '';

    String rawApplied = basic['applied_date'] ?? '';
    String formattApplieddate = rawApplied.isNotEmpty ? formatDate(rawApplied) : '';

    return TPOApplicant(
      name: basic['full_name'] ?? 'Tushar',
      imageUrl: basic['user_image'] ?? '',
      dob: formattedDob,
      gender: basic['gender'],
      appliedate: formattApplieddate,
      designation: resumeParsed['personal_info']?['title'] ?? '',
      email: basic['email'] ?? '',
      phone: basic['mobile'] ?? '',
      statename: basic['state_name'] ?? '',
      cityname: basic['city_name'] ?? '',
      resumeUrl: basic['resume'] ?? '',
      tpoeducationList: educationItems,
      experience: experiences,
      project: projectList,
      certifications: certifications,
      basiceducation: basicEduList
          .map((e) => BasicEducation.fromJson(e))
          .toList(), // Optional
      videoIntroduction: videoList, //  Now it's List<VideoIntroduction>
    );
  }
}

// ✔ Modified for resume_parsed_json
class Education {
  final String degreeOnly;
  final String coursename;
  final String specializationName;
  final String instituteName;
  final String marks;
  final String grade;

  Education({
    required this.degreeOnly,
    required this.coursename,
    required this.specializationName,
    required this.instituteName,
    required this.marks,
    required this.grade,
  });

  factory Education.fromDegreeDetails(Map<String, dynamic> json) {
    final isPursuing = (json['pursuing']?.toString().toLowerCase() == 'yes');
    final degree = json['degree_name'] ?? '';
    final course = json['course_name'] ?? '';
    final spec = json['specilization_name'] ?? '';
    final mark = json['marks'] ?? '';
    final grades = json['type'] ?? '';

    return Education(
      degreeOnly: isPursuing ? "$degree (Pursuing)" : degree,
      coursename: course,
      specializationName: spec,
      instituteName: '${json['college_name'] ?? ''}, ${json['city_name'] ?? ''}',
      marks: mark,
      grade: grades,
    );
  }

  factory Education.fromBasicEducation(Map<String, dynamic> json) {
    final isPursuing = (json['pursuing']?.toString().toLowerCase() == 'yes');
    final degree = json['degree_name'] ?? '';

    return Education(
      degreeOnly: isPursuing ? "Pursuing in $degree" : degree,
      coursename: json['course_name'] ?? '',
      specializationName: '',
      instituteName: json['board_name'] ?? '',
      marks:json['marks'] ,
      grade: json['type'],
    );
  }
}

class TpoExperience {
  final String organization;
  final String jobTitle;
  final String fromDate;
  final String toDate;
  final String totalExperience;
  final String salary;
  final String skills;
  final String jobdescription;

  TpoExperience({
    required this.organization,
    required this.jobTitle,
    required this.fromDate,
    required this.toDate,
    required this.totalExperience,
    required this.salary,
    required this.skills,
    required this.jobdescription,
  });

  factory TpoExperience.fromJson(Map<String, dynamic> json) {
    final salary = "${json['salary_in_lacs'] ?? '0'}.${json['salary_in_thousands'] ?? '00'} LPA";

    return TpoExperience(
      organization: json['organization'] ?? '',
      jobTitle: json['job_title'] ?? '',
      fromDate: json['work_from_date'] ?? '',
      toDate: json['work_to_date'] ?? '',
      totalExperience: json['total_experience'] ?? '',
      salary: salary,
      skills: json['skills'] ?? '',
      jobdescription: json['job_description'] ?? '',
    );
  }
}

// Updated for academic_projects JSON format
class TpoProject {
  final String project_name;
  final String type;
  final String month;
  final int internship_duration;
  final String skills;
  final String company_name;
  final String details;

  TpoProject({
    required this.project_name,
    required this.type,
    required this.month,
    required this.internship_duration,
    required this.skills,
    required this.company_name,
    required this.details,
  });

  factory TpoProject.fromJson(Map<String, dynamic> json) {
    return TpoProject(
      project_name: json['project_name'] ?? '',
      type: json['type'] ?? '',
      month: json['duration_period'] ?? '',
      internship_duration: json['duration'] ?? 0,
      skills: json['skills'] ?? '',
      company_name: json['company_name'] ?? '',
      details: json['details'] ?? '',
    );
  }
}

//  Updated for certifications JSON format
class Certifications {
  final String certificateName;
  final String issuedOrgName;
  final String issueDate;
  final String expireDate;
  final String description;

  Certifications({
    required this.certificateName,
    required this.issuedOrgName,
    required this.issueDate,
    required this.expireDate,
    required this.description,
  });

  factory Certifications.fromJson(Map<String, dynamic> json) {
    return Certifications(
      certificateName: json['certification_name'] ?? '',
      issuedOrgName: json['issued_org_name'] ?? '',
      issueDate: json['issue_date'] ?? '',
      expireDate: json['expire_date'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

// Optional, if needed for older API format
class BasicEducation {
  final String degreeName;
  final String boardName;

  BasicEducation({
    required this.degreeName,
    required this.boardName,
  });

  factory BasicEducation.fromJson(Map<String, dynamic> json) {
    return BasicEducation(
      degreeName: json['degree_name'] ?? '',
      boardName: json['board_name'] ?? '',
    );
  }
}



class TpoVideoIntroduction {
  final String? aboutYourself;
  final String? organizeYourDay;
  final String? yourStrength;
  final String? taughtYourselfLately;

  TpoVideoIntroduction({
    this.aboutYourself,
    this.organizeYourDay,
    this.yourStrength,
    this.taughtYourselfLately,
  });

  factory TpoVideoIntroduction.fromJson(Map<String, dynamic> json) {
    return TpoVideoIntroduction(
      aboutYourself: json['about_yourself'],
      organizeYourDay: json['organize_your_day'],
      yourStrength: json['your_strength'],
      taughtYourselfLately: json['taught_yourself_tately'],
    );
  }
}
