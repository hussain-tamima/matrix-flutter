import 'package:equatable/equatable.dart';

class ReportRoomState extends Equatable {
  const ReportRoomState({this.error, this.submitted = false});

  final String? error;
  final bool submitted;

  @override
  List<Object?> get props => [error, submitted];
}
