import 'package:equatable/equatable.dart';

class LockscreenState extends Equatable {
  const LockscreenState({this.error});

  final String? error;

  @override
  List<Object?> get props => [error];
}
