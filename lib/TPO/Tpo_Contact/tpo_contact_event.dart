abstract class TpoContactEvent {}

class TpoLoadContact extends TpoContactEvent {

  final int page;
  final int limit;

  TpoLoadContact({required this.page, this.limit = 10});

}