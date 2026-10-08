import 'package:equatable/equatable.dart';

class MigrationState extends Equatable {
  const MigrationState(this.summary);

  final String summary;

  @override
  List<Object?> get props => [summary];
}
