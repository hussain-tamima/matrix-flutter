import 'package:equatable/equatable.dart';

class AnalyticsState extends Equatable {
  const AnalyticsState({required this.enabled});

  final bool enabled;

  @override
  List<Object?> get props => [enabled];
}
