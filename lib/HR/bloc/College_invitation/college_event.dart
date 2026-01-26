abstract class CollegeEvent {}

class LoadInitialColleges extends CollegeEvent {
  final String collegeName;
  final String selectedState;
  final String selectedcity;
  final String instituteType;
  final String course;
  final String specialization;
  final String naacgrade;
  final String mylistname;
  final String collegestatus;
  final int jobId;
  final String type;



  LoadInitialColleges({
    this.collegeName = '',
    this.selectedState = '',
    this.selectedcity = '',
    this.instituteType = '',
    this.course = '',
    this.specialization = '',
    this.naacgrade = '',
    this.mylistname = '',
    this.collegestatus = '',
    required this.jobId,
    this.type = 'invitation', required int page,

  });
}

class LoadMoreColleges extends CollegeEvent {
  final String collegeName;
  final String selectedState;
  final String selectedcity;
  final String instituteType;
  final String course;
  final String specialization;
  final String naacgrade;
  final String mylistname;
  final String collegestatus;
  final int jobId;
  final String type;




  LoadMoreColleges({
    this.collegeName = '',
    this.selectedState = '',
    this.selectedcity = '',
    this.instituteType = '',
    this.course = '',
    this.specialization = '',
    this.naacgrade = '',
    this.mylistname = '',
    this.collegestatus = '',
    required this.jobId,
    this.type = 'invitation',required int page


  });
}


class SearchCollegeEvent extends CollegeEvent {
  final String query;          // ← yahi API me "college_name" banega
  final int jobId;

  // ✅ same filter fields as ApplyFilterCollegeEvent
  final String collegeName;
  final String selectedState;
  final String selectedcity;
  final String instituteType;
  final String course;
  final String specialization;
  final String naacgrade;
  final String mylistname;
  final String collegestatus;

  final String type;
  final int page;              // optional (for pagination in search)

  SearchCollegeEvent({
    required this.query,
    required this.jobId,

    this.collegeName = '',
    this.selectedState = '',
    this.selectedcity = '',
    this.instituteType = '',
    this.course = '',
    this.specialization = '',
    this.naacgrade = '',
    this.mylistname = '',
    this.collegestatus = '',
    this.type = 'invitation',
    this.page = 1,
  });
}


// class SearchCollegeEvent extends CollegeEvent {
//   final String query;
//   final int jobId;
//   final String selectedState;
//   final String selectedcity;
//
//   final String type;
//
//   SearchCollegeEvent({
//     required this.query,
//     required this.jobId,
//     required this.selectedState,
//     required this.selectedcity,
//
//     this.type = 'invitation',
//   });
// }


class ApplyFilterCollegeEvent extends CollegeEvent {
  final int jobId;
  final String? collegeName;
  final String? selectedState;
  final String? selectedcity;
  final String? collegestatus;
  final String? instituteType;
  final String? course;
  final String? naacgrade;
  final String? mylistname;
  final String? specialization;
  final String type;

  ApplyFilterCollegeEvent({
    required this.jobId,
    this.collegeName,
    this.selectedState,
    this.selectedcity,
    this.collegestatus,
    this.instituteType,
    this.course,
    this.naacgrade,
    this.mylistname,
    this.specialization,
    this.type = 'invitation',
  });

}


