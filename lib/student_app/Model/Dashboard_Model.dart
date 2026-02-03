
class DashboardData {
  final ProfileInfo profile;
  final List<OpportunityFeedItem> opportunityFeed;
  final List<ApplicationItem> myApplications;
  final List<Alert> alerts;
  final List<InterviewScheduleItem> interviewSchedule;
  final List<Assessment> assessments;
  final List<Survey> surveys;
  final List<ActivitySeriesItem> activitySeries;
  final DashboardStats stats;

  DashboardData({
    required this.profile,
    required this.opportunityFeed,
    required this.myApplications,
    required this.alerts,
    required this.interviewSchedule,
    required this.assessments,
    required this.surveys,
    required this.activitySeries,
    required this.stats,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      profile: ProfileInfo.fromJson(json['profile'] ?? {}),
      opportunityFeed: (json['opportunityFeed'] as List?)
          ?.map((e) => OpportunityFeedItem.fromJson(e))
          .toList() ?? [],
      myApplications: (json['myApplications'] as List?)
          ?.map((e) => ApplicationItem.fromJson(e))
          .toList() ?? [],
      alerts: (json['alerts'] as List?)
          ?.map((e) => Alert.fromJson(e))
          .toList() ?? [],
      interviewSchedule: (json['interviewSchedule'] as List?)
          ?.map((e) => InterviewScheduleItem.fromJson(e))
          .toList() ?? [],
      assessments: (json['assessments'] as List?)
          ?.map((e) => Assessment.fromJson(e))
          .toList() ?? [],
      surveys: (json['surveys'] as List?)
          ?.map((e) => Survey.fromJson(e))
          .toList() ?? [],
      activitySeries: (json['activitySeries'] as List?)
          ?.map((e) => ActivitySeriesItem.fromJson(e))
          .toList() ?? [],
      stats: DashboardStats.fromJson(json['stats'] ?? {}),
    );
  }
}

class ProfileInfo {
  final String name;
  final String college;
  final String stream;
  final String year;
  final int completion; // 0-100
  final bool jobLockActive;
  final ActiveJob? activeJob;

  ProfileInfo({
    required this.name,
    required this.college,
    required this.stream,
    required this.year,
    required this.completion,
    required this.jobLockActive,
    this.activeJob,
  });

  factory ProfileInfo.fromJson(Map<String, dynamic> json) {
    return ProfileInfo(
      name: json['name'] ?? '',
      college: json['college'] ?? '',
      stream: json['stream'] ?? '',
      year: json['year'] ?? '',
      completion: json['completion'] ?? 0,
      jobLockActive: json['jobLockActive'] ?? false,
      activeJob: json['activeJob'] != null 
          ? ActiveJob.fromJson(json['activeJob'])
          : null,
    );
  }
}

class ActiveJob {
  final String company;
  final String role;
  final String status;
  final String? nextStep;
  final int jobId;
  final String jobSlug;
  final String jobInvitationToken;

  ActiveJob({
    required this.company,
    required this.role,
    required this.status,
    this.nextStep,
    required this.jobId,
    required this.jobSlug,
    required this.jobInvitationToken,
  });

  factory ActiveJob.fromJson(Map<String, dynamic> json) {
    return ActiveJob(
      company: json['company'] ?? '',
      role: json['role'] ?? '',
      status: json['status'] ?? '',
      nextStep: json['nextStep'],
      jobId: json['job_id'] ?? 0,
      jobSlug: json['job_slug'] ?? '',
      jobInvitationToken: json['job_invitation_token'] ?? '',
    );
  }
}

class OpportunityFeedItem {
  final String id;
  final String type; // 'Job' or 'Internship'
  final String company;
  final String role;
  final String location;
  final String stipend; // e.g., "CTC ₹45"
  final String deadline; // e.g., "2027-01-31"
  final bool eligible;
  final int jobId; // Job ID for API calls (optional - fallback to id)
  final String jobSlug; // Job slug (optional)
  final String jobInvitationToken; // Token for job detail API (optional - fallback to id)
  final String companyLogo; // Company logo URL
  final String costToCompany; // CTC value for LPA formatting

  OpportunityFeedItem({
    required this.id,
    required this.type,
    required this.company,
    required this.role,
    required this.location,
    required this.stipend,
    required this.deadline,
    required this.eligible,
    this.jobId = 0,
    this.jobSlug = '',
    this.jobInvitationToken = '',
    this.companyLogo = '',
    this.costToCompany = '',
  });

  factory OpportunityFeedItem.fromJson(Map<String, dynamic> json) {
    // Safe string conversion helper
    String safeToString(dynamic value) {
      if (value == null) return '';
      return value.toString().trim();
    }

    // If jobInvitationToken is empty, fallback to id
    final String invitationToken = safeToString(json['job_invitation_token']);
    final String fallbackToken = invitationToken.isNotEmpty ? invitationToken : safeToString(json['id']);
    
    // If jobId is 0, try to parse id as fallback
    final int jobIdValue = (json['job_id'] is int) ? (json['job_id'] ?? 0) : (int.tryParse(safeToString(json['job_id'])) ?? 0);
    final int fallbackJobId = jobIdValue > 0 ? jobIdValue : (int.tryParse(safeToString(json['id'])) ?? 0);
    
    // Safe bool conversion
    bool safeToBool(dynamic value) {
      if (value is bool) return value;
      if (value is int) return value != 0;
      if (value is String) return value.toLowerCase() == 'true';
      return false;
    }
    
    return OpportunityFeedItem(
      id: safeToString(json['id']),
      type: safeToString(json['type']).isEmpty ? 'Job' : safeToString(json['type']),
      company: safeToString(json['company']),
      role: safeToString(json['role']),
      location: safeToString(json['location']),
      stipend: safeToString(json['stipend']),
      deadline: safeToString(json['deadline']),
      eligible: safeToBool(json['eligible']),
      jobId: fallbackJobId,
      jobSlug: safeToString(json['job_slug']),
      jobInvitationToken: fallbackToken,
      companyLogo: safeToString(json['company_logo']),
      costToCompany: safeToString(json['cost_to_company']),
    );
  }
}

class ApplicationItem {
  final int id;
  final String company;
  final String role;
  final String type; // 'Job' or 'Internship'
  final String status; // 'Applied', 'Cv Shortlist', 'Final Selected', 'Hold/Follow up'
  final String updated; // Date string
  final int jobId;
  final String jobSlug;
  final String jobInvitationToken;

  ApplicationItem({
    required this.id,
    required this.company,
    required this.role,
    required this.type,
    required this.status,
    required this.updated,
    required this.jobId,
    required this.jobSlug,
    required this.jobInvitationToken,
  });

  factory ApplicationItem.fromJson(Map<String, dynamic> json) {
    // Try to get company and role from the response
    // If not available, use fallback or empty string
    String company = json['company'] ?? '';
    String role = json['role'] ?? json['job_title'] ?? '';
    
    // Extract from activeJob if available (preferred source)
    final activeJob = json['activeJob'] as Map<String, dynamic>?;
    
    // Extract job_id with proper fallback
    int jobId = 0;
    if (activeJob != null && activeJob['job_id'] != null) {
      jobId = int.tryParse(activeJob['job_id'].toString()) ?? 0;
    } else if (json['job_id'] != null) {
      jobId = int.tryParse(json['job_id'].toString()) ?? 0;
    }
    
    // Extract job_slug
    String jobSlug = '';
    if (activeJob != null && activeJob['job_slug'] != null) {
      jobSlug = activeJob['job_slug'].toString();
    } else if (json['job_slug'] != null) {
      jobSlug = json['job_slug'].toString();
    }
    
    // Extract job_invitation_token - IMPORTANT: Get from activeJob first!
    String jobInvitationToken = '';
    if (activeJob != null && activeJob['job_invitation_token'] != null) {
      jobInvitationToken = activeJob['job_invitation_token'].toString();
    } else if (json['job_invitation_token'] != null) {
      jobInvitationToken = json['job_invitation_token'].toString();
    }
    
    // If still empty, try to format from job_slug
    if (role.isEmpty && jobSlug.isNotEmpty) {
      // Convert slug like "trainee-ai-engineer-205219262" to "Trainee AI Engineer"
      role = jobSlug
          .split('-')
          .where((word) => !word.contains(RegExp(r'^\d+$')))
          .map((word) => word[0].toUpperCase() + word.substring(1))
          .join(' ');
    }
    
    return ApplicationItem(
      id: json['id'] ?? 0,
      company: company,
      role: role,
      type: json['type'] ?? 'Job',
      status: json['status'] ?? (activeJob?['status'] ?? '') as String,
      updated: json['updated'] ?? '',
      jobId: jobId,
      jobSlug: jobSlug,
      jobInvitationToken: jobInvitationToken,
    );
  }
}

class Alert {
  final String id;
  final String text;
  final String kind; // 'interview', 'assessment', 'survey', etc.

  Alert({
    required this.id,
    required this.text,
    required this.kind,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      kind: json['kind'] ?? '',
    );
  }
}

class InterviewScheduleItem {
  final int id;
  final String interviewDate; // e.g., "2026-02-02"
  final String startTime; // e.g., "11:00"
  final String endTime; // e.g., "12:00"
  final String interviewName; // e.g., "Personal Interview"
  final String role;
  final String company;
  final String mode; // e.g., 'manual', 'automated'
  final String meetingLink; // URL for joining
  final String meetingMode; // 'online', 'offline'
  final String companyLogo; // Company logo URL

  InterviewScheduleItem({
    required this.id,
    required this.interviewDate,
    required this.startTime,
    required this.endTime,
    required this.interviewName,
    required this.role,
    required this.company,
    required this.mode,
    required this.meetingLink,
    required this.meetingMode,
    required this.companyLogo,
  });

  factory InterviewScheduleItem.fromJson(Map<String, dynamic> json) {
    return InterviewScheduleItem(
      id: json['id'] ?? 0,
      interviewDate: json['interview_date'] ?? json['when'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      interviewName: json['interview_name'] ?? '',
      role: json['job_title'] ?? '',
      company: json['company_name'] ?? '',
      mode: json['platform'] ?? 'manual',
      meetingLink: json['meeting_link'] ?? '',
      meetingMode: json['meeting_mode'] ?? 'online',
      companyLogo: json['company_logo'] ?? '',
    );
  }
}

class Assessment {
  final String? id;
  final String? title;
  final String? status;

  Assessment({
    this.id,
    this.title,
    this.status,
  });

  factory Assessment.fromJson(Map<String, dynamic> json) {
    return Assessment(
      id: json['id'] != null ? json['id'].toString() : null,
      title: json['title'] != null ? json['title'].toString() : null,
      status: json['status'] != null ? json['status'].toString() : null,
    );
  }
}

class Survey {
  final String? id;
  final String? title;
  final String? status;

  Survey({
    this.id,
    this.title,
    this.status,
  });

  factory Survey.fromJson(Map<String, dynamic> json) {
    return Survey(
      id: json['id'] != null ? json['id'].toString() : null,
      title: json['title'] != null ? json['title'].toString() : null,
      status: json['status'] != null ? json['status'].toString() : null,
    );
  }
}

class ActivitySeriesItem {
  final String day; // 'Mon', 'Tue', etc.
  final int applied; // Number of applications that day

  ActivitySeriesItem({
    required this.day,
    required this.applied,
  });

  factory ActivitySeriesItem.fromJson(Map<String, dynamic> json) {
    return ActivitySeriesItem(
      day: json['day'] ?? '',
      applied: json['applied'] ?? 0,
    );
  }
}

class DashboardStats {
  final int applications;
  final int interviewsThisWeek;
  final int assessmentsTaken;
  final int surveysAssigned;

  DashboardStats({
    required this.applications,
    required this.interviewsThisWeek,
    required this.assessmentsTaken,
    required this.surveysAssigned,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      applications: json['applications'] ?? 0,
      interviewsThisWeek: json['interviewsThisWeek'] ?? 0,
      assessmentsTaken: json['assessmentsTaken'] ?? 0,
      surveysAssigned: json['surveysAssigned'] ?? 0,
    );
  }
}
