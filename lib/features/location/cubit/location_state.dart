import 'package:equatable/equatable.dart';

class LocationState extends Equatable {
  const LocationState({required this.enabled, this.shared = false, this.error});

  final bool enabled;
  final bool shared;
  final String? error;

  @override
  List<Object?> get props => [enabled, shared, error];
}
