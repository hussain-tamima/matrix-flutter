import 'package:equatable/equatable.dart';

class DeactivationState extends Equatable {
  const DeactivationState({this.error, this.done = false});

  final String? error;
  final bool done;

  @override
  List<Object?> get props => [error, done];
}
