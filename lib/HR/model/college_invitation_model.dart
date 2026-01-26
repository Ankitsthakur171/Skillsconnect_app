

import 'dart:ui';

class College {
  final int id;
  final String name;
  final String invite_count;
  final String statename;
  final String status;
  final int cvRecieved;
  final String maxsalary;
  final String minsalary;
  final String? tpoId;
  final String? verification_status;
  final List<TpoUser> tpoUsers;


  College({
    required this.id,
    required this.name,
    required this.invite_count,
    required this.statename,
    required this.status,
    required this.cvRecieved,
    required this.maxsalary,
    required this.minsalary,
    required this.tpoId,
    required this.verification_status,
    required this.tpoUsers,
  });

  factory College.fromJson(Map<String, dynamic> json,String type) {
    return College(
      id: json['id'] ?? 0,
      name: json['college_name'] ?? 'N/A',
      invite_count: (json['invite_count'] ?? '')
          .toString()
          .replaceAll('Invited ', '')
          .trim(),
      statename: json['state_name'] ?? 'N/A',
      status: type,
      cvRecieved: json['cvs_recevied'] ?? 0,
      maxsalary: json['min_package']?.toString() ?? '',
      minsalary: json['max_package']?.toString() ?? '',
      tpoId: json['tpo_id']?.toString(),
      verification_status: json['verification_status']?.toString(),
      tpoUsers: (json['tpo_users'] as List<dynamic>?)
          ?.map((e) => TpoUser.fromJson(e))
          .toList() ??
          [],
    );
  }



  //-------Status Colours------------------------
  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'invitation':
        return const Color(0xffC64C2D); // Orange
      case 'excluded':
        return const Color(0xffB22121); // Red
      case 'invited':
        return const Color(0xff006A41); // Green
      default:
        return const Color(0xff7B7B7B); // Grey fallback
    }
  }

}


class TpoUser {
  final int id;
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final String? email;
  final String? mobile;

  TpoUser({
    required this.id,
    this.firstName,
    this.lastName,
    this.fullName,
    this.email,
    this.mobile,
  });

  factory TpoUser.fromJson(Map<String, dynamic> json) {
    return TpoUser(
      id: json['id'] ?? 0,
      firstName: json['first_name'],
      lastName: json['last_name'],
      fullName: json['full_name'],
      email: json['email'],
      mobile: json['mobile'],
    );
  }
}







class StateModel {
  final int id;
  final String name;
  final String status;
  final int countryId;

  StateModel({
    required this.id,
    required this.name,
    required this.status,
    required this.countryId,
  });

  factory StateModel.fromJson(Map<String, dynamic> json) {
    return StateModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      status: json['status'] ?? '',
      countryId: json['country_id'] ?? 0,
    );
  }

  @override
  String toString() => name;
}

class CityModel {
  final int id;
  final String name;
  final String status;
  final int stateId;

  CityModel({
    required this.id,
    required this.name,
    required this.status,
    required this.stateId,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      status: json['status'] ?? '',
      stateId: json['state_id'] ?? 0,
    );
  }

  @override
  String toString() => name;
}


class SpecializationModel {
  final int id;
  final String name;
  final String status;
  final int courseId;
  final String courseName;
  final String degreeName;

  SpecializationModel({
    required this.id,
    required this.name,
    required this.status,
    required this.courseId,
    required this.courseName,
    required this.degreeName,
  });

  factory SpecializationModel.fromJson(Map<String, dynamic> json) {
    return SpecializationModel(
      id: json['id'] ?? 0,
      name: json['specilization_name'] ?? '',
      status: json['status'] ?? '',
      courseId: json['course_id'] ?? 0,
      courseName: json['course_name'] ?? '',
      degreeName: json['degree_name'] ?? '',
    );
  }

  @override
  String toString() => name;
}





class CollegeModel {
  final int id;
  final String name;

  CollegeModel({required this.id, required this.name});

  factory CollegeModel.fromJson(Map<String, dynamic> json) {
    return CollegeModel(
      id: json['id'],
      name: json['text'] ?? '',
    );
  }

  @override
  String toString() => name;
}



class CourseModel {
  final int id;
  final String courseName;

  CourseModel({
    required this.id,
    required this.courseName,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'] ?? 0,
      courseName: json['course_name'] ?? '',  // 👈 key API se match ho
    );
  }

  @override
  String toString() => courseName;
}





class CollegeCriteria {
  final String collegeName;
  final String selectedState;
  final String selectedcity;
  final String collegestatus;
  final String instituteType;
  final String course;
  final String naacgrade;
  final String mylistname;
  final String specialization;
  final String type;

  const CollegeCriteria({
    this.collegeName = '',
    this.selectedState = '',
    this.selectedcity = '',
    this.collegestatus = '',
    this.instituteType = '',
    this.course = '',
    this.naacgrade = '',
    this.mylistname = '',
    this.specialization = '',
    this.type = 'invitation',
  });

  CollegeCriteria copyWith({
    String? collegeName,
    String? selectedState,
    String? selectedcity,
    String? collegestatus,
    String? instituteType,
    String? course,
    String? naacgrade,
    String? mylistname,
    String? specialization,
    String? type,
  }) {
    return CollegeCriteria(
      collegeName: collegeName ?? this.collegeName,
      selectedState: selectedState ?? this.selectedState,
      selectedcity: selectedcity ?? this.selectedcity,
      collegestatus: collegestatus ?? this.collegestatus,
      instituteType: instituteType ?? this.instituteType,
      course: course ?? this.course,
      naacgrade: naacgrade ?? this.naacgrade,
      mylistname: mylistname ?? this.mylistname,
      specialization: specialization ?? this.specialization,
      type: type ?? this.type,
    );
  }
}


