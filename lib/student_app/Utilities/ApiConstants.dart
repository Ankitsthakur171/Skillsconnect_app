
class ApiConstantsStu {
  static const String baseUrl = "https://api.skillsconnect.in/";
  static const String subUrl = "${baseUrl}dcxqyqzqpdydfk/mobile/";

  //job Apply url & sign up page
  static const jobApplyUrlLink = "https://api.skillsconnect.in/job-profile/";
  static const signupLink = 'https://skillsconnect.in/sign-up';

  //Auth
  static const loginUrl = "${subUrl}auth/login";
  static const requestOtp = "${subUrl}auth/request-login-otp";
  static const forget_password = "${subUrl}auth/forget-password";
  static const verify_otp = "${subUrl}auth/verify-otp";
  static const reset_password = "${subUrl}auth/change-password";
  static const logout = "${subUrl}auth/logout";

  //Master
  static const all_courses = "${subUrl}master/course/list";
  static const applied_jobs = "${subUrl}jobs";
  static const bookmark_add = "${subUrl}common/bookmark";
  static const bookmarkList =  "${subUrl}common/list-Bookmarks";
  // static const bookmark_status = "${subUrl}common/bookmark/status?module=$module&module_id=$moduleId;
  static const city_list = "${subUrl}master/city/list";
  static const college_list  = "${subUrl}common/get-college-list";
  static const interview_screen = "${subUrl}interview-room/list";
  static const job_detail = "${subUrl}jobs/details";
  static const jobList = "${subUrl}jobs";
  static const languageApi = "${subUrl}master/language/list";
  static const specializationListUrl = "${subUrl}master/courses-specilization/list";
  static const stateListUrl  = "${subUrl}master/state/list";
  static const degreeTypeApi = "${subUrl}master/degree/list";
  static const boardApi = "${subUrl}master/board/list";
  static const MediumApi = "${subUrl}master/medium/list";
  static const homeScreenApi = "${subUrl}jobs/home";
  static const accountScreenUrl = "${subUrl}profile/student/personal-details";
  static const certificateDetailsUrl = "${subUrl}profile/student/certification-details";
  static const certificateUpdateUrl = "${subUrl}profile/student/update-certification";
  static const educationDetails = "${subUrl}profile/student/education-details";
  static const internshipDetails  = "${subUrl}profile/student/project-internship-details";
  static const updateInternshipDetails = "${subUrl}profile/student/update-project-internship";
  static const fetchLanguageApi = "${subUrl}profile/student/language-details";
  static const updateLanguageApi = "${subUrl}profile/student/update-languages";
  static const fetchIntroVideos = "${subUrl}profile/student/video-intro-details";
  static const updateIntroVideos = "${subUrl}profile/student/update-video";
  static const personalDetailApi = "${subUrl}profile/student/personal-details";
  static const updatePersonalDetail = "${subUrl}profile/student/update-personal-details";
  static const fetchResume = "${subUrl}profile/student/resume";
  static const updateResume = "${subUrl}profile/student/update-resume";
  static const fetchSkills = "${subUrl}profile/student/skills-details";
  static const updateSkills = "${subUrl}profile/student/update-skills";
  static const fetchWorkExperience = "${subUrl}profile/student/work-experience-details";
  static const updateWorkExperience = "${subUrl}profile/student/update-student-work-experience";
  static const jobLocationApi = "${subUrl}jobs/locations";

}
