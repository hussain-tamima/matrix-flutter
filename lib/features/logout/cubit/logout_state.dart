import 'package:equatable/equatable.dart';

class LogoutState extends Equatable {
  const LogoutState({this.done = false});

  final bool done;

  @override
  List<Object?> get props => [done];
}
