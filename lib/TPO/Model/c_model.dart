// c_model.dart
class InstituteListingResponse {
  final bool success;
  final List<InstituteModel> data;
  final InstituteMeta meta;

  InstituteListingResponse({
    required this.success,
    required this.data,
    required this.meta,
  });

  factory InstituteListingResponse.fromJson(Map<String, dynamic> json) {
    return InstituteListingResponse(
      success: (json['success'] == true),
      data: (json['data'] as List? ?? [])
          .map((e) => InstituteModel.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      meta: InstituteMeta.fromJson((json['meta'] as Map).cast<String, dynamic>()),
    );
  }
}

class InstituteModel {
  final String fullName;
  final String firstName;
  final String lastName;
  final int userId;
  final String? userImage;
  final DateTime? createdOn;
  final String email;
  final String mobile;
  final String status;
  final int userType;
  final int id;
  final int frecordId;
  final String collegeName;
  final String stateName;
  final String cityName;
  final String courseName;
  final String marks;
  final String passing_year;
  final String grade_type;

  InstituteModel({
    required this.fullName,
    required this.firstName,
    required this.lastName,
    required this.userId,
    required this.userImage,
    required this.createdOn,
    required this.email,
    required this.mobile,
    required this.status,
    required this.userType,
    required this.id,
    required this.frecordId,
    required this.collegeName,
    required this.stateName,
    required this.cityName,
    required this.courseName,
    required this.marks,
    required this.passing_year,
    required this.grade_type,
  });

  factory InstituteModel.fromJson(Map<String, dynamic> json) {
    return InstituteModel(
      fullName: (json['full_name'] ?? '').toString(),
      firstName: (json['first_name'] ?? '').toString(),
      lastName: (json['last_name'] ?? '').toString(),
      userId: int.tryParse((json['user_id'] ?? json['id'] ?? '0').toString()) ?? 0,
      userImage: (json['user_image']?.toString().isNotEmpty == true)
          ? json['user_image'].toString()
          : null,
      createdOn: json['created_on'] != null
          ? DateTime.tryParse(json['created_on'].toString())
          : null,
      email: (json['email'] ?? '').toString(),
      mobile: (json['mobile'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      userType: int.tryParse((json['user_type'] ?? '0').toString()) ?? 0,
      id: int.tryParse((json['id'] ?? '0').toString()) ?? 0,
      frecordId: int.tryParse((json['frecord_id'] ?? '0').toString()) ?? 0,
      collegeName: (json['college_name'] ?? '').toString(),
      stateName: (json['state_name'] ?? '').toString(),
      cityName: (json['city_name'] ?? '').toString(),
      courseName: (json['course_name'] ?? '').toString(),
      marks: (json['marks'] ?? '').toString(),
      passing_year: (json['passing_year'] ?? '').toString(),
      grade_type: (json['type'] ?? '').toString(),
    );
  }
}

class InstituteMeta {
  final int total;
  final int perPage;
  final int offset;
  final int currentPage;
  final int totalPages;
  final String sortBy;
  final String order;

  InstituteMeta({
    required this.total,
    required this.perPage,
    required this.offset,
    required this.currentPage,
    required this.totalPages,
    required this.sortBy,
    required this.order,
  });

  factory InstituteMeta.fromJson(Map<String, dynamic> json) {
    return InstituteMeta(
      total: int.tryParse((json['total'] ?? '0').toString()) ?? 0,
      perPage: int.tryParse((json['per_page'] ?? '0').toString()) ?? 0,
      offset: int.tryParse((json['offset'] ?? '0').toString()) ?? 0,
      currentPage: int.tryParse((json['current_page'] ?? '0').toString()) ?? 0,
      totalPages: int.tryParse((json['total_pages'] ?? '0').toString()) ?? 0,
      sortBy: (json['sort_by'] ?? '').toString(),
      order: (json['order'] ?? '').toString(),
    );
  }
}
