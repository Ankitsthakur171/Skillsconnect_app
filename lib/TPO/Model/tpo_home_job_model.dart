import 'package:intl/intl.dart';

class TpoHomeJobModel {
  final String title;
  final String companyname;
  final String location;
  final String jobtype;
  final String mode;
  final String ctc;
  final String status;
  final String expiryNotice;
  final int applicants;
  final int jobId;
  final int Id;
  final int CustId;
  final String job_link;

  TpoHomeJobModel({
    required this.title,
    required this.companyname,
    required this.location,
    required this.jobtype,
    required this.mode,
    required this.ctc,
    required this.status,
    required this.expiryNotice,
    required this.applicants,
    required this.jobId,
    required this.Id,
    required this.CustId,
    required this.job_link,
  });

  factory TpoHomeJobModel.fromJson(Map<String, dynamic> json) {
    // Calculate expiry notice from end_date
    String expiryText = 'Job expires soon';
    try {
      if (json['end_date'] != null) {
        final endDate = DateTime.parse(json['end_date']);
        final now = DateTime.now();
        final difference = endDate.difference(now).inDays;

        if (difference > 0) {
          expiryText = 'Job expires in $difference days';
        } else if (difference == 0) {
          expiryText = 'Job expires today';
        } else {
          expiryText = 'Job expired';
        }
      }
    } catch (e) {
      expiryText = 'Expiry date not available';
    }

    return TpoHomeJobModel(
      title: json['title']?.toString() ?? '',
      companyname: json['company_name']?.toString() ?? '',
      location: json['city_name']?.toString() ?? 'Na',
      jobtype: json['job_type']?.toString() ?? '',
      mode: json['opportunity_type']?.toString() ?? '',
      ctc: json['cost_to_company']?.toString() ?? '',
      status: json['job_status']?.toString() ?? '',
      expiryNotice: expiryText,
      applicants: json['cv_received'] is int
          ? json['cv_received']
          : int.tryParse(json['cv_received']?.toString() ?? '') ?? 0,
      jobId: json['job_id'] is int
          ? json['job_id']
          : int.tryParse(json['job_id']?.toString() ?? '') ?? 0,
      Id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      CustId: json['cutm_id'] is int
          ? json['cutm_id']
          : int.tryParse(json['cutm_id']?.toString() ?? '') ?? 0,
        job_link : json['job_link']?.toString() ??   ''

    );
  }
}
