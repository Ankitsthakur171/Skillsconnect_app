
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

class Applicant {
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
  final List<EducationItem> educationList;
  final List<Experience> experience;
  final List<Project> project;
  final List<Certifications> certifications;
  final List<BasicEducation> basiceducation;
  final List<VideoIntroduction> videoIntroduction;

  Applicant({
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
    required this.educationList,
    required this.experience,
    required this.project,
    required this.certifications,
    required this.basiceducation,
    required this.videoIntroduction,
  });

  factory Applicant.fromJson(Map<String, dynamic> data) {

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
    // final degreeDetailsRaw = data['degree_details'];
    // final degreeList = degreeDetailsRaw is List ? degreeDetailsRaw : [];
    //
    // final basicEduRaw = data['basic_education'];
    // final basicEduList = basicEduRaw is List ? basicEduRaw : [];
    //
    // final educationItems = [
    //   ...degreeList.map((e) => EducationItem.fromDegreeDetails(e)),
    //   ...basicEduList.map((e) => EducationItem.fromBasicEducation(e)),
    // ];

    /// Education Details
    final degreeDetailsRaw = data['degree_details'];
    final degreeList = degreeDetailsRaw is List ? degreeDetailsRaw : [];

    final basicEduRaw = data['basic_education'];
    final basicEduList = basicEduRaw is List ? basicEduRaw : [];

    final educationItems = degreeList
        .map((e) => EducationItem.fromDegreeDetails(e))
        .toList();


    /// Project / Internship
    final projectInternshipRaw = data['project_internship'];
    final internshipList = (projectInternshipRaw is Map &&
        projectInternshipRaw['Internship'] is List)
        ? projectInternshipRaw['Internship'] as List
        : [];

    final projectList =
    internshipList.map((e) => Project.fromJson(e)).toList();

    /// Certifications
    final certListRaw = data['certification'];
    final certList = certListRaw is List ? certListRaw : [];
    final certifications =
    certList.map((e) => Certifications.fromJson(e)).toList();

    /// Experience
    final expRaw = data['user_workexperience'];
    final expList = expRaw is List ? expRaw : [];
    final experiences = expList.map((e) => Experience.fromJson(e)).toList();

    /// Video Introduction

    // final videoIntroRaw = data['video_introduction'];
    // final videoList = (videoIntroRaw is List)
    //     ? videoIntroRaw.map((e) => VideoIntroduction.fromJson(e)).toList()
    //     : [];
    final videoListRaw = data['video_introduction'];
    final List<VideoIntroduction> videoList = (videoListRaw is List)
        ? videoListRaw.map((e) => VideoIntroduction.fromJson(e)).toList()
        : [];



    /// Format DOB safely
    String rawDob = basic['date_of_birth'] ?? '';
    String formattedDob = rawDob.isNotEmpty ? formatDate(rawDob) : '';

    String rawApplied = basic['applied_date'] ?? '';
    String formattApplieddate = rawApplied.isNotEmpty ? formatDate(rawApplied) : '';

    return Applicant(
      name: basic['full_name'] ?? 'Tushar',
      imageUrl: basic['user_image'] ?? '',
      dob: formattedDob,
      gender: basic['gender'] ?? '',
      appliedate: formattApplieddate,
      designation: resumeParsed['personal_info']?['title'] ?? '',
      email: basic['email'] ?? '',
      phone: basic['mobile'] ?? '',
      statename: basic['state_name'] ?? '',
      cityname: basic['city_name'] ?? '',
      resumeUrl: basic['resume'] ?? '',
      educationList: educationItems,
      experience: experiences,
      project: projectList,
      certifications: certifications,
      basiceducation: basicEduList
          .map((e) => BasicEducation.fromJson(e))
          .toList(),
      videoIntroduction: videoList,
    );
  }
}

// ✔ Modified for resume_parsed_json
class EducationItem {
  final String degreeOnly;
  final String coursename;
  final String specializationName;
  final String instituteName;
  final String marks;
  final String grade;

  EducationItem({
    required this.degreeOnly,
    required this.coursename,
    required this.specializationName,
    required this.instituteName,
    required this.marks,
    required this.grade,
  });

  factory EducationItem.fromDegreeDetails(Map<String, dynamic> json) {
    final isPursuing = (json['pursuing']?.toString().toLowerCase() == 'yes');
    final degree = json['degree_name'] ?? '';
    final course = json['course_name'] ?? '';
    final spec = json['specilization_name'] ?? '';
    final mark = json['marks'] ?? '';
    final grades = json['type'] ?? '';

    return EducationItem(
      degreeOnly: isPursuing ? "$degree (Pursuing)" : degree,
      coursename: course,
      specializationName: spec,
      instituteName: '${json['college_name'] ?? ''}, ${json['city_name'] ?? ''}',
      marks: mark,
      grade: grades,
    );
  }

  factory EducationItem.fromBasicEducation(Map<String, dynamic> json) {
    final isPursuing = (json['pursuing']?.toString().toLowerCase() == 'yes');
    final degree = json['degree_name'] ?? '';

    return EducationItem(
      degreeOnly: isPursuing ? "Pursuing in $degree" : degree,
      coursename: json['course_name'] ?? '',
      specializationName: '',
      instituteName: json['board_name'] ?? '',
      marks:json['marks'] ,
      grade: json['type'],
    );
  }
}

// class EducationItem {
//   final String degreeName;
//   final String coursename;
//   final String instituteName;
//
//   EducationItem({
//     required this.degreeName,
//     required this.coursename,
//     required this.instituteName,
//   });
//
//   factory EducationItem.fromDegreeDetails(Map<String, dynamic> json) {
//     final isPursuing = (json['pursuing']?.toString().toLowerCase() == 'yes');
//
//     return EducationItem(
//       degreeName: isPursuing
//           ? '${json['degree_name'] ?? ''} - Pursuing in ${json['course_name'] ?? ''} in ${json['specilization_name'] ?? ''}'
//           : '${json['degree_name'] ?? ''} - ${json['course_name'] ?? ''} in ${json['specilization_name'] ?? ''}',
//       instituteName: '${json['college_name'] ?? ''}, ${json['city_name'] ?? ''}',
//       coursename: '${json['course_name']}',
//     );
//   }
//
//   factory EducationItem.fromBasicEducation(Map<String, dynamic> json) {
//     final isPursuing = (json['pursuing']?.toString().toLowerCase() == 'yes');
//
//     return EducationItem(
//       degreeName: isPursuing
//           ? 'Pursuing in ${json['degree_name'] ?? ''}'
//           : json['degree_name'] ?? '',
//       instituteName: json['board_name'] ?? '',
//       coursename: json['course_name'] ??  '',
//     );
//   }
// }


class Experience {
  final String organization;
  final String jobTitle;
  final String fromDate;
  final String toDate;
  final String totalExperience;
  final String salary;
  final String skills;
  final String jobdescription;

  Experience({
    required this.organization,
    required this.jobTitle,
    required this.fromDate,
    required this.toDate,
    required this.totalExperience,
    required this.salary,
    required this.skills,
    required this.jobdescription,
  });

  factory Experience.fromJson(Map<String, dynamic> json) {
    final salary = "${json['salary_in_lacs'] ?? '0'}.${json['salary_in_thousands'] ?? '00'} LPA";

    return Experience(
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

// ✔ Updated for academic_projects JSON format
class Project {
  final String project_name;
  final String type;
  final String month;
  final int internship_duration;
  final String skills;
  final String company_name;
  final String details;

  Project({
    required this.project_name,
    required this.type,
    required this.month,
    required this.internship_duration,
    required this.skills,
    required this.company_name,
    required this.details,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
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

// ✔ Updated for certifications JSON format

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

// class Certifications {
//   final String certificate_name;
//   final String issued_org_name;
//   final String provider;
//   final String completionDate;
//
//   Certifications({
//     required this.certificate_name,
//     required this.issued_org_name,
//     required this.provider,
//     required this.completionDate,
//   });
//
//   factory Certifications.fromJson(Map<String, dynamic> json) {
//     return Certifications(
//       certificate_name: json['certification_name'] ?? '',
//       issued_org_name: json['issued_org_name'] ?? '',
//       provider: '', // not available in your JSON
//       completionDate: json['year']?.toString() ?? '',
//     );
//   }
// }

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



class VideoIntroduction {
  final String? aboutYourself;
  final String? organizeYourDay;
  final String? yourStrength;
  final String? taughtYourselfLately;

  VideoIntroduction({
    this.aboutYourself,
    this.organizeYourDay,
    this.yourStrength,
    this.taughtYourselfLately,
  });

  factory VideoIntroduction.fromJson(Map<String, dynamic> json) {
    return VideoIntroduction(
      aboutYourself: json['about_yourself'],
      organizeYourDay: json['organize_your_day'],
      yourStrength: json['your_strength'],
      taughtYourselfLately: json['taught_yourself_tately'],
    );
  }
}







