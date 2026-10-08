import 'package:equatable/equatable.dart';
import 'package:element_x/core/matrix/matrix_models.dart';

class ThreadState extends Equatable {
  const ThreadState({this.root, this.events = const []});

  final TimelineEvent? root;
  final List<TimelineEvent> events;

  @override
  List<Object?> get props => [root, events];
}
