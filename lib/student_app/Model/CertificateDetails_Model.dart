class CertificateModel {
  final String? certificationId;
  final String certificateName;
  final String issuedOrgName;
  final String credId;
  final String issueDate;
  final String expiryDate;
  final String description;
  final String url;
  final String? exStartMonth;
  final String? exStartYear;
  final String? exEndMonth;
  final String? exEndYear;
  final int? userId;

  CertificateModel({
    this.certificationId,
    required this.certificateName,
    required this.issuedOrgName,
    required this.credId,
    required this.issueDate,
    required this.expiryDate,
    required this.description,
    required this.url,
    this.exStartMonth,
    this.exStartYear,
    this.exEndMonth,
    this.exEndYear,
    this.userId,
  });

  factory CertificateModel.fromJson(Map<String, dynamic> json) {
    String issueDate = '';
    if (json['issue_date'] != null) {
      final parts = json['issue_date'].toString().split('-');
      if (parts.length == 2) {
        final month = monthToNumber(parts[0]);
        final year = parts[1];
        issueDate = '$year-$month';
      }
    }

    String expiryDate = '';
    if (json['expire_date'] != null) {
      final parts = json['expire_date'].toString().split('-');
      if (parts.length == 2) {
        final month = monthToNumber(parts[0]);
        final year = parts[1];
        expiryDate = '$year-$month';
      }
    }

    return CertificateModel(
      certificationId:
          json['certificationId']?.toString() ?? json['id']?.toString(),
      certificateName: json['certification_name'] ?? '',
      issuedOrgName: json['issued_org_name'] ?? '',
      credId: json['cred_id'] ?? '',
      issueDate: issueDate.isEmpty ? '2025-01' : issueDate,
      expiryDate: expiryDate.isEmpty ? '2025-01' : expiryDate,
      description: json['description'] ?? '',
      url: json['cred_url'] ?? '',
      exStartMonth: json['exStartMonth']?.toString(),
      exStartYear: json['exStartYear']?.toString(),
      exEndMonth: json['exEndMonth']?.toString(),
      exEndYear: json['exEndYear']?.toString(),
      userId: json['user_id'],
    );
  }

  Map<String, dynamic> toJson({bool isNew = false}) {
    final issueParts = issueDate.split('-');
    final expiryParts = expiryDate.split('-');

    return {
      if (!isNew && certificationId != null) 'certificationId': certificationId,
      'certification_name': certificateName,
      'org_name': issuedOrgName,
      'crd_id': credId,
      'crd_url': url,
      'description': description,
      'exStartMonth': issueParts.length == 2
          ? numberToMonth(issueParts[1])
          : exStartMonth,
      'exStartYear': issueParts.length == 2 ? issueParts[0] : exStartYear,
      'exEndMonth': expiryParts.length == 2
          ? numberToMonth(expiryParts[1])
          : exEndMonth,
      'exEndYear': expiryParts.length == 2 ? expiryParts[0] : exEndYear,
      if (userId != null) 'user_id': userId,
    };
  }

  static String numberToMonth(String monthNumber) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final index = (int.tryParse(monthNumber) ?? 1).clamp(1, 12) - 1;
    return months[index];
  }

  static String monthToNumber(String month) {
    const months = {
      'Jan': '01',
      'Feb': '02',
      'Mar': '03',
      'Apr': '04',
      'May': '05',
      'Jun': '06',
      'Jul': '07',
      'Aug': '08',
      'Sep': '09',
      'Oct': '10',
      'Nov': '11',
      'Dec': '12',
    };

    final normalizedMonth = month.length > 3
        ? fullToShortMonth(month)
        : month
              .substring(0, month.length < 3 ? month.length : 3)
              .toLowerCase()
              .replaceFirstMapped(
                RegExp(r'^[a-z]'),
                (m) => m.group(0)!.toUpperCase(),
              );

    return months[normalizedMonth] ?? '01';
  }

  static String fullToShortMonth(String fullMonth) {
    const fullToShort = {
      'January': 'Jan',
      'February': 'Feb',
      'March': 'Mar',
      'April': 'Apr',
      'May': 'May',
      'June': 'Jun',
      'July': 'Jul',
      'August': 'Aug',
      'September': 'Sep',
      'October': 'Oct',
      'November': 'Nov',
      'December': 'Dec',
    };
    return fullToShort[fullMonth] ?? 'Jan';
  }
}
