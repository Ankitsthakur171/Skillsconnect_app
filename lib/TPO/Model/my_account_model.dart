// class ProfileModel {
//   final String name;
//   final String role;
//   final String phone;
//   final String whatsapp;
//   final String email;
//   final String location;
//   final String linkedin;
//   final String imageUrl; // 👈 ab String? ki jagah String kar diya
//   final String collegename; // 👈 ab String? ki jagah String kar diya
//   final int profileCompletion;
//
//   ProfileModel({
//     required this.name,
//     required this.role,
//     required this.phone,
//     required this.whatsapp,
//     required this.email,
//     required this.location,
//     required this.linkedin,
//     required this.imageUrl,
//     required this.collegename,
//     required this.profileCompletion,
//   });
//
//   factory ProfileModel.fromJson(Map<String, dynamic> json) {
//     return ProfileModel(
//       name: '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim(),
//       role: json['role'] ?? 'College TPO',
//       phone: json['mobile'] ?? '',
//       whatsapp: json['whatsapp_number'] ?? '',
//       email: json['email'] ?? '',
//       location: json['location'] ?? 'Mumbai, Maharashtra',
//       linkedin: json['linkedin'] ?? 'https://linkedin.com',
//       imageUrl: json['user_image'] ?? '', // 👈 null aaya to empty string
//       collegename: json['college'] ?? 'ACURA HRM', // 👈 null aaya to empty string
//       profileCompletion: json['profile_completion'] ?? 90, // 👈 ya default 90
//     );
//   }
// }



class ProfileModel {
  final String name;
  final String role;
  final String phone;
  final String whatsapp;
  final String email;
  final String location;       // API me nahi hai -> default
  final String linkedin;
  final String imageUrl;
  final String collegename;
  final int profileCompletion; // API me nahi hai -> default

  ProfileModel({
    required this.name,
    required this.role,
    required this.phone,
    required this.whatsapp,
    required this.email,
    required this.location,
    required this.linkedin,

    required this.imageUrl,
    required this.collegename,
    required this.profileCompletion,
  });

  /// ⬇️ NEW: API ke nested structure se parse
  // factory ProfileModel.fromApi(Map<String, dynamic> root) {
  //   final details = (root['details'] as Map?) ?? const {};
  //   final tpoList = (details['tpoDetails'] as List?) ?? const [];
  //   final roleList = (details['role_name'] as List?) ?? const [];
  //   final collegeList = (details['college_name'] as List?) ?? const [];
  //
  //   final tpo = (tpoList.isNotEmpty ? tpoList.first : const {}) as Map<String, dynamic>;
  //   final roleObj = (roleList.isNotEmpty ? roleList.first : const {}) as Map<String, dynamic>;
  //   final collegeObj = (collegeList.isNotEmpty ? collegeList.first : const {}) as Map<String, dynamic>;
  //
  //   final firstName = (tpo['first_name'] ?? '').toString();
  //   final lastName  = (tpo['last_name'] ?? '').toString();
  //   final fullName  = '$firstName $lastName'.trim();
  //
  //   return ProfileModel(
  //     name: fullName.isEmpty ? 'Name' : fullName,
  //     role: (roleObj['role_name'] ?? 'TPO').toString(),
  //     phone: (tpo['mobile'] ?? '').toString(),
  //     whatsapp: (tpo['whatsapp_number'] ?? '').toString(),
  //     email: (tpo['email'] ?? '').toString(),
  //     location: 'Mumbai, Maharashtra', // default (API me nahi aa raha)
  //     linkedin: (tpo['linkedin'] ?? 'https://linkedin.com').toString(),
  //     imageUrl: (tpo['user_image'] ?? '').toString(),
  //     collegename: (collegeObj['college_name'] ?? 'ACURA HRM').toString(),
  //     profileCompletion: 90, // default (API me nahi aa raha)
  //   );
  // }
  factory ProfileModel.fromApi(Map<String, dynamic> root) {
    // type-safe copies
    final details     = Map<String, dynamic>.from(root['details'] ?? {});
    final tpoList     = (details['tpoDetails'] as List? ?? const []);
    final roleList    = (details['role_name']  as List? ?? const []);
    final collegeList = (details['college_name'] as List? ?? const []);

    final tpo        = tpoList.isNotEmpty ? Map<String, dynamic>.from(tpoList.first) : <String, dynamic>{};
    final roleObj    = roleList.isNotEmpty ? Map<String, dynamic>.from(roleList.first) : <String, dynamic>{};
    final collegeObj = collegeList.isNotEmpty ? Map<String, dynamic>.from(collegeList.first) : <String, dynamic>{};

    String _safeStr(dynamic v, {String fallback = ''}) {
      final s = (v ?? '').toString().trim();
      return s.isEmpty ? fallback : s;
    }

    final firstName = _safeStr(tpo['first_name']);
    final lastName  = _safeStr(tpo['last_name']);
    final fullName  = ('$firstName $lastName').trim().replaceAll(RegExp(r'\s+'), ' ');

    final img = _safeStr(tpo['user_image']); // API se '' aa sakta hai
    final role = _safeStr(roleObj['role_name'], fallback: 'TPO');
    final college = _safeStr(collegeObj['college_name'], fallback: 'ACURA HRM');

    return ProfileModel(
      name: fullName.isEmpty ? 'Name' : fullName,
      role: role,
      phone: _safeStr(tpo['mobile']),
      whatsapp: _safeStr(tpo['whatsapp_number']),
      email: _safeStr(tpo['email']),
      location: 'Mumbai, Maharashtra',           // API me nahi—default OK
      linkedin: _safeStr(tpo['linkedin']),       // empty hua to '' hi rahega
      imageUrl: img,                              // UI me placeholder handle karna
      collegename: college,
      profileCompletion: 90,                      // default OK
    );
  }

}
