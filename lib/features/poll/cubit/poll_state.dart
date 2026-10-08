import 'package:equatable/equatable.dart';

class PollState extends Equatable {
  const PollState({this.error, this.created = false});

  final String? error;
  final bool created;

  @override
  List<Object?> get props => [error, created];
}
