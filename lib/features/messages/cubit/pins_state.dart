import 'package:equatable/equatable.dart';
import 'package:element_x/core/matrix/matrix_models.dart';

class PinsState extends Equatable {
  const PinsState({this.events = const []});

  final List<TimelineEvent> events;

  @override
  List<Object?> get props => [events];
}
