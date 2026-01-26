// class CollegeInfo {
//   final String name;
//   final String address;
//   final String instituteType;
//   final String naacGrade;
//   final String establishmentYear;
//   final String ownership;
//   final String email;
//   final String mobile;
//   final String firstname;
//   final String lastname;
//
//   CollegeInfo({
//     required this.name,
//     required this.address,
//     required this.instituteType,
//     required this.naacGrade,
//     required this.establishmentYear,
//     required this.ownership,
//     required this.email,
//     required this.mobile,
//     required this.firstname,
//     required this.lastname,
//   });
//
//   String get fullName {
//     final fn = firstname.trim();
//     final ln = lastname.trim();
//     if (fn.isEmpty && ln.isEmpty) return '';
//     if (fn.isEmpty) return ln;
//     if (ln.isEmpty) return fn;
//     return '$fn $ln';
//   }
//
//
//   factory CollegeInfo.fromJson(Map<String, dynamic> j) {
//     String s(dynamic v) => (v ?? '').toString();
//
//     return CollegeInfo(
//       name: s(j['college_name'] ?? j['name']),
//       address: s(j['college_address'] ?? j['address']),
//       instituteType: s(j['institute_type']),
//       naacGrade: s(j['naac'] ?? j['naac_grade']),
//       establishmentYear: s(j['year_of_establishment'] ?? j['establishment_year']),
//       ownership: s(j['Ownership'] ?? j['ownership']),
//       email: s(j['email'] ?? j['college_email']),
//       mobile: s(j['mobile'] ?? j['college_contact']),
//       firstname: s(j['first_name'] ?? j['first_name']),
//       lastname: s(j['last_name'] ?? j['last_name']),
//     );
//   }
// }
//
// class CourseInfo {
//   final String courseName;
//   final String specialization;
//   final String minPackage;
//   final String seatOffered;
//
//   CourseInfo({
//     required this.courseName,
//     required this.specialization,
//     required this.minPackage,
//     required this.seatOffered,
//   });
//
//   // API: data.collegeCourseDetails[*]
//   factory CourseInfo.fromApi(Map<String, dynamic> j) {
//     int i(dynamic v) {
//       if (v is int) return v;
//       if (v is String) return int.tryParse(v) ?? 0;
//       if (v is double) return v.toInt();
//       return 0;
//     }
//     String s(dynamic v) => (v ?? '').toString();
//
//     return CourseInfo(
//       courseName: s(j['course_name']),
//       specialization: s(j['specialization_name']),
//       minPackage: s(j['minpackage'] ?? "-/-"),
//       // seatOffered: i(j['seat_offered']),
//       seatOffered: s(j['seat_offered'] ?? "-/-"),
//
//     );
//   }
// }




class CollegePerson {
  final String firstName;
  final String lastName;
  final String email;
  final String mobile;
  final String roleName; // optional, agar dikhana chaho to

  CollegePerson({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobile,
    required this.roleName,
  });

  String get fullName {
    final f = firstName.trim();
    final l = lastName.trim();
    if (f.isEmpty && l.isEmpty) return '';
    if (f.isEmpty) return l;
    if (l.isEmpty) return f;
    return '$f $l';
  }

  factory CollegePerson.fromJson(Map<String, dynamic> j) {
    String s(dynamic v) => (v ?? '').toString();
    return CollegePerson(
      firstName: s(j['first_name']),
      lastName : s(j['last_name']),
      email    : s(j['email'] ?? j['college_email']),
      mobile   : s(j['mobile'] ?? j['college_contact']),
      roleName : s(j['roles_name']),
    );
  }
}


class CollegeInfo {
  final String name;
  final String roleName;
  final String verification_status;
  final String address;
  final String instituteType;
  final String naacGrade;
  final String establishmentYear;
  final String ownership;
  final String email;
  final String mobile;
  final String firstname;
  final String lastname;

  /// 🔹 NEW: multiple contacts parsed from `collegeDetails`
  final List<CollegePerson> contacts;

  CollegeInfo({
    required this.name,
    required this.roleName,
    required this.verification_status,
    required this.address,
    required this.instituteType,
    required this.naacGrade,
    required this.establishmentYear,
    required this.ownership,
    required this.email,
    required this.mobile,
    required this.firstname,
    required this.lastname,
    this.contacts = const [],
  });

  String get fullName {
    final fn = firstname.trim();
    final ln = lastname.trim();
    if (fn.isEmpty && ln.isEmpty) return '';
    if (fn.isEmpty) return ln;
    if (ln.isEmpty) return fn;
    return '$fn $ln';
  }

  /// 🔹 Joined names: "A B, C D, E"
  String get contactNamesJoined {
    final names = <String>{}; // LinkedHashSet behaviour via default Set keeps insertion order in Dart
    for (final c in contacts) {
      final n = c.fullName.trim();
      if (n.isNotEmpty) names.add(n);
    }
    return names.isEmpty ? '' : names.join(', ');
  }

  /// (optional) agar emails ya mobiles bhi comma-separated chahiye to:
  String get contactEmailsJoined {
    final emails = <String>{};
    for (final c in contacts) {
      final e = c.email.trim();
      if (e.isNotEmpty) emails.add(e);
    }
    return emails.join(', ');
  }

  String get contactMobilesJoined {
    final m = <String>{};
    for (final c in contacts) {
      final t = c.mobile.trim();
      if (t.isNotEmpty) m.add(t);
    }
    return m.join(', ');
  }

  /// Tumhara purana single-object factory (compatible)
  factory CollegeInfo.fromJson(Map<String, dynamic> j) {
    String s(dynamic v) => (v ?? '').toString();

    return CollegeInfo(
      name: s(j['college_name'] ?? j['name']),
      roleName: s(j['roles_name'] ?? j['name']),
      verification_status: s(j['verification_status'] ?? j['verification_status']),
      address: s(j['college_address'] ?? j['address']),
      instituteType: s(j['institute_type']),
      naacGrade: s(j['naac'] ?? j['naac_grade']),
      establishmentYear: s(j['year_of_establishment'] ?? j['establishment_year']),
      ownership: s(j['Ownership'] ?? j['ownership']),
      email: s(j['email'] ?? j['college_email']),
      mobile: s(j['mobile'] ?? j['college_contact']),
      firstname: s(j['first_name'] ?? j['first_name']),
      lastname: s(j['last_name'] ?? j['last_name']),
      contacts: const [],
    );
  }

  /// 🔹 NEW: Top-level response se parse karo (jisme `collegeDetails` list hoti hai)
  /// Example: final info = CollegeInfo.fromApi(rootMap);
  factory CollegeInfo.fromApi(Map<String, dynamic> root) {
    String s(dynamic v) => (v ?? '').toString();

    final list = (root['collegeDetails'] as List?) ?? [];
    // base fields ke liye first element lo agar ho to
    final base = (list.isNotEmpty ? list.first : <String, dynamic>{}) as Map<String, dynamic>;

    final contacts = list
        .map((e) => CollegePerson.fromJson((e as Map).cast<String, dynamic>()))
        .where((p) => p.fullName.isNotEmpty || p.email.isNotEmpty || p.mobile.isNotEmpty)
        .toList();

    return CollegeInfo(
      name: s(base['college_name']),
      roleName: s(base['roles_name']),
      verification_status: s(base['verification_status']),
      address: s(base['college_address']),
      instituteType: s(base['institute_type']),
      naacGrade: s(base['naac']),
      establishmentYear: s(base['year_of_establishment']),
      ownership: s(base['Ownership'] ?? base['ownership']),
      email: s(base['email'] ?? base['college_email']),
      mobile: s(base['mobile'] ?? base['college_contact']),
      firstname: s(base['first_name']),
      lastname: s(base['last_name']),
      contacts: contacts,
    );
  }
}


class CourseInfo {
  final String courseName;
  final String specialization;
  final String minPackage;
  final String seatOffered;

  CourseInfo({
    required this.courseName,
    required this.specialization,
    required this.minPackage,
    required this.seatOffered,
  });

  // API: data.collegeCourseDetails[*]
  factory CourseInfo.fromApi(Map<String, dynamic> j) {
    int i(dynamic v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      if (v is double) return v.toInt();
      return 0;
    }
    String s(dynamic v) => (v ?? '').toString();

    return CourseInfo(
      courseName: s(j['course_name']),
      specialization: s(j['specialization_name']),
      minPackage: s(j['minpackage'] ?? "-/-"),
      // seatOffered: i(j['seat_offered']),
      seatOffered: s(j['seat_offered'] ?? "-/-"),

    );
  }
}
