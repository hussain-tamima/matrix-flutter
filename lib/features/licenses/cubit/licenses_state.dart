import 'package:equatable/equatable.dart';

class LicensesState extends Equatable {
  const LicensesState(this.packages);

  final List<String> packages;

  @override
  List<Object?> get props => [packages];
}
