import 'package:equatable/equatable.dart';

class EnterpriseState extends Equatable {
  const EnterpriseState({required this.available});

  final bool available;

  @override
  List<Object?> get props => [available];
}
