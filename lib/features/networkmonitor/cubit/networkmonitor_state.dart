import 'package:equatable/equatable.dart';

class NetworkMonitorState extends Equatable {
  const NetworkMonitorState({required this.online});

  final bool online;

  @override
  List<Object?> get props => [online];
}
