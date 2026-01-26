import '../../model/college_invitation_model.dart';

// 2. Update your CollegeState
abstract class CollegeState {
  final List<College> colleges;

  CollegeState({required this.colleges});


}

class CollegeInitial extends CollegeState {
  CollegeInitial() : super(colleges: []);
}

class CollegeLoading extends CollegeState {
  CollegeLoading({required super.colleges,});
}

class CollegeLoaded extends CollegeState {
  final List<College> colleges;
  final bool hasReachedMax;
  final int currentPage;
  final String type;
  final List<College> filteredList;
  final bool isSearchMode;
  final String inviteCount; // 👈 NEW



  CollegeLoaded({
    required this.colleges,
    required this.hasReachedMax,
    required this.currentPage,
    required this.type,
    this.filteredList = const [],
    this.isSearchMode = false,
    this.inviteCount = "", // 👈 default empty

  }) : super(colleges: colleges);

  CollegeLoaded copyWith({
    List<College>? colleges,
    bool? hasReachedMax,
    int? currentPage,
    String? type,
    List<College>? filteredList,
    bool? isSearchMode,
    String? inviteCount,
  }) {
    return CollegeLoaded(
      colleges: colleges ?? this.colleges,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      type: type ?? this.type,
      filteredList: filteredList ?? this.filteredList,
      isSearchMode: isSearchMode ?? this.isSearchMode,
      inviteCount: inviteCount ?? this.inviteCount,
    );
  }
}

class CollegeError extends CollegeState {
  final String error;

  CollegeError({
    required this.error,
    required super.colleges,
  });
}